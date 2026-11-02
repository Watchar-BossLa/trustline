# ADR 0006 — Development tokens in the demo; WebAuthn and device attestation in the pilot

- Status: Accepted
- Date: 2026-11-02
- Deciders: Kelvin Wilson Antoine (owner); drafted with Claude

## Context
The demo needs quick persona switching. Production needs strong officer authentication bound to managed devices.

## Decision
DEV_AUTH issues short-lived tokens for synthetic personas and is refused when TRUSTLINE_ENV=production (tested). Tokens are bound to a device id. The pilot uses WebAuthn passkeys with Android device attestation, and NAF for citizens.

## Consequences
Threat T12 (token replay) is deferred to the pilot. The persona switcher is visible only with DEV_AUTH on.

## Alternatives rejected
Shared passwords (rejected). Building NAF-equivalent identity (rejected: NAF exists).
