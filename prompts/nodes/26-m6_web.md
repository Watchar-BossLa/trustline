# Node 26 — `m6_web` (prompt)

Paste this whole block into Claude Code when the graph reaches this node, or let the
orchestrator in MASTER_PROMPT.md load it. Replace {run_id} and {attempt}.

```xml
<node_prompt graph="trustline_build" node="m6_web" run="{run_id}" attempt="{attempt}">
<role>Senior Rust and TypeScript engineer building a security-critical government system to the TRUSTLINE spec</role>
<objective>Build the Next.js app with officer, dispatch, licensing, citizen, EMS and oversight screens and the Playwright demo flow.</objective>
<implements>
  <item id="R17">[must] The system shall provide web interfaces for officers (installable PWA with QR scan of synthetic demo cards and manual entry), dispatch, the Licensing Authority, citizens, EMS and oversight, usable at 360 px width, with SYNTHETIC and pending-legal-verification banners on every screen.</item>
  <item id="T6.1">Create the Next.js app (App Router, TypeScript strict, Tailwind) with route groups /officer, /dispatch, /licensing, /citizen, /ems and /oversight, and a persona switcher shown only when DEV_AUTH is on.</item>
  <item id="T6.2">Build the officer PWA with QR scan of synthetic demo cards, manual entry, reason-code picker, status card, ticket issue, offline indicator and driver receipt QR.</item>
  <item id="T6.3">Build the citizen portal with My Record, the access log (showing deferred_until on released entries and never any sign of a withheld one), disputes, emergency-card consent and simulated payment.</item>
  <item id="T6.4">Build the licensing console (proposed-action queue and decisions) and the dispatch console (hit decisions).</item>
  <item id="T6.5">Build the oversight console (alerts, deferrals with release, protected-identity designations, ledger status, monthly report) and the SYNTHETIC and pending-legal-verification banners on every screen.</item>
  <item id="AC17">From a fresh clone, `make demo` brings the system up with seeded data in under 10 minutes and the Playwright demo-flow test (docs/10 steps 1–8) passes.</item>
  <item id="AC22">Officer and citizen screens pass automated axe accessibility checks with no serious or critical violations, and the officer status card renders in under 3 s under Playwright 3G throttling.</item>
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
  - docs/10-demo-script.md
  - api/openapi.yaml
  - docs/04-api.md
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
  - Scope lock: touch only apps/web/ plus their tests and route wiring in crates/api/src/main.rs and crates/api/src/routes/mod.rs. Anything else needed goes in <exit code="needs_input">.
  - Do no work that belongs to another node. Treat spec/, graphs/, prompts/, policies/trustline.cedar, policies/trustline.cedarschema, rules/, db/schema.sql and api/openapi.yaml as the contract: if one of them is wrong, exit needs_input with the proposed change instead of editing it.
</constraints>
<contract>
  <outputs>{"summary": "string", "files_touched": "list"}</outputs>
  <preconditions>
    - Plan approved (tasks/todo.md exists and approve_plan exited approved)
    - verify_m5 exited success
  </preconditions>
  <postconditions>Self-check each before exiting success:
    - [ ] The web app calls only the API; it holds no business rules
    - [ ] Every screen shows the SYNTHETIC and pending-legal-verification banners
    - [ ] The persona switcher is absent when DEV_AUTH is off
  </postconditions>
</contract>
<budget>At most 100,000 output tokens and 180 tool calls; exit budget_exceeded if the objective cannot be met within them.</budget>
<feedback>{carried findings, on retries only}</feedback>
<exit_protocol>End with exactly one <exit code="..."><outputs>{JSON}</outputs></exit> where code is one of: success, fail, needs_input, budget_exceeded, timeout, blocked. Append one line to tasks/trace.jsonl (node, attempt, exit, files_touched, tokens if known). Do no work outside this node's objective.</exit_protocol>
</node_prompt>
```

**Routing after this node**

- `success` → `verify_m6`
- `needs_input` → `blocked`
- `blocked` → `blocked`
