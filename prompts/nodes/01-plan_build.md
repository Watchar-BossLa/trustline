# Node 01 — `plan_build` (prompt)

Paste this whole block into Claude Code when the graph reaches this node, or let the
orchestrator in MASTER_PROMPT.md load it. Replace {run_id} and {attempt}.

```xml
<node_prompt graph="trustline_build" node="plan_build" run="{run_id}" attempt="{attempt}">
<role>Principal engineer planning a security-critical government system build</role>
<objective>Produce an implementation plan for milestones M1 to M7 in tasks/todo.md that covers every must requirement and acceptance criterion, respects every hard limit, and names the files each task touches.</objective>
<implements>
  <item id="M1">Milestone Foundation: A compiling Rust workspace, database, CI, configuration and synthetic data that every later milestone builds on.</item>
  <item id="M2">Milestone Policy and ledger: Every request is decided by Cedar policy and recorded in a tamper-evident ledger.</item>
  <item id="M3">Milestone Agencies, broker and roadside check: A purpose-bound roadside check that fetches only permitted fields from mock agencies, with hit confirmation, rate limits and offline bundles.</item>
  <item id="M4">Milestone Tickets and demerit points: Tickets flow to payment or court, convictions record points, and section 179 and 107 actions are proposed for human decision.</item>
  <item id="M5">Milestone Citizen record and oversight: Citizens see their record and every access to it; oversight sees anomalies, deferrals and monthly reports.</item>
  <item id="M6">Milestone Web applications: Usable screens for every role, ready for the pitch demo.</item>
  <item id="M7">Milestone Hardening and demo readiness: Security gates green, threat model addressed, demo reproducible from a fresh clone.</item>
</implements>
<inputs>
  <input name="spec" type="file" source="$graph.input.hef"/>
  <input name="registry" type="file" source="$graph.input.registry"/>
  <input name="feedback" type="list" source="carried on retry edges only"/>
</inputs>
<context mode="flat">Read only these before acting:
  - TRUSTLINE.hef.md (all sections)
  - spec/registry.yaml
  - docs/01-product-brief.md
  - docs/02-architecture.md
  - docs/adr/
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
  <outputs>{"plan_path": "file", "open_questions": "list"}</outputs>
  <preconditions>
    - TRUSTLINE.hef.md, spec/registry.yaml and every file under docs/ have been read
  </preconditions>
  <postconditions>Self-check each before exiting success:
    - [ ] tasks/todo.md lists every task T1.1 to T7.5 as a checkbox with the files it touches
    - [ ] Every must requirement and every acceptance criterion id appears against at least one task
    - [ ] The plan names the crates, binaries and app routes exactly as in docs/02-architecture.md
    - [ ] Open questions are listed separately; none is silently decided
  </postconditions>
</contract>
<budget>At most 20,000 output tokens and 60 tool calls; exit budget_exceeded if the objective cannot be met within them.</budget>
<feedback>{carried findings, on retries only}</feedback>
<exit_protocol>End with exactly one <exit code="..."><outputs>{JSON}</outputs></exit> where code is one of: success, fail, needs_input, budget_exceeded, timeout, blocked. Append one line to tasks/trace.jsonl (node, attempt, exit, files_touched, tokens if known). Do no work outside this node's objective.</exit_protocol>
</node_prompt>
```

**Routing after this node**

- `success` → `verify_plan`
- `needs_input` → `blocked`
