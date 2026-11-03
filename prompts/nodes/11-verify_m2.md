# Node 11 — `verify_m2` (verifier)

Paste this whole block into Claude Code when the graph reaches this node, or let the
orchestrator in MASTER_PROMPT.md load it. Replace {run_id} and {attempt}.

```xml
<node_prompt graph="trustline_build" node="verify_m2" run="{run_id}" attempt="{attempt}">
<role>Independent verification engineer; you check, you do not build</role>
<objective>Confirm policy decisions and ledger integrity.</objective>
<implements>
  <item id="V2.1">Policy matrix test passes; any permit of a health field group to a police role fails the build.</item>
  <item id="V2.2">Ledger tamper tests pass for modify, delete and reorder.</item>
  <item id="V2.3">Integration tests show one ledger entry per ledger-scoped request.</item>
  <item id="AC3">The exhaustive policy matrix (every role × every reason code × every field group, with each boolean context flag both ways) contains no permit of a health-domain field group to any police role, and matches the expected-permissions table in docs/05.</item>
  <item id="AC4">An investigator query for criminal_record without a case reference is denied; with a valid open case reference it is allowed and the ledger entry carries the case reference.</item>
  <item id="AC5">`trustline-cli ledger verify` passes on an untouched ledger and, after any single entry is modified, deleted or reordered (via superuser in a test), fails and names the first bad sequence number; UPDATE and DELETE by the application role are rejected.</item>
  <item id="AC6">In the end-to-end suite, the number of ledger entries equals the number of ledger-scoped API requests (x-ledger: true) plus the number of synced offline checks (x-ledger: per_item), across allow, partial, deny, error and rate_limited.</item>
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
    - [ ] V2.1 policy matrix passes; health isolation holds
    - [ ] V2.2 tamper tests pass
    - [ ] V2.3 one entry per ledger-scoped request
  </postconditions>
</contract>
<command>cargo test -p trustline-policy -p trustline-ledger && cargo test -p trustline-api --test ledger_coverage</command>
<budget>At most 8,000 output tokens and 40 tool calls; exit budget_exceeded if the objective cannot be met within them.</budget>
<feedback>{carried findings, on retries only}</feedback>
<exit_protocol>End with exactly one <exit code="..."><outputs>{JSON}</outputs></exit> where code is one of: success, fail, needs_input, budget_exceeded, timeout. Append one line to tasks/trace.jsonl (node, attempt, exit, files_touched, tokens if known). Do no work outside this node's objective.</exit_protocol>
</node_prompt>
```

**Routing after this node**

- `fail` → `fix_m2`
- `needs_input` → `blocked`
- `success` → `m3_agencies`
