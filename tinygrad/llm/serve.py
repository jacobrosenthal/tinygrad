from __future__ import annotations
import base64, functools, json, pathlib, queue, re, socket, socketserver, threading, time, traceback, typing, urllib.request, uuid
from typing import TYPE_CHECKING
from tinygrad.helpers import DEBUG, colored, stderr_log, getenv
from tinygrad.viz.serve import TCPServerWithReuse, Handler as VizHandler
if TYPE_CHECKING:
  from tinygrad.llm.cli import SimpleTokenizer
  from tinygrad.llm.model import Transformer

def _param_types(tools:list|None, name:str) -> dict[str, typing.Any]:
  """declared JSON-schema type of each parameter of tool `name` (from the request's OpenAI `tools`)"""
  for t in tools or []:
    if (f := t.get("function", t)).get("name") == name: return {k: v.get("type") for k, v in f.get("parameters", {}).get("properties", {}).items()}
  return {}

def parse_tool_call(s:str, tools:list|None=None) -> tuple[str, typing.Any]|None:
  s = s.strip()
  # Kimi-K3 format: tool="name" index="1"<|sep|><|open|>argument key="key" type="string"<|sep|>value<|close|>argument<|sep|>...
  if (m := re.fullmatch(r'tool="([^"]+)"(?: index="\d+")?<\|sep\|>(.*)', s, re.DOTALL)):
    pattern = r'<\|open\|>argument key="([^"]+)" type="([^"]+)"<\|sep\|>(.*?)<\|close\|>argument<\|sep\|>'
    if re.sub(pattern, '', m[2], flags=re.DOTALL).strip(): return None
    def unescape(v:str) -> str: return v.replace('&quot;', '"').replace('&amp;', '&')
    try: return unescape(m[1]), {unescape(a[1]): a[3] if a[2] == "string" else json.loads(a[3]) for a in re.finditer(pattern, m[2], re.DOTALL)}
    except json.JSONDecodeError: return None
  if s.startswith("{"):  # hermes JSON format: {"name": ..., "arguments": {...}}
    try:
      call = json.loads(s)
      return call["name"], call.get("arguments", call.get("parameters", {}))
    except (json.JSONDecodeError, KeyError): return None
  # XML format: <function=name>\n<parameter=key>\nvalue\n</parameter>...</function>
  # GLM format: name<arg_key>key</arg_key><arg_value>value</arg_value>...
  patterns = (
    (r"<function=([^>]+)>\s*(.*?)\s*(?:</function>)?$", r"<parameter=([^>]+)>(.*?)</parameter>"),
    (r"([\w.-]+)\s*((?:<arg_key>[^<]+</arg_key>\s*<arg_value>.*?</arg_value>\s*)*)$", r"<arg_key>([^<]+)</arg_key>\s*<arg_value>(.*?)</arg_value>"))
  for call_pattern, arg_pattern in patterns:
    if (fm := re.match(call_pattern, s, re.DOTALL)):
      args, types = {}, _param_types(tools, fm.group(1))
      for pm in re.finditer(arg_pattern, fm.group(2), re.DOTALL):
        value = re.sub(r"^\r?\n|\r?\n\Z", "", pm.group(2))
        # XML values are bare text: a parameter the schema declares a string stays one even when it parses as JSON ("42", "true",
        # a JSON file's content) -- only a quoted JSON string is unquoted; other types (or no schema) are decoded when they parse
        if types.get(pm.group(1)) == "string" or (isinstance(t := types.get(pm.group(1)), list) and t and all(x in ("string", "null") for x in t)):
          try: args[pm.group(1)] = dec if isinstance(dec := json.loads(value), str) else value
          except json.JSONDecodeError: args[pm.group(1)] = value
          continue
        try: args[pm.group(1)] = json.loads(value)
        except json.JSONDecodeError: args[pm.group(1)] = value
      return fm.group(1), args
  return None

def load_image_url(url:str) -> bytes:
  # data: URLs (what chat clients send), http(s) URLs and local paths
  if url.startswith("data:"):
    header, _, payload = url.partition(",")
    return base64.b64decode(payload) if ";base64" in header else payload.encode()
  if url.startswith(("http://", "https://")):
    with urllib.request.urlopen(url, timeout=30) as r: return r.read()
  return pathlib.Path(url.removeprefix("file://")).read_bytes()

def extract_images(messages:list[dict]) -> list[bytes]:
  """image bytes in prompt order (the chat template renders one <|image_pad|> per image item, in the same order)"""
  out = []
  for m in messages:
    if not isinstance(m.get("content"), list): continue
    for item in m["content"]:
      if not isinstance(item, dict): continue
      if item.get("type") == "image_url" or "image_url" in item:
        u = item["image_url"]
        out.append(load_image_url(u["url"] if isinstance(u, dict) else u))
      elif item.get("type") == "image" or "image" in item:
        src = item.get("image") or item.get("source") or {}
        if isinstance(src, str): out.append(load_image_url(src))
        elif src.get("type") == "base64" or "data" in src: out.append(base64.b64decode(src["data"]))
        elif "url" in src: out.append(load_image_url(src["url"]))
  return out

def dead_devices() -> list[str]:
  # a device whose GPU was reset (or that hung unrecoverably) can never serve again
  from tinygrad import Device
  return [d for d in Device._opened_devices if getattr(Device[d], "error_state", None) is not None]

def normalize_messages(messages:list[dict]) -> None:
  # chat templates expect tool_call arguments as dicts (OpenAI clients send JSON strings)
  for m in messages:
    for tc in m.get("tool_calls") or []:
      if "function" in tc and isinstance(args := tc["function"].get("arguments"), str):
        try: tc["function"]["arguments"] = json.loads(args)
        except json.JSONDecodeError: pass
    # string-only templates need text parts joined and explicit null content emptied
    if m.get("content", "") is None: m["content"] = ""
    elif isinstance(c := m.get("content"), list) and all(p.get("type") == "text" for p in c): m["content"] = "".join(p["text"] for p in c)

def disconnected(conn:socket.socket) -> bool:
  # non-blocking peek, b'' means the client closed (or half-closed). assumes no socket timeout is set.
  try: return conn.recv(1, socket.MSG_PEEK | socket.MSG_DONTWAIT) == b''
  except BlockingIOError: return False
  except OSError: return True

class StreamRouter:
  # routes streamed output text to (field, text) deltas, keeping tool_call regions in .buf for the final parse
  # (start think, end think, end content, tool call)
  FORMATS = (("<think>", "</think>", "<tool_call>", r"<tool_call>\s*(.*?)\s*(?:</tool_call>|$)"),
             ("<|open|>think<|sep|>", "<|close|>think<|sep|><|open|>response<|sep|>", "<|close|>response<|sep|>",
              r"<\|open\|>call \s*(.*?)\s*(?:<\|close\|>call<\|sep\|>|$)"))
  def __init__(self, special_tokens:dict[str, int], reasoning:bool=False):
    self.think, self.end_think, self.end_content, self.call = next((f for f in self.FORMATS if any(f[2].startswith(t) for t in special_tokens)),
                                                                   self.FORMATS[0])
    self.buf = ""
    self.mode = "reasoning" if reasoning else "undecided"  # output inside a think block is sent as reasoning_content
  def split(self, tag:str, final:bool) -> tuple[str, bool]:
    # split buf on the first full tag, holding back a partial tag at the end unless final
    if tag in self.buf:
      before, self.buf = self.buf.split(tag, 1)
      return before, True
    hold = max((i for i in range(1, min(len(self.buf), len(tag))+1) if tag.startswith(self.buf[-i:])), default=0) if not final else 0
    emit, self.buf = self.buf[:len(self.buf)-hold], self.buf[len(self.buf)-hold:]
    return emit, False
  def route(self, piece:str, final:bool=False) -> typing.Iterator[tuple[str, str]]:
    self.buf += piece
    if self.mode == "undecided":  # decide whether the output starts with a think block
      if not final and len(self.buf) < len(self.think) and self.think.startswith(self.buf): return
      self.mode, self.buf = ("reasoning", self.buf[len(self.think):]) if self.buf.startswith(self.think) else ("content", self.buf)
    if self.mode == "reasoning":
      emit, done = self.split(self.end_think, final)
      if emit: yield "reasoning_content", emit
      if not done: return
      self.mode = "content"
    if self.mode == "tool": return
    emit, found = self.split(self.end_content, final)
    if emit: yield "content", emit
    if found: self.mode, self.buf = "tool", self.end_content + self.buf

class Request:
  def __init__(self, ids:list[int], disconnected:typing.Callable[[], bool], max_tokens:int|None=None, temperature:float=0.0, log_prefix:str="",
               tools:list|None=None, images:list[bytes]|None=None):
    self.ids, self.disconnected, self.max_tokens, self.temperature, self.log_prefix = ids, disconnected, max_tokens, temperature, log_prefix
    self.tools, self.images, self.media = tools, images or [], typing.cast(list, [])
    self.prompt_tokens = len(ids)  # generation appends to ids
    self.cache_prompt = True
    # the handler re-tokenizes the conversation with the reply (see Handler._recache_tokens) and hands it to the inference thread here,
    # which applies it before taking the next request
    self.recache: queue.Queue[list[int]|None] = queue.Queue(maxsize=1)
    self.finish_reason = "stop"
    self.cached_tokens = 0
    self.error: Exception|None = None
    self.out: queue.Queue[int|None] = queue.Queue()

class Handler(VizHandler):
  server: LLMServer
  def log_request(self, code='-', size='-'): pass
  def do_GET(self):
    if self.path in ("/health", "/v1/health"):
      # report a dead device so launchers do not reuse this process
      if (dead := dead_devices()):
        from tinygrad import Device
        self.send_data(f"device error: {dead[0]}: {Device[dead[0]].error_state}".encode(), content_type="text/plain", status_code=503)
      else: self.send_data(b"ok")
    elif self.path == "/props":
      self.send_data(json.dumps({"default_generation_settings": {"n_ctx": self.server.model.max_context}}).encode())
    elif self.path == "/v1/models":
      self.send_data(json.dumps({"object":"list","data":[{"id":self.server.model_name,"object":"model"}]}).encode())
    elif self.path.startswith("/assets/"): super().do_GET()
    else: self.send_data((pathlib.Path(__file__).parent / "chat.html").read_bytes(), content_type="text/html")
  def _recache_tokens(self, messages:list[dict], reply:dict, preserve_thinking:bool, enable_thinking:bool, reasoning_effort:str,
                      tools=None) -> list[int]|None:
    """After replying, re-render `messages + [reply]` (no generation prompt) and re-tokenize it, so
    model._cached_tokens matches what a FUTURE request's fresh render+tokenize will produce for this same
    prefix -- letting get_start_pos() find a real prefix match on the next turn.
    This exists because the raw token stream that generate() actually cached is NOT safe to reuse directly:
    (1) it may include a <think> block that a normal client strips before sending the next turn, and
    (2) tokenizing "<the prompt>" alone and tokenizing "<the prompt><reply text>" as one string can legally
    produce different token ids right at that boundary (BPE merges are decided over the whole string, e.g.
    two adjacent newlines from the role header + the reply's own leading newline can merge into one token
    that never existed in the original prompt-only tokenization). Recomputing from the same text both
    sides will render sidesteps both: next turn's render() call hits the identical text up to this point,
    so its tokenizer produces the identical ids.
    Only meaningful for the fork's has_recurrent_block=True path, which requires an exact full-prefix
    match -- but harmless to always run (a plain KV-cache model just uses the longest common prefix
    anyway, so a mismatched tail there is quietly discarded). Runs on the handler thread (CPU only); the
    inference thread applies the result (LLMServer._apply_recache)."""
    try:
      # deliberately drop reasoning_content here: essentially every OpenAI-compatible client (this includes
      # the fork's own chat.html) sends only the visible `content` back on the next turn, never the model's
      # own prior <think> block -- so that's the text a future request will actually re-render, and matching
      # it (not what the server itself still remembers thinking) is what makes get_start_pos() find a hit.
      replay = messages + [{"role": "assistant", "content": reply.get("content")}]
      text = self.server.template.render(messages=replay, tools=tools, add_generation_prompt=False,
        preserve_thinking=preserve_thinking, enable_thinking=enable_thinking, reasoning_effort=reasoning_effort)
      return self.server.tok.encode(text)
    except Exception as e:
      stderr_log(f"prefix-cache recompute failed (non-fatal, next turn just won't reuse this one): {e}\n")
      return None

  def run_model(self, req:Request, model_name:str, include_usage:bool=False, reasoning:bool=False, continuous_usage:bool=False):
    tok = self.server.tok
    tmpl = {"id":f"chatcmpl-{uuid.uuid4().hex[:24]}", "object":"chat.completion.chunk", "created":int(time.time()), "model":model_name}
    out: list[int] = []
    def usage():
      prompt_tokens = req.prompt_tokens  # read late: images widen req.ids on the inference thread
      return {"prompt_tokens": prompt_tokens, "completion_tokens": len(out), "total_tokens": prompt_tokens + len(out),
              "prompt_tokens_details": {"cached_tokens": req.cached_tokens}}
    def chunk(d:dict, finish_reason:str|None=None):
      ret = {"choices": [{"index":0, "delta":d, "finish_reason":finish_reason}], **tmpl}
      if continuous_usage: ret["usage"] = usage()
      return ret
    dec = tok.stream_decoder()
    router = StreamRouter(tok._special_tokens, reasoning)
    self.server.waiting.put(req)
    yield chunk({"role":"assistant", "content":""})
    while (next_id := req.out.get()) is not None:
      out.append(next_id)
      for field, delta in router.route(dec(next_id)): yield chunk({field:delta})
    if req.error is not None:
      yield {"error":{"message":f"{type(req.error).__name__}: {req.error}", "type":"server_error", "code":"generation_failed"}}
      return
    finish_reason = req.finish_reason
    for field, delta in router.route(dec(), final=True): yield chunk({field:delta})
    tool_calls: list[dict] = []
    for m in re.finditer(router.call, router.buf, re.DOTALL):
      if (parsed := parse_tool_call(m.group(1), req.tools)) is None:
        stderr_log(f"{colored('failed to parse tool call', 'red')}: {m.group(1)[:200]}\n")
        yield chunk({"content":m.group(0)})  # don't silently drop output the client can't use
      else:
        name, args = parsed
        tool_calls.append({"index":len(tool_calls), "id":f"call_{uuid.uuid4().hex[:24]}", "type":"function",
                           "function":{"name":name, "arguments":args if isinstance(args, str) else json.dumps(args)}})
    if tool_calls:
      yield chunk({"tool_calls":tool_calls})
      if finish_reason == "stop": finish_reason = "tool_calls"
    yield chunk({}, finish_reason)
    if include_usage: yield {"choices": [], "usage": usage(), **tmpl}
  def do_POST(self):
    request_st = time.perf_counter()
    log_prefix = f"{self.path}  {colored('--', 'BLACK')}  "
    raw_body = self.rfile.read(int(self.headers.get("Content-Length", "0")))
    body: dict[str, typing.Any] = json.loads(raw_body.decode("utf-8"))
    if DEBUG >= 1: print(json.dumps(body, indent=2))
    if self.path == "/v1/chat/completions":
      # render and tokenize
      normalize_messages(body["messages"])
      # Feedthrough reasoning: keep prior <think> / reasoning_content in the prompt.
      # Qwen3.8 chat template defaults effort to xhigh if omitted; daily default is medium.
      ctk = body.get("chat_template_kwargs") or {}
      effort = body.get("reasoning_effort") or ctk.get("reasoning_effort")
      if effort is None and isinstance(body.get("reasoning"), dict):
        effort = body["reasoning"].get("effort")
      if effort is None: effort = self.server.reasoning_effort
      enable = body.get("enable_thinking")
      if enable is None: enable = ctk.get("enable_thinking")
      if enable is None: enable = self.server.enable_thinking
      preserve = body.get("preserve_thinking")
      if preserve is None: preserve = ctk.get("preserve_thinking", True)
      rendered = self.server.template.render(
        messages=body["messages"], tools=body.get("tools"), add_generation_prompt=True,
        preserve_thinking=bool(preserve), enable_thinking=bool(enable), reasoning_effort=str(effort))
      ids: list[int] = self.server.tok.encode(rendered)
      # images: encode each one and widen its single <|image_pad|> token to one pad per embedding
      if (images := extract_images(body["messages"])):
        if self.server.vision is None or getattr(self.server.model, "image_pad_id", None) is None:
          return self.send_data(json.dumps({"error":{"message":"this server has no vision encoder loaded (--mmproj)",
            "type":"invalid_request_error", "param":"messages", "code":"unsupported_content"}}).encode(), status_code=400)
        pad = self.server.model.image_pad_id
        if ids.count(pad) != len(images):
          return self.send_data(json.dumps({"error":{"message":f"{len(images)} images but the chat template produced {ids.count(pad)} image "
            "placeholders", "type":"invalid_request_error", "param":"messages", "code":"invalid_images"}}).encode(), status_code=400)
      log_prefix += f"prep:{(time.perf_counter()-request_st)*1e3:5.0f} ms  {colored('--', 'BLACK')}  "
      if len(ids) >= self.server.model.max_context:
        stderr_log(log_prefix + f"{colored('context length exceeded', 'red')}  in:{len(ids):5d}  max:{self.server.model.max_context:5d}\n")
        return self.send_data(json.dumps({"error":{"message":f"prompt has {len(ids)} tokens, but the model context is "
          f"{self.server.model.max_context}", "type":"invalid_request_error", "param":"messages", "code":"context_length_exceeded"}}).encode(),
          status_code=400)

      # reply
      max_tokens = body.get("max_completion_tokens") or body.get("max_tokens")
      req = Request(ids, functools.partial(disconnected, self.connection), max_tokens=max_tokens, temperature=float(body.get("temperature", 0.6)),
                    log_prefix=log_prefix, tools=body.get("tools"), images=images)
      # llama.cpp's request field, same meaning: prefill from scratch. drops the live state and leaves the snapshots alone,
      # which makes a cold reference run possible without a restart (the correctness tests compare against it)
      req.cache_prompt = body.get("cache_prompt") is not False
      stream_options = body.get("stream_options", {})
      include_usage = not body.get("stream") or stream_options.get("include_usage", False)
      continuous_usage = include_usage and stream_options.get("continuous_usage_stats", False)
      chunks = self.run_model(req, body.get("model") or self.server.model_name, include_usage, continuous_usage=continuous_usage,
                              reasoning=bool(enable) or rendered.rstrip().endswith(tuple(f[0] for f in StreamRouter.FORMATS)))
      def accumulate(chunks):
        # shared by both branches: collect content/reasoning/tool_calls while passing chunks through untouched,
        # so the prefix cache (see _recache_tokens) can be kept in sync for streaming requests too
        for c in chunks:
          if c.get("choices"):
            choice = c["choices"][0]
            if (delta := choice.get("delta", {})):
              if delta.get("content"): out.append(delta["content"])
              if delta.get("reasoning_content"): reasoning.append(delta["reasoning_content"])
              tool_calls_raw.extend(delta.get("tool_calls", []))
            if choice.get("finish_reason"): finish[0] = choice["finish_reason"]
          yield c
      out, reasoning, tool_calls_raw, finish = [], [], [], ["stop"]
      recache: list[int]|None = None
      try:
        last, error = None, None
        if body.get("stream"): self.stream_json(accumulate(chunks))
        else:
          for c in accumulate(chunks):
            if "error" in c: error = c
            last = c
        tool_calls = [{k:v for k, v in tc.items() if k != "index"} for tc in tool_calls_raw]
        message: dict[str, typing.Any] = {"role":"assistant", "content":"".join(out) or None}
        if reasoning: message["reasoning_content"] = "".join(reasoning)
        if tool_calls: message["tool_calls"] = tool_calls
        if req.error is None: recache = self._recache_tokens(body["messages"], message, preserve, enable, effort, tools=body.get("tools"))
      finally:
        req.recache.put(recache)
      if not body.get("stream"):
        if error is not None: return self.send_data(json.dumps(error).encode(), status_code=500)
        try:
          self.send_data(json.dumps({**(last or {}), "object":"chat.completion",
            "choices":[{"index":0, "message":message, "finish_reason":finish[0]}]}).encode())
        except (BrokenPipeError, ConnectionResetError): pass
    else:
      raise RuntimeError(f"unhandled path {self.path}")

class LLMServer(socketserver.ThreadingMixIn, TCPServerWithReuse):
  daemon_threads = True
  def __init__(self, server_address:tuple, model:Transformer, model_name:str, tok:SimpleTokenizer, template:typing.Any,
               reasoning_effort:str="medium", enable_thinking:bool=True, vision:typing.Any=None,
               host_snapshots:int=0, host_snapshot_gb:float=16.0):
    self.model, self.model_name, self.tok, self.template, self.vision = model, model_name, tok, template, vision
    self.reasoning_effort, self.enable_thinking = reasoning_effort, enable_thinking
    self.waiting: queue.Queue[Request|None] = queue.Queue()
    self.snapshots: list = []  # StateSnapshot, oldest first; see LLMServer._pick_prefix_state
    # host-memory snapshot tier (--host-snapshots N / --host-snapshot-gb, default off): states evicted from the VRAM slots are
    # copied to host memory instead of dropped. A snapshot is ~2.2 GB at max_context 98304, so this needs real RAM headroom
    self.host_snapshots: list = []
    self.max_host_snapshots, self.max_host_bytes = host_snapshots, int(host_snapshot_gb * 1e9)
    self.max_snapshots, self.snapshot_min_tokens = getenv("PREFIX_SNAPSHOTS", 1), getenv("PREFIX_SNAPSHOT_MIN", 1024)
    super().__init__(server_address, Handler)

  def serve_forever(self, poll_interval:float=0.5):
    # inference runs on the caller's thread: BEAM with PARALLEL=0 uses SIGALRM, which only works on the main thread
    threading.Thread(target=super().serve_forever, args=(poll_interval,), daemon=True, name="HTTPServer").start()
    while (req := self.waiting.get()) is not None:
      try:
        if req.disconnected(): stderr_log(req.log_prefix + f"{colored('cancelled while queued', 'red')}\n")
        else:
          for next_id in self.generate(req): req.out.put(next_id)  # TODO: batch decodes across requests (batched_step)
      except Exception as e:
        traceback.print_exc()
        req.error = e
        # a device hang/reset is permanent for this process: exit now so the launcher restarts a fresh server (its stale queues cannot serve,
        # and tearing them down later only triggers another GPU reset at a surprising moment)
        if (dead := dead_devices()):
          import os
          stderr_log(f"\ndevice {dead[0]} is in error state: exiting\n")
          os._exit(3)
      req.out.put(None)
      if req.error is None and not req.disconnected(): self._apply_recache(req)

  def _apply_recache(self, req:Request):
    # wait for the handler's re-tokenized conversation (Handler._recache_tokens) before the next request looks at the cache
    try: tokens = req.recache.get(timeout=getenv("RECACHE_TIMEOUT_S", 10))
    except queue.Empty: tokens = None
    if tokens is not None: self.model._cached_tokens = tokens

  def shutdown(self):
    # a request queued after the sentinel is never picked up, so its handler thread waits forever. fine since handlers are daemon threads
    super().shutdown()
    self.waiting.put(None)

  def encode_images(self, req:Request):
    # on the inference thread (the vision encoder runs on the GPU): encode each image and widen its single <|image_pad|> token to one pad
    # per embedding
    if not req.images: return
    pad = self.model.image_pad_id
    req.media = [self.vision.encode(img) for img in req.images]
    expanded, k = [], 0
    for t in req.ids:
      if t == pad:
        expanded += [pad] * req.media[k].n_tokens
        k += 1
      else: expanded.append(t)
    req.ids, req.prompt_tokens = expanded, len(expanded)
    req.log_prefix += f"img:{len(req.media)} ({sum(m.n_tokens for m in req.media)} tok)  {colored('--', 'BLACK')}  "
    if len(req.ids) >= self.model.max_context: raise ValueError(f"prompt has {len(req.ids)} tokens with its images, but the model context is "
                                                                f"{self.model.max_context}")

  def _pick_prefix_state(self, ids:list[int], media:list) -> None:
    """prefix-state snapshots (PREFIX_SNAPSHOTS=N saved slots, default 1; PREFIX_SNAPSHOT_MIN tokens, default 1024;
    --host-snapshots N / --host-snapshot-gb for the host-memory tier, default off).
    the model holds ONE decode state, so any request that doesn't extend the cached conversation evicts it -- another session,
    a sub-agent, a housekeeping call -- and the next turn of the long conversation then reprocesses its whole 20K+ token
    prefix from scratch (the recurrent blocks need an exact full-prefix match, so there is no partial reuse to fall back on).
    Before such an eviction, save the live state; when a later request extends a saved conversation rather than the live one,
    restore it, saving the live one into the freed slot if it is itself worth keeping (two long conversations alternating,
    e.g. an agent and its sub-agent, keep swapping through one slot). A snapshot is a full copy of every state buffer
    (~1.5 GB at max_context 65536 for Qwen3.8-27B with the quantized kv cache), so the slot count is kept small."""
    srv, model = self, self.model
    if srv.max_snapshots <= 0 or media or time.perf_counter() < getattr(srv, "snapshots_paused_until", 0.0): return
    live = model.get_start_pos(ids)
    # candidates: the VRAM slots, then the host tier (PREFIX_HOST_SNAPSHOTS slots / PREFIX_HOST_GB): a state evicted from VRAM is
    # copied to host memory instead of being dropped -- re-prefilling a 30K-token conversation takes over a minute here, restoring
    # a 2 GB snapshot from host memory a fraction of a second even over PCIe x4
    best_i, best, best_host = -1, live, False
    for tier, lst in ((False, srv.snapshots), (True, srv.host_snapshots)):
      for i, s in enumerate(lst):
        # a snapshot serves a request that extends either its generated sequence or (far more often) its prefill checkpoint
        m = max([model.prefix_match(ids, s.tokens), model.prefix_match(ids, s.ckpt_tokens or [])] + [model.prefix_match(ids, t) for t, _ in s.ckpts])
        if m > best: best_i, best, best_host = i, m, tier
    live_worth_keeping = live == 0 and len(model._cached_tokens) >= srv.snapshot_min_tokens
    try:
      t0 = time.perf_counter()
      if best_i >= 0:
        snap = (srv.host_snapshots if best_host else srv.snapshots).pop(best_i)
        if live_worth_keeping: srv.snapshots.append(model.snapshot_state())
        model.restore_state(snap)
        if best_host: srv.snapshots.append(model.snapshot_state())  # it is live again; keep a device copy so the next switch is cheap
        stderr_log(f"{colored(f'restored snapshot ({best} tok, {'host' if best_host else 'vram'}, {(time.perf_counter()-t0)*1e3:.0f} ms)', 'cyan')}  {colored('--', 'BLACK')}  ")
      elif live_worth_keeping:
        srv.snapshots.append(snap := model.snapshot_state())
        stderr_log(f"{colored(f'saved snapshot ({len(snap.tokens)} tok, {snap.nbytes()/1e9:.2f} GB, {(time.perf_counter()-t0)*1e3:.0f} ms)', 'cyan')}  {colored('--', 'BLACK')}  ")
      while len(srv.snapshots) > srv.max_snapshots:
        old = srv.snapshots.pop(0)
        if srv.max_host_snapshots > 0 and old.nbytes() <= srv.max_host_bytes:
          t1 = time.perf_counter(); srv.host_snapshots.append(old.to_host())
          stderr_log(f"{colored(f'snapshot -> host ({len(old.tokens)} tok, {(time.perf_counter()-t1)*1e3:.0f} ms)', 'cyan')}  {colored('--', 'BLACK')}  ")
        del old
      while len(srv.host_snapshots) > srv.max_host_snapshots or sum(s.nbytes() for s in srv.host_snapshots) > srv.max_host_bytes:
        srv.host_snapshots.pop(0)
    except MemoryError as e:
      # out of VRAM for a clone (a 131072-context run hit this at a 33K prompt, 2026-08-26): drop the saved slots to free
      # their memory and pause snapshots for a while instead of disabling them for the life of the process -- the next
      # conversation may be short again, and the live prefix cache keeps working either way
      srv.snapshots = []
      srv.snapshots_paused_until = time.perf_counter() + getenv("PREFIX_SNAPSHOT_PAUSE_S", 600)
      stderr_log(f"{colored(f'prefix snapshots paused {getenv("PREFIX_SNAPSHOT_PAUSE_S", 600)}s: {e}', 'red')}  {colored('--', 'BLACK')}  ")

  def generate(self, req:Request):
    n, finished = 0, False
    self.encode_images(req)
    stderr_log(req.log_prefix)
    model = self.model
    if not req.cache_prompt: model._cached_tokens, model._ckpt_tokens = [], None
    else: self._pick_prefix_state(req.ids, req.media)
    media_keys = tuple((s, m.key) for s, m in model._media_spans(req.ids, req.media)) if req.media else ()
    req.cached_tokens = cache_start_pos = model.get_start_pos(req.ids, media_keys)
    stderr_log(f"in:{colored(f'{cache_start_pos:5d}', 'green')} +{len(req.ids)-cache_start_pos:5d}  {colored('--', 'BLACK')}  ")
    if cache_start_pos == 0 and (model._cached_tokens or model._ckpt_tokens):
      # nothing was reused although something was cached: say where each candidate diverged (index/length), it is the whole story
      div = lambda c: next((i for i, (a, b) in enumerate(zip(req.ids, c)) if a != b), min(len(req.ids), len(c)))
      ck = model._ckpt_tokens or []
      stderr_log(f"{colored(f'miss: live@{div(model._cached_tokens)}/{len(model._cached_tokens)} ckpt@{div(ck)}/{len(ck)}', 'yellow')}  {colored('--', 'BLACK')}  ")
    prompt_tokens = len(req.ids)
    st = pt = time.perf_counter()
    try:
      for next_id in self.model.generate(req.ids, temperature=req.temperature, media=req.media):
        if n == 0: stderr_log(f"prefill:{(prompt_tokens-cache_start_pos)/((pt:=time.perf_counter())-st):4.0f} tok/s  {colored('--', 'BLACK')}  ")
        if self.tok.is_end(next_id): break
        if req.disconnected(): return
        yield next_id
        n += 1
        if req.max_tokens is not None and n >= req.max_tokens:
          req.finish_reason = "length"
          break
      finished = True
    finally:
      et = time.perf_counter()
      total = f"total:{et-st:6.2f}s"
      stderr_log(f"gen:{n/(et-pt) if n > 1 else 0:4.0f} tok/s  {colored('--', 'BLACK')}  "
                 f"out:{n:5d}  {colored('--', 'BLACK')}  {colored(total, 'red') if not finished else total}\n")
