# Node 16 — `verify_m3` (verifier)

Paste this whole block into Claude Code when the graph reaches this node, or let the
orchestrator in MASTER_PROMPT.md load it. Replace {run_id} and {attempt}.

```xml
<node_prompt graph="trustline_build" node="verify_m3" run="{run_id}" attempt="{attempt}">
<role>Independent verification engineer; you check, you do not build</role>
<objective>Confirm the roadside path end to end.</objective>
<implements>
  <item id="V3.1">Roadside integration tests for personas S1 to S5 return the expected cards; p95 under 2 s over 200 checks.</item>
  <item id="V3.2">With any mock agency stopped, its fields show UNKNOWN and the card still returns.</item>
  <item id="V3.3">Offline bundle tamper and expiry tests pass; rate-limit test returns 429 and is logged.</item>
  <item id="AC1">Given persona S2 (suspended licence), when OFF-101 posts a roadside check with reason TS, the response contains exactly the TS field groups listed in docs/05 and licence.status = SUSPENDED; p95 latency over 200 checks in compose is under 2 s.</item>
  <item id="AC2">A roadside check without a reason code, with an unknown reason code, or from an unattested device returns 403 problem+json and writes a ledger entry with decision deny.</item>
  <item id="AC11">A stolen-vehicle or warrant match is returned as UNCONFIRMED_MATCH; only a dispatcher decision changes it to CONFIRMED or CLEARED; the match and the decision are separate ledger entries.</item>
  <item id="AC13">A contract test over api/openapi.yaml confirms no response schema combines more than one ministry domain outside the purpose-bound status card and investigation result; exceeding the per-officer lookup limit returns 429 and is logged.</item>
  <item id="AC15">A freshly issued offline bundle verifies; a bundle with any byte altered, signed by an unknown key, or past its expiry is rejected; synced offline checks create ledger entries flagged offline = true.</item>
  <item id="AC19">A schema test confirms no table holds agency master records; with a mock agency stopped, the status card returns its fields as UNKNOWN with source status timeout or error, never stale data.</item>
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
    - [ ] V3.1 personas S1–S5 cards correct; p95 under 2 s
    - [ ] V3.2 agency outage yields UNKNOWN
    - [ ] V3.3 bundle and rate-limit tests pass
  </postconditions>
</contract>
<command>cargo test --workspace && make loadtest-smoke</command>
<budget>At most 8,000 output tokens and 40 tool calls; exit budget_exceeded if the objective cannot be met within them.</budget>
<feedback>{carried findings, on retries only}</feedback>
<exit_protocol>End with exactly one <exit code="..."><outputs>{JSON}</outputs></exit> where code is one of: success, fail, needs_input, budget_exceeded, timeout. Append one line to tasks/trace.jsonl (node, attempt, exit, files_touched, tokens if known). Do no work outside this node's objective.</exit_protocol>
</node_prompt>
```

**Routing after this node**

- `fail` → `fix_m3`
- `needs_input` → `blocked`
- `success` → `m4_tickets`
