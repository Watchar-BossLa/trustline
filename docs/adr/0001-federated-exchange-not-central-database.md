# ADR 0001 — Federated, purpose-bound exchange instead of a central database

- Status: Accepted
- Date: 2026-11-02
- Deciders: Kelvin Wilson Antoine (owner); drafted with Claude

## Context
The original concept was one online database showing everything about a person, including medical records, to police at a stop. Saint Lucia's Data Protection Act sets purpose-limitation and minimisation principles; a single store of every record would be one breach target for the whole population (Moldova, Oct 2026: about 750,000 people exposed through ID-number lookups).

## Decision
Agency records stay with each agency. TRUSTLINE fetches only the field groups the policy permits for the stated purpose, at query time, and stores only what it creates (tickets, demerit ledger, licence actions, access logs, alerts, consents, disputes).

## Consequences
Each check depends on agency availability, so the card must show UNKNOWN for failed sources. Integration work moves to adapters. The privacy case for the pitch is strong and structural.

## Alternatives rejected
Central national database (rejected: legal, breach and trust risk). Nightly copies of agency registers (rejected: same risks, stale data).
