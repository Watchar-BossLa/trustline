# Node 14 — `m3_broker` (prompt)

Paste this whole block into Claude Code when the graph reaches this node, or let the
orchestrator in MASTER_PROMPT.md load it. Replace {run_id} and {attempt}.

```xml
<node_prompt graph="trustline_build" node="m3_broker" run="{run_id}" attempt="{attempt}">
<role>Senior Rust and TypeScript engineer building a security-critical government system to the TRUSTLINE spec</role>
<objective>Implement the broker, status card, hit confirmation, investigation queries and rate limits.</objective>
<implements>
  <item id="R1">[must] The system shall return a roadside status card for a NIC number, driver's licence number or vehicle plate, containing only the field groups the policy engine permits for the stated purpose, within 2 seconds at the 95th percentile on the reference environment (docker compose on a 4-core, 8 GB machine).</item>
  <item id="R9">[must] The system shall mark every warrant or stolen-vehicle match as UNCONFIRMED until a dispatcher confirms or clears it against the source agency, and shall log both the match and the decision.</item>
  <item id="R11">[must] The system shall expose no endpoint, query, report or export that returns a person's data combined across ministries, no bulk export, and shall rate-limit identifier lookups per officer and per device.</item>
  <item id="T3.3">Implement trustline-broker to resolve identifiers to subject keys, ask the policy engine for permitted field groups, fan out only permitted calls in parallel, assemble the status card and mark failed sources UNKNOWN.</item>
  <item id="T3.4">Implement hit confirmation and the endpoints POST /v1/roadside/checks, POST /v1/hits/{hitId}/decision and POST /v1/investigations/queries.</item>
  <item id="T3.5">Add per-officer and per-device rate limits and a contract test proving no endpoint returns a cross-domain profile.</item>
  <item id="AC1">Given persona S2 (suspended licence), when OFF-101 posts a roadside check with reason TS, the response contains exactly the TS field groups listed in docs/05 and licence.status = SUSPENDED; p95 latency over 200 checks in compose is under 2 s.</item>
  <item id="AC2">A roadside check without a reason code, with an unknown reason code, or from an unattested device returns 403 problem+json and writes a ledger entry with decision deny.</item>
  <item id="AC11">A stolen-vehicle or warrant match is returned as UNCONFIRMED_MATCH; only a dispatcher decision changes it to CONFIRMED or CLEARED; the match and the decision are separate ledger entries.</item>
  <item id="AC13">A contract test over api/openapi.yaml confirms no response schema combines more than one ministry domain outside the purpose-bound status card and investigation result; exceeding the per-officer lookup limit returns 429 and is logged.</item>
  <item id="AC19">A schema test confirms no table holds agency master records; with a mock agency stopped, the status card returns its fields as UNKNOWN with source status timeout or error, never stale data.</item>
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
  - docs/04-api.md
  - docs/05-access-policy.md
  - rules/field-groups.yaml
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
  - Scope lock: touch only crates/broker/, crates/api/src/routes/roadside.rs, crates/api/src/routes/hits.rs, crates/api/src/routes/investigations.rs plus their tests and route wiring in crates/api/src/main.rs and crates/api/src/routes/mod.rs. Anything else needed goes in <exit code="needs_input">.
  - Do no work that belongs to another node. Treat spec/, graphs/, prompts/, policies/trustline.cedar, policies/trustline.cedarschema, rules/, db/schema.sql and api/openapi.yaml as the contract: if one of them is wrong, exit needs_input with the proposed change instead of editing it.
</constraints>
<contract>
  <outputs>{"summary": "string", "files_touched": "list"}</outputs>
  <preconditions>
    - Plan approved (tasks/todo.md exists and approve_plan exited approved)
    - m3_agencies exited success
  </preconditions>
  <postconditions>Self-check each before exiting success:
    - [ ] Only policy-permitted adapter calls are made (test asserts the mock received no other call)
    - [ ] A failed source yields UNKNOWN fields with source status
    - [ ] Rate limit returns 429 and writes a ledger entry
    - [ ] Responses validate against api/openapi.yaml
  </postconditions>
</contract>
<budget>At most 60,000 output tokens and 120 tool calls; exit budget_exceeded if the objective cannot be met within them.</budget>
<feedback>{carried findings, on retries only}</feedback>
<exit_protocol>End with exactly one <exit code="..."><outputs>{JSON}</outputs></exit> where code is one of: success, fail, needs_input, budget_exceeded, timeout, blocked. Append one line to tasks/trace.jsonl (node, attempt, exit, files_touched, tokens if known). Do no work outside this node's objective.</exit_protocol>
</node_prompt>
```

**Routing after this node**

- `success` → `m3_offline`
- `needs_input` → `blocked`
- `blocked` → `blocked`
