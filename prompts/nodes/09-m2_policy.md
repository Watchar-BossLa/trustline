# Node 09 — `m2_policy` (prompt)

Paste this whole block into Claude Code when the graph reaches this node, or let the
orchestrator in MASTER_PROMPT.md load it. Replace {run_id} and {attempt}.

```xml
<node_prompt graph="trustline_build" node="m2_policy" run="{run_id}" attempt="{attempt}">
<role>Senior Rust and TypeScript engineer building a security-critical government system to the TRUSTLINE spec</role>
<objective>Implement the Cedar policy engine and the exhaustive permission matrix test.</objective>
<implements>
  <item id="R2">[must] The system shall require every data request to carry an authenticated actor, an attested device (for officers), a reason code from rules/reason-codes.yaml and, where that reason code requires it, a valid case, incident or warrant reference; any request failing a check shall be denied by default.</item>
  <item id="R3">[must] The system shall decide access per field group with the Cedar policies in policies/trustline.cedar, including forbid rules that make health data unreachable by every police role under every purpose.</item>
  <item id="T2.1">Implement trustline-policy to load and validate policies/trustline.cedar against policies/trustline.cedarschema at startup and expose decide() and policy_version().</item>
  <item id="T2.2">Generate the exhaustive role × reason × field-group × context matrix test and assert it against the expected-permissions table in docs/05-access-policy.md.</item>
  <item id="AC3">The exhaustive policy matrix (every role × every reason code × every field group, with each boolean context flag both ways) contains no permit of a health-domain field group to any police role, and matches the expected-permissions table in docs/05.</item>
  <item id="AC4">An investigator query for criminal_record without a case reference is denied; with a valid open case reference it is allowed and the ledger entry carries the case reference.</item>
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
  - policies/
  - docs/05-access-policy.md
  - rules/reason-codes.yaml
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
  - Scope lock: touch only crates/policy/, policies/tests/ plus their tests and route wiring in crates/api/src/main.rs and crates/api/src/routes/mod.rs. Anything else needed goes in <exit code="needs_input">.
  - Do no work that belongs to another node. Treat spec/, graphs/, prompts/, policies/trustline.cedar, policies/trustline.cedarschema, rules/, db/schema.sql and api/openapi.yaml as the contract: if one of them is wrong, exit needs_input with the proposed change instead of editing it.
</constraints>
<contract>
  <outputs>{"summary": "string", "files_touched": "list"}</outputs>
  <preconditions>
    - Plan approved (tasks/todo.md exists and approve_plan exited approved)
    - verify_m1 exited success
  </preconditions>
  <postconditions>Self-check each before exiting success:
    - [ ] Policies validate against the schema at startup or the process exits
    - [ ] Matrix test covers every role, reason code, field group and context flag combination
    - [ ] Matrix equals the expected-permissions table in docs/05
  </postconditions>
</contract>
<budget>At most 60,000 output tokens and 120 tool calls; exit budget_exceeded if the objective cannot be met within them.</budget>
<feedback>{carried findings, on retries only}</feedback>
<exit_protocol>End with exactly one <exit code="..."><outputs>{JSON}</outputs></exit> where code is one of: success, fail, needs_input, budget_exceeded, timeout, blocked. Append one line to tasks/trace.jsonl (node, attempt, exit, files_touched, tokens if known). Do no work outside this node's objective.</exit_protocol>
</node_prompt>
```

**Routing after this node**

- `success` → `m2_ledger`
- `needs_input` → `blocked`
- `blocked` → `blocked`
