# ADR 0007 — Police never see health data; opt-in emergency card for EMS only

- Status: Accepted
- Date: 2026-11-02
- Deciders: Kelvin Wilson Antoine (owner); drafted with Claude

## Context
The original concept placed medical records in the roadside view. Health data is sensitive personal data and has no role in a traffic stop.

## Decision
Health-domain field groups are forbidden to every police role under every purpose (Cedar G3), and only the emergency_card group is readable, by an EMS responder at an active incident with the person's opt-in consent (G4). Content stays at the Ministry of Health adapter.

## Consequences
Some value at crash scenes is preserved with consent; the police exposure risk is removed structurally and proven by the matrix test.

## Alternatives rejected
Full medical records at stops (rejected). No health data at all (rejected: loses a real life-saving use at crashes).
