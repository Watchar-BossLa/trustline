# ADR 0002 — X-Road as the production exchange; X-Road-shaped mocks in the demo

- Status: Accepted
- Date: 2026-11-02
- Deciders: Kelvin Wilson Antoine (owner); drafted with Claude

## Context
Agency-to-agency exchange needs signed, encrypted, logged messages. X-Road is proven at national scale (Estonia, Finland, Iceland and others) and fits the CARDTP interoperability framework. Running X-Road Security Servers is out of reach for a demo build.

## Decision
Adapters send X-Road REST headers (X-Road-Client, X-Road-Service, X-Road-Id, X-Road-UserId, X-Road-Issue) to services/mock-agencies over HTTPS/JSON behind one AgencyAdapter trait. The pilot replaces the transport with X-Road Security Servers or the CARDTP interoperability layer without changing the broker.

## Consequences
The demo exercises the message shape but not X-Road's PKI and mTLS (threat T13 deferred to pilot).

## Alternatives rejected
Rebuilding an exchange layer in Rust (rejected: years of work, worse assurance). Direct database links to agencies (rejected: no audit, tight coupling).
