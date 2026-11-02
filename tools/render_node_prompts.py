#!/usr/bin/env python3
"""Render one Claude Code task prompt per graph node (HEF v1.1.0 Meta Prompting).

Reads graphs/build.graph.yaml and spec/registry.yaml and writes prompts/nodes/NN-<node>.md.
Never hand-edit the rendered prompts: change the graph or the registry, then re-run:

  python3 tools/graph_lint.py && python3 tools/render_node_prompts.py
"""
from __future__ import annotations

import json
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "prompts/nodes"

DEFAULT_ROLE = {
    "prompt": "Senior Rust and TypeScript engineer building a security-critical government system to the TRUSTLINE spec",
    "verifier": "Independent verification engineer; you check, you do not build",
    "human": "Facilitator asking Kelvin for a decision",
}

HEF_SECTIONS = {
    "hef.all": "TRUSTLINE.hef.md (all sections)",
    "hef.constraints": "TRUSTLINE.hef.md — <hef_constraints>",
    "hef.architecture": "TRUSTLINE.hef.md — <hef_architecture>",
    "hef.verification": "TRUSTLINE.hef.md — <hef_verification>",
}


def load(p: Path):
    return yaml.safe_load(p.read_text(encoding="utf-8"))


def index_registry(reg: dict) -> dict[str, str]:
    idx: dict[str, str] = {}
    for r in reg["requirements"]:
        idx[r["id"]] = f"[{r['priority']}] {r['text'].strip()}"
    for a in reg["acceptance_criteria"]:
        idx[a["id"]] = a["text"].strip()
    for m in reg["milestones"]:
        idx[m["id"]] = f"Milestone {m['name']}: {m['objective']}"
        for t in m["tasks"]:
            idx[t["id"]] = t["text"]
        for c in m["checks"]:
            idx[c["id"]] = c["text"]
    return idx


def render(node: dict, n: int, idx: dict, reg: dict, graph: dict) -> str:
    gid = graph["graph"]["id"]
    kind = node["kind"]
    role = (node.get("prompt") or {}).get("role") or DEFAULT_ROLE.get(kind, DEFAULT_ROLE["prompt"])
    lines = [f"# Node {n:02d} — `{node['id']}` ({kind})", "",
             "Paste this whole block into Claude Code when the graph reaches this node, or let the",
             "orchestrator in MASTER_PROMPT.md load it. Replace {run_id} and {attempt}.", "",
             "```xml",
             f'<node_prompt graph="{gid}" node="{node["id"]}" run="{{run_id}}" attempt="{{attempt}}">',
             f"<role>{role}</role>",
             f"<objective>{node['objective']}</objective>",
             "<implements>"]
    for rid in node.get("implements", []):
        lines.append(f"  <item id=\"{rid}\">{idx.get(rid, '(see spec/registry.yaml)')}</item>")
    lines.append("</implements>")

    lines.append("<inputs>")
    for name, spec in (node.get("inputs") or {}).items():
        src = spec.get("source", "")
        lines.append(f"  <input name=\"{name}\" type=\"{spec.get('type')}\" source=\"{src}\"/>")
    if kind in {"prompt", "verifier"}:
        lines.append("  <input name=\"feedback\" type=\"list\" source=\"carried on retry edges only\"/>")
    lines.append("</inputs>")

    ctx = (node.get("context") or {}).get("include", [])
    if ctx:
        lines.append("<context mode=\"flat\">Read only these before acting:")
        for c in ctx:
            lines.append(f"  - {HEF_SECTIONS.get(c, c)}")
        lines.append("</context>")

    lines.append("<constraints>")
    for hl in reg["hard_limits"]:
        lines.append(f"  - {hl['id']}: {hl['text']}")
    if node.get("files_touched"):
        lines.append("  - Scope lock: touch only " + ", ".join(node["files_touched"]) +
                     " plus their tests and route wiring in crates/api/src/main.rs and crates/api/src/routes/mod.rs. "
                     "Anything else needed goes in <exit code=\"needs_input\">.")
    lines.append("  - Do no work that belongs to another node. Treat spec/, graphs/, prompts/, policies/trustline.cedar, "
                 "policies/trustline.cedarschema, rules/, db/schema.sql and api/openapi.yaml as the contract: "
                 "if one of them is wrong, exit needs_input with the proposed change instead of editing it.")
    lines.append("</constraints>")

    contract = node.get("contract") or {}
    if kind != "human":
        lines.append("<contract>")
        outs = {k: v.get("type") for k, v in (node.get("outputs") or {}).items()}
        lines.append(f"  <outputs>{json.dumps(outs)}</outputs>")
        if contract.get("preconditions"):
            lines.append("  <preconditions>")
            for p in contract["preconditions"]:
                lines.append(f"    - {p}")
            lines.append("  </preconditions>")
        lines.append("  <postconditions>Self-check each before exiting success:")
        for p in contract.get("postconditions", []):
            lines.append(f"    - [ ] {p}")
        lines.append("  </postconditions>")
        lines.append("</contract>")
    if node.get("command"):
        lines.append(f"<command>{node['command']}</command>")
    if kind == "human":
        lines.append(f"<ask>Use AskUserQuestion: {node.get('ask')}</ask>")

    b = node.get("budget") or {}
    if kind != "human":
        lines.append(f"<budget>At most {b.get('max_output_tokens', 0):,} output tokens and {b.get('max_calls', 0)} tool calls; "
                     f"exit budget_exceeded if the objective cannot be met within them.</budget>")
    lines.append("<feedback>{carried findings, on retries only}</feedback>")
    exits = ", ".join(node.get("exits", []))
    lines.append("<exit_protocol>End with exactly one <exit code=\"...\"><outputs>{JSON}</outputs></exit> "
                 f"where code is one of: {exits}. Append one line to tasks/trace.jsonl "
                 "(node, attempt, exit, files_touched, tokens if known). Do no work outside this node's objective.</exit_protocol>")
    lines.append("</node_prompt>")
    lines.append("```")

    nexts = [e for e in graph["edges"] if e["from"] == node["id"]]
    if nexts:
        lines += ["", "**Routing after this node**", ""]
        for e in nexts:
            loop = f" (loop `{e['loop']}`)" if e.get("loop") else ""
            lines.append(f"- `{e['when']}` → `{e['to']}`{loop}")
    return "\n".join(lines) + "\n"


def main() -> None:
    graph = load(ROOT / "graphs/build.graph.yaml")
    reg = load(ROOT / "spec/registry.yaml")
    idx = index_registry(reg)
    OUT.mkdir(parents=True, exist_ok=True)
    for old in OUT.glob("*.md"):
        old.unlink()
    n = 0
    index_lines = ["# Node prompts (rendered — do not hand-edit)", "",
                   "Rendered from graphs/build.graph.yaml and spec/registry.yaml by tools/render_node_prompts.py.", "",
                   "| # | Node | Kind | Implements |", "| --- | --- | --- | --- |"]
    for node in graph["nodes"]:
        if node["kind"] == "terminal":
            continue
        n += 1
        fname = f"{n:02d}-{node['id']}.md"
        (OUT / fname).write_text(render(node, n, idx, reg, graph), encoding="utf-8")
        index_lines.append(f"| {n:02d} | [{node['id']}]({fname}) | {node['kind']} | {', '.join(node.get('implements', []))} |")
    terminals = [x for x in graph["nodes"] if x["kind"] == "terminal"]
    index_lines += ["", "Terminal nodes (no prompt; the orchestrator performs them):", ""]
    for t in terminals:
        index_lines.append(f"- `{t['id']}` ({t['status']}): {t['objective']}")
    (OUT / "README.md").write_text("\n".join(index_lines) + "\n", encoding="utf-8")
    print(f"rendered {n} node prompts to {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
