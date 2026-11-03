"""Generate graphs/build.graph.yaml for TRUSTLINE from a compact definition.

The graph is generated, never hand-edited. Change this file, then run:
  python3 tools/gen_graph.py && python3 tools/graph_lint.py && python3 tools/render_node_prompts.py
"""
import yaml, sys
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "graphs/build.graph.yaml"

PROMPT_EXITS = ["success", "fail", "needs_input", "budget_exceeded", "timeout", "blocked"]
VERIFIER_EXITS = ["success", "fail", "needs_input", "budget_exceeded", "timeout"]

BUILD_BUDGET = {"max_input_tokens": 200000, "max_output_tokens": 60000, "max_calls": 120, "max_wall_seconds": 10800}
WEB_BUDGET = {"max_input_tokens": 300000, "max_output_tokens": 100000, "max_calls": 180, "max_wall_seconds": 14400}
VERIFY_BUDGET = {"max_input_tokens": 80000, "max_output_tokens": 8000, "max_calls": 40, "max_wall_seconds": 3600}
FIX_BUDGET = {"max_input_tokens": 150000, "max_output_tokens": 40000, "max_calls": 80, "max_wall_seconds": 7200}

CORE_CONTEXT = ["hef.constraints", "hef.architecture", "CLAUDE.md", "tasks/lessons.md"]


def build_node(nid, objective, implements, context, postconditions, files, budget=None, role=None):
    n = {
        "id": nid,
        "kind": "prompt",
        "objective": objective,
        "implements": implements,
        "critical": False,
        "inputs": {
            "plan": {"type": "file", "source": "$node.plan_build.plan_path"},
        },
        "outputs": {
            "summary": {"type": "string", "required": True},
            "files_touched": {"type": "list", "required": True},
        },
        "contract": {
            "preconditions": ["Plan approved (tasks/todo.md exists and approve_plan exited approved)"],
            "postconditions": postconditions,
        },
        "context": {"mode": "flat", "include": CORE_CONTEXT + context},
        "reasoning": {"mode": "direct"},
        "budget": budget or BUILD_BUDGET,
        "retry": {"max": 2, "mutate": ["add_feedback"]},
        "files_touched": files,
        "exits": PROMPT_EXITS,
    }
    if role:
        n["prompt"] = {"role": role}
    return n


def verifier(nid, objective, implements, checks, command):
    return {
        "id": nid,
        "kind": "verifier",
        "objective": objective,
        "implements": implements,
        "critical": False,
        "inputs": {"plan": {"type": "file", "source": "$node.plan_build.plan_path"}},
        "outputs": {
            "report": {"type": "file", "required": True},
            "failures": {"type": "list", "required": True},
        },
        "contract": {
            "preconditions": ["All build nodes of this milestone exited success"],
            "postconditions": checks,
        },
        "context": {"mode": "flat", "include": ["hef.verification", "docs/08-verification-plan.md", "tasks/lessons.md"]},
        "reasoning": {"mode": "direct"},
        "command": command,
        "budget": VERIFY_BUDGET,
        "retry": {"max": 1, "mutate": ["add_feedback"]},
        "exits": VERIFIER_EXITS,
    }


def fixer(nid, milestone, verifier_id):
    return {
        "id": nid,
        "kind": "prompt",
        "objective": f"Find the root cause of every failure reported by {verifier_id} and fix it without widening {milestone} scope.",
        "implements": [milestone],
        "critical": False,
        "inputs": {
            "plan": {"type": "file", "source": "$node.plan_build.plan_path"},
            "failures": {"type": "list", "source": f"$node.{verifier_id}.failures"},
        },
        "outputs": {
            "summary": {"type": "string", "required": True},
            "files_touched": {"type": "list", "required": True},
        },
        "contract": {
            "preconditions": [f"{verifier_id} exited fail with a non-empty failures list"],
            "postconditions": [
                "Each failure has a stated root cause and a fix, not a workaround",
                "No test was weakened, skipped or deleted to make it pass",
                "A lesson is appended to tasks/lessons.md for each distinct root cause",
            ],
        },
        "context": {"mode": "flat", "include": CORE_CONTEXT + ["docs/08-verification-plan.md"]},
        "reasoning": {"mode": "direct"},
        "budget": FIX_BUDGET,
        "retry": {"max": 1, "mutate": ["add_feedback", "escalate_model"]},
        "exits": PROMPT_EXITS,
    }


nodes = []
edges = []
loops = []

# ---------- Plan ----------
nodes.append({
    "id": "plan_build",
    "kind": "prompt",
    "objective": "Produce an implementation plan for milestones M1 to M7 in tasks/todo.md that covers every must requirement and acceptance criterion, respects every hard limit, and names the files each task touches.",
    "implements": ["M1", "M2", "M3", "M4", "M5", "M6", "M7"],
    "critical": True,
    "inputs": {"spec": {"type": "file", "source": "$graph.input.hef"}, "registry": {"type": "file", "source": "$graph.input.registry"}},
    "outputs": {"plan_path": {"type": "file", "required": True}, "open_questions": {"type": "list", "required": False}},
    "contract": {
        "preconditions": ["TRUSTLINE.hef.md, spec/registry.yaml and every file under docs/ have been read"],
        "postconditions": [
            "tasks/todo.md lists every task T1.1 to T7.5 as a checkbox with the files it touches",
            "Every must requirement and every acceptance criterion id appears against at least one task",
            "The plan names the crates, binaries and app routes exactly as in docs/02-architecture.md",
            "Open questions are listed separately; none is silently decided",
        ],
    },
    "context": {"mode": "flat", "include": ["hef.all", "spec/registry.yaml", "docs/01-product-brief.md", "docs/02-architecture.md", "docs/adr/"]},
    "reasoning": {"mode": "got", "branches": 3, "merge": "critique", "budget_multiplier": 2.5},
    "budget": {"max_input_tokens": 150000, "max_output_tokens": 20000, "max_calls": 60, "max_wall_seconds": 3600},
    "retry": {"max": 1, "mutate": ["add_feedback"]},
    "prompt": {"role": "Principal engineer planning a security-critical government system build"},
    "exits": PROMPT_EXITS,
})
nodes.append({
    "id": "verify_plan",
    "kind": "verifier",
    "objective": "Confirm the plan is complete, traceable and within the hard limits before any code is written.",
    "implements": ["M1"],
    "critical": False,
    "inputs": {"plan": {"type": "file", "source": "$node.plan_build.plan_path"}},
    "outputs": {"report": {"type": "file", "required": True}, "failures": {"type": "list", "required": True}},
    "contract": {"preconditions": ["tasks/todo.md exists"],
                 "postconditions": ["Every must requirement and acceptance criterion id is mapped to a task",
                                    "No task contradicts a hard limit HL1 to HL12",
                                    "Every task names its files and its verification"]},
    "context": {"mode": "flat", "include": ["hef.verification", "spec/registry.yaml"]},
    "reasoning": {"mode": "direct"},
    "command": "python3 tools/graph_lint.py --plan tasks/todo.md",
    "budget": {"max_input_tokens": 60000, "max_output_tokens": 6000, "max_calls": 20, "max_wall_seconds": 1800},
    "retry": {"max": 1, "mutate": ["add_feedback"]},
    "exits": VERIFIER_EXITS,
})
nodes.append({
    "id": "approve_plan",
    "kind": "human",
    "objective": "Kelvin approves the plan or asks for changes before implementation starts.",
    "implements": ["M1"],
    "inputs": {"plan": {"type": "file", "source": "$node.plan_build.plan_path"},
               "open_questions": {"type": "list", "source": "$node.plan_build.open_questions"}},
    "outputs": {"decision": {"type": "string", "required": True}, "notes": {"type": "string", "required": False}},
    "ask": "Here is the implementation plan in tasks/todo.md and the open questions. Approve it, or tell me what to change.",
    "budget": {"max_input_tokens": 0, "max_output_tokens": 0, "max_calls": 1, "max_wall_seconds": 604800},
    "exits": ["approved", "rejected", "timeout"],
})
edges += [
    {"from": "plan_build", "to": "verify_plan", "when": "success"},
    {"from": "verify_plan", "to": "approve_plan", "when": "success"},
    {"from": "verify_plan", "to": "plan_build", "when": "fail", "carries": {"feedback": "$node.verify_plan.failures"}, "loop": "plan_revise"},
    {"from": "approve_plan", "to": "m1_scaffold", "when": "approved"},
    {"from": "approve_plan", "to": "plan_build", "when": "rejected", "carries": {"feedback": "$node.approve_plan.notes"}, "loop": "plan_human_revise"},
    {"from": "approve_plan", "to": "blocked", "when": "timeout"},
]
loops += [{"id": "plan_revise", "max_iterations": 2}, {"id": "plan_human_revise", "max_iterations": 3}]

# ---------- Milestones ----------
M = [
    ("M1", [
        build_node("m1_scaffold", "Create the Cargo workspace, compose stack, Makefile, CI and typed configuration with the DEV_AUTH guard.",
                   ["R12", "T1.1", "T1.2", "T1.3", "T1.4"], ["docs/02-architecture.md", "docs/adr/0006-demo-auth-and-pilot-auth.md"],
                   ["cargo build --workspace succeeds", "make verify runs every gate listed in docs/08", "DEV_AUTH with TRUSTLINE_ENV=production refuses to start (test)", ".env.example contains no secret values"],
                   ["Cargo.toml", "crates/*/", "services/mock-agencies/", "docker-compose.yml", "Makefile", ".github/workflows/ci.yml", ".env.example", "crates/core/src/config.rs"]),
        build_node("m1_schema", "Turn db/schema.sql into sqlx migrations with roles and append-only triggers, plus the no-master-records schema test.",
                   ["R4", "R12", "T1.5"], ["db/schema.sql", "docs/03-data-model.md", "db/tests/disclosure_test.sql"],
                   ["Migrations reproduce db/schema.sql exactly (diff of pg_dump --schema-only is empty)", "App role cannot UPDATE or DELETE ledger.access_event", "Schema test lists every table and fails if a master-record table appears",
                    "db/tests/disclosure_test.sql passes against the migrated database (DF1-DF25)"],
                   ["db/migrations/", "crates/api/tests/schema.rs", "Makefile"]),
        build_node("m1_seed", "Implement the deterministic synthetic data generator for TRUSTLINE tables and mock-agency fixtures.",
                   ["T1.6"], ["docs/09-synthetic-data.md", "rules/"],
                   ["Personas S1 to S10 and officers in docs/09 exist after make seed", "Same seed gives byte-identical fixtures", "Every generated identifier starts with SYN and every name is from the fictional list"],
                   ["crates/cli/src/seed/", "services/mock-agencies/fixtures/"]),
    ], verifier("verify_m1", "Confirm the foundation builds, migrates and seeds cleanly.", ["V1.1", "V1.2", "V1.3", "R12"],
                ["V1.1 make verify passes on a clean clone", "V1.2 migrations apply; ledger UPDATE/DELETE rejected", "V1.3 seeding is deterministic"],
                "make verify && make db && make seed && cargo test -p trustline-api --test schema && make db-test")),
    ("M2", [
        build_node("m2_policy", "Implement the Cedar policy engine and the exhaustive permission matrix test.",
                   ["R2", "R3", "T2.1", "T2.2", "AC3", "AC4"], ["policies/", "docs/05-access-policy.md", "rules/reason-codes.yaml", "rules/field-groups.yaml"],
                   ["Policies validate against the schema at startup or the process exits", "Matrix test covers every role, reason code, field group and context flag combination", "Matrix equals the expected-permissions table in docs/05"],
                   ["crates/policy/", "policies/tests/"]),
        build_node("m2_ledger", "Implement the hash-chained, signed ledger, checkpoints, ledger middleware and the verify command.",
                   ["R5", "T2.3", "T2.4", "AC5", "AC6"], ["docs/02-architecture.md", "docs/03-data-model.md", "docs/adr/0004-tamper-evident-ledger.md"],
                   ["Every ledger-scoped request writes exactly one entry, including errors", "verify detects modify, delete and reorder at the first bad sequence", "No raw identifier is written to the ledger (test scans entries)"],
                   ["crates/ledger/", "crates/api/src/middleware/ledger.rs", "crates/cli/src/ledger.rs"]),
    ], verifier("verify_m2", "Confirm policy decisions and ledger integrity.", ["V2.1", "V2.2", "V2.3", "AC3", "AC4", "AC5", "AC6"],
                ["V2.1 policy matrix passes; health isolation holds", "V2.2 tamper tests pass", "V2.3 one entry per ledger-scoped request"],
                "cargo test -p trustline-policy -p trustline-ledger && cargo test -p trustline-api --test ledger_coverage")),
    ("M3", [
        build_node("m3_agencies", "Build the mock agencies service and the X-Road-shaped adapters.",
                   ["R4", "T3.1", "T3.2"], ["docs/02-architecture.md", "docs/adr/0002-xroad-exchange.md", "docs/09-synthetic-data.md"],
                   ["Each adapter has a contract test against the mock", "Every adapter call sends client, service, message id, user id and purpose headers", "Latency and failure injection are configurable per agency"],
                   ["services/mock-agencies/", "crates/adapters/"]),
        build_node("m3_broker", "Implement the broker, status card, hit confirmation, investigation queries and rate limits.",
                   ["R1", "R9", "R11", "T3.3", "T3.4", "T3.5", "AC1", "AC2", "AC11", "AC13", "AC19"], ["api/openapi.yaml", "docs/04-api.md", "docs/05-access-policy.md", "rules/field-groups.yaml"],
                   ["Only policy-permitted adapter calls are made (test asserts the mock received no other call)", "A failed source yields UNKNOWN fields with source status", "Rate limit returns 429 and writes a ledger entry", "Responses validate against api/openapi.yaml"],
                   ["crates/broker/", "crates/api/src/routes/roadside.rs", "crates/api/src/routes/hits.rs", "crates/api/src/routes/investigations.rs"]),
        build_node("m3_offline", "Implement the signed, encrypted, expiring offline bundle and sync endpoint.",
                   ["R14", "T3.6", "AC15"], ["docs/02-architecture.md", "docs/06-security-threat-model.md"],
                   ["trustline-offline has no tokio dependency and exposes a UniFFI-compatible API", "Tampered, unknown-key and expired bundles are rejected", "Synced checks create ledger entries with offline = true"],
                   ["crates/offline/", "crates/api/src/routes/offline.rs"]),
    ], verifier("verify_m3", "Confirm the roadside path end to end.", ["V3.1", "V3.2", "V3.3", "AC1", "AC2", "AC11", "AC13", "AC15", "AC19"],
                ["V3.1 personas S1–S5 cards correct; p95 under 2 s", "V3.2 agency outage yields UNKNOWN", "V3.3 bundle and rate-limit tests pass"],
                "cargo test --workspace && make loadtest-smoke")),
    ("M4", [
        build_node("m4_tickets", "Implement tickets, payments, court referral and outcomes, section 107 and the court timeline.",
                   ["R7", "R13", "R18", "T4.1", "T4.2", "T4.3", "AC14", "AC21"], ["rules/offences.yaml", "api/openapi.yaml", "docs/03-data-model.md"],
                   ["Ticket identifiers are envelope-encrypted at rest", "Court outcome and payment endpoints require the court_system service principal", "Section 107 detection runs on schedule and is idempotent"],
                   ["crates/tickets/", "crates/api/src/routes/tickets.rs", "crates/api/src/routes/court.rs"]),
        build_node("m4_demerit", "Implement the demerit engine, proposed actions and Licensing Authority decisions.",
                   ["R8", "T4.4", "T4.5", "T4.6", "AC8", "AC9", "AC10"], ["rules/demerit-schedule.yaml", "docs/08-verification-plan.md", "docs/07-privacy-and-legal-basis.md"],
                   ["The engine is pure (no I/O) and versioned by the rules file hash", "Every row of the docs/08 section 179 table has a passing test", "No licence action is effective without a decision event"],
                   ["crates/demerit/", "crates/api/src/routes/licensing.rs"]),
    ], verifier("verify_m4", "Confirm tickets, points and licence actions.", ["V4.1", "V4.2", "V4.3", "AC8", "AC9", "AC10", "AC14", "AC21"],
                ["V4.1 section 179 table fully covered", "V4.2 S6 flow passes", "V4.3 S10 flow passes"],
                "cargo test -p trustline-demerit -p trustline-tickets && cargo test -p trustline-api --test flows")),
    ("M5", [
        build_node("m5_citizen", "Implement the citizen record, the access log with leak-proof disclosure control, deferrals, protected identities, disputes and the emergency card.",
                   ["R6", "R15", "R16", "R21", "R22", "T5.1", "T5.2", "T5.3", "AC7", "AC16", "AC20", "AC23", "AC24"],
                   ["api/openapi.yaml", "docs/05-access-policy.md", "docs/07-privacy-and-legal-basis.md", "rules/disclosure.yaml",
                    "db/tests/disclosure_test.sql", "docs/adr/0011-leak-proof-disclosure-deferrals.md"],
                   ["Citizen endpoints only ever resolve the caller's own subject hash",
                    "Every citizen-facing access-log read goes through citizen.visible_access_events; a test fails the build if any other query touches ledger.access_event_subject for a citizen route",
                    "The AC23 leak suite compares persona S8 with control persona S11 response by response and they match apart from sequence numbers, request ids and generation times",
                    "Disputes against withheld, foreign and nonexistent sequence numbers return byte-identical 404 bodies and headers",
                    "Deferral and designation actions write ledger entries with relation administrative",
                    "EMS access is denied without an active incident or consent"],
                   ["crates/api/src/routes/me.rs", "crates/api/src/routes/ems.rs", "crates/api/src/routes/deferrals.rs",
                    "crates/api/src/routes/protected_identities.rs", "crates/api/tests/disclosure_leak.rs", "crates/api/tests/deferral_lifecycle.rs"]),
        build_node("m5_oversight", "Implement the anomaly engine, alerts, monthly report and ledger status endpoint.",
                   ["R10", "T5.4", "T5.5", "AC12"], ["rules/anomaly-rules.yaml", "docs/06-security-threat-model.md"],
                   ["Every rule in rules/anomaly-rules.yaml has a test that fires it and one that does not", "Reports contain aggregates only, never identifiers", "Alert reviews are themselves ledger entries"],
                   ["crates/oversight/", "crates/api/src/routes/oversight.rs"]),
    ], verifier("verify_m5", "Confirm citizen transparency, leak-proof deferrals and oversight.", ["V5.1", "V5.2", "V5.3", "AC7", "AC12", "AC16", "AC20", "AC23", "AC24"],
                ["V5.1 S8 misuse alert raised", "V5.2 disclosure_test.sql, deferral lifecycle and API leak suite pass", "V5.3 EMS flow and police denial pass"],
                "cargo test -p trustline-oversight && cargo test -p trustline-api --test citizen --test oversight --test disclosure_leak --test deferral_lifecycle && make db-test")),
    ("M6", [
        build_node("m6_web", "Build the Next.js app with officer, dispatch, licensing, citizen, EMS and oversight screens and the Playwright demo flow.",
                   ["R17", "T6.1", "T6.2", "T6.3", "T6.4", "T6.5", "AC17", "AC22"], ["docs/10-demo-script.md", "api/openapi.yaml", "docs/04-api.md"],
                   ["The web app calls only the API; it holds no business rules", "Every screen shows the SYNTHETIC and pending-legal-verification banners", "The persona switcher is absent when DEV_AUTH is off"],
                   ["apps/web/"], budget=WEB_BUDGET),
    ], verifier("verify_m6", "Confirm the screens, accessibility and performance.", ["V6.1", "V6.2", "V6.3", "AC17", "AC22"],
                ["V6.1 Playwright demo flow passes", "V6.2 axe checks pass", "V6.3 status card under 3 s on 3G"],
                "pnpm -C apps/web lint && pnpm -C apps/web typecheck && pnpm -C apps/web test:e2e")),
    ("M7", [
        build_node("m7_security", "Harden the build against the threat model and run every security gate.",
                   ["R11", "R12", "T7.1", "T7.2", "T7.3", "AC13", "AC18"], ["docs/06-security-threat-model.md", "docs/08-verification-plan.md"],
                   ["Each threat in docs/06 has status mitigated, accepted with reason, or deferred to pilot", "No medium-or-higher finding from cargo-deny, gitleaks, npm audit or ZAP remains open", "Load-test results are recorded in docs/08"],
                   ["docs/06-security-threat-model.md", "docs/08-verification-plan.md", "deny.toml"], role="Security engineer; use the security-reviewer subagent for an independent pass"),
        build_node("m7_demo", "Make the demo reproducible from a fresh clone and update all state documents.",
                   ["T7.4", "T7.5", "AC17"], ["docs/10-demo-script.md", "README.md"],
                   ["make demo from a fresh clone needs under 10 minutes of setup", "README, CLAUDE.md Current State and tasks/todo.md review are current"],
                   ["README.md", "CLAUDE.md", "tasks/todo.md", "Makefile"]),
    ], verifier("verify_m7", "Confirm every quality gate and the demo from a fresh clone.", ["V7.1", "V7.2", "V7.3", "AC13", "AC17", "AC18"],
                ["V7.1 all gates green", "V7.2 every threat has a status", "V7.3 fresh-clone demo under 10 minutes setup"],
                "make verify && make demo-check")),
]

prev_verifier = None
for idx, (mid, builds, ver) in enumerate(M):
    fix_id = f"fix_{mid.lower()}"
    # build chain
    for i, b in enumerate(builds):
        if i == 0:
            pred = "approve_plan exited approved" if idx == 0 else f"{M[idx-1][2]['id']} exited success"
        else:
            pred = f"{builds[i-1]['id']} exited success"
        if not (idx == 0 and i == 0):
            b["contract"]["preconditions"].append(pred)
        nodes.append(b)
        nxt = builds[i + 1]["id"] if i + 1 < len(builds) else ver["id"]
        edges.append({"from": b["id"], "to": nxt, "when": "success"})
        edges.append({"from": b["id"], "to": "blocked", "when": "needs_input"})
        edges.append({"from": b["id"], "to": "blocked", "when": "blocked"})
    nodes.append(ver)
    nodes.append(fixer(fix_id, mid, ver["id"]))
    edges.append({"from": ver["id"], "to": fix_id, "when": "fail", "carries": {"failures": f"$node.{ver['id']}.failures"}})
    edges.append({"from": fix_id, "to": ver["id"], "when": "success", "loop": f"{fix_id}_loop"})
    edges.append({"from": fix_id, "to": "blocked", "when": "needs_input"})
    edges.append({"from": fix_id, "to": "blocked", "when": "blocked"})
    edges.append({"from": ver["id"], "to": "blocked", "when": "needs_input"})
    loops.append({"id": f"{fix_id}_loop", "max_iterations": 3})
    if idx + 1 < len(M):
        edges.append({"from": ver["id"], "to": M[idx + 1][1][0]["id"], "when": "success"})
    else:
        edges.append({"from": ver["id"], "to": "approve_demo", "when": "success"})

edges.append({"from": "plan_build", "to": "blocked", "when": "needs_input"})
edges.append({"from": "verify_plan", "to": "blocked", "when": "needs_input"})

nodes.append({
    "id": "approve_demo",
    "kind": "human",
    "objective": "Kelvin runs the demo script and signs off the build as pitch-ready, or lists changes.",
    "implements": ["M7", "AC17"],
    "inputs": {"report": {"type": "file", "source": "$node.verify_m7.report"}},
    "outputs": {"decision": {"type": "string", "required": True}, "notes": {"type": "string", "required": False}},
    "ask": "The build passes every gate. Please run docs/10-demo-script.md and tell me: sign off, or the changes you want.",
    "budget": {"max_input_tokens": 0, "max_output_tokens": 0, "max_calls": 1, "max_wall_seconds": 604800},
    "exits": ["approved", "rejected", "timeout"],
})
nodes.append({
    "id": "apply_demo_feedback",
    "kind": "prompt",
    "objective": "Apply Kelvin's demo feedback within the existing scope and hard limits.",
    "implements": ["M7"],
    "critical": False,
    "inputs": {"notes": {"type": "string", "source": "$node.approve_demo.notes"}},
    "outputs": {"summary": {"type": "string", "required": True}, "files_touched": {"type": "list", "required": True}},
    "contract": {"preconditions": ["approve_demo exited rejected with notes"],
                 "postconditions": ["Each requested change is applied or explained as out of scope", "No hard limit is crossed"]},
    "context": {"mode": "flat", "include": CORE_CONTEXT + ["docs/10-demo-script.md"]},
    "reasoning": {"mode": "direct"},
    "budget": FIX_BUDGET,
    "retry": {"max": 1, "mutate": ["add_feedback"]},
    "exits": PROMPT_EXITS,
})
edges += [
    {"from": "approve_demo", "to": "done", "when": "approved"},
    {"from": "approve_demo", "to": "apply_demo_feedback", "when": "rejected", "carries": {"notes": "$node.approve_demo.notes"}},
    {"from": "approve_demo", "to": "blocked", "when": "timeout"},
    {"from": "apply_demo_feedback", "to": "verify_m7", "when": "success", "loop": "demo_feedback_loop"},
    {"from": "apply_demo_feedback", "to": "blocked", "when": "needs_input"},
    {"from": "apply_demo_feedback", "to": "blocked", "when": "blocked"},
]
loops.append({"id": "demo_feedback_loop", "max_iterations": 3})

for tid, status, obj in [
    ("done", "complete", "Write hef_state as complete, append the run's lessons to tasks/lessons.md and stop."),
    ("blocked", "blocked", "Write hef_state with the blocker and the exact question for Kelvin, append lessons, and stop."),
    ("aborted", "failed", "Write hef_state with the failure, the last node and its exit, append lessons, and stop."),
]:
    nodes.append({"id": tid, "kind": "terminal", "status": status, "objective": obj, "implements": ["T7.5"]})

graph = {
    "graph": {
        "id": "trustline_build",
        "version": "1.0.0",
        "hef_ref": {"name": "TRUSTLINE", "version": "1.0.0"},
        "entry": "plan_build",
        "inputs": {
            "hef": {"type": "file", "required": True, "default": "TRUSTLINE.hef.md"},
            "registry": {"type": "file", "required": True, "default": "spec/registry.yaml"},
        },
        "budget": {"total_tokens": 8000000, "max_wall_seconds": 259200, "reserve_fraction": 0.1},
        "budget_note": "First-run planning budgets. Tune from tasks/trace.jsonl after M1; keep node ids stable.",
    },
    "policy": {
        "on_unrouted_exit": {"route_to": "aborted"},
        "max_concurrency": 2,
        "trace_path": "tasks/trace.jsonl",
        "lessons_path": "tasks/lessons.md",
    },
    "loops": loops,
    "nodes": nodes,
    "edges": edges,
}

class NoAlias(yaml.SafeDumper):
    def ignore_aliases(self, data):
        return True

header = (
    "# TRUSTLINE build graph (HEF v1.1.0 Graph Layer)\n"
    "# Execution order for Claude Code. One node = one task prompt (prompts/nodes/).\n"
    "# Lint:   python3 tools/graph_lint.py\n"
    "# Render: python3 tools/render_node_prompts.py\n"
    "# Edge conditions use `when` (YAML 1.1 parses `on` as a boolean).\n\n"
)
OUT.write_text(header + yaml.dump(graph, Dumper=NoAlias, sort_keys=False, width=110, allow_unicode=True))
print("nodes", len(nodes), "edges", len(edges), "loops", len(loops))
