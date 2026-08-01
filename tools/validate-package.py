from __future__ import annotations

import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError as exc:
    raise SystemExit("PyYAML is required to validate this package") from exc

ROOT = Path(__file__).resolve().parents[1]
SKILLS_ROOT = ROOT / ".github" / "skills"
AGENTS_ROOT = ROOT / ".github" / "agents"

NAMES = (
    "spec-writer",
    "spec-to-tasks",
    "spec-implementer",
    "task-implementer",
    "task-test-guardian",
    "task-code-reviewer",
)

EXPECTED_TOOLS = {
    "spec-writer": ["read", "search", "edit"],
    "spec-to-tasks": ["read", "search", "edit"],
    "spec-implementer": ["read", "search", "execute", "agent"],
    "task-implementer": ["read", "search", "edit", "execute"],
    "task-test-guardian": ["read", "search", "edit", "execute"],
    "task-code-reviewer": ["read", "search"],
}

EXPECTED_AGENT_NAMES = {
    "spec-writer": "Spring Spec Writer",
    "spec-to-tasks": "Spec to Tasks",
    "spec-implementer": "Spec Implementer",
    "task-implementer": "Task Implementer",
    "task-test-guardian": "Task Test Guardian",
    "task-code-reviewer": "Task Code Reviewer",
}

EXPECTED_HANDOFFS = {
    "spec-writer": [
        {
            "label": "Decompor spec aprovada",
            "agent": "spec-to-tasks",
            "prompt": "Use a spec aprovada desta conversa e decomponha-a em tasks rastreaveis. Nao implemente codigo.",
            "send": False,
        }
    ],
    "spec-to-tasks": [
        {
            "label": "Implementar tasks",
            "agent": "spec-implementer",
            "prompt": "Implemente a fila de tasks criada nesta conversa, uma task por vez, com testes, review e aprovacao entre tasks.",
            "send": False,
        }
    ],
    "spec-implementer": [],
    "task-implementer": [],
    "task-test-guardian": [],
    "task-code-reviewer": [],
}

SKILL_FIELDS = {
    "name",
    "description",
    "license",
    "argument-hint",
    "allowed-tools",
    "user-invocable",
    "disable-model-invocation",
}

AGENT_FIELDS = {
    "name",
    "description",
    "argument-hint",
    "tools",
    "model",
    "target",
    "disable-model-invocation",
    "user-invocable",
    "infer",
    "mcp-servers",
    "metadata",
    "handoffs",
}

FORBIDDEN = (
    "spawn_agent",
    "followup_task",
    "fork_turns",
    "send_message",
    "gpt-5.6",
    "agents/openai.yaml",
)


def fail(message: str) -> None:
    raise AssertionError(message)


def read_frontmatter(path: Path) -> tuple[dict, str, str]:
    text = path.read_text(encoding="utf-8")
    match = re.fullmatch(r"---\r?\n(?P<yaml>[\s\S]*?)\r?\n---\r?\n(?P<body>[\s\S]*)", text)
    if not match:
        fail(f"invalid frontmatter envelope: {path}")
    data = yaml.safe_load(match.group("yaml"))
    if not isinstance(data, dict):
        fail(f"frontmatter is not a mapping: {path}")
    return data, match.group("body").strip(), text


def validate_skill(name: str) -> tuple[dict, str, str]:
    folder = SKILLS_ROOT / name
    path = folder / "SKILL.md"
    if not path.is_file():
        fail(f"missing skill: {path}")

    data, body, text = read_frontmatter(path)
    unknown = set(data) - SKILL_FIELDS
    if unknown:
        fail(f"unsupported skill fields in {path}: {sorted(unknown)}")
    if data.get("name") != name:
        fail(f"skill name does not match folder: {path}")
    if not re.fullmatch(r"[a-z0-9-]{1,64}", name):
        fail(f"invalid skill name: {name}")
    description = data.get("description")
    if not isinstance(description, str) or not description.strip() or len(description) > 1024:
        fail(f"invalid skill description: {path}")
    if data.get("user-invocable") is not True:
        fail(f"skill must be user-invocable: {path}")
    if data.get("disable-model-invocation") is not False:
        fail(f"skill must allow model invocation: {path}")
    if "allowed-tools" in data:
        fail(f"skill must not pre-approve tools: {path}")
    if not body:
        fail(f"empty skill body: {path}")
    return data, body, text


def validate_agent(name: str, skill_data: dict, skill_body: str) -> str:
    path = AGENTS_ROOT / f"{name}.agent.md"
    if not path.is_file():
        fail(f"missing agent: {path}")
    if not re.fullmatch(r"[A-Za-z0-9._-]+\.agent\.md", path.name):
        fail(f"invalid agent filename: {path.name}")

    data, body, text = read_frontmatter(path)
    unknown = set(data) - AGENT_FIELDS
    if unknown:
        fail(f"unsupported agent fields in {path}: {sorted(unknown)}")
    if data.get("name") != EXPECTED_AGENT_NAMES[name]:
        fail(f"unexpected agent display name: {path}: {data.get('name')}")
    description = data.get("description")
    if not isinstance(description, str) or not description.strip():
        fail(f"invalid agent description: {path}")
    if description != skill_data.get("description"):
        fail(f"agent description is stale relative to skill: {path}")
    if data.get("argument-hint") != skill_data.get("argument-hint"):
        fail(f"agent argument-hint is stale relative to skill: {path}")
    if data.get("tools") != EXPECTED_TOOLS[name]:
        fail(f"unexpected tool scope: {path}: {data.get('tools')}")
    if data.get("user-invocable") is not True:
        fail(f"agent must be user-invocable: {path}")
    if data.get("disable-model-invocation") is not False:
        fail(f"agent must allow model invocation: {path}")
    if "model" in data or "target" in data or "infer" in data:
        fail(f"non-portable model, target, or infer field: {path}")
    if len(body) > 30000:
        fail(f"agent body exceeds 30000 characters: {path}")

    body_lines = body.splitlines()
    marker = f"<!-- Gerado de ../skills/{name}/SKILL.md por tools/generate-agents.ps1. -->"
    if not body_lines or body_lines[0] != marker:
        fail(f"missing generated-source marker: {path}")
    generated_body = "\n".join(body_lines[1:]).strip()
    if generated_body != skill_body:
        fail(f"agent body is stale relative to skill: {path}")

    handoffs = data.get("handoffs", [])
    if handoffs != EXPECTED_HANDOFFS[name]:
        fail(f"unexpected handoffs: {path}: {handoffs}")
    for handoff in handoffs:
        if not isinstance(handoff, dict):
            fail(f"invalid handoff: {path}")
        target = handoff.get("agent")
        if target not in NAMES or not (AGENTS_ROOT / f"{target}.agent.md").is_file():
            fail(f"handoff target is missing: {path}: {target}")
        if handoff.get("send") is not False:
            fail(f"handoff must preserve human confirmation: {path}: {target}")

    if name == "spec-implementer" and ("agent" not in data["tools"] or "edit" in data["tools"]):
        fail("orchestrator must delegate and must not edit directly")
    if name != "spec-implementer" and "agent" in data["tools"]:
        fail(f"specialist must not delegate: {path}")
    if name == "task-code-reviewer" and ({"edit", "execute", "agent"} & set(data["tools"])):
        fail("reviewer must not receive mutation-capable or delegation tools")
    return text


def validate_package() -> None:
    skill_dirs = sorted(path.name for path in SKILLS_ROOT.iterdir() if path.is_dir())
    agent_ids = sorted(path.name.removesuffix(".agent.md") for path in AGENTS_ROOT.glob("*.agent.md"))
    if skill_dirs != sorted(NAMES):
        fail(f"unexpected skill directories: {skill_dirs}")
    if agent_ids != sorted(NAMES):
        fail(f"unexpected agents: {agent_ids}")

    all_text = []
    for name in NAMES:
        skill_data, skill_body, skill_text = validate_skill(name)
        agent_text = validate_agent(name, skill_data, skill_body)
        all_text.extend((skill_text, agent_text))
        print(f"PASS {name}")

    corpus = "\n".join(all_text)
    for token in FORBIDDEN:
        if token in corpus:
            fail(f"Codex-specific token remains: {token}")
    if "\ufffd" in corpus:
        fail("Unicode replacement character found")
    for mojibake in ("Ã¡", "Ã£", "Ã§", "Ã©", "Ã³", "Ã­", "Ãª", "Ãµ", "Â"):
        if mojibake in corpus:
            fail(f"mojibake found: {mojibake}")

    print("PASS package: 6 skills, 6 agents, tool scopes, handoffs, parity, UTF-8")


if __name__ == "__main__":
    try:
        validate_package()
    except AssertionError as exc:
        print(f"FAIL {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
