# Architecture decision records

| ADR | Decision |
| --- | --- |
| [0001](0001-federated-exchange-not-central-database.md) | Federated, purpose-bound exchange instead of a central database |
| [0002](0002-xroad-exchange.md) | X-Road as the production exchange; X-Road-shaped mocks in the demo |
| [0003](0003-cedar-policy-engine.md) | Cedar for access policy, per field group |
| [0004](0004-tamper-evident-ledger.md) | Append-only, hash-chained, signed ledger with published checkpoints |
| [0005](0005-rust-core-typescript-web.md) | Rust for the core, TypeScript/Next.js for the web |
| [0006](0006-demo-auth-and-pilot-auth.md) | Development tokens in the demo; WebAuthn and device attestation in the pilot |
| [0007](0007-no-health-data-for-police.md) | Police never see health data; opt-in emergency card for EMS only |
| [0008](0008-human-decision-for-licence-actions.md) | Software proposes licence actions; a Licensing Authority officer decides |
| [0009](0009-keyed-hash-subject-identifiers.md) | Keyed hashes for subject identifiers; encryption for tickets |
| [0010](0010-officer-app-pwa-now-kotlin-later.md) | Officer app: PWA in the demo, native Kotlin with a Rust core in the pilot |
| [0011](0011-leak-proof-disclosure-deferrals.md) | Leak-proof, accountable disclosure deferrals |
