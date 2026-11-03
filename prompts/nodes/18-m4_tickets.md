# Node 18 — `m4_tickets` (prompt)

Paste this whole block into Claude Code when the graph reaches this node, or let the
orchestrator in MASTER_PROMPT.md load it. Replace {run_id} and {attempt}.

```xml
<node_prompt graph="trustline_build" node="m4_tickets" run="{run_id}" attempt="{attempt}">
<role>Senior Rust and TypeScript engineer building a security-critical government system to the TRUSTLINE spec</role>
<objective>Implement tickets, payments, court referral and outcomes, section 107 and the court timeline.</objective>
<implements>
  <item id="R7">[must] The system shall issue electronic tickets under the Motor Vehicles and Road Traffic (Ticketable Offences) Regulations, track payment and court referral, and expose ticket status to the court and Licensing Authority.</item>
  <item id="R13">[should] The system shall flag a driver whose court fine remains unpaid 30 days after all proceedings end, generate a section 107 disqualification notice for the Licensing Authority, and clear the disqualification when the Clerk of Court confirms payment.</item>
  <item id="R18">[should] The system shall show court dates and outcomes for driving matters to authorised roles and to the citizen concerned, read through the courts adapter.</item>
  <item id="T4.1">Implement ticket issuance from rules/offences.yaml with ticket numbering, encrypted identifiers and the ticket endpoints.</item>
  <item id="T4.2">Implement simulated online payment, court-confirmed payment, court referral and court outcome endpoints.</item>
  <item id="T4.3">Implement section 107 unpaid-fine detection and the court timeline endpoint for authorised roles.</item>
  <item id="AC14">For persona S10, a fine unpaid 30 days after proceedings end produces a pending disqualify_unpaid_fine proposed action; recording court-confirmed payment ends the disqualification.</item>
  <item id="AC21">A licensing_officer and the citizen concerned see the next court date for a referred ticket; a traffic officer at a stop sees only court_date_pending = true.</item>
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
  - rules/offences.yaml
  - api/openapi.yaml
  - docs/03-data-model.md
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
  - HL13: Never read or count a subject's access entries for anything citizen-facing except through citizen.visible_access_events, and never reveal a withheld entry, a deferral or a protected officer's identity through any citizen-facing channel.
  - HL14: Never allow a deferral or protected-identity designation without a second-person approval, a time limit and real-time oversight visibility; never let a deferral hide an entry the subject could already see.
  - Scope lock: touch only crates/tickets/, crates/api/src/routes/tickets.rs, crates/api/src/routes/court.rs plus their tests and route wiring in crates/api/src/main.rs and crates/api/src/routes/mod.rs. Anything else needed goes in <exit code="needs_input">.
  - Do no work that belongs to another node. Treat spec/, graphs/, prompts/, policies/trustline.cedar, policies/trustline.cedarschema, rules/, db/schema.sql and api/openapi.yaml as the contract: if one of them is wrong, exit needs_input with the proposed change instead of editing it.
</constraints>
<contract>
  <outputs>{"summary": "string", "files_touched": "list"}</outputs>
  <preconditions>
    - Plan approved (tasks/todo.md exists and approve_plan exited approved)
    - verify_m3 exited success
  </preconditions>
  <postconditions>Self-check each before exiting success:
    - [ ] Ticket identifiers are envelope-encrypted at rest
    - [ ] Court outcome and payment endpoints require the court_system service principal
    - [ ] Section 107 detection runs on schedule and is idempotent
  </postconditions>
</contract>
<budget>At most 60,000 output tokens and 120 tool calls; exit budget_exceeded if the objective cannot be met within them.</budget>
<feedback>{carried findings, on retries only}</feedback>
<exit_protocol>End with exactly one <exit code="..."><outputs>{JSON}</outputs></exit> where code is one of: success, fail, needs_input, budget_exceeded, timeout, blocked. Append one line to tasks/trace.jsonl (node, attempt, exit, files_touched, tokens if known). Do no work outside this node's objective.</exit_protocol>
</node_prompt>
```

**Routing after this node**

- `success` → `m4_demerit`
- `needs_input` → `blocked`
- `blocked` → `blocked`
