# Node 22 — `m5_citizen` (prompt)

Paste this whole block into Claude Code when the graph reaches this node, or let the
orchestrator in MASTER_PROMPT.md load it. Replace {run_id} and {attempt}.

```xml
<node_prompt graph="trustline_build" node="m5_citizen" run="{run_id}" attempt="{attempt}">
<role>Senior Rust and TypeScript engineer building a security-critical government system to the TRUSTLINE spec</role>
<objective>Implement the citizen record, access log, deferrals, disputes and emergency card.</objective>
<implements>
  <item id="R6">[must] The system shall show each signed-in citizen every access to their data, with time, agency, officer badge number, reason code and case reference, except entries under an approved, time-limited disclosure deferral, which shall appear automatically when the deferral expires.</item>
  <item id="R15">[should] The system shall let an EMS responder with an active incident open the emergency card of a citizen who has opted in, record each opening in that citizen's access log, and leave the card's content at the Ministry of Health adapter.</item>
  <item id="R16">[should] The system shall let citizens view their own licence, vehicle, ticket, points and court-date record, pay (simulated) or contest a ticket, manage emergency-card consent, and file a dispute against any access-log entry.</item>
  <item id="T5.1">Implement the citizen API (/v1/me/record, /v1/me/access-log, disputes, ticket payment) keyed by the citizen's subject hash.</item>
  <item id="T5.2">Implement disclosure deferrals with supervisor approval, a configured maximum duration, oversight visibility and automatic release.</item>
  <item id="T5.3">Implement emergency-card consent and EMS access with the incident check, the Ministry of Health adapter call and the citizen log entry.</item>
  <item id="AC7">Persona S8 sees each access to their data within 60 s, with time, agency, badge, reason code and case reference; an entry under an approved deferral is hidden until expiry and then appears; creating a deferral without supervisor approval fails, and every deferral is visible in oversight.</item>
  <item id="AC16">EMS-601 with an active incident opens persona S9's emergency card; the opening appears in S9's access log; the same request by any police role is denied.</item>
  <item id="AC20">Persona S2 sees their own tickets, points, licence and vehicle status; filing a dispute creates an item in the oversight queue linked to the ledger entry.</item>
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
  - api/openapi.yaml
  - docs/05-access-policy.md
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
  - Scope lock: touch only crates/api/src/routes/me.rs, crates/api/src/routes/ems.rs, crates/api/src/routes/deferrals.rs plus their tests and route wiring in crates/api/src/main.rs and crates/api/src/routes/mod.rs. Anything else needed goes in <exit code="needs_input">.
  - Do no work that belongs to another node. Treat spec/, graphs/, prompts/, policies/trustline.cedar, policies/trustline.cedarschema, rules/, db/schema.sql and api/openapi.yaml as the contract: if one of them is wrong, exit needs_input with the proposed change instead of editing it.
</constraints>
<contract>
  <outputs>{"summary": "string", "files_touched": "list"}</outputs>
  <preconditions>
    - Plan approved (tasks/todo.md exists and approve_plan exited approved)
    - verify_m4 exited success
  </preconditions>
  <postconditions>Self-check each before exiting success:
    - [ ] Citizen endpoints only ever resolve the caller's own subject hash
    - [ ] Deferrals need supervisor approval, cap at the configured maximum and release automatically
    - [ ] EMS access is denied without an active incident or consent
  </postconditions>
</contract>
<budget>At most 60,000 output tokens and 120 tool calls; exit budget_exceeded if the objective cannot be met within them.</budget>
<feedback>{carried findings, on retries only}</feedback>
<exit_protocol>End with exactly one <exit code="..."><outputs>{JSON}</outputs></exit> where code is one of: success, fail, needs_input, budget_exceeded, timeout, blocked. Append one line to tasks/trace.jsonl (node, attempt, exit, files_touched, tokens if known). Do no work outside this node's objective.</exit_protocol>
</node_prompt>
```

**Routing after this node**

- `success` → `m5_oversight`
- `needs_input` → `blocked`
- `blocked` → `blocked`
