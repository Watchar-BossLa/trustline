# TRUSTLINE — build pack

**TRUSTLINE** (working name) is a purpose-bound public-safety data exchange for the Government of
Saint Lucia. An officer's scan returns only what the law allows for that stop, fetched live from
the agency that holds it; every lookup is decided by written policy, recorded in a tamper-evident
ledger, and visible to the citizen concerned — except investigative lookups under an approved,
time-limited deferral, which stay undetectable until it ends. Police never see health data. Software proposes
licence suspensions; a Licensing Authority officer decides.

This repository is the **specification pack** for building TRUSTLINE with Claude Code. No
application code exists yet; Claude Code creates it by executing the build graph.

Status: ready to build · Version 1.0.0 · 2 Nov 2026 · Owner: Kelvin Wilson Antoine, Limah Innovations, Corp.
All data is synthetic. Legal values are unverified until counsel confirms them.

## Start the build
1. `git clone https://github.com/Watchar-BossLa/trustline.git && cd trustline`
2. `claude`
3. Paste **Prompt A** from [MASTER_PROMPT.md](MASTER_PROMPT.md). Claude Code plans first and asks
   you to approve before writing code.

## What is in the pack

| Path | What it is |
| --- | --- |
| [MASTER_PROMPT.md](MASTER_PROMPT.md) | The execution master prompt (start, resume, single node, spec change) |
| [CLAUDE.md](CLAUDE.md) | Workflow rules (Boris Cherny framework) and project conventions for Claude Code |
| [TRUSTLINE.hef.md](TRUSTLINE.hef.md) | Master specification in Harness Engineering Format: context, decisions, requirements, constraints, architecture, execution, verification, state |
| [spec/registry.yaml](spec/registry.yaml) | Canonical ids: 22 requirements, 24 acceptance criteria, 14 hard limits, 7 milestones, 37 tasks, 21 checks |
| [graphs/build.graph.yaml](graphs/build.graph.yaml) | Execution graph: 37 nodes, 10 bounded loops, verifier after every milestone |
| [prompts/nodes/](prompts/nodes/README.md) | One rendered task prompt per graph node |
| [docs/01-product-brief.md](docs/01-product-brief.md) | Users, scope, programme phases, success measures, open questions |
| [docs/02-architecture.md](docs/02-architecture.md) | Components, request lifecycle, adapters, ledger, offline bundles |
| [docs/03-data-model.md](docs/03-data-model.md) | What TRUSTLINE stores and the database invariants |
| [docs/04-api.md](docs/04-api.md) | API conventions and examples |
| [docs/05-access-policy.md](docs/05-access-policy.md) | Who sees what, guardrails, policy change process |
| [docs/06-security-threat-model.md](docs/06-security-threat-model.md) | 27 threats with controls and proofs |
| [docs/07-privacy-and-legal-basis.md](docs/07-privacy-and-legal-basis.md) | Legal landscape, processing register, DPIA questions (not legal advice) |
| [docs/08-verification-plan.md](docs/08-verification-plan.md) | Quality gates, AC-to-test map, section 179/107 test table |
| [docs/09-synthetic-data.md](docs/09-synthetic-data.md) | Personas S1–S10, officers, volumes |
| [docs/10-demo-script.md](docs/10-demo-script.md) | Eight-minute pitch demo |
| [docs/adr/](docs/adr/README.md) | Eleven architecture decision records (0011: leak-proof disclosure deferrals) |
| [db/schema.sql](db/schema.sql) | Canonical PostgreSQL 16 schema, including the citizen access-log function |
| [db/tests/disclosure_test.sql](db/tests/disclosure_test.sql) | 25 database scenarios proving withheld lookups cannot be detected and deferrals stay accountable |
| [api/openapi.yaml](api/openapi.yaml) | OpenAPI 3.1 contract (37 operations) |
| [policies/](policies/) | Cedar schema and policy; hand-written intended permissions |
| [rules/](rules/) | Reason codes, field groups, demerit schedule, offences, anomaly rules, retention, disclosure control |
| [tools/](tools/) | Graph generator and linter, node-prompt renderer, HEF sync, policy matrix |
| [.claude/](.claude/) | Subagents (security-reviewer, policy-auditor, spec-verifier) and commands (/next-node, /verify, /status) |
| [demo/trustline-pitch-demo.html](demo/trustline-pitch-demo.html) | Static, clickable pitch demo (synthetic data, browser-only). Separate from the Claude Code build; open the file in a browser |

## Checks already run on this pack (2 Nov 2026)

| Check | Result |
| --- | --- |
| `db/schema.sql` loaded into PostgreSQL 16 | Passed; append-only and human-decision triggers tested |
| `cedar validate` (Cedar CLI 4.14) | Passed, no warnings |
| `tools/policy_matrix.py` — 184,536 decisions (field groups and operations) vs intended permissions | Matches; mutation test caught; tightened three oversight permits it flagged |
| `db/tests/disclosure_test.sql` — 25 disclosure scenarios | All passed, including suspect-vs-control indistinguishability |
| OpenAPI 3.1 validation | Passed |
| `tools/graph_lint.py` | OK — structure, budgets, traceability, context files |

## Things to know before the pilot
- **Legal values are unverified.** Schedule 2 demerit points were read from a garbled online copy;
  fixed penalties could not be read online. Both must be confirmed by Saint Lucian counsel
  (`verified: false` in `rules/`; the UI shows a banner).
- **The Data Protection Commissioner provisions** (Act 11 of 2011, sections 5–31) were not in the
  2023 commencement list. The pilot needs working oversight.
- **This build is a demo** on mocks and synthetic data. Real integrations, X-Road, WebAuthn,
  HSM keys, a penetration test and an external code review come before any pilot.

## Keeping the pack consistent
Edit `spec/registry.yaml` first, then:
```bash
python3 tools/gen_graph.py           # regenerate graphs/build.graph.yaml (after editing tools/gen_graph.py)
python3 tools/graph_lint.py          # graph rules, budgets, traceability
python3 tools/sync_hef.py            # regenerate HEF sections 3, 6, 7
python3 tools/render_node_prompts.py # regenerate prompts/nodes/
python3 tools/policy_matrix.py       # after any policy change (pip install cedarpy pyyaml)
```

## Open questions
Q1 first officials to meet · Q2 partner with the RSLPF system's developer · Q3 integrator for
World Bank-funded bids · Q4 final name · Q5 who funds Phase 0 · Q7 digital licence on PWEV or the
government wallet. (Q6, disclosure deferrals, approved 2 Nov 2026 — see ADR 0011.) Details: docs/01-product-brief.md.
