# ADR 0009 — Keyed hashes for subject identifiers; encryption for tickets

- Status: Accepted
- Date: 2026-11-02
- Deciders: Kelvin Wilson Antoine (owner); drafted with Claude

## Context
The ledger and the citizen log must find a person's entries without storing NIC, licence or plate numbers.

## Decision
SubjectKey = HMAC-SHA-256(pepper, TYPE:normalised value), versioned pepper in the key store (HSM in the pilot). Ledger and log rows hold keys only. Tickets, which are legal records, hold identifiers envelope-encrypted.

## Consequences
Pepper secrecy is critical because identifiers have low entropy (threat T8). Every lookup is attributed to the person's NIC key so the citizen log is one indexed query.

## Alternatives rejected
Plain identifiers (rejected: HL4). Unkeyed hashes (rejected: trivially reversible by enumeration).
