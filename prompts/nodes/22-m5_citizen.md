# Node 22 — `m5_citizen` (prompt)

Paste this whole block into Claude Code when the graph reaches this node, or let the
orchestrator in MASTER_PROMPT.md load it. Replace {run_id} and {attempt}.

```xml
<node_prompt graph="trustline_build" node="m5_citizen" run="{run_id}" attempt="{attempt}">
<role>Senior Rust and TypeScript engineer building a security-critical government system to the TRUSTLINE spec</role>
<objective>Implement the citizen record, the access log with leak-proof disclosure control, deferrals, protected identities, disputes and the emergency card.</objective>
<implements>
  <item id="R6">[must] The system shall show each signed-in citizen every access to their data, with time, agency, officer badge and reason code, except entries withheld under rules/disclosure.yaml (a 72-hour provisional hold for investigative purposes, and approved, time-limited disclosure deferrals); a withheld entry shall appear automatically, with its original time, when its hold or deferral ends.</item>
  <item id="R15">[should] The system shall let an EMS responder with an active incident open the emergency card of a citizen who has opted in, record each opening in that citizen's access log, and leave the card's content at the Ministry of Health adapter.</item>
  <item id="R16">[should] The system shall let citizens view their own licence, vehicle, ticket, points and court-date record, pay (simulated) or contest a ticket, manage emergency-card consent, and file a dispute against any access-log entry.</item>
  <item id="R21">[must] The system shall make a withheld access entry undetectable by the subject and by every other person attached to it: citizen-facing access entries shall be read only through citizen.visible_access_events in db/schema.sql, which filters before ordering and paging; no citizen-facing response, error, count, notification or published report shall reveal a withheld entry, a deferral or its administration; investigative case references shall never be shown to the subject; and officers with an approved protected identity shall never have their badge or unit shown in any citizen-facing view or driver receipt.</item>
  <item id="R22">[must] The system shall keep every disclosure deferral accountable: case- or entry-scoped and tied to a case open at source; requested by an investigator and approved by a different supervisor; lapsing if not approved within 72 hours; at most 90 days per approval; renewable only while active and without a gap; beyond 365 days only with a recorded magistrate's order; releasable early by the case team or oversight; visible to oversight in real time with acknowledgement required; and recorded in the ledger as administrative entries. Protected-identity designations shall likewise be approved by a supervisor, visible to and acknowledged by oversight.</item>
  <item id="T5.1">Implement the citizen API (/v1/me/record, /v1/me/access-log, disputes, ticket payment) keyed by the citizen's subject hash.</item>
  <item id="T5.2">Implement disclosure control per rules/disclosure.yaml with citizen.visible_access_events as the only read path — provisional holds, case- and entry-scoped deferrals, approval, lapse, renewal, the 365-day magistrate threshold, early release, protected identities, administrative ledger entries — plus the API leak suite (AC23) and lifecycle tests (AC24).</item>
  <item id="T5.3">Implement emergency-card consent and EMS access with the incident check, the Ministry of Health adapter call and the citizen log entry.</item>
  <item id="AC7">Persona S8 sees each non-investigative access to their data within 60 s, with time, agency, badge and reason code; an INV lookup without a deferral appears after the 72-hour hold with its original time; entries covered by an approved deferral appear automatically when it ends, marked with deferred_until.</item>
  <item id="AC16">EMS-601 with an active incident opens persona S9's emergency card; the opening appears in S9's access log; the same request by any police role is denied.</item>
  <item id="AC20">Persona S2 sees their own tickets, points, licence and vehicle status; filing a dispute creates an item in the oversight queue linked to the ledger entry.</item>
  <item id="AC23">The database scenario suite db/tests/disclosure_test.sql passes (DF1-DF25), and the API leak suite passes for persona S8 against control persona S11: while a case deferral covers S8's investigative lookups, every citizen-facing response for S8 (access log at every page size from 1 to 25 with cursors and include_self both ways, My Record, dispute attempts against the withheld sequence numbers, and the public monthly report) equals S11's response apart from sequence numbers, request ids and generation times; a dispute against a withheld entry returns the same 404 as a nonexistent one; the vehicle co-owner sees nothing; and lookups by protected officer UC-311 never show a badge or unit to the citizen, before or after release.</item>
  <item id="AC24">Deferral lifecycle tests pass at API and database level: self-approval refused; an unapproved request lapses after 72 hours; approval over 90 days refused; renewal after expiry refused; retroactive coverage beyond the hold refused; a chain over 365 days refused without a magistrate order and accepted with one; early release by oversight works; every deferral and protected-identity designation is listed in the oversight console within 60 s; every deferral action writes a ledger entry with relation administrative.</item>
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
  - rules/disclosure.yaml
  - db/tests/disclosure_test.sql
  - docs/adr/0011-leak-proof-disclosure-deferrals.md
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
  - Scope lock: touch only crates/api/src/routes/me.rs, crates/api/src/routes/ems.rs, crates/api/src/routes/deferrals.rs, crates/api/src/routes/protected_identities.rs, crates/api/tests/disclosure_leak.rs, crates/api/tests/deferral_lifecycle.rs plus their tests and route wiring in crates/api/src/main.rs and crates/api/src/routes/mod.rs. Anything else needed goes in <exit code="needs_input">.
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
    - [ ] Every citizen-facing access-log read goes through citizen.visible_access_events; a test fails the build if any other query touches ledger.access_event_subject for a citizen route
    - [ ] The AC23 leak suite compares persona S8 with control persona S11 response by response and they match apart from sequence numbers, request ids and generation times
    - [ ] Disputes against withheld, foreign and nonexistent sequence numbers return byte-identical 404 bodies and headers
    - [ ] Deferral and designation actions write ledger entries with relation administrative
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
