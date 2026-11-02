# ADR 0008 — Software proposes licence actions; a Licensing Authority officer decides

- Status: Accepted
- Date: 2026-11-02
- Deciders: Kelvin Wilson Antoine (owner); drafted with Claude

## Context
Section 179 gives suspension decisions to the Licensing Authority, and automated suspensions would be hard to defend and to correct.

## Decision
The demerit engine is pure and only proposes actions. A licence action is created only from a proposal confirmed by an authorised licensing_officer, enforced by a database trigger, with the appeal deadline recorded.

## Consequences
Adds a human step to every suspension (also a training and staffing need for the Authority). Errors in rules or data are caught before effect.

## Alternatives rejected
Automatic suspensions at thresholds (rejected: HL5, legal and fairness risk).
