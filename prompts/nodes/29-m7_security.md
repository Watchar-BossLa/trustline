# Node 29 — `m7_security` (prompt)

Paste this whole block into Claude Code when the graph reaches this node, or let the
orchestrator in MASTER_PROMPT.md load it. Replace {run_id} and {attempt}.

```xml
<node_prompt graph="trustline_build" node="m7_security" run="{run_id}" attempt="{attempt}">
<role>Security engineer; use the security-reviewer subagent for an independent pass</role>
<objective>Harden the build against the threat model and run every security gate.</objective>
<implements>
  <item id="R11">[must] The system shall expose no endpoint, query, report or export that returns a person's data combined across ministries, no bulk export, and shall rate-limit identifier lookups per officer and per device.</item>
  <item id="R12">[must] The system shall authenticate officers per device (signed development tokens behind a DEV_AUTH flag in the demo build; WebAuthn passkeys with device attestation from the pilot), encrypt every network hop with TLS outside localhost, keep secrets out of the repository, store personal identifiers only as keyed hashes or envelope-encrypted values, and pass the security gates in docs/08-verification-plan.md.</item>
  <item id="T7.1">Work through the threat-model checklist in docs/06, fix gaps, and record a security-reviewer subagent review.</item>
  <item id="T7.2">Run cargo-deny, gitleaks, the web dependency audit and an OWASP ZAP baseline scan against compose, and fix findings rated medium or above.</item>
  <item id="T7.3">Load test the roadside endpoint and record results in docs/08.</item>
  <item id="AC13">A contract test over api/openapi.yaml confirms no response schema combines more than one ministry domain outside the purpose-bound status card and investigation result; exceeding the per-officer lookup limit returns 429 and is logged.</item>
  <item id="AC18">cargo fmt, clippy (-D warnings), tests, cargo-deny, gitleaks, the web lint, typecheck and audit all pass in CI; no secret is present in the git history; DEV_AUTH cannot be enabled when TRUSTLINE_ENV=production.</item>
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
  - docs/06-security-threat-model.md
  - docs/08-verification-plan.md
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
  - Scope lock: touch only docs/06-security-threat-model.md, docs/08-verification-plan.md, deny.toml plus their tests and route wiring in crates/api/src/main.rs and crates/api/src/routes/mod.rs. Anything else needed goes in <exit code="needs_input">.
  - Do no work that belongs to another node. Treat spec/, graphs/, prompts/, policies/trustline.cedar, policies/trustline.cedarschema, rules/, db/schema.sql and api/openapi.yaml as the contract: if one of them is wrong, exit needs_input with the proposed change instead of editing it.
</constraints>
<contract>
  <outputs>{"summary": "string", "files_touched": "list"}</outputs>
  <preconditions>
    - Plan approved (tasks/todo.md exists and approve_plan exited approved)
    - verify_m6 exited success
  </preconditions>
  <postconditions>Self-check each before exiting success:
    - [ ] Each threat in docs/06 has status mitigated, accepted with reason, or deferred to pilot
    - [ ] No medium-or-higher finding from cargo-deny, gitleaks, npm audit or ZAP remains open
    - [ ] Load-test results are recorded in docs/08
  </postconditions>
</contract>
<budget>At most 60,000 output tokens and 120 tool calls; exit budget_exceeded if the objective cannot be met within them.</budget>
<feedback>{carried findings, on retries only}</feedback>
<exit_protocol>End with exactly one <exit code="..."><outputs>{JSON}</outputs></exit> where code is one of: success, fail, needs_input, budget_exceeded, timeout, blocked. Append one line to tasks/trace.jsonl (node, attempt, exit, files_touched, tokens if known). Do no work outside this node's objective.</exit_protocol>
</node_prompt>
```

**Routing after this node**

- `success` → `m7_demo`
- `needs_input` → `blocked`
- `blocked` → `blocked`
