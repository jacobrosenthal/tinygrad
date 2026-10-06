import unittest, threading, time, json
from unittest.mock import Mock, patch
from tinygrad.llm.model import Transformer, TransformerConfig
from tinygrad.llm.serve import StreamRouter, parse_tool_call

TEST_CONFIG = TransformerConfig(num_blocks=1, dim=64, hidden_dim=128, n_heads=2, n_kv_heads=2,
                           norm_eps=1e-5, vocab_size=100, head_dim=32, rope_theta=10000.0, rope_dim=32, v_head_dim=32, max_context=32)

class TestParseToolCall(unittest.TestCase):
  def test_argument_newlines(self):
    for value in ("", "text", " text ", "\n", "\nfirst\nsecond\n\n", "\r\nfirst\r\nsecond\r\n\r\n"):
      for newline in ("\n", "\r\n"):
        self.assertEqual(parse_tool_call(f"write<arg_key>content</arg_key><arg_value>{newline}{value}{newline}</arg_value>"),
                         ("write", {"content":value}))
        self.assertEqual(parse_tool_call(f"<function=write><parameter=content>{newline}{value}{newline}</parameter></function>"),
                         ("write", {"content":value}))

  def test_json_arguments(self):
    for value in ('"text"', '42', 'true', 'null', '[1, "two"]', '{"nested":{"ok":true}}'):
      for call in (f"read<arg_key>value</arg_key><arg_value>{value}</arg_value>",
                   f"<function=read><parameter=value>{value}</parameter></function>"):
        self.assertEqual(parse_tool_call(call), ("read", {"value":json.loads(value)}))

  def test_glm_multiple_arguments(self):
    for separator in ("", "\n"):
      call = separator.join(("write", "<arg_key>path</arg_key>", "<arg_value>out.txt</arg_value>",
                             "<arg_key>content</arg_key>", "<arg_value>\nhello\n</arg_value>"))
      self.assertEqual(parse_tool_call(call), ("write", {"path":"out.txt", "content":"hello"}))

  def test_glm_no_arguments(self):
    self.assertEqual(parse_tool_call("tools.ping-v1"), ("tools.ping-v1", {}))

  def test_invalid_glm_call(self):
    for call in ("not a call", "read<arg_key>path</arg_key>", "read<arg_key>path</arg_key><arg_value>unfinished",
                 "read<arg_key>path</arg_key><arg_value>a</arg_value>trailing junk"):
      self.assertIsNone(parse_tool_call(call))

class TestLLMServer(unittest.TestCase):
  """Integration tests using the real OpenAI client."""

  @classmethod
  def setUpClass(cls):
    cls.mock_tok = Mock()
    cls.mock_tok.encode = Mock(return_value=[200, 201, 202])
    cls.mock_tok.decode = Mock(return_value="Hello")
    cls.mock_tok.stream_decoder = Mock(return_value=lambda tid=None: "Hello" if tid is not None else "")
    cls.mock_tok.preset = "llama3"
    cls.mock_tok.bos_id = 1
    cls.mock_tok.eos_id = 999
    cls.mock_tok.eot_id = None
    cls.mock_tok.is_end = Mock(side_effect=lambda tid: tid in (999,))

    cls.mock_model = Mock()
    cls.mock_model.max_context = 4
    cls.mock_model.generate = Mock(side_effect=lambda ids, **kwargs: iter([300, 301, 999]))
    cls.mock_model.get_start_pos = Mock(return_value=0)
    # the prefix-cache and spec-decode state the real model always has (a Mock attribute is truthy and not a list)
    cls.mock_model._cached_tokens, cls.mock_model._ckpt_tokens, cls.mock_model._mtp_accept, cls.mock_model._mtp_drafts = [], None, None, None

    from tinygrad.llm.cli import FallbackTemplate
    from tinygrad.llm.serve import LLMServer

    cls.server = LLMServer(('127.0.0.1', 0), cls.mock_model, "test-model", cls.mock_tok, FallbackTemplate(cls.mock_tok),
                           enable_thinking=False)  # the fork defaults to thinking on: every token would be reasoning_content
    cls.port = cls.server.server_address[1]
    cls.server_thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
    cls.server_thread.start()
    time.sleep(0.1)

    from openai import OpenAI
    cls.client = OpenAI(base_url=f"http://127.0.0.1:{cls.port}/v1", api_key="test")

  @classmethod
  def tearDownClass(cls):
    cls.server.shutdown()
    cls.server.server_close()

  def test_chat_completion_stream(self):
    stream = self.client.chat.completions.create(
      model="test",
      messages=[{"role": "user", "content": "Hello"}],
      stream=True
    )

    chunks = list(stream)
    self.assertGreater(len(chunks), 0)
    self.assertEqual(chunks[0].choices[0].delta.role, "assistant")
    self.assertEqual(chunks[-1].choices[0].finish_reason, "stop")

  def test_openai_response_structure(self):
    stream = self.client.chat.completions.create(
      model="test-model",
      messages=[{"role": "user", "content": "Test"}],
      stream=True
    )

    for chunk in stream:
      self.assertTrue(chunk.id.startswith("chatcmpl-"))
      self.assertEqual(chunk.object, "chat.completion.chunk")
      self.assertIsNotNone(chunk.choices)
      self.assertIsNotNone(chunk.created)
      self.assertIsInstance(chunk.created, int)
      self.assertEqual(chunk.model, "test-model")

  def test_stream_with_usage(self):
    def generate(ids, **kwargs):
      for token in (300, 301, 999):
        ids.append(token)
        yield token
    with patch.object(self.mock_model, "generate", side_effect=generate):
      chunks = list(self.client.chat.completions.create(
        model="test", messages=[{"role": "user", "content": "Hello"}], stream=True, stream_options={"include_usage": True}))
    last_chunk = chunks[-1]

    self.assertEqual(last_chunk.usage.prompt_tokens, 3)
    self.assertEqual(last_chunk.usage.completion_tokens, 2)
    self.assertEqual(last_chunk.usage.total_tokens, 5)

  def test_multi_turn_conversation(self):
    stream = self.client.chat.completions.create(
      model="test",
      messages=[
        {"role": "system", "content": "You are helpful."},
        {"role": "user", "content": "Hello"},
        {"role": "assistant", "content": "Hi!"},
        {"role": "user", "content": "How are you?"}
      ],
      stream=True
    )

    chunks = list(stream)
    self.assertGreater(len(chunks), 0)
    self.assertEqual(chunks[-1].choices[0].finish_reason, "stop")

  def test_text_parts_with_string_template(self):
    import jinja2
    # Qwen3's template concatenates content with strings, so a content array raises TypeError without normalization.
    template = jinja2.Template("{% for m in messages %}{{ '<|im_start|>' + m.role + '\n' + m.content + '<|im_end|>\n' }}{% endfor %}")
    with patch.object(self.server, "template", template), patch.object(self.mock_tok, "encode", side_effect=lambda text: [200, 201, 202]):
      response = self.client.chat.completions.create(model="test", messages=[
        {"role":"user", "content":[{"type":"text", "text":"Hello"}, {"type":"text", "text":" world"}]},
        {"role":"assistant", "content":None, "tool_calls":[
          {"id":"call_1", "type":"function", "function":{"name":"read", "arguments":"{}"}}]},
        {"role":"tool", "tool_call_id":"call_1", "content":"result"},
      ], stream=True)
      self.assertEqual(list(response)[-1].choices[0].finish_reason, "stop")
      # the fork's server encodes again after the answer (prefix cache resync), so the prompt is not the last call
      self.mock_tok.encode.assert_any_call('<|im_start|>user\nHello world<|im_end|>\n'
                                              '<|im_start|>assistant\n<|im_end|>\n<|im_start|>tool\nresult<|im_end|>\n')

  def test_content_is_streamed(self):
    stream = self.client.chat.completions.create(
      model="test",
      messages=[{"role": "user", "content": "Hello"}],
      stream=True
    )

    contents = []
    for chunk in stream:
      if chunk.choices and chunk.choices[0].delta.content:
        contents.append(chunk.choices[0].delta.content)

    self.assertGreater(len(contents), 0)

  def test_interrupted_stream_logs_tokens(self):
    with patch.object(self.mock_model, "generate", side_effect=lambda ids, **kwargs: iter([300, 301, 999])), \
         patch("tinygrad.llm.serve.stderr_log") as log, patch("tinygrad.llm.serve.colored", side_effect=lambda text, color: text) as color:
      stream = self.server.RequestHandlerClass.run_model(Mock(server=self.server), [200, 201, 202], "test")
      next(stream)
      next(stream)
      stream.close()
    interrupt = log.call_args.args[0]
    self.assertFalse(interrupt.startswith("\n"))
    self.assertTrue(interrupt.endswith("\n"))
    self.assertIn("gen:", interrupt)
    self.assertIn("out:    1", interrupt)
    self.assertTrue(any(args[0].startswith("total:") and args[1] == "red" for args, _ in color.call_args_list))

  def test_stream_disconnect_closes_source(self):
    from tinygrad.llm.serve import Handler
    source, handler = Mock(), Mock()
    source.__iter__ = Mock(return_value=iter([{}]))
    handler.wfile.write.side_effect = BrokenPipeError
    Handler.stream_json(handler, source)
    source.close.assert_called_once()

  def test_non_streaming(self):
    resp = self.client.chat.completions.create(
      model="test-model",
      messages=[{"role": "user", "content": "Hello"}],
      stream=False
    )

    self.assertTrue(resp.id.startswith("chatcmpl-"))
    self.assertEqual(resp.object, "chat.completion")
    self.assertEqual(resp.model, "test-model")
    self.assertIsNotNone(resp.created)
    self.assertEqual(len(resp.choices), 1)
    self.assertEqual(resp.choices[0].message.role, "assistant")
    self.assertIsNotNone(resp.choices[0].message.content)
    self.assertEqual(resp.choices[0].finish_reason, "stop")
    self.assertIsNotNone(resp.usage)
    self.assertIsNotNone(resp.usage.prompt_tokens)
    self.assertIsNotNone(resp.usage.completion_tokens)

  def test_context_length_error(self):
    from openai import BadRequestError
    self.mock_tok.encode.return_value = [200, 201, 202, 203]
    try:
      with self.assertRaises(BadRequestError) as err:
        self.client.chat.completions.create(model="test-model", messages=[{"role":"user", "content":"too long"}])
      self.assertEqual(err.exception.code, "context_length_exceeded")
    finally:
      self.mock_tok.encode.return_value = [200, 201, 202]

  def test_max_tokens_streaming(self):
    self.mock_model.generate = Mock(side_effect=lambda ids, **kwargs: iter([300, 301, 302, 303, 999]))
    stream = self.client.chat.completions.create(
      model="test", messages=[{"role": "user", "content": "Hello"}], stream=True, max_tokens=2
    )
    chunks = list(stream)
    content_chunks = [c for c in chunks if c.choices and c.choices[0].delta.content]
    self.assertEqual(len(content_chunks), 2)
    self.assertEqual(chunks[-1].choices[0].finish_reason, "length")

  def test_max_tokens_non_streaming(self):
    self.mock_model.generate = Mock(side_effect=lambda ids, **kwargs: iter([300, 301, 302, 303, 999]))
    resp = self.client.chat.completions.create(
      model="test", messages=[{"role": "user", "content": "Hello"}], stream=False, max_tokens=2
    )
    self.assertEqual(resp.choices[0].finish_reason, "length")
    self.assertEqual(resp.usage.completion_tokens, 2)

  def test_models_endpoint(self):
    import requests as req
    resp = req.get(f"http://127.0.0.1:{self.port}/v1/models")
    self.assertEqual(resp.status_code, 200)
    data = resp.json()
    self.assertEqual(data["object"], "list")
    self.assertEqual(len(data["data"]), 1)
    self.assertEqual(data["data"][0]["id"], "test-model")
    self.assertEqual(data["data"][0]["object"], "model")

  def test_get_while_generating(self):
    # a liveness probe is answered while another request holds the model
    import urllib.request
    with self.server.model_lock:
      t = time.perf_counter()
      with urllib.request.urlopen(f"http://127.0.0.1:{self.port}/v1/models", timeout=5) as r: self.assertEqual(r.status, 200)
      with urllib.request.urlopen(f"http://127.0.0.1:{self.port}/health", timeout=5) as r: self.assertEqual(r.read(), b"ok")
      self.assertLess(time.perf_counter() - t, 2)

class TestLLMToolCalls(unittest.TestCase):
  """Tool calling through the OpenAI-compatible HTTP API."""

  @classmethod
  def setUpClass(cls):
    cls.mock_tok = Mock()
    cls.mock_tok.encode = Mock(return_value=[200, 201, 202])
    cls.mock_tok.decode = Mock(return_value="")
    cls.mock_tok.preset = "qwen2"
    cls.mock_tok.bos_id, cls.mock_tok.eos_id, cls.mock_tok.eot_id = None, 999, None
    cls.mock_tok.is_end = Mock(return_value=False)

    cls.mock_model = Mock()
    cls.mock_model.max_context = 4
    cls.mock_model.get_start_pos = Mock(return_value=0)
    # the prefix-cache and spec-decode state the real model always has (a Mock attribute is truthy and not a list)
    cls.mock_model._cached_tokens, cls.mock_model._ckpt_tokens, cls.mock_model._mtp_accept, cls.mock_model._mtp_drafts = [], None, None, None

    from tinygrad.llm.serve import LLMServer
    import jinja2
    # .items() matches tool-aware templates and ensures OpenAI JSON argument strings are normalized before rendering the next turn.
    template = jinja2.Template("""{% for m in messages %}{{ m.content or '' }}{% for tc in m.tool_calls or [] %}
      {% for key, value in tc.function.arguments.items() %}{{ key }}={{ value }}{% endfor %}{% endfor %}{% endfor %}""")
    cls.server = LLMServer(('127.0.0.1', 0), cls.mock_model, "tool-model", cls.mock_tok, template,
                           enable_thinking=False)  # the fork defaults to thinking on: every token would be reasoning_content
    cls.port = cls.server.server_address[1]
    cls.server_thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
    cls.server_thread.start()
    time.sleep(0.1)

    from openai import OpenAI
    cls.client = OpenAI(base_url=f"http://127.0.0.1:{cls.port}/v1", api_key="test")

  @classmethod
  def tearDownClass(cls):
    cls.server.shutdown()
    cls.server.server_close()

  def set_output(self, text:str):
    pieces = dict(enumerate(text, 1))
    self.mock_tok.stream_decoder = Mock(return_value=lambda tid=None: pieces[tid] if tid is not None else "")
    self.mock_model.generate = Mock(side_effect=lambda ids, **kwargs: iter(pieces))

  @staticmethod
  def tools():
    return [{"type":"function", "function":{"name":"read", "description":"Read a file",
      "parameters":{"type":"object", "properties":{"path":{"type":"string"}}, "required":["path"]}}}]

  def test_streaming_tool_call(self):
    self.set_output('before<tool_call>{"name":"read","arguments":{"path":"README.md"}}</tool_call>')
    chunks = list(self.client.chat.completions.create(model="tool-model", messages=[{"role":"user", "content":"Read README.md"}],
                                                     tools=self.tools(), stream=True))
    self.assertEqual("".join(c.choices[0].delta.content or "" for c in chunks if c.choices), "before")
    calls = [tc for c in chunks if c.choices for tc in c.choices[0].delta.tool_calls or []]
    self.assertEqual(len(calls), 1)
    self.assertEqual(calls[0].function.name, "read")
    self.assertEqual(json.loads(calls[0].function.arguments), {"path":"README.md"})
    self.assertEqual(chunks[-1].choices[0].finish_reason, "tool_calls")

  def test_multiple_xml_tool_calls(self):
    self.set_output("<tool_call><function=read><parameter=path>\"a\"</parameter></function></tool_call>"
                    "<tool_call><function=read><parameter=path>\"b\"</parameter></function></tool_call>")
    response = self.client.chat.completions.create(model="tool-model", messages=[{"role":"user", "content":"Read a and b"}],
                                                   tools=self.tools())
    self.assertEqual([json.loads(tc.function.arguments)["path"] for tc in response.choices[0].message.tool_calls], ["a", "b"])
    self.assertEqual(response.choices[0].finish_reason, "tool_calls")

  def test_xml_string_parameter_stays_string(self):
    # a string-typed parameter whose text happens to be valid JSON must not be decoded into a number / bool / object
    self.set_output("<tool_call><function=read><parameter=path>42</parameter></function></tool_call>"
                    "<tool_call><function=read><parameter=path>{\"a\": 1}</parameter></function></tool_call>")
    response = self.client.chat.completions.create(model="tool-model", messages=[{"role":"user", "content":"Read"}], tools=self.tools())
    self.assertEqual([json.loads(tc.function.arguments)["path"] for tc in response.choices[0].message.tool_calls], ["42", '{"a": 1}'])

  def test_streaming_glm_tool_calls(self):
    self.set_output("before<tool_call>read<arg_key>path</arg_key><arg_value>a</arg_value></tool_call>"
                    "<tool_call>read\n<arg_key>path</arg_key>\n<arg_value>\nb\n</arg_value>\n</tool_call>")
    chunks = list(self.client.chat.completions.create(model="tool-model", messages=[{"role":"user", "content":"Read files"}],
                                                     tools=self.tools(), stream=True))
    self.assertEqual("".join(c.choices[0].delta.content or "" for c in chunks if c.choices), "before")
    calls = [tc for c in chunks if c.choices for tc in c.choices[0].delta.tool_calls or []]
    self.assertEqual([tc.function.name for tc in calls], ["read", "read"])
    self.assertEqual([json.loads(tc.function.arguments) for tc in calls], [{"path":"a"}, {"path":"b"}])
    self.assertEqual([tc.index for tc in calls], [0, 1])
    self.assertEqual(chunks[-1].choices[0].finish_reason, "tool_calls")

  def test_multiline_tool_argument_preserves_trailing_newline(self):
    self.set_output("<tool_call>\n<function=write>\n<parameter=content>\nfirst\nsecond\n\n</parameter>\n"
                    "<parameter=filePath>\nout.txt\n</parameter>\n</function>\n</tool_call>")
    response = self.client.chat.completions.create(model="tool-model", messages=[{"role":"user", "content":"Write out.txt"}], tools=self.tools())
    args = json.loads(response.choices[0].message.tool_calls[0].function.arguments)
    self.assertEqual(args, {"content":"first\nsecond\n", "filePath":"out.txt"})

  def test_invalid_tool_call_becomes_content(self):
    self.set_output("<tool_call>not a call</tool_call>")
    response = self.client.chat.completions.create(model="tool-model", messages=[{"role":"user", "content":"Hello"}], tools=self.tools())
    self.assertEqual(response.choices[0].message.content, "<tool_call>not a call</tool_call>")
    self.assertIsNone(response.choices[0].message.tool_calls)
    self.assertEqual(response.choices[0].finish_reason, "stop")

  def test_tool_call_in_reasoning_is_not_executed(self):
    self.set_output('<think>draft <tool_call>{"name":"wrong","arguments":{}}</tool_call></think>answer')
    response = self.client.chat.completions.create(model="tool-model", messages=[{"role":"user", "content":"Hello"}], tools=self.tools())
    self.assertEqual(response.choices[0].message.content, "answer")
    self.assertIsNone(response.choices[0].message.tool_calls)
    self.assertEqual(response.choices[0].finish_reason, "stop")

  def test_tool_result_round_trip(self):
    self.set_output('<tool_call>{"name":"read","arguments":{"path":"README.md"}}</tool_call>')
    first = self.client.chat.completions.create(model="tool-model", messages=[{"role":"user", "content":"Read README.md"}], tools=self.tools())
    call = first.choices[0].message.tool_calls[0]
    self.set_output("done")
    second = self.client.chat.completions.create(model="tool-model", messages=[
      {"role":"user", "content":"Read README.md"},
      {"role":"assistant", "content":None, "tool_calls":[call.model_dump()]},
      {"role":"tool", "tool_call_id":call.id, "content":"file contents"},
    ], tools=self.tools())
    self.assertEqual(second.choices[0].message.content, "done")
    self.assertEqual(second.choices[0].finish_reason, "stop")

class TestDeadDevices(unittest.TestCase):
  def test_error_word(self):
    # error_state is a buffer every device has: only a nonzero error word means the device failed
    from tinygrad import Device, Tensor
    from tinygrad.llm.serve import _dead_devices
    Tensor([1]).realize()
    self.assertEqual(_dead_devices(), [])
    err = Device[Device.DEFAULT].error_state.host.view(fmt='q')
    err[0] = 5
    try: self.assertIn((Device.DEFAULT, 5), _dead_devices())
    finally: err[0] = 0
    self.assertEqual(_dead_devices(), [])

class TestPrefixSnapshots(unittest.TestCase):
  def test_save_before_checkpoint_rollback(self):
    # a conversation diverging after the shared system prompt: get_start_pos rolls the live state back to the system prompt
    # checkpoint, so the save must copy the state from before that
    from types import SimpleNamespace
    from tinygrad.llm.serve import Handler
    sys_p, conv_b = list(range(10)), list(range(10)) + [50] * 2000
    model = SimpleNamespace(_ckpt_tokens=conv_b, _cached_tokens=conv_b + [7], prefix_match=lambda ids, c: 0)
    model.snapshot_state = lambda arena=None: SimpleNamespace(tokens=list(model._cached_tokens), nbytes=lambda: 1)
    model.snapshot_nbytes = lambda: 1
    def get_start_pos(ids):
      model._cached_tokens = list(sys_p)
      return len(sys_p)
    model.get_start_pos = get_start_pos
    srv = SimpleNamespace(model=model, max_snapshots=2, snapshot_min_tokens=1024, snapshots=[], host_snapshots=[], max_host_snapshots=0,
                          max_host_bytes=0, arena=object())
    with patch("tinygrad.llm.serve.stderr_log"): Handler._pick_prefix_state(SimpleNamespace(server=srv), sys_p + [60] * 100, [])
    self.assertEqual([len(s.tokens) for s in srv.snapshots], [len(conv_b) + 1])

  def test_host_arena(self):
    # snapshot pieces are views of one pinned buffer; a snapshot's pieces come back when it is collected
    import gc
    from tinygrad import Device
    from tinygrad.llm.model import HostArena
    a = HostArena(Device.DEFAULT, 4096)
    snaps = []
    class Snap: pass
    for _ in range(4):
      a.take(1000); snaps.append(Snap()); a.claim(snaps[-1])
    with self.assertRaises(MemoryError): a.take(1000)
    a.abandon()
    snaps.pop(0); gc.collect()
    a.take(1000)  # fits again

  def test_save_snapshot_drops_oldest(self):
    from types import SimpleNamespace
    from tinygrad.llm import serve
    tries = iter([MemoryError(), MemoryError(), "snap"])
    def snapshot_state(arena):
      r = next(tries)
      if isinstance(r, Exception): raise r
      return r
    snap = lambda n: SimpleNamespace(tokens=[0] * n, nbytes=lambda: n)
    srv = SimpleNamespace(arena=SimpleNamespace(nbytes=10), host_snapshots=[snap(1), snap(2)], snapshots=[snap(3)])
    with patch("tinygrad.llm.serve.stderr_log"):
      self.assertEqual(serve._save_snapshot(srv, SimpleNamespace(snapshot_state=snapshot_state)), "snap")
    self.assertEqual((srv.host_snapshots, len(srv.snapshots)), ([], 1))  # the two oldest (host tier first) made room
    tries = iter([MemoryError()])
    srv = SimpleNamespace(arena=SimpleNamespace(nbytes=10), host_snapshots=[], snapshots=[])
    with patch("tinygrad.llm.serve.stderr_log"): self.assertIsNone(serve._save_snapshot(srv, SimpleNamespace(snapshot_state=snapshot_state)))

  def test_arena_snapshot_is_on_host(self):
    # arena pieces are views: a snapshot of them is already in host memory (to_host must not copy it again, and must keep segs)
    from tinygrad import Device, dtypes
    from tinygrad.device import Buffer
    from tinygrad.llm.model import HostArena, StateSnapshot
    a = HostArena(Device.DEFAULT, 4096)
    snap = StateSnapshot([1], (), [a.take(100)], None, [], [], [[(0, 100)]])
    self.assertTrue(snap.on_host)
    self.assertIs(snap.to_host(), snap)
    dev = StateSnapshot([1], (), [Buffer(Device.DEFAULT, 100, dtypes.uint8).ensure_allocated()], None, [], [], [[(0, 100)]])
    self.assertEqual(dev.to_host().segs, [[(0, 100)]])

  def test_failed_restore_drops_live_state(self):
    # a restore that fails partway must not leave the half-overwritten live state reusable
    from types import SimpleNamespace
    from tinygrad import Device, Tensor, dtypes
    from tinygrad.device import Buffer
    from tinygrad.llm.model import Transformer, StateSnapshot
    live = Tensor.empty(200, dtype=dtypes.uint8).contiguous().realize()
    m = SimpleNamespace(snapshot_tensors=lambda: [live], _cached_tokens=[1, 2, 3], _ckpt_tokens=[1, 2], _ckpts=[([1], [])])
    snap = StateSnapshot([1], (), [Buffer(Device.DEFAULT, 100, dtypes.uint8).ensure_allocated()], None, [], [], [None])
    with self.assertRaises(AssertionError): Transformer.restore_state(m, snap)
    self.assertEqual((m._cached_tokens, m._ckpt_tokens, m._ckpts), ([], None, []))

  def test_snapshot_buffers_freed(self):
    # a dropped snapshot gives its memory back: snapshot sizes vary, so a buffer parked in the allocator's LRU cache was never reused
    from tinygrad import Device, dtypes
    from tinygrad.device import Buffer
    from tinygrad.llm.model import StateSnapshot
    src = Buffer(Device.DEFAULT, 12345, dtypes.uint8).ensure_allocated()
    for hb in (StateSnapshot._host_copy(src), StateSnapshot._host_pack(src, [(0, 1000), (2000, 345)])): del hb
    self.assertFalse(any(len(v) for k, v in Device[Device.DEFAULT].allocator.cache.items() if k[0] in (12345, 1345)))

class TestTransformerGenerate(unittest.TestCase):
  def test_warmup(self):
    model, calls = Transformer(TEST_CONFIG), []
    def generate(tokens, **kwargs):
      calls.append(tokens)
      yield from (1, 2)
    with patch.object(model, "generate", generate): model.warmup()
    self.assertEqual(calls, [[0], [0]])

  def test_template_starts_reasoning(self):
    router = StreamRouter(reasoning=True)
    self.assertEqual(list(router.route("reasoning</think>answer")),
                     [("reasoning_content", "reasoning"), ("content", "answer")])

if __name__ == '__main__':
  unittest.main()
class TestCheckpointResume(unittest.TestCase):
  def _model(self, cached, ck):
    from types import SimpleNamespace
    m = SimpleNamespace(has_recurrent_block=True, _cached_tokens=list(cached), _ckpt_tokens=list(ck), _ckpts=[], _pfx_tokens=None,
                        _media_cut=lambda key: None, restored=[])
    m._restore_checkpoint = lambda: m.restored.append(True)
    return m

  def test_resume_from_prefill_checkpoint(self):
    from tinygrad.llm.model import Transformer
    m = self._model(cached=[1, 2, 3, 4, 9, 9], ck=[1, 2, 3, 4])  # the conversation's own next turn
    self.assertEqual(Transformer.get_start_pos(m, [1, 2, 3, 4, 5, 6]), 4)
    self.assertEqual(m.restored, [True])

  def test_no_resume_after_kv_overwritten(self):
    # a 1-token request ran in between: it wrote kv at position 0.. without taking a checkpoint; the old checkpoint must not be used
    from tinygrad.llm.model import Transformer
    m = self._model(cached=[7, 8], ck=[1, 2, 3, 4])
    self.assertEqual(Transformer.get_start_pos(m, [1, 2, 3, 4, 5, 6]), 0)
    self.assertEqual(m.restored, [])

