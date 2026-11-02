# 09 — Synthetic data

All data in this build is synthetic (HL6). The generator (`trustline-cli seed`, node `m1_seed`)
is deterministic: the same seed (default `TRUSTLINE_SEED=20261102`) produces byte-identical
fixtures for TRUSTLINE tables and for `services/mock-agencies/fixtures/`.

## Rules for every generated record
- Identifiers start with `SYN`: NIC `SYN-NIC-000001`…, licence `SYN-DL-000001`…, plates
  `SYN-PA 0001` style, tickets `SYN-T-2026-000001`, cases `SYN-CASE-2026-0001`, incidents
  `SYN-INC-2026-0001`, warrants `SYN-WAR-2026-0001`.
- Names come from a fixed fictional list in `crates/cli/src/seed/names.rs`, combined so that
  every displayed name ends with "(SYNTHETIC)" in the UI.
- Photos are generated placeholders (initials on a coloured tile); never photos of real people.
- Phone numbers use the reserved fictional pattern `+1 758 555 01xx`.
- Addresses are not generated (not needed by any field group).

## Volumes

| Entity | Count |
| --- | --- |
| Citizens | 500 |
| Driver's licences | 400 (5% expired, 2% suspended at source) |
| Vehicles | 450 (8% insurance expired, 10% inspection expired) |
| Historic tickets | 300 over 36 months (70% paid, 20% referred, 10% unpaid) |
| Court cases | 60 |
| Active warrants | 5 |
| Stolen vehicles | 4 |
| Emergency-card opt-ins | 40 |
| Officers | 9 named demo officers + 30 background officers |

## Demo personas

| Id | Name (fictional) | Identifiers | Scenario | Used in |
| --- | --- | --- | --- | --- |
| S1 | Anya Florent | SYN-NIC-000001 · SYN-DL-000001 · SYN-PA 1001 | Everything valid | AC1 baseline, demo step 1 |
| S2 | Darnell Vieux-Fort | SYN-NIC-000002 · SYN-DL-000017 · SYN-PB 4521 | 15 points in force; confirmed 6-month suspension active; 2 unpaid tickets (EC$400 illustrative) | AC1, AC20 |
| S3 | Mireille Castagne | SYN-NIC-000003 · SYN-PA 1187 | Insurance and inspection expired | Demo step 1 variant |
| S4 | Odile Marquis | SYN-NIC-000004 · SYN-PC 0909 | Owner reported vehicle stolen; flag at source | AC11 |
| S5 | Rocco Delaire | SYN-NIC-000005 · SYN-DL-000055 | Active warrant SYN-WAR-2026-0003 | AC11 |
| S6 | Keisha Morne-Rouge | SYN-NIC-000006 · SYN-DL-000066 · SYN-PB 6606 | 8 points in the last year (2(b) 6 + 4(b) 2); receives SPEED-20 ticket → 15 → `suspend_6m` | AC8, AC10, demo steps 3–5 |
| S7 | Bertrand Soufrière | SYN-NIC-000007 · SYN-DL-000077 | 12 points over 2 years, 6 in the last year → `notice_11_13` | AC9 |
| S8 | Celine Anse-La-Raye | SYN-NIC-000008 · SYN-DL-000088 | Looked up 5 times in 24 h by OFF-102 with no stop record; one INV lookup under an approved deferral | AC7, AC12, demo steps 6–7 |
| S9 | Jonah Praslin | SYN-NIC-000009 | Opted in to emergency card (blood group O+, penicillin allergy, asthma) | AC16, demo step 8 |
| S10 | Petra Dennery | SYN-NIC-000010 · SYN-DL-000100 | Court fine EC$800 unpaid 31 days after proceedings | AC14 |

## Demo officers and principals

| Badge | Name (fictional) | Roles | Unit | Device |
| --- | --- | --- | --- | --- |
| OFF-101 | PC Joel Marchand | traffic_officer | Gros Islet Traffic | attested |
| OFF-102 | PC Ryan Lafitte | traffic_officer | Castries Traffic | attested (misuse persona) |
| DSP-201 | Sgt Nadia Fontaine | dispatcher | Control Room | attested |
| INV-301 | DC Tessa Grandval | investigator | CID | attested |
| CRS-351 | Sgt Ian Bexon | crash_investigator | Road Safety and Traffic Investigations | attested |
| SUP-401 | Insp Marcus Belair | supervisor | CID | attested |
| LIC-501 | Grace Monplaisir | licensing_officer | Division of Transport | attested |
| EMS-601 | Leon Choc | ems_responder | Fire Service EMS | attested |
| DPC-701 | Ruth Calixte | oversight_analyst | Data Protection oversight | attested |
| — | court-traffic-part | court_system (service) | District Court Traffic Part | — |

Active references seeded at the mock police agency: case SYN-CASE-2026-0001 (open, CID),
incident SYN-INC-2026-0007 (active crash, EMS dispatched), warrant SYN-WAR-2026-0003 (active).

## Determinism check (V1.3)
`make seed && sha256sum services/mock-agencies/fixtures/*.json > /tmp/a; make seed && sha256sum … > /tmp/b; diff /tmp/a /tmp/b` must be empty.
