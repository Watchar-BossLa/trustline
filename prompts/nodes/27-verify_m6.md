# Node 27 — `verify_m6` (verifier)

Paste this whole block into Claude Code when the graph reaches this node, or let the
orchestrator in MASTER_PROMPT.md load it. Replace {run_id} and {attempt}.

```xml
<node_prompt graph="trustline_build" node="verify_m6" run="{run_id}" attempt="{attempt}">
<role>Independent verification engineer; you check, you do not build</role>
<objective>Confirm the screens, accessibility and performance.</objective>
<implements>
  <item id="V6.1">The Playwright demo-flow test passes.</item>
  <item id="V6.2">axe checks pass with no serious or critical violations on officer and citizen screens.</item>
  <item id="V6.3">The officer status card renders in under 3 s under 3G throttling.</item>
  <item id="AC17">From a fresh clone, `make demo` brings the system up with seeded data in under 10 minutes and the Playwright demo-flow test (docs/10 steps 1–8) passes.</item>
  <item id="AC22">Officer and citizen screens pass automated axe accessibility checks with no serious or critical violations, and the officer status card renders in under 3 s under Playwright 3G throttling.</item>
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
    - [ ] V6.1 Playwright demo flow passes
    - [ ] V6.2 axe checks pass
    - [ ] V6.3 status card under 3 s on 3G
  </postconditions>
</contract>
<command>pnpm -C apps/web lint && pnpm -C apps/web typecheck && pnpm -C apps/web test:e2e</command>
<budget>At most 8,000 output tokens and 40 tool calls; exit budget_exceeded if the objective cannot be met within them.</budget>
<feedback>{carried findings, on retries only}</feedback>
<exit_protocol>End with exactly one <exit code="..."><outputs>{JSON}</outputs></exit> where code is one of: success, fail, needs_input, budget_exceeded, timeout. Append one line to tasks/trace.jsonl (node, attempt, exit, files_touched, tokens if known). Do no work outside this node's objective.</exit_protocol>
</node_prompt>
```

**Routing after this node**

- `fail` → `fix_m6`
- `needs_input` → `blocked`
- `success` → `m7_security`
