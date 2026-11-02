# Node 19 — `m4_demerit` (prompt)

Paste this whole block into Claude Code when the graph reaches this node, or let the
orchestrator in MASTER_PROMPT.md load it. Replace {run_id} and {attempt}.

```xml
<node_prompt graph="trustline_build" node="m4_demerit" run="{run_id}" attempt="{attempt}">
<role>Senior Rust and TypeScript engineer building a security-critical government system to the TRUSTLINE spec</role>
<objective>Implement the demerit engine, proposed actions and Licensing Authority decisions.</objective>
<implements>
  <item id="R8">[must] The system shall record demerit points on conviction from the versioned schedule in rules/demerit-schedule.yaml, evaluate the section 179 thresholds, and produce proposed licence actions that take effect only after an authorised Licensing Authority officer records a decision.</item>
  <item id="T4.4">Implement trustline-demerit as pure functions over conviction history and the versioned schedule, covering recording, appeals, the same-incident rule, expiry and all thresholds.</item>
  <item id="T4.5">Implement proposed actions, the Licensing Authority decision endpoints, licence-action effects on the roadside card and appeal deadlines.</item>
  <item id="T4.6">Write table tests mirroring every section 179 subsection and property-based tests for the demerit engine.</item>
  <item id="AC8">Paying a ticket for an offence mapped to Schedule 2 paragraph 2(e) (exceeding the speed limit by 20 mph or more) records the number of points set in rules/demerit-schedule.yaml, dated the conviction date, with the ticket linked.</item>
  <item id="AC9">Demerit engine tests pass for every row of the section 179 test table in docs/08: recording on conviction, appeal suspension and reinstatement, same-incident rule, 3-year expiry, 11–13 notice, 14–17 interview, ≥10 in 1 year 6-month suspension, ≥18 over 1–2 years 1-year suspension, clearance after a suspension of 3+ months, and concurrent suspensions.</item>
  <item id="AC10">No licence action becomes effective without a decision event by a licensing_officer; after confirmation, the roadside card for that driver shows SUSPENDED within 60 s.</item>
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
  - rules/demerit-schedule.yaml
  - docs/08-verification-plan.md
  - docs/07-privacy-and-legal-basis.md
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
  - Scope lock: touch only crates/demerit/, crates/api/src/routes/licensing.rs plus their tests and route wiring in crates/api/src/main.rs and crates/api/src/routes/mod.rs. Anything else needed goes in <exit code="needs_input">.
  - Do no work that belongs to another node. Treat spec/, graphs/, prompts/, policies/trustline.cedar, policies/trustline.cedarschema, rules/, db/schema.sql and api/openapi.yaml as the contract: if one of them is wrong, exit needs_input with the proposed change instead of editing it.
</constraints>
<contract>
  <outputs>{"summary": "string", "files_touched": "list"}</outputs>
  <preconditions>
    - Plan approved (tasks/todo.md exists and approve_plan exited approved)
    - m4_tickets exited success
  </preconditions>
  <postconditions>Self-check each before exiting success:
    - [ ] The engine is pure (no I/O) and versioned by the rules file hash
    - [ ] Every row of the docs/08 section 179 table has a passing test
    - [ ] No licence action is effective without a decision event
  </postconditions>
</contract>
<budget>At most 60,000 output tokens and 120 tool calls; exit budget_exceeded if the objective cannot be met within them.</budget>
<feedback>{carried findings, on retries only}</feedback>
<exit_protocol>End with exactly one <exit code="..."><outputs>{JSON}</outputs></exit> where code is one of: success, fail, needs_input, budget_exceeded, timeout, blocked. Append one line to tasks/trace.jsonl (node, attempt, exit, files_touched, tokens if known). Do no work outside this node's objective.</exit_protocol>
</node_prompt>
```

**Routing after this node**

- `success` → `verify_m4`
- `needs_input` → `blocked`
- `blocked` → `blocked`
