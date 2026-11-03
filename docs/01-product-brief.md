# 01 — Product brief

**TRUSTLINE** (working name) is a purpose-bound public-safety data exchange for the
Government of Saint Lucia. An officer's scan returns only what the law allows for that stop,
fetched live from the agency that holds it; every lookup is decided by written policy, logged
in a tamper-evident ledger and visible to the citizen concerned.

## Problem
- Saint Lucia has the pieces — NAF digital identity (launched 26 Feb 2026), digiGov licence and
  vehicle services, an RSLPF data system (Dec 2024), ECSC e-Litigation (criminal module since
  9 Oct 2024), SLUHIS — but they do not meet at the roadside.
- The section 179 demerit point system has never been applied because no shared ledger links
  police, the Licensing Authority and the court. Officials announced activation in March 2026.
- Road harm is high: 3,815 reported accidents, 189 extremely serious and 10 fatal, Jan–Sep 2025.
- A "see everything" police database would breach data-protection principles and become a
  single target for attackers.

## Users and jobs
| User | Job to be done | Sees |
| --- | --- | --- |
| Traffic or patrol officer | Decide in seconds whether a driver and vehicle are legal | Status card for the stop |
| Dispatcher | Confirm or clear a warrant or stolen-vehicle match before officers act | Match detail from the source agency |
| Investigator | Pursue an open case | Case-gated criminal, vehicle and accident history |
| Crash investigator | Reconstruct a collision | Incident-gated accident, insurance and inspection history |
| Licensing Authority officer | Apply section 179 lawfully | Points ledger and proposed actions to decide |
| Court (system) | Receive tickets, record payments and outcomes | Tickets and court timeline |
| EMS or fire crew | Treat a casualty safely | Opted-in emergency card at an active incident |
| Citizen | Know their record and who looked at it | My Record and access log |
| Oversight (Data Protection Commissioner) | Detect and deter misuse | Access-log metadata, alerts, reports |

## Scope

**In this build (M1–M7)** — the pitch demo on a production-shaped architecture:
roadside check, hit confirmation, investigation and crash queries, e-tickets, payments (simulated),
court referral and outcomes, section 179 demerit engine with officer decisions, section 107
unpaid fines, citizen My Record and access log with deferrals, emergency card, oversight anomalies
and monthly report, offline bundle, web screens for every role, mock agencies, synthetic data.

**Not in this build:** real agency integrations, X-Road Security Servers, NAF production
integration, native Kotlin app, WebAuthn device enrolment, ISO 18013-5 digital licence (R19),
analytics (R20), plate-recognition cameras, OECS cross-border checks, production hosting.

## Programme phases (estimates, from the first ministerial meeting)
| Phase | Months | Content | Gate to pass |
| --- | --- | --- | --- |
| 0 Discover and demo | 0–3 | Legal path, MoUs, this demo, baseline fine data | Minister sponsors the pilot; data-sharing MoUs signed |
| 1 Pilot, one division | 4–12 | Roadside Verify, demerit ledger, hit confirmation, oversight, citizen access log | Oversight body operating; pilot targets met; penetration test passed |
| 2 National rollout | 13–18 | All divisions, My Record, online payment, court timeline, insurer and garage feeds | Health consent approved; government wallet ready |
| 3 Extend | 19–30 | Emergency card, digital licence, analytics; plate recognition and OECS only after enabling law | — |

## Success measures for the pilot (proposed; confirm baselines in Phase 0)
- Median roadside check under 2 s; status card available for 99% of checks during service hours.
- Share of tickets paid within the payment period rises against the Phase 0 baseline.
- 100% of lookups appear in the ledger and in the citizen's access log (investigative lookups after the hold or deferral ends).
- Zero detectable withheld entries in the AC23 leak suite; every deferral visible to oversight.
- Every anomaly alert reviewed within 10 working days.
- Zero health-data disclosures to police roles (structural, verified by test and audit).

## Commercial guardrails
Fixed-price pilot, then annual licence and support or build-operate-transfer; perpetual licence
with source escrow; product IP retained by Limah Innovations; no share of fines.

## Open questions
| # | Question | Owner |
| --- | --- | --- |
| Q1 | Which ministers or officials can be met first? | Kelvin |
| Q2 | Approach the RSLPF system's developer as a partner? | Kelvin |
| Q3 | Which established integrator for World Bank-funded bids? | Kelvin |
| Q4 | Keep the name TRUSTLINE? | Kelvin |
| Q5 | Who funds Phase 0 and the demo? | Kelvin |
| Q6 | ~~Confirm disclosure deferrals~~ — approved by Kelvin on 2 Nov 2026 (ADR 0011); durations and legal basis go to counsel | Counsel |
| Q7 | Digital licence on PWEV credentials or the government's planned secure wallet? | Kelvin |
