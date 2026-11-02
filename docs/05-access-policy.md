# 05 — Access policy

Access is decided per **field group** by Cedar (`policies/trustline.cedar`, schema
`policies/trustline.cedarschema`). Default is deny; `forbid` always beats `permit`. The intended
permissions are written by hand in `policies/expected-permissions.yaml`; `tools/policy_matrix.py`
evaluates the policy over every role × purpose × field group × context-flag combination
(170,368 decisions) and fails if the two disagree.

**Status on 2 Nov 2026:** the policy validates against the schema (`cedar` CLI 4.14) and the
full matrix matches the intended permissions. A mutation test (adding a criminal-record permit
for traffic officers) was caught; adding the emergency card to the roadside permit was blocked by
the health guardrails, as designed.

## Expected permissions

A row allows exactly the listed groups when every flag in "Requires" is true. Everything else is denied.

| Role | Purpose | Requires | Allowed field groups |
| --- | --- | --- | --- |
| traffic_officer, patrol_officer, supervisor | TS, CP | device_attested | identity_basic, licence_status, points_band, vehicle_registration, insurance_status, inspection_status, compliance_summary, alerts_summary, court_flag |
| dispatcher | DSP | device_attested | identity_basic, alerts_summary |
| investigator | INV | device_attested, case_ref_valid | identity_basic, licence_status, alerts_summary, criminal_record, vehicle_history, accident_history |
| investigator | WAR | device_attested, warrant_ref_valid | identity_basic, alerts_summary |
| crash_investigator | CRASH | device_attested, incident_active | identity_basic, licence_status, vehicle_registration, accident_history, insurance_detail, inspection_history |
| licensing_officer | LIC | device_attested | identity_basic, licence_status, points_detail, ticket_detail, court_timeline |
| ems_responder | EMS | device_attested, incident_active, emergency_consent | identity_basic, emergency_card |
| oversight_analyst | AUD | device_attested | ledger_metadata |
| court_system (service) | CRT | — | ticket_detail, court_timeline |
| citizen | CIT | is_self | identity_basic, licence_status, points_detail, vehicle_registration, insurance_status, inspection_status, compliance_summary, ticket_detail, court_timeline, access_log_own |

## Guardrails (forbid rules)

| Id | Rule | Why |
| --- | --- | --- |
| G1 | `cross_domain_profile` is forbidden to everyone | HL1 — no "everything about a person" view |
| G2 | `health_record` is forbidden to everyone | Health records stay in SLUHIS |
| G3 | Any health-domain group is forbidden to every police role, whatever the purpose or flags | HL2 — a person holding a police role and an EMS role still cannot read health data |
| G4 | The only health data anyone can read is `emergency_card`, by an EMS responder, purpose EMS, active incident, consent, attested device | Opt-in emergency card only |
| G5, G6 | Officers on unattested devices are allowed nothing | Device binding |
| G7 | A citizen can only read their own record, purpose CIT | Self-access only |

## Operations

| Action | Who | Resource |
| --- | --- | --- |
| IssueTicket | traffic_officer, patrol_officer, supervisor | Capability `tickets` |
| ConfirmHit | dispatcher (DSP) | Capability `hits` |
| DecideLicenceAction | licensing_officer (LIC) | Capability `licence_actions` |
| RequestDeferral | investigator (INV) | Capability `deferrals` |
| ApproveDeferral | supervisor (INV); never the requester (database CHECK) | Capability `deferrals` |
| AcknowledgeDeferral, ReviewAlert | oversight_analyst (AUD) | Capabilities `deferrals`, `alerts` |
| RecordCourtOutcome, RecordPayment | court_system service (CRT) | Capability `court_records` |

## How the API builds the context

| Flag | Set true when |
| --- | --- |
| `device_attested` | The request's device id is enrolled, active and attested for that officer |
| `case_ref_valid` | The police adapter confirms the case is open (pilot: and assigned to the officer's unit) |
| `warrant_ref_valid` | The police adapter confirms the warrant is active |
| `incident_active` | The police or EMS dispatch adapter confirms an active incident with that reference |
| `emergency_consent` | `ems.emergency_card_consent` has an un-withdrawn opt-in for the subject |
| `is_self` | The citizen's NAF subject key equals the requested subject key |

`purpose` is the request's reason code. Reference checks happen before policy evaluation; a
failed check sets the flag false (it does not error), so the decision and the ledger entry record
an ordinary deny.

## Changing the policy

1. Change the intent first (`policies/expected-permissions.yaml`) and say why in the decision log.
2. Change `policies/trustline.cedar`.
3. Run `cedar validate --schema policies/trustline.cedarschema --policies policies/trustline.cedar`
   and `python3 tools/policy_matrix.py`. Both must pass.
4. Run the `policy-auditor` subagent. Policy changes need Kelvin's approval and, before the pilot,
   the Data Protection Commissioner's.
