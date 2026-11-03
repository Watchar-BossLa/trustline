# CLAUDE.md — TRUSTLINE

TRUSTLINE is a purpose-bound public-safety data exchange for the Government of Saint Lucia.
This file tells Claude Code how to work in this repository. The workflow layer comes first
and overrides convenience; the project layer below it is specific to TRUSTLINE.

---

## Workflow Orchestration

### 1. Plan Mode Default
- Enter plan mode for any non-trivial task: three or more steps, or any architectural decision.
- If something goes sideways, stop and re-plan immediately. Do not keep pushing.
- Use plan mode for verification steps too, not only for building.
- Specs are already written (TRUSTLINE.hef.md, docs/, spec/registry.yaml). Read them before planning; do not re-invent them.

### 2. Subagent Strategy
- Use subagents to keep the main context clean: research, codebase exploration, parallel analysis.
- One task per subagent. Give it the node prompt, the files it may touch and the exit protocol.
- Use the project subagents in `.claude/agents/`: `security-reviewer` after every milestone,
  `policy-auditor` whenever policies, roles, reason codes or field groups change,
  `spec-verifier` before any verifier node exits success.

### 3. Self-Improvement Loop
- After any correction from Kelvin, or any verifier failure, add the pattern to `tasks/lessons.md`.
- Write the lesson as a rule that prevents the mistake, with the date and node id.
- Read `tasks/lessons.md` at the start of every session and every node.

### 4. Verification Before Done
- Never mark a task or node complete without proving it works: run the node's command and tests.
- Compare behaviour before and after your change when relevant.
- Ask: "Would a staff engineer at a national identity agency approve this?"
- A node exits `success` only when every postcondition in its prompt is checked off with evidence.

### 5. Demand Elegance (Balanced)
- For non-trivial changes, pause and ask whether there is a simpler, more elegant design.
- If a fix feels hacky, implement the clean solution you would choose knowing everything you know now.
- Do not over-engineer simple, obvious changes.
- Challenge your own work before presenting it.

### 6. Autonomous Bug Fixing
- Given a failing test, CI error or bug report: find the root cause and fix it. No hand-holding needed.
- Read logs, errors and failing tests, then resolve them.
- Never weaken, skip or delete a test to make it pass. Never mark a known failure as expected.

## Task Management
1. **Plan first** — write the plan to `tasks/todo.md` as checkable items (node `plan_build`).
2. **Verify the plan** — get Kelvin's approval before implementation (node `approve_plan`).
3. **Track progress** — tick items as you complete them; one node at a time.
4. **Explain changes** — a short, plain-language summary after each node (Kelvin is non-technical).
5. **Document results** — add a review section to `tasks/todo.md` at the end of each milestone.
6. **Capture lessons** — update `tasks/lessons.md` after every correction or verifier failure.

## Core Principles
- **Simplicity First** — make every change as simple as possible; touch the least code.
- **No Laziness** — find root causes; no temporary fixes; senior-engineer standards.
- **Minimal Impact** — change only what the node needs; avoid side effects and collateral edits.

---

## Project overview

TRUSTLINE lets a police officer at a traffic stop see, on one screen, only what the law allows
for that stop — licence valid or suspended, vehicle registered, insured and inspected, unpaid
tickets, an open warrant — fetched live from each agency, never stored centrally. Every lookup
is decided by Cedar policy, written to a tamper-evident ledger, and shown to the citizen in
their access log. Tickets feed a section 179 demerit ledger whose licence actions a Licensing
Authority officer must confirm. Health data never reaches the police.

Read in this order before any work: `TRUSTLINE.hef.md` → `spec/registry.yaml` →
`docs/02-architecture.md` → the docs your node lists → `tasks/lessons.md`.

## Tech stack
- Rust stable, edition 2024: tokio, axum, tower, sqlx (PostgreSQL), serde, cedar-policy 4.x,
  ed25519-dalek, sha2, hmac, uuid v7, time, tracing.
- PostgreSQL 16. Canonical DDL: `db/schema.sql`; migrations in `db/migrations/` are generated from it.
- Cedar: `policies/trustline.cedar` + `policies/trustline.cedarschema`.
- OpenAPI 3.1: `api/openapi.yaml` is the contract (spec-first).
- Next.js App Router, TypeScript strict, Tailwind, pnpm, Playwright, axe — in `apps/web/`.
- docker compose for local runs; GitHub Actions CI.

## Architecture
```
crates/core        trustline-core       domain types, config, errors, SubjectKey (HMAC)
crates/policy      trustline-policy     Cedar wrapper: decide(), policy_version()
crates/ledger      trustline-ledger     canonical JSON, SHA-256 chain, Ed25519, checkpoints, verify
crates/adapters    trustline-adapters   AgencyAdapter trait + one adapter per agency (X-Road-shaped)
crates/broker      trustline-broker     policy-first fan-out, status card, hits
crates/tickets     trustline-tickets    tickets, payments, court, section 107, court timeline
crates/demerit     trustline-demerit    pure section 179 engine (no I/O)
crates/oversight   trustline-oversight  anomaly rules, alerts, monthly report
crates/offline     trustline-offline    offline bundles; no async runtime; UniFFI-ready
crates/api         trustline-api        axum server, auth, rate limits, ledger middleware
crates/cli         trustline-cli        seed, keys, ledger verify, reports
services/mock-agencies                  synthetic agency systems
apps/web                                /officer /dispatch /licensing /citizen /ems /oversight
```
Dependency direction: core ← policy, ledger, adapters, demerit, offline ← broker, tickets,
oversight ← api, cli. No crate depends on api. demerit and offline do no I/O.

## Development conventions
- **Policy first, then fetch.** The broker asks Cedar which field groups are permitted, then
  calls only the adapters those groups need. Never fetch and then filter.
- **One ledger entry per ledger-scoped request** (endpoints marked `x-ledger: true` in the
  OpenAPI), written by middleware, including denials, rate limits and errors.
- **Identifiers:** raw NIC, licence and plate numbers exist only in transit and, for tickets,
  envelope-encrypted at rest. Everywhere else use `SubjectKey` (HMAC-SHA-256 with the pepper
  from config). Logs must never contain raw identifiers — there is a test for it.
- **Errors:** `application/problem+json` per the `Problem` schema; never leak internals or
  which agency holds what.
- **Unknown beats stale.** A source that times out yields `UNKNOWN` with its source status.
- **Withheld means never existed.** A citizen must not be able to tell a withheld access entry from
  a lookup that never happened: same pages, same 404s, no counts, no notifications (ADR 0011).
  Deferral handling is written to the ledger with subject relation `administrative`.
- **Rules are data.** Reason codes, field groups, demerit points, offences, anomaly thresholds
  and retention come from `rules/*.yaml`, loaded and validated at startup; the rules file hash is
  recorded with every decision that used it.
- **Tests:** unit tests beside code; integration tests in `crates/api/tests/`; property tests for
  `trustline-demerit`; Playwright for the demo flow. Every acceptance criterion in
  `spec/registry.yaml` has at least one test whose name contains its id (e.g. `ac9_...`).
- **Commits:** small, one node per branch or commit series, message `node <id>: <summary>`.
- **Plain-language summaries** for Kelvin after each node: what now works, how to see it, what is next.

## Graph Execution
This build runs as a graph: `graphs/build.graph.yaml`. Each node has a rendered prompt in
`prompts/nodes/`. The orchestrator is `MASTER_PROMPT.md`.
- Execute one node at a time in graph order. Follow the node's routing on its exit code.
- `human` nodes → AskUserQuestion. `verifier` nodes → run the node's command, then check
  postconditions; use the `spec-verifier` subagent for an independent pass.
- Respect each node's scope lock and budget. Out-of-scope needs → exit `needs_input`.
- Log every node exit as one JSON line in `tasks/trace.jsonl`.
- Back-edges are bounded loops; when a loop's `max_iterations` is exhausted, route to `blocked`.
- Terminal nodes write `<hef_state>` in `TRUSTLINE.hef.md` and append to `tasks/lessons.md`.
- After changing `spec/registry.yaml` or `tools/gen_graph.py`: `python3 tools/gen_graph.py`,
  `python3 tools/graph_lint.py`, `python3 tools/sync_hef.py`, `python3 tools/render_node_prompts.py`.

## Commands (available after M1)
| Command | What it does |
| --- | --- |
| `make setup` | Install toolchains and git hooks |
| `make keys` | Generate local dev keys (ledger signing, bundle signing, pepper) into `.local/` (git-ignored) |
| `make db` | Start Postgres and apply migrations |
| `make seed` | Load synthetic personas and fixtures |
| `make db-test` | Run `db/tests/disclosure_test.sql` against a fresh database |
| `make run` | Start api, mock-agencies and web via docker compose |
| `make test` | All Rust and web tests |
| `make verify` | Every quality gate: fmt, clippy, tests, deny, gitleaks, cedar, OpenAPI, web |
| `make demo` | Fresh database, seed, run — ready for docs/10-demo-script.md |

## Do not
- Do not build any endpoint, query, report or export that combines a person's data across ministries (HL1).
- Do not let any police role read health data, under any purpose (HL2).
- Do not store agency master records; adapters fetch at query time (HL3).
- Do not write raw identifiers to the ledger or logs (HL4).
- Do not make software suspend or disqualify a driver without a recorded officer decision (HL5).
- Do not use real personal data; synthetic only, with SYNTHETIC banners (HL6).
- Do not implement facial recognition, appearance profiling, risk scores or plate-recognition ticketing (HL7).
- Do not UPDATE or DELETE ledger rows (HL8).
- Do not commit secrets or disable TLS verification (HL9).
- Do not model revenue on fines (HL10).
- Do not treat rules marked `verified: false` as law; keep the pending-legal-verification banner (HL11).
- Do not deploy this build anywhere with real data (HL12).
- Do not read or count access entries for anything citizen-facing except through
  `citizen.visible_access_events`; never reveal a withheld entry, a deferral or a protected
  officer's identity through any citizen-facing channel (HL13).
- Do not allow a deferral or protected-identity designation without second-person approval, a time
  limit and oversight visibility; never let a deferral hide an entry the subject could already see (HL14).
- Do not edit the contract files (spec/, graphs/, prompts/, policies/, rules/, db/schema.sql,
  api/openapi.yaml) inside a build node; propose changes through `needs_input`.

## Current state
- Specification pack complete (2 Nov 2026), iteration 2: leak-proof disclosure deferrals approved
  by Kelvin and specified (ADR 0011). No code yet.
- Next node: `plan_build`. Start with MASTER_PROMPT.md.
