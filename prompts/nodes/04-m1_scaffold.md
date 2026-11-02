# Node 04 — `m1_scaffold` (prompt)

Paste this whole block into Claude Code when the graph reaches this node, or let the
orchestrator in MASTER_PROMPT.md load it. Replace {run_id} and {attempt}.

```xml
<node_prompt graph="trustline_build" node="m1_scaffold" run="{run_id}" attempt="{attempt}">
<role>Senior Rust and TypeScript engineer building a security-critical government system to the TRUSTLINE spec</role>
<objective>Create the Cargo workspace, compose stack, Makefile, CI and typed configuration with the DEV_AUTH guard.</objective>
<implements>
  <item id="R12">[must] The system shall authenticate officers per device (signed development tokens behind a DEV_AUTH flag in the demo build; WebAuthn passkeys with device attestation from the pilot), encrypt every network hop with TLS outside localhost, keep secrets out of the repository, store personal identifiers only as keyed hashes or envelope-encrypted values, and pass the security gates in docs/08-verification-plan.md.</item>
  <item id="T1.1">Create the Cargo workspace (edition 2024) with crates core, policy, ledger, broker, adapters, demerit, tickets, oversight, offline, api, cli and the services/mock-agencies binary, each compiling with a placeholder test.</item>
  <item id="T1.2">Add docker-compose.yml (Postgres 16, api, mock-agencies, web) and a Makefile with targets setup, keys, db, seed, run, test, verify and demo.</item>
  <item id="T1.3">Add GitHub Actions CI running fmt, clippy -D warnings, tests, cargo-deny, gitleaks, migration check, Cedar validation, OpenAPI lint and web lint, typecheck and tests.</item>
  <item id="T1.4">Add typed configuration (.env.example, no secrets), tracing with request ids, the problem+json error model from api/openapi.yaml, and the DEV_AUTH token issuer for synthetic personas that refuses to start when TRUSTLINE_ENV=production.</item>
</implements>
<inputs>
  <input name="plan" type="file" source="$node.plan_build.plan_path"/>
  <input name="feedback" type="list" source="carried on retry edges only"/>
</inputs>
<context mode="flat">Read only these before acting:
  - TRUSTLINE.hef.md — <hef_constraints>
  - TRUSTLINE.hef.md — <hef_architecture>
  - CLAUDE.md
  - tasks/lessons.md
  - docs/02-architecture.md
  - docs/adr/0006-demo-auth-and-pilot-auth.md
</context>
<constraints>
  - HL1: Never build an endpoint, query, report or export that returns a person's data combined across ministries.
  - HL2: Never allow a police role to read health data. Health content leaves the Ministry of Health adapter only as the opted-in emergency card to an EMS responder with an active incident.
  - HL3: Never store agency master records in TRUSTLINE's database; cache only what the offline-bundle spec allows.
  - HL4: Never write raw NIC, licence or plate numbers to the access ledger or application logs; use keyed hashes (HMAC-SHA-256 with a managed pepper).
  - HL5: Never let software alone suspend or disqualify a driver; every licence action needs a recorded decision by an authorised Licensing Authority officer.
  - HL6: Never use real personal data in development, tests or demos; synthetic data only, marked SYNTHETIC on every screen.
  - HL7: Never implement facial recognition, appearance-based profiling, predictive risk scores or automatic plate-recognition ticketing.
  - HL8: Never update or delete ledger rows; corrections are new entries.
  - HL9: Never commit secrets, keys or tokens, and never disable TLS verification.
  - HL10: Never model vendor revenue on fines collected.
  - HL11: Never treat values in rules/demerit-schedule.yaml, rules/offences.yaml or rules/retention.yaml as legally verified while verified is false; show the pending-legal-verification banner.
  - HL12: Never deploy this build with real data or to third-party hosting; production hosting is the Government of Saint Lucia data centre and is out of scope.
  - Scope lock: touch only Cargo.toml, crates/*/, services/mock-agencies/, docker-compose.yml, Makefile, .github/workflows/ci.yml, .env.example, crates/core/src/config.rs plus their tests and route wiring in crates/api/src/main.rs and crates/api/src/routes/mod.rs. Anything else needed goes in <exit code="needs_input">.
  - Do no work that belongs to another node. Treat spec/, graphs/, prompts/, policies/trustline.cedar, policies/trustline.cedarschema, rules/, db/schema.sql and api/openapi.yaml as the contract: if one of them is wrong, exit needs_input with the proposed change instead of editing it.
</constraints>
<contract>
  <outputs>{"summary": "string", "files_touched": "list"}</outputs>
  <preconditions>
    - Plan approved (tasks/todo.md exists and approve_plan exited approved)
  </preconditions>
  <postconditions>Self-check each before exiting success:
    - [ ] cargo build --workspace succeeds
    - [ ] make verify runs every gate listed in docs/08
    - [ ] DEV_AUTH with TRUSTLINE_ENV=production refuses to start (test)
    - [ ] .env.example contains no secret values
  </postconditions>
</contract>
<budget>At most 60,000 output tokens and 120 tool calls; exit budget_exceeded if the objective cannot be met within them.</budget>
<feedback>{carried findings, on retries only}</feedback>
<exit_protocol>End with exactly one <exit code="..."><outputs>{JSON}</outputs></exit> where code is one of: success, fail, needs_input, budget_exceeded, timeout, blocked. Append one line to tasks/trace.jsonl (node, attempt, exit, files_touched, tokens if known). Do no work outside this node's objective.</exit_protocol>
</node_prompt>
```

**Routing after this node**

- `success` → `m1_schema`
- `needs_input` → `blocked`
- `blocked` → `blocked`
