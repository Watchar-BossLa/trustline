# ADR 0003 — Cedar for access policy, per field group

- Status: Accepted
- Date: 2026-11-02
- Deciders: Kelvin Wilson Antoine (owner); drafted with Claude

## Context
Permissions depend on role, purpose, references, device and consent. Hard-coding them in Rust would hide them from auditors and lawyers.

## Decision
Access is decided by Cedar policies (policies/trustline.cedar) validated against a schema at startup. The unit of permission is the field group. Guardrails are forbid rules. Intended permissions live separately in policies/expected-permissions.yaml and a full matrix test compares the two.

## Consequences
Policy changes are reviewable text with a test; the policy-auditor subagent and Kelvin approve changes. Cedar is written in Rust and embeds directly.

## Alternatives rejected
OPA/Rego (rejected: extra runtime, less static validation). Hand-written authorisation code (rejected: not auditable).
