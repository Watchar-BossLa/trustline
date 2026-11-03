# TRUSTLINE — Harness Engineering Format specification

Full HEF, v1.1.0 format. This is the master build specification. Sections 3, 6 and 7 are
generated from `spec/registry.yaml` by `tools/sync_hef.py`; edit the registry, not those
sections. Everything else in this file is hand-written.

<harness_engineering_format version="1.1.0">

<hef_identity>
  <name>TRUSTLINE</name>
  <type>product</type>
  <version>1.0.0</version>
  <parent>standalone (Limah Innovations, Corp. product line; related to PWEV)</parent>
  <owner>Kelvin Wilson Antoine — Limah Innovations, Corp.</owner>
  <date>2026-11-02</date>
  <status>ready</status>
</hef_identity>

<hef_context>
  <problem_statement>
    Saint Lucia has built much of its digital plumbing — a national digital identity (the
    National Authentication Framework, launched 26 Feb 2026), online licence and vehicle
    services (digiGov), a police data system (launched Dec 2024), court e-filing (ECSC
    e-Litigation, criminal module since 9 Oct 2024) and a primary-care health information
    system (SLUHIS) — but none of it meets at the roadside. An officer at a stop cannot see,
    in one place, whether a licence is valid, a vehicle insured and inspected, a ticket
    unpaid or a warrant open. The demerit point system in section 179 of the Motor Vehicles
    and Road Traffic Act has existed for years and has never been applied, because no shared
    ledger connects the police, the Licensing Authority and the court. Police recorded
    3,815 reported accidents, 189 extremely serious and 10 fatal, between January and
    September 2025.

    At the same time, a system that shows police "everything about a person" would clash with
    the Data Protection Act, put sensitive data (health above all) in front of people with no
    lawful need for it, and create a single breach target for the whole population. In
    October 2026 attackers queried Moldova's government services by ID number and exposed
    licence, vehicle, photo and health-insurance data for about 750,000 people.

    TRUSTLINE closes the gap without creating that risk: a purpose-bound exchange in which
    data stays with each agency, every lookup is decided by written policy and logged in a
    tamper-evident ledger, and citizens can see who viewed their data, when and why.
  </problem_statement>

  <target_user>
    Primary: traffic and patrol officers of the Royal Saint Lucia Police Force at stops and
    checkpoints, on a phone, often with weak mobile signal.
    Secondary: dispatchers (confirming warrant and stolen-vehicle matches), investigators and
    crash investigators, Licensing Authority officers (points and licence actions), the
    District Court Traffic Part (tickets, payments, outcomes), EMS and fire crews (emergency
    card), every licensed driver and vehicle owner (My Record and the access log), and the
    Data Protection Commissioner or interim oversight body.
    Build-time user: Kelvin Wilson Antoine, a non-technical founder executing this
    specification with Claude Code.
  </target_user>

  <business_case>
    The build produces the pitch demo for the Government of Saint Lucia: the minister for
    the Public Service (which runs NAF, digiGov and the World Bank-funded CARDTP programme)
    was quoted in March 2026 as overseeing transport and committing to act on demerit
    points. TRUSTLINE delivers a law already passed, gives citizens a reason to adopt NAF,
    rides infrastructure CARDTP is already funding (interoperability framework, data centre,
    payment platform, secure wallet), and offers a regional product for the other CARDTP
    countries. Commercial model: fixed-price pilot, then an annual licence and support fee
    per agency or build-operate-transfer; perpetual licence with source escrow; no share
    of fine revenue. It is a 12–24 month government sale, run as a pitch track beside PWEV.
  </business_case>

  <prior_work>
    - Concept assessment and refined proposal (Claude Docs, 2 Nov 2026): the source of every
      design decision below, with sources.
    - Existing government systems TRUSTLINE must integrate with, not replace: NAF, digiGov,
      RSLPF data management system, ECSC e-Litigation, SLUHIS, the CARDTP interoperability
      framework and planned secure wallet.
    - PWEV (Limah Innovations): W3C VC 2.0 / Ed25519 / did:web credential rails, a candidate
      for the digital driver's licence in programme phase 3.
    - Comparable systems: Estonia's X-Road and Data Tracker (since 2017; only 15 of 300+
      systems integrated as of Dec 2025); St Kitts and Nevis digital inspection and
      insurance feeds (Oct 2024).
  </prior_work>

  <decision_log>
    D1. Decision: a federated, purpose-bound exchange; data stays with each agency.
        Rationale: Data Protection Act principles, breach blast radius, public trust.
        Rejected: one national database of everything about a person.
    D2. Decision: police never see health data; an opt-in emergency card goes only to EMS
        and fire crews at an active incident. Rejected: medical records at traffic stops.
    D3. Decision: beachhead is e-tickets plus the section 179 demerit ledger.
        Rationale: the law exists, it has never been applied, and the minister has committed.
    D4. Decision: signature feature is the citizen access log ("who viewed my data"), with
        leak-proof, accountable disclosure deferrals so it never tips off a suspect or exposes an
        undercover officer. Approved by Kelvin on 2 Nov 2026 (Q6 closed), who asked that no
        investigation be detectable and no cover blown. Design: ADR 0011, rules/disclosure.yaml,
        citizen.visible_access_events in db/schema.sql (single read path; 72 h provisional hold for
        INV/WAR; case-scoped deferrals covering the case team's lookups; withheld from everyone on the
        entry; no retroactive hiding; administrative entries invisible; protected officer identities;
        references withheld). Accountability kept: second-person approval, 72 h lapse, 90-day
        approvals, magistrate order beyond 365 days, oversight sees all in real time and can release,
        disclosure delayed but never cancelled; a release ends the whole renewal chain at once (added 2 Nov
        2026 after the test console showed an overlapping earlier approval could keep withholding).
        Verified by db/tests/disclosure_test.sql (DF1-DF28).
        Rejected: excluding investigative lookups from the log altogether; app-level filtering.
    D5. Decision: Rust for the broker, policy engine, audit ledger and offline core; Cedar
        for access policy; PostgreSQL; X-Road as the production exchange layer, with
        X-Road-shaped mock adapters in the demo build. Rejected: rebuilding X-Road.
    D6. Decision: officer app is an installable PWA in the demo build; native Kotlin with
        the Rust offline core via UniFFI for the pilot. Rationale: demo speed now, device
        security and NFC later.
    D7. Decision: web front end in Next.js and TypeScript (Kelvin's existing tooling),
        with no business rules in the front end. Rejected: Supabase and Vercel hosting for
        anything beyond the synthetic demo — production data stays in the Government of
        Saint Lucia data centre.
    D8. Decision: software proposes licence actions; an authorised Licensing Authority
        officer decides. Rationale: section 179 gives the decision to the Authority.
    D9. Decision: integrate with the RSLPF data system as a source; do not replace it.
    D10. Decision: no vendor revenue tied to fines.
    D11. Decision: synthetic data only, with SYNTHETIC banners.
    D12. Decision: legal values (demerit schedule, offences and fixed penalties, retention)
         live in rules/ with verified flags. The Schedule 2 point values in
         rules/demerit-schedule.yaml were matched by position from a garbled web copy of the
         Act and must be confirmed against a certified copy before the pilot.
    D13. Decision (2 Nov 2026): do not build yet; prepare this pack for a later Claude Code
         build from a private GitHub repo named trustline.
    D14. Working name TRUSTLINE; final name open (Q4).
  </decision_log>
</hef_context>

<!-- BEGIN:spec -->
<hef_specification>
  <core_requirements>
    <requirement id="R1" priority="must" milestone="M3">The system shall return a roadside status card for a NIC number, driver's licence number or vehicle plate, containing only the field groups the policy engine permits for the stated purpose, within 2 seconds at the 95th percentile on the reference environment (docker compose on a 4-core, 8 GB machine).</requirement>
    <requirement id="R2" priority="must" milestone="M2">The system shall require every data request to carry an authenticated actor, an attested device (for officers), a reason code from rules/reason-codes.yaml and, where that reason code requires it, a valid case, incident or warrant reference; any request failing a check shall be denied by default.</requirement>
    <requirement id="R3" priority="must" milestone="M2">The system shall decide access per field group with the Cedar policies in policies/trustline.cedar, including forbid rules that make health data unreachable by every police role under every purpose.</requirement>
    <requirement id="R4" priority="must" milestone="M3">The system shall not store agency master records (licences, vehicles, criminal, court or health records); it shall fetch them at query time through adapter interfaces modelled on X-Road service calls, and shall persist only tickets, the demerit ledger, licence actions, access logs, alerts, consents and disputes.</requirement>
    <requirement id="R5" priority="must" milestone="M2">The system shall append every request decision (allow, partial, deny, error or rate_limited) to an append-only ledger in which each entry is hash-chained to its predecessor, signed with Ed25519 and covered by periodic signed Merkle checkpoints; tampering with any entry shall be detectable by an offline verification command.</requirement>
    <requirement id="R6" priority="must" milestone="M5">The system shall show each signed-in citizen every access to their data, with time, agency, officer badge and reason code, except entries withheld under rules/disclosure.yaml (a 72-hour provisional hold for investigative purposes, and approved, time-limited disclosure deferrals); a withheld entry shall appear automatically, with its original time, when its hold or deferral ends.</requirement>
    <requirement id="R7" priority="must" milestone="M4">The system shall issue electronic tickets under the Motor Vehicles and Road Traffic (Ticketable Offences) Regulations, track payment and court referral, and expose ticket status to the court and Licensing Authority.</requirement>
    <requirement id="R8" priority="must" milestone="M4">The system shall record demerit points on conviction from the versioned schedule in rules/demerit-schedule.yaml, evaluate the section 179 thresholds, and produce proposed licence actions that take effect only after an authorised Licensing Authority officer records a decision.</requirement>
    <requirement id="R9" priority="must" milestone="M3">The system shall mark every warrant or stolen-vehicle match as UNCONFIRMED until a dispatcher confirms or clears it against the source agency, and shall log both the match and the decision.</requirement>
    <requirement id="R10" priority="must" milestone="M5">The system shall evaluate the rules in rules/anomaly-rules.yaml over the access ledger, raise alerts in the oversight console, and produce a monthly aggregate transparency report that includes the ledger checkpoint roots.</requirement>
    <requirement id="R11" priority="must" milestone="M3">The system shall expose no endpoint, query, report or export that returns a person's data combined across ministries, no bulk export, and shall rate-limit identifier lookups per officer and per device.</requirement>
    <requirement id="R12" priority="must" milestone="M1">The system shall authenticate officers per device (signed development tokens behind a DEV_AUTH flag in the demo build; WebAuthn passkeys with device attestation from the pilot), encrypt every network hop with TLS outside localhost, keep secrets out of the repository, store personal identifiers only as keyed hashes or envelope-encrypted values, and pass the security gates in docs/08-verification-plan.md.</requirement>
    <requirement id="R13" priority="should" milestone="M4">The system shall flag a driver whose court fine remains unpaid 30 days after all proceedings end, generate a section 107 disqualification notice for the Licensing Authority, and clear the disqualification when the Clerk of Court confirms payment.</requirement>
    <requirement id="R14" priority="should" milestone="M3">The system shall produce a signed, encrypted, expiring offline bundle of suspension, stolen-vehicle and warrant flags keyed by keyed hashes; clients shall verify it before use and queue offline checks for later sync and ledger entry.</requirement>
    <requirement id="R15" priority="should" milestone="M5">The system shall let an EMS responder with an active incident open the emergency card of a citizen who has opted in, record each opening in that citizen's access log, and leave the card's content at the Ministry of Health adapter.</requirement>
    <requirement id="R16" priority="should" milestone="M5">The system shall let citizens view their own licence, vehicle, ticket, points and court-date record, pay (simulated) or contest a ticket, manage emergency-card consent, and file a dispute against any access-log entry.</requirement>
    <requirement id="R17" priority="must" milestone="M6">The system shall provide web interfaces for officers (installable PWA with QR scan of synthetic demo cards and manual entry), dispatch, the Licensing Authority, citizens, EMS and oversight, usable at 360 px width, with SYNTHETIC and pending-legal-verification banners on every screen.</requirement>
    <requirement id="R18" priority="should" milestone="M4">The system shall show court dates and outcomes for driving matters to authorised roles and to the citizen concerned, read through the courts adapter.</requirement>
    <requirement id="R21" priority="must" milestone="M5">The system shall make a withheld access entry undetectable by the subject and by every other person attached to it: citizen-facing access entries shall be read only through citizen.visible_access_events in db/schema.sql, which filters before ordering and paging; no citizen-facing response, error, count, notification or published report shall reveal a withheld entry, a deferral or its administration; investigative case references shall never be shown to the subject; and officers with an approved protected identity shall never have their badge or unit shown in any citizen-facing view or driver receipt.</requirement>
    <requirement id="R22" priority="must" milestone="M5">The system shall keep every disclosure deferral accountable: case- or entry-scoped and tied to a case open at source; requested by an investigator and approved by a different supervisor; lapsing if not approved within 72 hours; at most 90 days per approval; renewable only while active and without a gap; beyond 365 days only with a recorded magistrate's order; releasable early by the case team or oversight; visible to oversight in real time with acknowledgement required; and recorded in the ledger as administrative entries. Protected-identity designations shall likewise be approved by a supervisor, visible to and acknowledged by oversight.</requirement>
    <requirement id="R19" priority="could" milestone="deferred">The system shall verify ISO/IEC 18013-5 mobile driving licences presented by drivers. Not built in M1–M7; the offline crate must not preclude it.</requirement>
    <requirement id="R20" priority="could" milestone="deferred">The system shall produce de-identified road-safety analytics (crash hotspots, offence trends, repeat-offender rates). Not built in M1–M7.</requirement>
  </core_requirements>
  <user_flows>
    <flow id="UF1" name="Roadside check">Officer signs in on an enrolled device → picks reason TS or CP → scans the
      driver's ID card or licence QR, or types the plate → TRUSTLINE returns the status card in under 2 s →
      a possible warrant or stolen match shows UNCONFIRMED and prompts a dispatch call → officer issues a
      ticket or lets the driver go → driver receives a QR receipt with the stop's reference.</flow>
    <flow id="UF2" name="Ticket to points">Ticket issued → driver pays online (guilty plea) or the court convicts →
      points recorded from the schedule → thresholds evaluated → proposed action appears in the Licensing
      Authority queue → officer confirms or rejects with a note → if confirmed, the roadside card shows
      SUSPENDED and the driver is notified with the appeal deadline.</flow>
    <flow id="UF3" name="Citizen sees who looked">Citizen signs in with NAF → My Record shows licence, vehicles,
      tickets, points and court dates → Access log lists every lookup (time, agency, badge, reason, case) →
      citizen can dispute an entry, which opens an oversight item.</flow>
    <flow id="UF4" name="Oversight catches misuse">An officer looks up the same person repeatedly with no stop,
      ticket or case → the anomaly rule fires → alert in the oversight console → reviewer records the outcome →
      the monthly transparency report counts it.</flow>
    <flow id="UF5" name="Crash scene emergency card">EMS responder with an active incident scans the casualty's ID →
      if the person opted in, the emergency card (blood group, allergies, critical conditions, emergency
      contact) appears → the opening is logged and shown to the citizen.</flow>
  </user_flows>
  <data_model>See db/schema.sql (canonical) and docs/03-data-model.md. TRUSTLINE owns only: officers,
    devices, reason codes, keyed subject references, the access ledger and checkpoints, hits, tickets,
    payments, court referrals, convictions, incidents, proposed and effective licence actions,
    deferrals, disputes, alerts, reports, emergency-card consents and offline-bundle records.</data_model>
  <api_surface>See api/openapi.yaml (canonical) and docs/04-api.md.</api_surface>
  <ui_specification>See docs/10-demo-script.md and the M6 tasks; screens per role: officer, dispatch,
    licensing, citizen, EMS, oversight.</ui_specification>
</hef_specification>
<!-- END:spec -->

<hef_constraints>
  <stack>
    Core services: Rust stable (edition 2024), tokio, axum, tower, sqlx (PostgreSQL),
      serde, cedar-policy (4.x), ed25519-dalek, sha2, hmac, uuid (v7), time, tracing.
    Database: PostgreSQL 16, one database, schemas core, ledger, tickets, demerit,
      citizen, oversight, ems. Canonical DDL: db/schema.sql.
    Access policy: Cedar — policies/trustline.cedar validated against
      policies/trustline.cedarschema.
    API contract: OpenAPI 3.1 — api/openapi.yaml is the source of truth (spec-first;
      server conforms; contract tests enforce it).
    Web: Next.js (App Router), TypeScript strict, Tailwind, pnpm; Playwright for e2e;
      axe for accessibility. Barcode/QR scanning with a maintained browser library.
    Officer app: PWA in this build; Kotlin + Rust core via UniFFI in the pilot (not built here).
    Exchange: adapters with X-Road-shaped headers to services/mock-agencies in this
      build; X-Road Security Servers in the pilot.
    Local runtime: docker compose; Makefile entry points.
    CI: GitHub Actions in the private trustline repository.
    Pin exact versions in Cargo.lock and pnpm-lock.yaml at build time; prefer the latest
    stable release of each library on the day M1 starts.
  </stack>

  <hard_limits>
    HL1. Never build an endpoint, query, report or export that returns a person's data combined across ministries.
    HL2. Never allow a police role to read health data. Health content leaves the Ministry of Health adapter only as the opted-in emergency card to an EMS responder with an active incident.
    HL3. Never store agency master records in TRUSTLINE's database; cache only what the offline-bundle spec allows.
    HL4. Never write raw NIC, licence or plate numbers to the access ledger or application logs; use keyed hashes (HMAC-SHA-256 with a managed pepper).
    HL5. Never let software alone suspend or disqualify a driver; every licence action needs a recorded decision by an authorised Licensing Authority officer.
    HL6. Never use real personal data in development, tests or demos; synthetic data only, marked SYNTHETIC on every screen.
    HL7. Never implement facial recognition, appearance-based profiling, predictive risk scores or automatic plate-recognition ticketing.
    HL8. Never update or delete ledger rows; corrections are new entries.
    HL9. Never commit secrets, keys or tokens, and never disable TLS verification.
    HL10. Never model vendor revenue on fines collected.
    HL11. Never treat values in rules/demerit-schedule.yaml, rules/offences.yaml or rules/retention.yaml as legally verified while verified is false; show the pending-legal-verification banner.
    HL12. Never deploy this build with real data or to third-party hosting; production hosting is the Government of Saint Lucia data centre and is out of scope.
    HL13. Never read or count a subject's access entries for anything citizen-facing except through citizen.visible_access_events, and never reveal a withheld entry, a deferral or a protected officer's identity through any citizen-facing channel.
    HL14. Never allow a deferral or protected-identity designation without a second-person approval, a time limit and real-time oversight visibility; never let a deferral hide an entry the subject could already see.
  </hard_limits>

  <budget>
    No cash budget is set for this build [NEEDS INPUT: Q5]. Agent token budgets are in
    graphs/build.graph.yaml (8M total, 10% reserve) and are first-run estimates.
  </budget>

  <timeline>
    Build milestones M1–M7 run in order; no calendar dates are committed. Programme phases
    (0: discover and demo, months 0–3; 1: pilot, months 4–12; 2: national rollout,
    months 13–18; 3: extend, months 19–30) are estimates from the first ministerial meeting.
  </timeline>

  <dependencies>
    This build: none external. All agencies are mocked; NAF sign-in is simulated by an
    OIDC-style mock.
    Pilot (not this build): ministerial sponsor; data-sharing agreements with Transport,
    RSLPF, the Court Office, the Ministry of Health and the Department of the Public
    Service; NAF integration specification; X-Road (or the CARDTP interoperability layer);
    an operating Data Protection Commissioner or interim oversight body; hosting in the
    government data centre; independent security audit.
  </dependencies>

  <security>
    Authentication: officers per device — signed development tokens behind DEV_AUTH in this
      build (refused when TRUSTLINE_ENV=production); WebAuthn passkeys with device
      attestation in the pilot. Citizens via NAF (mocked here). Agency systems and the court
      as service principals with mTLS client certificates (pilot) or signed service tokens (demo).
    Authorization: Cedar policy per field group; default deny; forbid rules for health and
      cross-domain profiles; reason code and reference checks on every request.
    Data handling: subject identifiers in logs and ledger only as HMAC-SHA-256 keyed hashes;
      identifiers on tickets envelope-encrypted; no agency master records stored; offline
      bundles signed, encrypted and expiring.
    Integrity: append-only ledger with SHA-256 chaining, Ed25519 signatures, Merkle
      checkpoints published in the monthly transparency report.
    Abuse controls: per-officer and per-device rate limits, anomaly rules, hit confirmation.
    Compliance anchor: Saint Lucia Data Protection Act (Act 11 of 2011, amended 2015; partly
      in force since 31 Jan 2023). See docs/07-privacy-and-legal-basis.md. Not legal advice;
      Saint Lucian counsel must review before the pilot.
  </security>
</hef_constraints>

<hef_architecture>
  <system_overview>
    A modular Rust backend (one API binary built from library crates) in front of
    PostgreSQL, calling agency systems through adapters. A request flows:
    authenticate actor and device → validate reason code and references → Cedar decides the
    permitted field groups → broker calls only the adapters those groups need, in parallel,
    with timeouts → status card assembled, unknowns marked → one ledger entry written →
    oversight rules evaluate the entry asynchronously. The web app (Next.js) is a thin client
    over the API. A mock-agencies service plays every government system with synthetic data.
    Full detail: docs/02-architecture.md.
  </system_overview>

  <directory_structure>
    trustline/
    ├── CLAUDE.md, MASTER_PROMPT.md, TRUSTLINE.hef.md, README.md
    ├── spec/registry.yaml            — canonical ids (requirements, ACs, hard limits, milestones)
    ├── graphs/build.graph.yaml       — execution graph
    ├── prompts/nodes/                — one rendered prompt per graph node
    ├── docs/                         — product brief, architecture, data model, API, policy,
    │                                    threat model, privacy, verification, synthetic data, demo, ADRs
    ├── db/schema.sql                 — canonical DDL (migrations generated from it in M1)
    ├── db/tests/disclosure_test.sql  — database scenarios for leak-proof deferrals (make db-test)
    ├── api/openapi.yaml              — API contract
    ├── policies/                     — Cedar schema, policies, entities, sample requests
    ├── rules/                        — reason codes, field groups, demerit schedule, offences,
    │                                    anomaly rules, retention (configuration, versioned)
    ├── tools/                        — graph generator and linter, prompt renderer, HEF sync, policy matrix
    ├── tasks/                        — todo.md, lessons.md, trace.jsonl
    │   — created during the build —
    ├── Cargo.toml                    — workspace
    ├── crates/
    │   ├── core/        trustline-core       domain types, config, errors, subject keys
    │   ├── policy/      trustline-policy     Cedar engine wrapper
    │   ├── ledger/      trustline-ledger     hash chain, signatures, checkpoints, verify
    │   ├── adapters/    trustline-adapters   one adapter per agency (X-Road-shaped)
    │   ├── broker/      trustline-broker     fan-out, status card, hit confirmation
    │   ├── tickets/     trustline-tickets    tickets, payments, court, section 107
    │   ├── demerit/     trustline-demerit    pure section 179 engine
    │   ├── oversight/   trustline-oversight  anomaly rules, alerts, reports
    │   ├── offline/     trustline-offline    offline bundles (UniFFI-ready)
    │   ├── api/         trustline-api        axum server (binary)
    │   └── cli/         trustline-cli        seed, keys, ledger verify, reports (binary)
    ├── services/mock-agencies/       — synthetic agency systems (binary)
    ├── apps/web/                     — Next.js app: /officer /dispatch /licensing /citizen /ems /oversight
    ├── db/migrations/                — sqlx migrations
    ├── docker-compose.yml, Makefile, .env.example, deny.toml
    └── .github/workflows/ci.yml
  </directory_structure>

  <component_map>
    trustline-core: identifiers, SubjectKey (HMAC), Purpose, Role, FieldGroup, StatusCard
      types, config loader, Problem errors. Depends on nothing internal.
    trustline-policy: loads and validates Cedar files; decide(principal, action, resource,
      context) → Decision; policy_version = SHA-256 of the policy set. Depends on core.
    trustline-ledger: append(entry) → seq; canonical JSON (RFC 8785); chain + sign;
      checkpoints; verify(range). Depends on core.
    trustline-adapters: AgencyAdapter trait; LicensingAdapter, VehicleAdapter, PoliceAdapter,
      CourtsAdapter, InsuranceAdapter, InspectionAdapter, HealthEmergencyAdapter, NafAdapter.
      Depends on core.
    trustline-broker: check(request) → StatusCard | InvestigationResult; asks policy, calls
      adapters, assembles, records hits. Depends on core, policy, adapters.
    trustline-tickets: issue, pay, refer, record outcome, unpaid-fine detection, court timeline.
    trustline-demerit: pure functions over conviction history + schedule → points, proposed
      actions. No I/O.
    trustline-oversight: evaluates anomaly rules on ledger entries; alerts; monthly reports.
    trustline-offline: build/verify bundles; no async runtime; UniFFI-ready for Kotlin.
    trustline-api: axum routes per api/openapi.yaml; auth, rate limits, ledger middleware.
    trustline-cli: seed, keys, ledger verify, report generation.
    services/mock-agencies: synthetic agency endpoints with latency and failure injection.
    apps/web: role screens; calls the API only.
  </component_map>

  <integration_points>
    Agency systems (mocked): HTTPS JSON with X-Road-shaped headers
      (X-Road-Client, X-Road-Service, X-Road-Id, X-Road-UserId, X-Road-Issue = purpose + reference).
      Pilot: X-Road Security Server per agency, or the CARDTP interoperability layer.
    NAF (mocked): OIDC authorization code flow with PKCE; subject claim = NIC; TRUSTLINE
      derives the SubjectKey and never stores the NIC.
    Court: service principal posts payments and outcomes; reads tickets.
    Ministry of Health: emergency-card read only, opted-in subjects, EMS purpose only.
    Payments: simulated in this build; the CARDTP government payment platform in the pilot.
  </integration_points>

  <state_management>
    Server state: PostgreSQL (TRUSTLINE-owned tables only, docs/03); no agency master records.
    Caches: in-process, short-lived (under 60 s) for policy decisions and reference data;
      never for personal records. Offline bundles on officer devices, signed and expiring.
    Session state: short-lived signed tokens (15 min officer, 30 min citizen in this build).
    Client state: React state only; no personal data in browser storage beyond the
      encrypted offline bundle in the officer PWA.
  </state_management>
</hef_architecture>

<!-- BEGIN:execution -->
<hef_execution>
  <phase id="M1" name="Foundation">
    <objective>A compiling Rust workspace, database, CI, configuration and synthetic data that every later milestone builds on.</objective>
    <tasks>
      <task id="T1.1">Create the Cargo workspace (edition 2024) with crates core, policy, ledger, broker, adapters, demerit, tickets, oversight, offline, api, cli and the services/mock-agencies binary, each compiling with a placeholder test.</task>
      <task id="T1.2">Add docker-compose.yml (Postgres 16, api, mock-agencies, web) and a Makefile with targets setup, keys, db, seed, run, test, verify and demo.</task>
      <task id="T1.3">Add GitHub Actions CI running fmt, clippy -D warnings, tests, cargo-deny, gitleaks, migration check, Cedar validation, OpenAPI lint and web lint, typecheck and tests.</task>
      <task id="T1.4">Add typed configuration (.env.example, no secrets), tracing with request ids, the problem+json error model from api/openapi.yaml, and the DEV_AUTH token issuer for synthetic personas that refuses to start when TRUSTLINE_ENV=production.</task>
      <task id="T1.5">Turn db/schema.sql into sqlx migrations, create the database roles and append-only triggers, and add a schema test proving no agency master-record tables exist.</task>
      <task id="T1.6">Implement the deterministic synthetic data generator in trustline-cli per docs/09-synthetic-data.md for TRUSTLINE tables and mock-agency fixtures.</task>
    </tasks>
    <verification>
      <check id="V1.1">make verify passes on a clean clone.</check>
      <check id="V1.2">make db applies all migrations to an empty database; UPDATE or DELETE on ledger.access_event by the app role fails.</check>
      <check id="V1.3">make seed produces the personas and counts in docs/09; the same seed produces byte-identical fixtures.</check>
    </verification>
    <deliverables>Cargo workspace, docker-compose.yml, Makefile, CI workflow, migrations, config, seeder.</deliverables>
  </phase>
  <phase id="M2" name="Policy and ledger">
    <objective>Every request is decided by Cedar policy and recorded in a tamper-evident ledger.</objective>
    <tasks>
      <task id="T2.1">Implement trustline-policy to load and validate policies/trustline.cedar against policies/trustline.cedarschema at startup and expose decide() and policy_version().</task>
      <task id="T2.2">Generate the exhaustive role × reason × field-group × context matrix test and assert it against the expected-permissions table in docs/05-access-policy.md.</task>
      <task id="T2.3">Implement trustline-ledger with RFC 8785 canonical JSON, SHA-256 hash chaining, Ed25519 signatures with key ids, and Merkle checkpoints every N entries or T minutes.</task>
      <task id="T2.4">Add trustline-cli ledger verify (against the database or an export file) and API middleware that writes exactly one ledger entry per ledger-scoped request, including denials and errors.</task>
    </tasks>
    <verification>
      <check id="V2.1">Policy matrix test passes; any permit of a health field group to a police role fails the build.</check>
      <check id="V2.2">Ledger tamper tests pass for modify, delete and reorder.</check>
      <check id="V2.3">Integration tests show one ledger entry per ledger-scoped request.</check>
    </verification>
    <deliverables>trustline-policy, trustline-ledger, ledger middleware, ledger verify command.</deliverables>
  </phase>
  <phase id="M3" name="Agencies, broker and roadside check">
    <objective>A purpose-bound roadside check that fetches only permitted fields from mock agencies, with hit confirmation, rate limits and offline bundles.</objective>
    <tasks>
      <task id="T3.1">Build services/mock-agencies serving synthetic licensing, vehicle, police, courts, insurance, inspection, health-emergency and NAF-style OIDC endpoints per the adapter contracts in docs/02, with latency and failure injection.</task>
      <task id="T3.2">Implement trustline-adapters with one adapter per agency behind an AgencyAdapter trait, X-Road-shaped request headers and per-call timeouts.</task>
      <task id="T3.3">Implement trustline-broker to resolve identifiers to subject keys, ask the policy engine for permitted field groups, fan out only permitted calls in parallel, assemble the status card and mark failed sources UNKNOWN.</task>
      <task id="T3.4">Implement hit confirmation and the endpoints POST /v1/roadside/checks, POST /v1/hits/{hitId}/decision and POST /v1/investigations/queries.</task>
      <task id="T3.5">Add per-officer and per-device rate limits and a contract test proving no endpoint returns a cross-domain profile.</task>
      <task id="T3.6">Implement trustline-offline (UniFFI-ready, no async runtime) to build, sign, encrypt and verify expiring bundles, with GET /v1/offline/bundle and POST /v1/offline/sync.</task>
    </tasks>
    <verification>
      <check id="V3.1">Roadside integration tests for personas S1 to S5 return the expected cards; p95 under 2 s over 200 checks.</check>
      <check id="V3.2">With any mock agency stopped, its fields show UNKNOWN and the card still returns.</check>
      <check id="V3.3">Offline bundle tamper and expiry tests pass; rate-limit test returns 429 and is logged.</check>
    </verification>
    <deliverables>mock-agencies service, adapters, broker, roadside, hit and investigation endpoints, offline bundle.</deliverables>
  </phase>
  <phase id="M4" name="Tickets and demerit points">
    <objective>Tickets flow to payment or court, convictions record points, and section 179 and 107 actions are proposed for human decision.</objective>
    <tasks>
      <task id="T4.1">Implement ticket issuance from rules/offences.yaml with ticket numbering, encrypted identifiers and the ticket endpoints.</task>
      <task id="T4.2">Implement simulated online payment, court-confirmed payment, court referral and court outcome endpoints.</task>
      <task id="T4.3">Implement section 107 unpaid-fine detection and the court timeline endpoint for authorised roles.</task>
      <task id="T4.4">Implement trustline-demerit as pure functions over conviction history and the versioned schedule, covering recording, appeals, the same-incident rule, expiry and all thresholds.</task>
      <task id="T4.5">Implement proposed actions, the Licensing Authority decision endpoints, licence-action effects on the roadside card and appeal deadlines.</task>
      <task id="T4.6">Write table tests mirroring every section 179 subsection and property-based tests for the demerit engine.</task>
    </tasks>
    <verification>
      <check id="V4.1">Demerit tests cover every row of the docs/08 section 179 table.</check>
      <check id="V4.2">Persona S6 flow passes end to end, ticket to SUSPENDED card after officer confirmation.</check>
      <check id="V4.3">Persona S10 unpaid-fine flow passes.</check>
    </verification>
    <deliverables>tickets crate and endpoints, demerit engine, proposed actions and licensing endpoints, court endpoints.</deliverables>
  </phase>
  <phase id="M5" name="Citizen record and oversight">
    <objective>Citizens see their record and every access to it; oversight sees anomalies, deferrals and monthly reports.</objective>
    <tasks>
      <task id="T5.1">Implement the citizen API (/v1/me/record, /v1/me/access-log, disputes, ticket payment) keyed by the citizen's subject hash.</task>
      <task id="T5.2">Implement disclosure control per rules/disclosure.yaml with citizen.visible_access_events as the only read path — provisional holds, case- and entry-scoped deferrals, approval, lapse, renewal, the 365-day magistrate threshold, early release, protected identities, administrative ledger entries — plus the API leak suite (AC23) and lifecycle tests (AC24).</task>
      <task id="T5.3">Implement emergency-card consent and EMS access with the incident check, the Ministry of Health adapter call and the citizen log entry.</task>
      <task id="T5.4">Implement trustline-oversight to evaluate rules/anomaly-rules.yaml on new ledger entries and on schedule, with the alerts API and review workflow.</task>
      <task id="T5.5">Implement the monthly transparency report and the ledger verification status endpoint.</task>
    </tasks>
    <verification>
      <check id="V5.1">The persona S8 misuse scenario raises the expected alert.</check>
      <check id="V5.2">db/tests/disclosure_test.sql, the deferral lifecycle tests and the API leak suite pass.</check>
      <check id="V5.3">The EMS flow passes and every police role is denied the emergency card.</check>
    </verification>
    <deliverables>citizen endpoints, deferrals, emergency card, oversight engine, alerts, reports.</deliverables>
  </phase>
  <phase id="M6" name="Web applications">
    <objective>Usable screens for every role, ready for the pitch demo.</objective>
    <tasks>
      <task id="T6.1">Create the Next.js app (App Router, TypeScript strict, Tailwind) with route groups /officer, /dispatch, /licensing, /citizen, /ems and /oversight, and a persona switcher shown only when DEV_AUTH is on.</task>
      <task id="T6.2">Build the officer PWA with QR scan of synthetic demo cards, manual entry, reason-code picker, status card, ticket issue, offline indicator and driver receipt QR.</task>
      <task id="T6.3">Build the citizen portal with My Record, the access log (showing deferred_until on released entries and never any sign of a withheld one), disputes, emergency-card consent and simulated payment.</task>
      <task id="T6.4">Build the licensing console (proposed-action queue and decisions) and the dispatch console (hit decisions).</task>
      <task id="T6.5">Build the oversight console (alerts, deferrals with release, protected-identity designations, ledger status, monthly report) and the SYNTHETIC and pending-legal-verification banners on every screen.</task>
    </tasks>
    <verification>
      <check id="V6.1">The Playwright demo-flow test passes.</check>
      <check id="V6.2">axe checks pass with no serious or critical violations on officer and citizen screens.</check>
      <check id="V6.3">The officer status card renders in under 3 s under 3G throttling.</check>
    </verification>
    <deliverables>apps/web with all role screens and Playwright tests.</deliverables>
  </phase>
  <phase id="M7" name="Hardening and demo readiness">
    <objective>Security gates green, threat model addressed, demo reproducible from a fresh clone.</objective>
    <tasks>
      <task id="T7.1">Work through the threat-model checklist in docs/06, fix gaps, and record a security-reviewer subagent review.</task>
      <task id="T7.2">Run cargo-deny, gitleaks, the web dependency audit and an OWASP ZAP baseline scan against compose, and fix findings rated medium or above.</task>
      <task id="T7.3">Load test the roadside endpoint and record results in docs/08.</task>
      <task id="T7.4">Run docs/10-demo-script.md end to end from a fresh clone with make demo and remove friction.</task>
      <task id="T7.5">Update README, the CLAUDE.md Current State, the tasks/todo.md review section and hef_state.</task>
    </tasks>
    <verification>
      <check id="V7.1">All quality gates are green in CI.</check>
      <check id="V7.2">Every threat in docs/06 has a status of mitigated, accepted with reason, or deferred to pilot.</check>
      <check id="V7.3">The demo script completes with under 10 minutes of setup from a fresh clone.</check>
    </verification>
    <deliverables>hardened build, security review record, load-test results, demo-ready repo.</deliverables>
  </phase>
</hef_execution>
<!-- END:execution -->

<!-- BEGIN:verification -->
<hef_verification>
  <acceptance_criteria>
    <criterion id="AC1" verifies="R1">Given persona S2 (suspended licence), when OFF-101 posts a roadside check with reason TS, the response contains exactly the TS field groups listed in docs/05 and licence.status = SUSPENDED; p95 latency over 200 checks in compose is under 2 s.</criterion>
    <criterion id="AC2" verifies="R2">A roadside check without a reason code, with an unknown reason code, or from an unattested device returns 403 problem+json and writes a ledger entry with decision deny.</criterion>
    <criterion id="AC3" verifies="R3">The exhaustive policy matrix (every role × every reason code × every field group, with each boolean context flag both ways) contains no permit of a health-domain field group to any police role, and matches the expected-permissions table in docs/05.</criterion>
    <criterion id="AC4" verifies="R2,R3">An investigator query for criminal_record without a case reference is denied; with a valid open case reference it is allowed and the ledger entry carries the case reference.</criterion>
    <criterion id="AC5" verifies="R5">`trustline-cli ledger verify` passes on an untouched ledger and, after any single entry is modified, deleted or reordered (via superuser in a test), fails and names the first bad sequence number; UPDATE and DELETE by the application role are rejected.</criterion>
    <criterion id="AC6" verifies="R5">In the end-to-end suite, the number of ledger entries equals the number of ledger-scoped API requests (x-ledger: true) plus the number of synced offline checks (x-ledger: per_item), across allow, partial, deny, error and rate_limited.</criterion>
    <criterion id="AC7" verifies="R6">Persona S8 sees each non-investigative access to their data within 60 s, with time, agency, badge and reason code; an INV lookup without a deferral appears after the 72-hour hold with its original time; entries covered by an approved deferral appear automatically when it ends, marked with deferred_until.</criterion>
    <criterion id="AC8" verifies="R7,R8">Paying a ticket for an offence mapped to Schedule 2 paragraph 2(e) (exceeding the speed limit by 20 mph or more) records the number of points set in rules/demerit-schedule.yaml, dated the conviction date, with the ticket linked.</criterion>
    <criterion id="AC9" verifies="R8">Demerit engine tests pass for every row of the section 179 test table in docs/08: recording on conviction, appeal suspension and reinstatement, same-incident rule, 3-year expiry, 11–13 notice, 14–17 interview, ≥10 in 1 year 6-month suspension, ≥18 over 1–2 years 1-year suspension, clearance after a suspension of 3+ months, and concurrent suspensions.</criterion>
    <criterion id="AC10" verifies="R8">No licence action becomes effective without a decision event by a licensing_officer; after confirmation, the roadside card for that driver shows SUSPENDED within 60 s.</criterion>
    <criterion id="AC11" verifies="R9">A stolen-vehicle or warrant match is returned as UNCONFIRMED_MATCH; only a dispatcher decision changes it to CONFIRMED or CLEARED; the match and the decision are separate ledger entries.</criterion>
    <criterion id="AC12" verifies="R10">The seeded misuse scenario (OFF-102 checks persona S8 five times in 24 h with no ticket, incident or case) raises a repeat_subject alert visible in the oversight console; the monthly report contains counts by agency, reason and decision and the checkpoint roots for the period.</criterion>
    <criterion id="AC13" verifies="R11">A contract test over api/openapi.yaml confirms no response schema combines more than one ministry domain outside the purpose-bound status card and investigation result; exceeding the per-officer lookup limit returns 429 and is logged.</criterion>
    <criterion id="AC14" verifies="R13">For persona S10, a fine unpaid 30 days after proceedings end produces a pending disqualify_unpaid_fine proposed action; recording court-confirmed payment ends the disqualification.</criterion>
    <criterion id="AC15" verifies="R14">A freshly issued offline bundle verifies; a bundle with any byte altered, signed by an unknown key, or past its expiry is rejected; synced offline checks create ledger entries flagged offline = true.</criterion>
    <criterion id="AC16" verifies="R15">EMS-601 with an active incident opens persona S9's emergency card; the opening appears in S9's access log; the same request by any police role is denied.</criterion>
    <criterion id="AC17" verifies="R17">From a fresh clone, `make demo` brings the system up with seeded data in under 10 minutes and the Playwright demo-flow test (docs/10 steps 1–8) passes.</criterion>
    <criterion id="AC18" verifies="R12">cargo fmt, clippy (-D warnings), tests, cargo-deny, gitleaks, the web lint, typecheck and audit all pass in CI; no secret is present in the git history; DEV_AUTH cannot be enabled when TRUSTLINE_ENV=production.</criterion>
    <criterion id="AC19" verifies="R4">A schema test confirms no table holds agency master records; with a mock agency stopped, the status card returns its fields as UNKNOWN with source status timeout or error, never stale data.</criterion>
    <criterion id="AC20" verifies="R16">Persona S2 sees their own tickets, points, licence and vehicle status; filing a dispute creates an item in the oversight queue linked to the ledger entry.</criterion>
    <criterion id="AC21" verifies="R18">A licensing_officer and the citizen concerned see the next court date for a referred ticket; a traffic officer at a stop sees only court_date_pending = true.</criterion>
    <criterion id="AC22" verifies="R17">Officer and citizen screens pass automated axe accessibility checks with no serious or critical violations, and the officer status card renders in under 3 s under Playwright 3G throttling.</criterion>
    <criterion id="AC23" verifies="R21">The database scenario suite db/tests/disclosure_test.sql passes (DF1-DF28), and the API leak suite passes for persona S8 against control persona S11: while a case deferral covers S8's investigative lookups, every citizen-facing response for S8 (access log at every page size from 1 to 25 with cursors and include_self both ways, My Record, dispute attempts against the withheld sequence numbers, and the public monthly report) equals S11's response apart from sequence numbers, request ids and generation times; a dispute against a withheld entry returns the same 404 as a nonexistent one; the vehicle co-owner sees nothing; and lookups by protected officer UC-311 never show a badge or unit to the citizen, before or after release.</criterion>
    <criterion id="AC24" verifies="R22">Deferral lifecycle tests pass at API and database level: self-approval refused; an unapproved request lapses after 72 hours; approval over 90 days refused; renewal after expiry refused; retroactive coverage beyond the hold refused; a chain over 365 days refused without a magistrate order and accepted with one; early release by oversight works; every deferral and protected-identity designation is listed in the oversight console within 60 s; every deferral action writes a ledger entry with relation administrative.</criterion>
  </acceptance_criteria>
  <quality_gates>
    <gate name="Rust">cargo fmt --check; cargo clippy --workspace --all-targets -- -D warnings; cargo test --workspace</gate>
    <gate name="Supply chain">cargo deny check; pnpm audit --prod (no high or critical)</gate>
    <gate name="Secrets">gitleaks detect on the full history</gate>
    <gate name="Contracts">cedar validate; OpenAPI lint; response contract tests; migration drift check</gate>
    <gate name="Web">pnpm lint; pnpm typecheck; pnpm test; Playwright demo flow; axe</gate>
    <gate name="Graph">python3 tools/graph_lint.py</gate>
    <gate name="Manual">Kelvin runs docs/10-demo-script.md and signs off (node approve_demo)</gate>
  </quality_gates>
  <known_risks>
    <risk id="RK1" severity="high">Legal values unverified (Schedule 2 points matched from a garbled web copy). Mitigation: verified flags, banner, counsel review before the pilot (HL11).</risk>
    <risk id="RK2" severity="high">Scope creep in a long agent build. Mitigation: graph scope locks, one node at a time, verifiers between milestones, needs_input instead of improvisation.</risk>
    <risk id="RK3" severity="high">Security mistakes in AI-written code. Mitigation: security-reviewer subagent per milestone, M7 gates, independent human review and penetration test before any pilot.</risk>
    <risk id="RK4" severity="medium">Founder cannot judge Rust code quality directly. Mitigation: make verify as the single green/red signal; plain-language node summaries; external code review (e.g. SpireHub) before the pilot.</risk>
    <risk id="RK5" severity="medium">X-Road not exercised in this build. Mitigation: adapters send X-Road-shaped headers behind one trait (ADR 0002); pilot replaces the transport only.</risk>
    <risk id="RK6" severity="medium">Synthetic names could coincide with real people. Mitigation: SYN identifiers, fictional name list, SYNTHETIC banners, no photos of real people (generated placeholders only).</risk>
  </known_risks>
</hef_verification>
<!-- END:verification -->

<hef_platform_exports>
  Claude Code (target platform):
    - CLAUDE.md — workflow rules (Boris Cherny framework), conventions and Graph Execution.
    - MASTER_PROMPT.md — the orchestrator prompt that runs the graph.
    - prompts/nodes/ — one rendered task prompt per graph node.
    - .claude/agents/ — security-reviewer, policy-auditor and spec-verifier subagents.
    - .claude/commands/ — /next-node, /verify, /status.
  Other platforms: not exported. The universal form is this file.
</hef_platform_exports>

<hef_graph file="graphs/build.graph.yaml" version="1.0.0">
  37 nodes (24 prompt, 8 verifier, 2 human, 3 terminal), entry plan_build, 10 bounded loops.
  Linted with tools/graph_lint.py (a local implementation of the HEF graph rules; the
  hef-graph-layer bundle linter was not available when this pack was produced).
</hef_graph>

<session_context>
  Planned in a Claude conversation on 2 Nov 2026 (assessment doc, then this pack).
  Rejected alternatives: central national database; hiding investigative lookups from citizens altogether; health records for police; automatic
  licence suspension; plate-recognition ticketing before enabling law; Supabase/Vercel
  production hosting; vendor share of fines; rebuilding X-Road.
  Open questions (also in docs/01-product-brief.md):
    Q1. Which ministers or officials can Kelvin meet first?
    Q2. Approach the RSLPF system's developer as a partner?
    Q3. Which established integrator for World Bank-funded bids?
    Q4. Keep the name TRUSTLINE?
    Q5. Who funds Phase 0 and the demo?
    Q6. Closed 2 Nov 2026 — deferral design approved (D4); durations and legal basis go to counsel.
    Q7. Digital licence on PWEV credentials or the government's planned secure wallet?
</session_context>

<hef_state>
  <completed>none — specification pack only (iteration 2: disclosure deferrals approved and specified)</completed>
  <current>awaiting decision to start the build (graph node plan_build)</current>
  <blocked>none for the build; pilot blocked on Q1–Q3 and the dependencies above</blocked>
  <next>Run MASTER_PROMPT.md in Claude Code inside the trustline repository</next>
  <iteration>2</iteration>
</hef_state>

</harness_engineering_format>
