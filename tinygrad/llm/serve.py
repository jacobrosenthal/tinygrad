from __future__ import annotations
import base64, json, pathlib, re, time, typing, urllib.request, uuid
from typing import TYPE_CHECKING
from tinygrad.helpers import DEBUG, colored, stderr_log
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
  def run_model(self, ids:list[int], model_name:str, include_usage=False, max_tokens:int|None=None, temperature:float=0.0,
                reasoning:bool=False, media:list|None=None):
    model, tok = self.server.model, self.server.tok
    prompt_tokens = len(ids)
    cache_start_pos = model.get_start_pos(ids, tuple((s, m.key) for s, m in model._media_spans(ids, media)) if media else ())
    stderr_log(f"in:{colored(f'{cache_start_pos:5d}', 'green')} +{len(ids)-cache_start_pos:5d}  {colored('--', 'BLACK')}  ")
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
                                        "total_tokens": prompt_tokens + len(out)}, **tmpl}
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
      chunks = self.run_model(ids, body.get("model") or self.server.model_name,
                              not body.get("stream") or body.get("stream_options",{}).get("include_usage", False),
                              max_tokens=max_tokens, temperature=float(body.get("temperature", 0.6)),
                              reasoning=bool(enable) or rendered.rstrip().endswith("<think>"), media=media)
      if body.get("stream"): self.stream_json(chunks)
      else:
        out, reasoning, tool_calls, finish_reason = [], [], [], "stop"
        for c in chunks:
          if not c["choices"]: continue
          choice = c["choices"][0]
          if (delta := choice.get("delta", {})):
            if delta.get("content"): out.append(delta["content"])
            if delta.get("reasoning_content"): reasoning.append(delta["reasoning_content"])
            tool_calls += [{k:v for k, v in tc.items() if k != "index"} for tc in delta.get("tool_calls", [])]
          if choice.get("finish_reason"): finish_reason = choice["finish_reason"]
        message: dict[str, typing.Any] = {"role":"assistant", "content":"".join(out) or None}
        if reasoning: message["reasoning_content"] = "".join(reasoning)
        if tool_calls: message["tool_calls"] = tool_calls
        self.send_data(json.dumps({**c, "object":"chat.completion",
          "choices":[{"index":0, "message":message, "finish_reason":finish_reason}]}).encode())
    else:
      raise RuntimeError(f"unhandled path {self.path}")

class LLMServer(TCPServerWithReuse):
  def __init__(self, server_address:tuple, model:Transformer, model_name:str, tok:SimpleTokenizer, template:typing.Any,
               reasoning_effort:str="medium", enable_thinking:bool=True, vision:typing.Any=None):
    self.model, self.model_name, self.tok, self.template, self.vision = model, model_name, tok, template, vision
    self.reasoning_effort, self.enable_thinking = reasoning_effort, enable_thinking
    super().__init__(server_address, Handler)
