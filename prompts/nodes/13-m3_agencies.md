# Node 13 — `m3_agencies` (prompt)

Paste this whole block into Claude Code when the graph reaches this node, or let the
orchestrator in MASTER_PROMPT.md load it. Replace {run_id} and {attempt}.

```xml
<node_prompt graph="trustline_build" node="m3_agencies" run="{run_id}" attempt="{attempt}">
<role>Senior Rust and TypeScript engineer building a security-critical government system to the TRUSTLINE spec</role>
<objective>Build the mock agencies service and the X-Road-shaped adapters.</objective>
<implements>
  <item id="R4">[must] The system shall not store agency master records (licences, vehicles, criminal, court or health records); it shall fetch them at query time through adapter interfaces modelled on X-Road service calls, and shall persist only tickets, the demerit ledger, licence actions, access logs, alerts, consents and disputes.</item>
  <item id="T3.1">Build services/mock-agencies serving synthetic licensing, vehicle, police, courts, insurance, inspection, health-emergency and NAF-style OIDC endpoints per the adapter contracts in docs/02, with latency and failure injection.</item>
  <item id="T3.2">Implement trustline-adapters with one adapter per agency behind an AgencyAdapter trait, X-Road-shaped request headers and per-call timeouts.</item>
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
  - docs/adr/0002-xroad-exchange.md
  - docs/09-synthetic-data.md
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
  - Scope lock: touch only services/mock-agencies/, crates/adapters/ plus their tests and route wiring in crates/api/src/main.rs and crates/api/src/routes/mod.rs. Anything else needed goes in <exit code="needs_input">.
  - Do no work that belongs to another node. Treat spec/, graphs/, prompts/, policies/trustline.cedar, policies/trustline.cedarschema, rules/, db/schema.sql and api/openapi.yaml as the contract: if one of them is wrong, exit needs_input with the proposed change instead of editing it.
</constraints>
<contract>
  <outputs>{"summary": "string", "files_touched": "list"}</outputs>
  <preconditions>
    - Plan approved (tasks/todo.md exists and approve_plan exited approved)
    - verify_m2 exited success
  </preconditions>
  <postconditions>Self-check each before exiting success:
    - [ ] Each adapter has a contract test against the mock
    - [ ] Every adapter call sends client, service, message id, user id and purpose headers
    - [ ] Latency and failure injection are configurable per agency
  </postconditions>
</contract>
<budget>At most 60,000 output tokens and 120 tool calls; exit budget_exceeded if the objective cannot be met within them.</budget>
<feedback>{carried findings, on retries only}</feedback>
<exit_protocol>End with exactly one <exit code="..."><outputs>{JSON}</outputs></exit> where code is one of: success, fail, needs_input, budget_exceeded, timeout, blocked. Append one line to tasks/trace.jsonl (node, attempt, exit, files_touched, tokens if known). Do no work outside this node's objective.</exit_protocol>
</node_prompt>
```

**Routing after this node**

- `success` → `m3_broker`
- `needs_input` → `blocked`
- `blocked` → `blocked`
