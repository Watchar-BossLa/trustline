# 07 — Privacy and legal basis

**Not legal advice.** This is a working register for Saint Lucian counsel and the Data Protection
Commissioner (or the interim oversight body). Every entry marked "to confirm" needs a lawyer's view
before the pilot. The build treats all legal values as configuration with `verified: false` (HL11).

## Legal landscape (as found on 2 Nov 2026)

| Instrument | Relevance | Status found |
| --- | --- | --- |
| Data Protection Act, Act 11 of 2011, amended by Act 2 of 2015 | Principles, sensitive data (sections 35–36), health (37), exemptions (Part 6), data-subject rights (Part 5), Commissioner (Part 2, sections 5–31) | Partly in force since 31 Jan 2023 (S.I. 4/2023): Part I, sections 32–43, Part VI, Schedule 2(a)–(g). The Commissioner provisions are not in that commencement list |
| Motor Vehicles and Road Traffic Act — section 179 and Schedule 2 | Demerit points, notices, interviews, suspensions, appeals | In the 2023 Revised Laws; the online copy is labelled "not yet authenticated through a Commencement Order"; Schedule 2 text garbled online |
| Same Act — section 107 | Disqualification for unpaid fines (30 days after proceedings end; until paid) | As above |
| Ticketable Offences Regulations (S.I. 20/2006; 21/2015; 46/2015) | Ticket form and fixed penalties | Schedule not readable online; penalties must be supplied |
| Computer Misuse Act; Electronic Transactions Act; Evidence Act | Misuse offences; electronic records and signatures as evidence | Referenced by government in 2020; check applicability |
| Constitution of Saint Lucia | Protection from arbitrary search and privacy of property | Counsel to review proportionality |
| CARDTP legal-framework consultancy (2026) | Government is modernising electronic-transactions law | Track outcomes |

## Processing register (draft)

| Processing | Controller (proposed) | Purpose | Legal basis (to confirm) | Data | Recipients |
| --- | --- | --- | --- | --- | --- |
| Roadside status card | RSLPF | Enforcing road traffic law at stops | Statutory functions under the Motor Vehicles and Road Traffic Act and police powers; DPA Part 6 exemptions for crime prevention to confirm | Licence status, vehicle, insurance, inspection, unpaid tickets, flags, court-pending flag | The officer at the stop |
| Hit confirmation | RSLPF | Avoid action on stale matches | As above | Flag references | Dispatch |
| Investigation and crash queries | RSLPF | Investigating offences and collisions | As above, case- or incident-bound | Criminal, vehicle, accident, insurance, inspection history | Assigned investigator |
| E-tickets and payments | RSLPF and the Court Office | Issuing and settling fixed penalties | Ticketable Offences Regulations | Identifiers (encrypted), offence, location | Court, Licensing Authority |
| Demerit ledger and licence actions | Licensing Authority (Division of Transport) | Section 179 and 107 | Statute | Convictions, points, decisions | Driver; Licensing Authority; police (status only) |
| Emergency card | Ministry of Health | Safe treatment at incidents | Explicit consent (opt-in) — sensitive data | Blood group, allergies, critical conditions, contact | EMS responder at the incident |
| Access ledger and citizen access log | Department of the Public Service (system operator) with each agency | Accountability and transparency | Statutory duty of care / DPA principles; to confirm | Metadata and subject keys | Citizen; oversight |
| Oversight alerts and reports | Data Protection Commissioner or interim body | Detect misuse | To confirm | Metadata, subject keys, aggregates | Oversight; public (aggregates only) |

TRUSTLINE (and Limah Innovations as vendor) would act as **processor** for the agencies; a
data-processing agreement is required.

## Privacy by design in this build

| Principle | How |
| --- | --- |
| Purpose limitation | Reason codes on every request; Cedar per field group; references validated |
| Data minimisation | Status card shows bands and flags, not histories; policy before fetch |
| Storage limitation | No agency master records; retention proposals in rules/retention.yaml |
| Integrity and confidentiality | Encrypted identifiers; keyed hashes; tamper-evident ledger; TLS |
| Transparency | Citizen access log; monthly public report |
| Accountability | Ledger, oversight console, decisions recorded with officer and reason |
| Special categories | Health data only via opt-in emergency card, EMS only; police excluded by policy |

## Disclosure deferrals (decision D4, open question Q6)

Showing every lookup to the citizen can tip off a suspect. The design allows an investigator to
request a **time-limited deferral** for a specific ledger entry tied to an open case; a different
officer with the supervisor role must approve; maximum 90 days per approval (configurable);
oversight sees every deferral and must acknowledge it; the entry appears in the citizen's log
automatically at expiry, marked with the deferral date. The citizen's log never reveals that a
deferral exists while it is active. Counsel should confirm the legal basis and maximum duration.

## Data-subject rights (to design with counsel)
Access: the access log and My Record cover most requests; formal subject-access requests for
police records stay with RSLPF. Rectification: disputes route to the owning agency. Objection
and erasure: limited for law-enforcement processing; ledger entries are never erased (HL8).

## DPIA starter — questions counsel must answer before the pilot
1. Which DPA provisions apply while Part 2 (Commissioner) is not commenced, and who oversees?
2. Legal basis for each processing line above, and the Part 6 exemptions relied on.
3. Lawfulness of showing officer badge numbers to citizens (staff privacy vs accountability).
4. Deferral legal basis and maximum duration.
5. Retention periods (rules/retention.yaml).
6. Emergency-card consent wording and withdrawal process.
7. Whether section 179 can operate on electronically recorded convictions and notices, and
   whether registered-mail notices (section 107) can be supplemented by electronic notice.
8. Data-processing agreement terms, hosting location and access by the vendor.
