# Node 20 — `verify_m4` (verifier)

Paste this whole block into Claude Code when the graph reaches this node, or let the
orchestrator in MASTER_PROMPT.md load it. Replace {run_id} and {attempt}.

```xml
<node_prompt graph="trustline_build" node="verify_m4" run="{run_id}" attempt="{attempt}">
<role>Independent verification engineer; you check, you do not build</role>
<objective>Confirm tickets, points and licence actions.</objective>
<implements>
  <item id="V4.1">Demerit tests cover every row of the docs/08 section 179 table.</item>
  <item id="V4.2">Persona S6 flow passes end to end, ticket to SUSPENDED card after officer confirmation.</item>
  <item id="V4.3">Persona S10 unpaid-fine flow passes.</item>
  <item id="AC8">Paying a ticket for an offence mapped to Schedule 2 paragraph 2(e) (exceeding the speed limit by 20 mph or more) records the number of points set in rules/demerit-schedule.yaml, dated the conviction date, with the ticket linked.</item>
  <item id="AC9">Demerit engine tests pass for every row of the section 179 test table in docs/08: recording on conviction, appeal suspension and reinstatement, same-incident rule, 3-year expiry, 11–13 notice, 14–17 interview, ≥10 in 1 year 6-month suspension, ≥18 over 1–2 years 1-year suspension, clearance after a suspension of 3+ months, and concurrent suspensions.</item>
  <item id="AC10">No licence action becomes effective without a decision event by a licensing_officer; after confirmation, the roadside card for that driver shows SUSPENDED within 60 s.</item>
  <item id="AC14">For persona S10, a fine unpaid 30 days after proceedings end produces a pending disqualify_unpaid_fine proposed action; recording court-confirmed payment ends the disqualification.</item>
  <item id="AC21">A licensing_officer and the citizen concerned see the next court date for a referred ticket; a traffic officer at a stop sees only court_date_pending = true.</item>
</implements>
<inputs>
  <input name="plan" type="file" source="$node.plan_build.plan_path"/>
  <input name="feedback" type="list" source="carried on retry edges only"/>
</inputs>
<context mode="flat">Read only these before acting:
  - TRUSTLINE.hef.md — <hef_verification>
  - docs/08-verification-plan.md
  - tasks/lessons.md
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
  - Do no work that belongs to another node. Treat spec/, graphs/, prompts/, policies/trustline.cedar, policies/trustline.cedarschema, rules/, db/schema.sql and api/openapi.yaml as the contract: if one of them is wrong, exit needs_input with the proposed change instead of editing it.
</constraints>
<contract>
  <outputs>{"report": "file", "failures": "list"}</outputs>
  <preconditions>
    - All build nodes of this milestone exited success
  </preconditions>
  <postconditions>Self-check each before exiting success:
    - [ ] V4.1 section 179 table fully covered
    - [ ] V4.2 S6 flow passes
    - [ ] V4.3 S10 flow passes
  </postconditions>
</contract>
<command>cargo test -p trustline-demerit -p trustline-tickets && cargo test -p trustline-api --test flows</command>
<budget>At most 8,000 output tokens and 40 tool calls; exit budget_exceeded if the objective cannot be met within them.</budget>
<feedback>{carried findings, on retries only}</feedback>
<exit_protocol>End with exactly one <exit code="..."><outputs>{JSON}</outputs></exit> where code is one of: success, fail, needs_input, budget_exceeded, timeout. Append one line to tasks/trace.jsonl (node, attempt, exit, files_touched, tokens if known). Do no work outside this node's objective.</exit_protocol>
</node_prompt>
```

**Routing after this node**

- `fail` → `fix_m4`
- `needs_input` → `blocked`
- `success` → `m5_citizen`
