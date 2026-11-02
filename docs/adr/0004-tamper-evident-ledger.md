# ADR 0004 — Append-only, hash-chained, signed ledger with published checkpoints

- Status: Accepted
- Date: 2026-11-02
- Deciders: Kelvin Wilson Antoine (owner); drafted with Claude

## Context
Citizens and oversight must be able to trust that every access is recorded and that records were not altered after the fact.

## Decision
Every ledger-scoped request writes one entry: RFC 8785 canonical JSON, SHA-256 chained to the previous entry, Ed25519-signed. Signed Merkle checkpoints every 1,000 entries or 15 minutes; roots published in the monthly report. Database triggers and privileges forbid UPDATE, DELETE and TRUNCATE.

## Consequences
Writes are serialised (one chain); throughput target > 300 entries/s is far above pilot need. Retention is by signed export and partition detach, never row deletion.

## Alternatives rejected
Plain audit table (rejected: silently editable). Public blockchain (rejected: cost, privacy, unnecessary; Merkle roots give the same tamper evidence).
