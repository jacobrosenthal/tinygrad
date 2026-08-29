from __future__ import annotations
import base64, json, pathlib, re, time, typing, urllib.request, uuid
from typing import TYPE_CHECKING
from tinygrad.helpers import DEBUG, colored, stderr_log, getenv
from tinygrad.viz.serve import TCPServerWithReuse, HTTPRequestHandler
if TYPE_CHECKING:
  from tinygrad.llm.cli import SimpleTokenizer
  from tinygrad.llm.model import Transformer

def parse_tool_call(s:str) -> tuple[str, typing.Any]|None:
  s = s.strip()
  if s.startswith("{"):  # hermes JSON format: {"name": ..., "arguments": {...}}
    try:
      call = json.loads(s)
      return call["name"], call.get("arguments", call.get("parameters", {}))
    except (json.JSONDecodeError, KeyError): return None
  # XML format: <function=name>\n<parameter=key>\nvalue\n</parameter>...</function>
  if (fm := re.match(r"<function=([^>]+)>\s*(.*?)\s*(?:</function>)?$", s, re.DOTALL)):
    args = {}
    for pm in re.finditer(r"<parameter=([^>]+)>(.*?)</parameter>", fm.group(2), re.DOTALL):
      value = re.sub(r"^\r?\n|\r?\n\Z", "", pm.group(2))
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

def normalize_messages(messages:list[dict]) -> None:
  # chat templates expect tool_call arguments as dicts (OpenAI clients send JSON strings)
  for m in messages:
    for tc in m.get("tool_calls") or []:
      if "function" in tc and isinstance(args := tc["function"].get("arguments"), str):
        try: tc["function"]["arguments"] = json.loads(args)
        except json.JSONDecodeError: pass

class StreamRouter:
  # routes streamed output text to (field, text) deltas, keeping tool_call regions in .buf for the final parse
  def __init__(self, reasoning:bool=False):
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
      if not final and len(self.buf) < len("<think>") and "<think>".startswith(self.buf): return
      self.mode, self.buf = ("reasoning", self.buf[len("<think>"):]) if self.buf.startswith("<think>") else ("content", self.buf)
    if self.mode == "reasoning":
      emit, done = self.split("</think>", final)
      if emit: yield "reasoning_content", emit
      if not done: return
      self.mode = "content"
    if self.mode == "tool": return
    emit, found = self.split("<tool_call>", final)
    if emit: yield "content", emit
    if found: self.mode, self.buf = "tool", "<tool_call>" + self.buf

class Handler(HTTPRequestHandler):
  server: LLMServer
  def log_request(self, code='-', size='-'): pass
  def do_GET(self):
    if self.path in ("/health", "/v1/health"):
      # a device whose GPU was reset (or that hung unrecoverably) can never serve again: report it so launchers do not reuse this process
      from tinygrad import Device
      dead = [d for d in Device._opened_devices if getattr(Device[d], "error_state", None) is not None]
      if dead: self.send_data(f"device error: {dead[0]}: {Device[dead[0]].error_state}".encode(), content_type="text/plain", status_code=503)
      else: self.send_data(b"ok")
    elif self.path == "/props":
      self.send_data(json.dumps({"default_generation_settings": {"n_ctx": self.server.model.max_context}}).encode())
    elif self.path == "/v1/models":
      self.send_data(json.dumps({"object":"list","data":[{"id":self.server.model_name,"object":"model"}]}).encode())
    else: self.send_data((pathlib.Path(__file__).parent / "chat.html").read_bytes(), content_type="text/html")
  def _recache_for_next_turn(self, messages:list[dict], reply:dict, preserve_thinking:bool, enable_thinking:bool, reasoning_effort:str,
                              tools=None) -> None:
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
    anyway, so a mismatched tail there is quietly discarded)."""
    try:
      # deliberately drop reasoning_content here: essentially every OpenAI-compatible client (this includes
      # the fork's own chat.html) sends only the visible `content` back on the next turn, never the model's
      # own prior <think> block -- so that's the text a future request will actually re-render, and matching
      # it (not what the server itself still remembers thinking) is what makes get_start_pos() find a hit.
      replay = messages + [{"role": "assistant", "content": reply.get("content")}]
      text = self.server.template.render(messages=replay, tools=tools, add_generation_prompt=False,
        preserve_thinking=preserve_thinking, enable_thinking=enable_thinking, reasoning_effort=reasoning_effort)
      self.server.model._cached_tokens = self.server.tok.encode(text)
    except Exception as e:
      stderr_log(f"prefix-cache recompute failed (non-fatal, next turn just won't reuse this one): {e}\n")

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
    srv, model = self.server, self.server.model
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

  def run_model(self, ids:list[int], model_name:str, include_usage=False, max_tokens:int|None=None, temperature:float=0.0,
                reasoning:bool=False, media:list|None=None):
    model, tok = self.server.model, self.server.tok
    prompt_tokens = len(ids)
    cache_start_pos = model.get_start_pos(ids, tuple((s, m.key) for s, m in model._media_spans(ids, media)) if media else ())
    stderr_log(f"in:{colored(f'{cache_start_pos:5d}', 'green')} +{len(ids)-cache_start_pos:5d}  {colored('--', 'BLACK')}  ")
    if cache_start_pos == 0 and (model._cached_tokens or model._ckpt_tokens):
      # nothing was reused although something was cached: say where each candidate diverged (index/length), it is the whole story
      div = lambda c: next((i for i, (a, b) in enumerate(zip(ids, c)) if a != b), min(len(ids), len(c)))
      ck = model._ckpt_tokens or []
      stderr_log(f"{colored(f'miss: live@{div(model._cached_tokens)}/{len(model._cached_tokens)} ckpt@{div(ck)}/{len(ck)}', 'yellow')}  {colored('--', 'BLACK')}  ")
    tmpl = {"id":f"chatcmpl-{uuid.uuid4().hex[:24]}", "object":"chat.completion.chunk", "created":int(time.time()), "model":model_name}
    def chunk(d:dict): return {"choices": [{"index":0, "delta":d, "finish_reason":None}], **tmpl}
    out: list[int] = []
    finish_reason = "stop"
    st = pt = time.perf_counter()
    dec = tok.stream_decoder()
    router = StreamRouter(reasoning)
    def log_stats(interrupted:bool=False):
      et = time.perf_counter()
      total = f"total:{et-st:6.2f}s"
      stderr_log(f"gen:{len(out)/(et-pt) if len(out) > 1 else 0:4.0f} tok/s  {colored('--', 'BLACK')}  "
                 f"out:{len(out):5d}  {colored('--', 'BLACK')}  {colored(total, 'red') if interrupted else total}\n")
    completed = False
    try:
      yield chunk({"role":"assistant", "content":""})
      for next_id in model.generate(ids, temperature=temperature, media=media):
        if len(out) == 0:
          stderr_log(f"prefill:{(prompt_tokens-cache_start_pos)/((pt:=time.perf_counter())-st):4.0f} tok/s  {colored('--', 'BLACK')}  ")
        if tok.is_end(next_id): break
        out.append(next_id)
        for field, delta in router.route(dec(next_id)): yield chunk({field:delta})
        if max_tokens is not None and len(out) >= max_tokens:
          finish_reason = "length"
          break
      for field, delta in router.route(dec(), final=True): yield chunk({field:delta})
      tool_calls: list[dict] = []
      for m in re.finditer(r"<tool_call>\s*(.*?)\s*(?:</tool_call>|$)", router.buf, re.DOTALL):
        if (parsed := parse_tool_call(m.group(1))) is None:
          stderr_log(f"failed to parse tool call: {m.group(1)[:200]}")
          yield chunk({"content":m.group(0)})  # don't silently drop output the client can't use
        else:
          name, args = parsed
          tool_calls.append({"index":len(tool_calls), "id":f"call_{uuid.uuid4().hex[:24]}", "type":"function",
                             "function":{"name":name, "arguments":args if isinstance(args, str) else json.dumps(args)}})
      if tool_calls:
        yield chunk({"tool_calls":tool_calls})
        if finish_reason == "stop": finish_reason = "tool_calls"
      completed = True
      yield {"choices": [{"index":0, "delta":{},"finish_reason":finish_reason}], **tmpl}
      if include_usage:
        yield {"choices": [], "usage": {"prompt_tokens": prompt_tokens, "completion_tokens": len(out),
                                        "total_tokens": prompt_tokens + len(out),
                                        "prompt_tokens_details": {"cached_tokens": cache_start_pos}}, **tmpl}
      log_stats()
    except GeneratorExit:
      if not completed: log_stats(interrupted=True)
      raise
    except Exception as e:
      # a device hang/reset is permanent for this process: exit now so the launcher restarts a fresh server (its stale queues cannot serve,
      # and tearing them down later only triggers another GPU reset at a surprising moment)
      from tinygrad import Device
      dead = [d for d in Device._opened_devices if getattr(Device[d], "error_state", None) is not None]
      if dead:
        import os
        stderr_log(f"\ndevice {dead[0]} is in error state ({Device[dead[0]].error_state}): exiting\n")
        os._exit(3)
      raise

  def do_POST(self):
    request_st = time.perf_counter()
    stderr_log(f"{self.path}  {colored('--', 'BLACK')}  ")
    raw_body = self.rfile.read(int(self.headers.get("Content-Length", "0")))
    body: dict[str, typing.Any] = json.loads(raw_body.decode("utf-8"))
    if self.server.record_dir:  # --record-requests DIR: exact traces of real traffic, replayed by sweeps/replay.py
      try:
        with open(pathlib.Path(self.server.record_dir) / f"requests-{time.strftime('%Y%m%d')}.jsonl", "a") as f:
          f.write(json.dumps({"ts": time.time(), "path": self.path, "body": body}) + "\n")
      except OSError as e: stderr_log(f"{colored(f'record failed: {e}', 'red')}  {colored('--', 'BLACK')}  ")
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
      if effort is None: effort = getattr(self.server, "reasoning_effort", "medium")
      enable = body.get("enable_thinking")
      if enable is None: enable = ctk.get("enable_thinking")
      if enable is None: enable = getattr(self.server, "enable_thinking", True)
      preserve = body.get("preserve_thinking")
      if preserve is None: preserve = ctk.get("preserve_thinking", True)
      rendered = self.server.template.render(
        messages=body["messages"], tools=body.get("tools"), add_generation_prompt=True,
        preserve_thinking=bool(preserve), enable_thinking=bool(enable), reasoning_effort=str(effort))
      ids: list[int] = self.server.tok.encode(rendered)
      # images: encode each one and widen its single <|image_pad|> token to one pad per embedding
      media: list = []
      if (images := extract_images(body["messages"])):
        if self.server.vision is None or self.server.model.image_pad_id is None:
          return self.send_data(json.dumps({"error":{"message":"this server has no vision encoder loaded (--mmproj)",
            "type":"invalid_request_error", "param":"messages", "code":"unsupported_content"}}).encode(), status_code=400)
        pad = self.server.model.image_pad_id
        if ids.count(pad) != len(images):
          return self.send_data(json.dumps({"error":{"message":f"{len(images)} images but the chat template produced {ids.count(pad)} image "
            "placeholders", "type":"invalid_request_error", "param":"messages", "code":"invalid_images"}}).encode(), status_code=400)
        media = [self.server.vision.encode(img) for img in images]
        expanded, k = [], 0
        for t in ids:
          if t == pad:
            expanded += [pad] * media[k].n_tokens
            k += 1
          else: expanded.append(t)
        ids = expanded
        stderr_log(f"img:{len(media)} ({sum(m.n_tokens for m in media)} tok)  {colored('--', 'BLACK')}  ")
      stderr_log(f"prep:{(time.perf_counter()-request_st)*1e3:5.0f} ms  {colored('--', 'BLACK')}  ")
      if len(ids) >= self.server.model.max_context:
        stderr_log(f"{colored('context length exceeded', 'red')}  in:{len(ids):5d}  max:{self.server.model.max_context:5d}\n")
        return self.send_data(json.dumps({"error":{"message":f"prompt has {len(ids)} tokens, but the model context is "
          f"{self.server.model.max_context}", "type":"invalid_request_error", "param":"messages", "code":"context_length_exceeded"}}).encode(),
          status_code=400)

      # reply
      max_tokens = body.get("max_completion_tokens") or body.get("max_tokens")
      if body.get("cache_prompt") is False:
        # llama.cpp's request field, same meaning: prefill from scratch. drops the live state and leaves the snapshots alone,
        # which makes a cold reference run possible without a restart (the correctness tests compare against it)
        self.server.model._cached_tokens, self.server.model._ckpt_tokens = [], None
      else: self._pick_prefix_state(ids, media)
      # top_p/top_k are server-fixed (--top-p/--top-k at startup, see model.py _apply_top_pk): baked into the JIT
      # graph, not a per-request field. Log rather than silently ignore a client that asked for something different
      req_top_p, req_top_k = body.get("top_p"), body.get("top_k")
      if (req_top_p is not None and float(req_top_p) != self.server.model.top_p) or \
         (req_top_k is not None and int(req_top_k) != self.server.model.top_k):
        stderr_log(f"note: request top_p={req_top_p} top_k={req_top_k} ignored -- this server is fixed at "
                   f"top_p={self.server.model.top_p} top_k={self.server.model.top_k} (--top-p/--top-k)\n")
      # same story for repeat/frequency/presence penalty -- server-fixed (see model.py _apply_repeat_penalty), not per-request
      req_rp, req_fp, req_pp = body.get("repeat_penalty"), body.get("frequency_penalty"), body.get("presence_penalty")
      if (req_rp is not None and float(req_rp) != self.server.model.repeat_penalty) or \
         (req_fp is not None and float(req_fp) != self.server.model.frequency_penalty) or \
         (req_pp is not None and float(req_pp) != self.server.model.presence_penalty):
        stderr_log(f"note: request repeat_penalty={req_rp} frequency_penalty={req_fp} presence_penalty={req_pp} ignored -- this "
                   f"server is fixed at repeat_penalty={self.server.model.repeat_penalty} "
                   f"frequency_penalty={self.server.model.frequency_penalty} presence_penalty={self.server.model.presence_penalty} "
                   f"(--repeat-penalty/--frequency-penalty/--presence-penalty)\n")
      chunks = self.run_model(ids, body.get("model") or self.server.model_name,
                              not body.get("stream") or body.get("stream_options",{}).get("include_usage", False),
                              max_tokens=max_tokens, temperature=float(body.get("temperature", self.server.temperature)),
                              reasoning=bool(enable) or rendered.rstrip().endswith("<think>"), media=media)
      def accumulate(chunks):
        # shared by both branches: collect content/reasoning/tool_calls while passing chunks through untouched,
        # so the prefix cache (see _recache_for_next_turn) can be kept in sync for streaming requests too
        for c in chunks:
          if c["choices"]:
            choice = c["choices"][0]
            if (delta := choice.get("delta", {})):
              if delta.get("content"): out.append(delta["content"])
              if delta.get("reasoning_content"): reasoning.append(delta["reasoning_content"])
              tool_calls_raw.extend(delta.get("tool_calls", []))
            if choice.get("finish_reason"): finish[0] = choice["finish_reason"]
          yield c
      out, reasoning, tool_calls_raw, finish = [], [], [], ["stop"]
      if body.get("stream"): self.stream_json(accumulate(chunks))
      else:
        for c in accumulate(chunks): last = c
      tool_calls = [{k:v for k, v in tc.items() if k != "index"} for tc in tool_calls_raw]
      message: dict[str, typing.Any] = {"role":"assistant", "content":"".join(out) or None}
      if reasoning: message["reasoning_content"] = "".join(reasoning)
      if tool_calls: message["tool_calls"] = tool_calls
      self._recache_for_next_turn(body["messages"], message, preserve, enable, effort, tools=body.get("tools"))
      if not body.get("stream"):
        self.send_data(json.dumps({**last, "object":"chat.completion",
          "choices":[{"index":0, "message":message, "finish_reason":finish[0]}]}).encode())
    else:
      raise RuntimeError(f"unhandled path {self.path}")

class LLMServer(TCPServerWithReuse):
  def __init__(self, server_address:tuple, model:Transformer, model_name:str, tok:SimpleTokenizer, template:typing.Any,
               reasoning_effort:str="medium", enable_thinking:bool=True, vision:typing.Any=None, temperature:float=1.0,
               host_snapshots:int=0, host_snapshot_gb:float=16.0, record_dir:str=""):
    self.model, self.model_name, self.tok, self.template, self.vision = model, model_name, tok, template, vision
    self.reasoning_effort, self.enable_thinking, self.temperature = reasoning_effort, enable_thinking, temperature
    self.snapshots: list = []  # StateSnapshot, oldest first; see Handler._pick_prefix_state
    # host-memory snapshot tier (--host-snapshots N / --host-snapshot-gb, default off): states evicted from the VRAM slots are
    # copied to host memory instead of dropped. A snapshot is ~2.2 GB at max_context 98304, so this needs real RAM headroom
    self.host_snapshots: list = []
    self.max_host_snapshots, self.max_host_bytes = host_snapshots, int(host_snapshot_gb * 1e9)
    self.record_dir = record_dir
    if record_dir: pathlib.Path(record_dir).mkdir(parents=True, exist_ok=True)
    self.max_snapshots, self.snapshot_min_tokens = getenv("PREFIX_SNAPSHOTS", 1), getenv("PREFIX_SNAPSHOT_MIN", 1024)
    super().__init__(server_address, Handler)
