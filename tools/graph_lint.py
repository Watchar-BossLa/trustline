#!/usr/bin/env python3
"""TRUSTLINE graph linter — local implementation of the HEF v1.1.0 structural rules.

This is a stand-in for the hef-graph-layer bundle linter (tools/graph_lint.py in that
bundle). If you have the bundle, run its linter as well; this one checks the same eight
rules plus TRUSTLINE-specific traceability against spec/registry.yaml.

Usage:
  python3 tools/graph_lint.py                      # lint graphs/build.graph.yaml
  python3 tools/graph_lint.py --plan tasks/todo.md # also check the plan covers every id
Exit code 0 = clean, 1 = errors.
"""
from __future__ import annotations

import argparse
import re
import sys
from collections import defaultdict
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
KINDS = {"prompt", "tool", "verifier", "router", "fanout", "join", "human", "terminal"}


def load(path: Path):
    with path.open(encoding="utf-8") as fh:
        return yaml.safe_load(fh)


def lint(graph_doc: dict, registry: dict) -> list[str]:
    errors: list[str] = []
    g = graph_doc.get("graph", {})
    policy = graph_doc.get("policy", {})
    nodes = {n["id"]: n for n in graph_doc.get("nodes", [])}
    edges = graph_doc.get("edges", [])
    loops = {l["id"]: l for l in graph_doc.get("loops", [])}

    if len(nodes) != len(graph_doc.get("nodes", [])):
        errors.append("duplicate node ids")
    for nid, n in nodes.items():
        if n.get("kind") not in KINDS:
            errors.append(f"{nid}: unknown kind {n.get('kind')!r}")
        if "implements" not in n:
            errors.append(f"{nid}: missing implements")

    # Rule 1: single entry, at least one terminal, DAG minus loop edges
    entry = g.get("entry")
    if entry not in nodes:
        errors.append(f"entry {entry!r} is not a node")
    terminals = [i for i, n in nodes.items() if n.get("kind") == "terminal"]
    if not terminals:
        errors.append("no terminal node")
    for e in edges:
        if "on" in e or True in e:
            errors.append(f"edge {e.get('from')}->{e.get('to')}: use `when`, not `on`")
        for end in ("from", "to"):
            if e.get(end) not in nodes:
                errors.append(f"edge references unknown node {e.get(end)!r}")
    adj = defaultdict(list)
    for e in edges:
        if not e.get("loop"):
            adj[e["from"]].append(e["to"])
    state: dict[str, int] = {}

    def dfs(u: str, stack: list[str]) -> None:
        state[u] = 1
        for v in adj[u]:
            if state.get(v) == 1:
                errors.append("cycle without a declared loop: " + " -> ".join(stack + [u, v]))
            elif state.get(v) is None:
                dfs(v, stack + [u])
        state[u] = 2

    for nid in nodes:
        if nid not in state:
            dfs(nid, [])

    # reachability from entry (all edges)
    full = defaultdict(list)
    for e in edges:
        full[e["from"]].append(e["to"])
    seen, todo = set(), [entry]
    while todo:
        u = todo.pop()
        if u in seen:
            continue
        seen.add(u)
        todo.extend(full[u])
    for nid in nodes:
        if nid not in seen and nid != "aborted":
            errors.append(f"{nid}: unreachable from entry")

    # Rule 2: every non-terminal has an outgoing edge; exits routed or fall back
    out_by_node = defaultdict(set)
    for e in edges:
        out_by_node[e["from"]].add(e.get("when"))
    fallback = policy.get("on_unrouted_exit")
    for nid, n in nodes.items():
        if n.get("kind") == "terminal":
            continue
        if not out_by_node[nid]:
            errors.append(f"{nid}: non-terminal with no outgoing edge")
        for ex in n.get("exits", []):
            if ex not in out_by_node[nid] and not fallback:
                errors.append(f"{nid}: exit {ex!r} unrouted and no policy.on_unrouted_exit")
        for w in out_by_node[nid]:
            if w not in n.get("exits", []):
                errors.append(f"{nid}: edge condition {w!r} is not a declared exit")
    if fallback and fallback.get("route_to") not in nodes and fallback != "abort":
        errors.append("policy.on_unrouted_exit.route_to is not a node")

    # Rule 3: back-edges name a loop with max_iterations
    for e in edges:
        if e.get("loop"):
            l = loops.get(e["loop"])
            if not l:
                errors.append(f"edge {e['from']}->{e['to']}: loop {e['loop']!r} not declared")
            elif not isinstance(l.get("max_iterations"), int) or l["max_iterations"] < 1:
                errors.append(f"loop {e['loop']}: max_iterations must be a positive int")

    # Rule 4: fanout/join pairing
    fanouts = [i for i, n in nodes.items() if n["kind"] == "fanout"]
    joins = [n for n in nodes.values() if n["kind"] == "join"]
    for f in fanouts:
        if sum(1 for j in joins if j.get("of") == f) != 1:
            errors.append(f"{f}: fanout must have exactly one join")

    # Rule 5: input sources and carries resolve
    graph_inputs = set((g.get("inputs") or {}).keys())
    outputs = {nid: set((n.get("outputs") or {}).keys()) for nid, n in nodes.items()}
    ref = re.compile(r"^\$(graph\.input\.(?P<gi>\w+)|node\.(?P<n>\w+)\.(?P<o>\w+)|item)$")

    def check_source(where: str, src: str) -> None:
        m = ref.match(src or "")
        if not m:
            errors.append(f"{where}: bad source {src!r}")
            return
        if m.group("gi") and m.group("gi") not in graph_inputs:
            errors.append(f"{where}: unknown graph input {m.group('gi')}")
        if m.group("n"):
            if m.group("n") not in nodes:
                errors.append(f"{where}: unknown node {m.group('n')}")
            elif m.group("o") not in outputs[m.group("n")]:
                errors.append(f"{where}: node {m.group('n')} has no output {m.group('o')}")
        if src == "$item":
            errors.append(f"{where}: $item used outside a fanout")

    for nid, n in nodes.items():
        for iname, spec in (n.get("inputs") or {}).items():
            check_source(f"{nid}.inputs.{iname}", spec.get("source"))
    for e in edges:
        for target, src in (e.get("carries") or {}).items():
            check_source(f"edge {e['from']}->{e['to']}.carries.{target}", src)
            tnode = nodes.get(e["to"], {})
            allowed = set((tnode.get("inputs") or {}).keys())
            if tnode.get("kind") in {"prompt", "verifier", "router"}:
                allowed.add("feedback")
            if target not in allowed:
                errors.append(f"edge {e['from']}->{e['to']}: carries unknown input {target!r}")

    # Rule 6: budgets
    total = g.get("budget", {}).get("total_tokens", 0)
    reserve = g.get("budget", {}).get("reserve_fraction", 0)
    spent = 0
    for nid, n in nodes.items():
        b = n.get("budget") or {}
        cost = b.get("max_input_tokens", 0) + b.get("max_output_tokens", 0)
        r = n.get("reasoning") or {}
        if r.get("mode") == "got":
            cost *= r.get("budget_multiplier", 1)
        if n["kind"] == "fanout":
            cost *= n.get("max_parallel", 1)
        spent += cost
    limit = total * (1 - reserve)
    if spent > limit:
        errors.append(f"budget: nodes sum to {spent:,.0f} tokens > {limit:,.0f} allowed")

    # Rule 7: GoT only on critical nodes
    for nid, n in nodes.items():
        if (n.get("reasoning") or {}).get("mode") == "got" and not n.get("critical"):
            errors.append(f"{nid}: reasoning.mode got requires critical: true")

    # Rule 8: traceability
    implemented = set()
    for n in nodes.values():
        implemented.update(n.get("implements", []))
    must = [r["id"] for r in registry["requirements"] if r["priority"] == "must"]
    acs = [a["id"] for a in registry["acceptance_criteria"]]
    known = set(must) | set(acs) | {r["id"] for r in registry["requirements"]}
    for m in registry["milestones"]:
        known.add(m["id"])
        known.update(t["id"] for t in m["tasks"])
        known.update(c["id"] for c in m["checks"])
    for rid in must + acs:
        if rid not in implemented:
            errors.append(f"traceability: {rid} is not implemented by any node")
    for nid, n in nodes.items():
        for rid in n.get("implements", []):
            if rid not in known:
                errors.append(f"{nid}: implements unknown id {rid}")

    # TRUSTLINE rule: every context file a node reads must exist in the pack
    for nid, n in nodes.items():
        for inc in (n.get("context") or {}).get("include", []):
            if inc.startswith("hef."):
                continue
            if not (ROOT / inc).exists():
                errors.append(f"{nid}: context file {inc!r} does not exist")

    # TRUSTLINE rule: no build node reaches a terminal without a verifier
    build_kinds = {"prompt", "tool"}
    for e in edges:
        src, dst = nodes.get(e["from"], {}), nodes.get(e["to"], {})
        if src.get("kind") in build_kinds and dst.get("kind") == "terminal" and dst.get("status") == "complete":
            errors.append(f"{e['from']} reaches terminal {e['to']} without a verifier")
    return errors


def check_plan(plan: Path, registry: dict) -> list[str]:
    text = plan.read_text(encoding="utf-8")
    errs = []
    ids = [r["id"] for r in registry["requirements"] if r["priority"] == "must"]
    ids += [a["id"] for a in registry["acceptance_criteria"]]
    for m in registry["milestones"]:
        ids += [t["id"] for t in m["tasks"]]
    for i in ids:
        if not re.search(rf"\b{re.escape(i)}\b", text):
            errs.append(f"plan: {i} not mentioned in {plan}")
    return errs


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--graph", default=str(ROOT / "graphs/build.graph.yaml"))
    ap.add_argument("--registry", default=str(ROOT / "spec/registry.yaml"))
    ap.add_argument("--plan")
    a = ap.parse_args()
    registry = load(Path(a.registry))
    errs = lint(load(Path(a.graph)), registry)
    if a.plan:
        errs += check_plan(Path(a.plan), registry)
    for e in errs:
        print("ERROR", e)
    print(f"{'FAIL' if errs else 'OK'}: {len(errs)} error(s)")
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())
