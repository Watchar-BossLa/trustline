# ADR 0010 — Officer app: PWA in the demo, native Kotlin with a Rust core in the pilot

- Status: Accepted
- Date: 2026-11-02
- Deciders: Kelvin Wilson Antoine (owner); drafted with Claude

## Context
The demo must run on any phone in a meeting. Production needs NFC (digital licences), hardware-backed keys, managed devices and reliable offline mode.

## Decision
This build ships an installable PWA (QR scan of synthetic demo cards and manual entry). trustline-offline has no async runtime and a UniFFI-ready API so the pilot's Kotlin app can use the same Rust code for bundle verification.

## Consequences
Plate OCR and MRZ scanning arrive with the native app. The PWA's offline storage is a demo-grade compromise (threat T9 accepted for synthetic data only).

## Alternatives rejected
Native app now (rejected: slows the demo, needs device management). Cross-platform frameworks (deferred decision for the pilot).
