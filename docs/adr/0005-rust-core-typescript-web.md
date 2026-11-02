# ADR 0005 — Rust for the core, TypeScript/Next.js for the web

- Status: Accepted
- Date: 2026-11-02
- Deciders: Kelvin Wilson Antoine (owner); drafted with Claude

## Context
Kelvin asked for Rust for maintainability and sustainability. The web front end should use tools Kelvin already works with.

## Decision
Rust (edition 2024) for every crate that handles identifiers, policy, the ledger, the demerit engine and offline bundles. Next.js App Router with TypeScript strict for the screens; the web app holds no business rules.

## Consequences
Two toolchains; memory safety and strong types where the risk is; fast UI iteration where the risk is low.

## Alternatives rejected
All-TypeScript backend (rejected: weaker guarantees for security-critical code). Supabase/Vercel for production (rejected: data sovereignty; production belongs in the government data centre).
