# 06 — Security threat model

Method: STRIDE over the components in docs/02, plus abuse cases specific to police data. Each
threat gets a status in M7 (node `m7_security`): **mitigated** (with the test or control that
proves it), **accepted** (with reason), or **deferred to pilot**. This build is a demo on
synthetic data; the pilot needs an independent penetration test and code review regardless.

## Assets
Access ledger and its keys · pepper (subject-key secret) · ticket identifiers (encrypted) ·
offline bundles and bundle keys · policy files and rules · officer tokens and devices ·
agency adapter credentials · the citizen access log's completeness.

## Threats and controls

| # | Threat (STRIDE) | Control | Proven by | Status |
| --- | --- | --- | --- | --- |
| T1 | Officer looks up people for personal reasons (abuse of authority) | Reason codes; anomaly rules; citizen sees the lookup; discipline code | AC12, AC7 | open |
| T2 | Officer probes for data beyond their role (Elevation) | Cedar per field group, default deny; denied_spike rule | AC3, AC4 | open |
| T3 | Police read health data (Information disclosure) | G3/G4 forbid; MoH adapter only called for EMS purpose; matrix test | AC3, AC16 | open |
| T4 | Bulk harvesting of the population (Information disclosure) | No bulk endpoints; rate limits; high_volume rule; identifiers only in bodies | AC13 | open |
| T5 | Lookup-by-ID abuse as in the Oct 2026 Moldova breach | Every query authenticated and tied to an officer and device; no unauthenticated identifier lookup exists | Route-table test, AC2 | open |
| T6 | Ledger rewritten to hide misuse (Tampering, Repudiation) | Append-only triggers; app role lacks UPDATE/DELETE; hash chain; signatures; published checkpoint roots | AC5 | open |
| T7 | Ledger signing key stolen (Tampering) | Key in HSM (pilot); key ids and rotation; checkpoints signed with a separate key; roots published monthly | Key-rotation test | deferred to pilot (HSM) |
| T8 | Pepper leaked → subject keys reversible by guessing identifiers (Information disclosure) | Pepper in key store/HSM, versioned; identifiers have limited entropy, so pepper secrecy is essential | Config test: pepper never logged | deferred to pilot (HSM) |
| T9 | Stolen officer phone with offline bundle (Information disclosure) | Flags only, per-bundle salt, encryption to device key, 12 h expiry, remote revocation | AC15 | accepted residual (documented in docs/02 §9) |
| T10 | Forged bundle injected into a device (Spoofing) | Ed25519 signature and key-id check before use | AC15 | open |
| T11 | DEV_AUTH left on in production (Spoofing) | Startup refuses DEV_AUTH when TRUSTLINE_ENV=production; CI test | AC18 | open |
| T12 | Stolen officer token replayed (Spoofing) | 15-minute tokens bound to device id; pilot: WebAuthn + device attestation | Token-binding test | deferred to pilot (WebAuthn) |
| T13 | Adapter or mock spoofed (Spoofing) | Pilot: X-Road mutual TLS between security servers; demo: compose network only | — | deferred to pilot |
| T14 | Wrongful arrest from stale warrant or stolen flag | Hit confirmation by dispatch at source before action | AC11 | open |
| T15 | Software suspends a licence wrongly | Proposals only; DB trigger requires a confirmed proposal by the authorising officer | AC10 | open |
| T16 | Deferrals used to hide misuse from citizens | Second-person approval; case open at source; 72 h lapse; 90-day approvals; magistrate order beyond 365 days; no retroactive hiding; oversight sees all in real time and can release; deferral_overuse and deferral_long_running rules | AC24, DF3, DF10–DF15 | open |
| T17 | Raw identifiers leak into logs or traces | Logging filters; identifier types never implement Display/Debug with the value; log-scan test | AC18 | open |
| T18 | Injection (SQL, header) | sqlx parameterised queries only; header values validated; ZAP baseline | M7 gates | open |
| T19 | Dependency compromise (supply chain) | cargo-deny (advisories, licences, sources); pnpm audit; lockfiles; minimal dependencies in identifier and ledger crates | AC18 | open |
| T20 | Secrets in repository | gitleaks on full history in CI; `.local/` git-ignored | AC18 | open |
| T21 | Denial of service on roadside checks | Per-officer and per-device limits; adapter timeouts; unknown-not-stale | V3.2, load test | open |
| T22 | Citizen reads someone else's log (Elevation) | Subject key from the NAF token only; G7 forbid; is_self check | AC7 | open |
| T23 | Error messages reveal which agency holds a record | Problem responses are generic; contract test | Contract tests | open |
| T24 | Synthetic demo data mistaken for real people | SYN identifiers; fictional names; generated placeholder photos; SYNTHETIC banners | HL6 checks | open |
| T25 | A suspect detects an investigation through a side channel (short pages, cursors, counts, 404 differences, notifications, co-owner logs, administrative entries, renewal gaps, report cells) | Single read path `citizen.visible_access_events` filtering before paging; identical 404s; no counts; administrative relation; withhold from everyone attached; gapless renewals; national report totals with small cells suppressed | AC23, DF1–DF9, DF13, DF20 | open |
| T26 | An undercover officer's identity reaches a suspect (access log or driver receipt) | Protected-identity designations; badge and unit masked permanently in citizen views and receipts; snapshot on each ledger entry | AC23, DF18 | open |
| T27 | Source agencies' own portals or formal access requests reveal a deferred lookup | Pilot: deferral status passed with X-Road requests; agency portals honour it; Part 6 exemptions for formal requests (counsel) | — | deferred to pilot |

## Abuse cases to demo (oversight story)
1. OFF-102 checks persona S8 five times in 24 hours with no stop record → `repeat_subject` alert.
2. A traffic officer tries an investigation query → denied, ledger entry, `denied_spike` after repeats.
3. A supervisor tries to approve their own deferral → refused by the database.
4. An investigator tries to hide a lookup the citizen can already see → refused by the database.

## Before the pilot (not in this build)
Independent penetration test; external code review; HSM for ledger, bundle and pepper keys;
WebAuthn officer enrolment and managed devices; X-Road security servers; DPIA signed off; incident
response plan with the government CIRT; backup and disaster recovery tested at a second site.
