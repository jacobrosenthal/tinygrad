#!/usr/bin/env python3
"""Synthesize a realistic agent 'skills/tools' system prompt: many JSON-schema function
definitions with verbose descriptions, structurally similar to what Hermes/OpenAI-style
agent harnesses send (we measured the real Hermes system prompt at ~20K tokens of exactly
this kind of content: '# Tools\\n\\nYou have access to the following functions...')."""
import json, random

random.seed(42)
DOMAINS = ["file", "terminal", "web", "memory", "calendar", "email", "spotify", "slack",
           "kanban", "browser", "image_gen", "video_gen", "tts", "stt", "code_execution",
           "cronjob", "delegation", "skills", "todo", "vision", "x_search", "homeassistant",
           "discord", "telegram", "whatsapp", "signal", "spotify_playback", "weather", "maps"]
ACTIONS = ["create", "read", "update", "delete", "search", "list", "execute", "schedule",
           "cancel", "send", "receive", "upload", "download", "analyze", "summarize", "query"]
PARAM_TYPES = ["string", "integer", "boolean", "number", "array", "object"]

def make_tool(name):
    n_params = random.randint(3, 8)
    props = {}
    for i in range(n_params):
        pname = f"param_{i}_{random.choice(['id','name','value','path','query','limit','offset','filter','sort_by','options'])}"
        props[pname] = {
            "type": random.choice(PARAM_TYPES),
            "description": f"Controls {pname.replace('_',' ')} for the {name} operation. " * random.randint(1,3)
        }
    return {
        "type": "function",
        "function": {
            "name": name,
            "description": (f"Use this tool to {random.choice(ACTIONS)} resources in the {name.split('_')[0]} domain. "
                             f"This is part of a larger toolkit for agentic task execution. " * random.randint(2,4)),
            "parameters": {"type": "object", "properties": props, "required": list(props.keys())[:2]}
        }
    }

def build(target_tokens=14000):
    tools = []
    for domain in DOMAINS:
        for action in ACTIONS[:random.randint(2,5)]:
            tools.append(make_tool(f"{domain}_{action}"))
    text = "# Tools\n\nYou have access to the following functions:\n\n"
    text += json.dumps(tools, indent=1)
    # rough word->token expansion until we hit the target (JSON ~1.3 tok/word for this content)
    while len(text.split()) * 1.3 < target_tokens:
        for domain in DOMAINS:
            tools.append(make_tool(f"{domain}_{random.choice(ACTIONS)}_{len(tools)}"))
        text = "# Tools\n\nYou have access to the following functions:\n\n" + json.dumps(tools, indent=1)
    return text, tools

if __name__ == "__main__":
    text, tools = build()
    with open("skills_system_prompt.txt", "w") as f: f.write(text)
    print(f"{len(tools)} tools, {len(text.split())} words, ~{int(len(text.split())*1.3)} est. tokens")
