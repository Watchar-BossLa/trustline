# Node 07 — `verify_m1` (verifier)

Paste this whole block into Claude Code when the graph reaches this node, or let the
orchestrator in MASTER_PROMPT.md load it. Replace {run_id} and {attempt}.

```xml
<node_prompt graph="trustline_build" node="verify_m1" run="{run_id}" attempt="{attempt}">
<role>Independent verification engineer; you check, you do not build</role>
<objective>Confirm the foundation builds, migrates and seeds cleanly.</objective>
<implements>
  <item id="V1.1">make verify passes on a clean clone.</item>
  <item id="V1.2">make db applies all migrations to an empty database; UPDATE or DELETE on ledger.access_event by the app role fails.</item>
  <item id="V1.3">make seed produces the personas and counts in docs/09; the same seed produces byte-identical fixtures.</item>
  <item id="R12">[must] The system shall authenticate officers per device (signed development tokens behind a DEV_AUTH flag in the demo build; WebAuthn passkeys with device attestation from the pilot), encrypt every network hop with TLS outside localhost, keep secrets out of the repository, store personal identifiers only as keyed hashes or envelope-encrypted values, and pass the security gates in docs/08-verification-plan.md.</item>
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
  - Do no work that belongs to another node. Treat spec/, graphs/, prompts/, policies/trustline.cedar, policies/trustline.cedarschema, rules/, db/schema.sql and api/openapi.yaml as the contract: if one of them is wrong, exit needs_input with the proposed change instead of editing it.
</constraints>
<contract>
  <outputs>{"report": "file", "failures": "list"}</outputs>
  <preconditions>
    - All build nodes of this milestone exited success
  </preconditions>
  <postconditions>Self-check each before exiting success:
    - [ ] V1.1 make verify passes on a clean clone
    - [ ] V1.2 migrations apply; ledger UPDATE/DELETE rejected
    - [ ] V1.3 seeding is deterministic
  </postconditions>
</contract>
<command>make verify && make db && make seed && cargo test -p trustline-api --test schema</command>
<budget>At most 8,000 output tokens and 40 tool calls; exit budget_exceeded if the objective cannot be met within them.</budget>
<feedback>{carried findings, on retries only}</feedback>
<exit_protocol>End with exactly one <exit code="..."><outputs>{JSON}</outputs></exit> where code is one of: success, fail, needs_input, budget_exceeded, timeout. Append one line to tasks/trace.jsonl (node, attempt, exit, files_touched, tokens if known). Do no work outside this node's objective.</exit_protocol>
</node_prompt>
```

**Routing after this node**

- `fail` → `fix_m1`
- `needs_input` → `blocked`
- `success` → `m2_policy`
