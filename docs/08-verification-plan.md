# 08 — Verification plan

"Done" means proven by an automated test or gate, not asserted. Every acceptance criterion in
`spec/registry.yaml` has at least one test whose name contains its id (for example
`ac9_suspend_6m_when_10_points_in_a_year`). Verifier nodes in the graph run the commands below.

## Quality gates (`make verify`)

| Gate | Command (created in M1) | Pass condition |
| --- | --- | --- |
| Format | `cargo fmt --all --check` | No diff |
| Lint | `cargo clippy --workspace --all-targets -- -D warnings` | Zero warnings |
| Tests | `cargo test --workspace` | All pass |
| Supply chain | `cargo deny check` · `pnpm -C apps/web audit --prod` | No high/critical advisories; licences allowed |
| Secrets | `gitleaks detect --redact` (full history) | No findings |
| Policy | `cedar validate --schema policies/trustline.cedarschema --policies policies/trustline.cedar` · `python3 tools/policy_matrix.py` | Valid; matrix matches intent |
| API | OpenAPI lint · response contract tests | Valid; all responses conform |
| Database | migrations apply to empty DB; `pg_dump --schema-only` equals `db/schema.sql` load; `make db-test` runs `db/tests/disclosure_test.sql` | No drift; ALL DISCLOSURE TESTS PASSED |
| Graph | `python3 tools/graph_lint.py` | OK |
| Web | `pnpm -C apps/web lint && pnpm -C apps/web typecheck && pnpm -C apps/web test` | All pass |
| E2E | `pnpm -C apps/web test:e2e` (Playwright demo flow + axe) | Pass; no serious/critical axe violations |

## Acceptance criteria → tests

| AC | Test location | Notes |
| --- | --- | --- |
| AC1 | `crates/api/tests/roadside.rs`; `make loadtest-smoke` | Exact field-group set for TS; p95 < 2 s over 200 checks |
| AC2 | `crates/api/tests/roadside.rs` | Missing, unknown reason code; unattested device |
| AC3 | `crates/policy/tests/matrix.rs`; `tools/policy_matrix.py` | Full matrix; health isolation |
| AC4 | `crates/api/tests/investigations.rs` | Case reference required; carried to ledger |
| AC5 | `crates/ledger/tests/tamper.rs`; `crates/api/tests/schema.rs` | Modify, delete, reorder; app-role privileges |
| AC6 | `crates/api/tests/ledger_coverage.rs` | Counts across all decisions |
| AC7 | `crates/api/tests/citizen.rs` | Visibility within 60 s; hold; release with deferred_until |
| AC8 | `crates/api/tests/flows.rs` | SPEED-20 → paragraph 2(e) points |
| AC9 | `crates/demerit/tests/section_179.rs` | Table below |
| AC10 | `crates/api/tests/flows.rs`; DB trigger test | No effect before decision; SUSPENDED within 60 s after |
| AC11 | `crates/api/tests/hits.rs` | Match and decision entries |
| AC12 | `crates/oversight/tests/rules.rs`; `crates/api/tests/oversight.rs` | S8 misuse scenario; report contents |
| AC13 | `crates/api/tests/contract.rs`; `crates/api/tests/rate_limits.rs` | No cross-domain schema; 429 logged |
| AC14 | `crates/api/tests/flows.rs` | S10 unpaid fine |
| AC15 | `crates/offline/tests/bundle.rs`; `crates/api/tests/offline.rs` | Tamper, unknown key, expiry; offline entries |
| AC16 | `crates/api/tests/ems.rs` | EMS allowed with incident + consent; police denied |
| AC17 | `apps/web/e2e/demo-flow.spec.ts`; `make demo-check` | Fresh clone to passing flow in < 10 min setup |
| AC18 | CI workflow; `crates/api/tests/config.rs`; log-scan test | Gates green; DEV_AUTH guard |
| AC19 | `crates/api/tests/schema.rs`; `crates/api/tests/roadside.rs` | Allowed-table list; agency down → UNKNOWN |
| AC20 | `crates/api/tests/citizen.rs` | Own record; dispute to oversight |
| AC21 | `crates/api/tests/court.rs` | Licensing and citizen see date; roadside sees flag only |
| AC22 | `apps/web/e2e/a11y.spec.ts`; `apps/web/e2e/perf.spec.ts` | axe; 3G throttling < 3 s |
| AC23 | `db/tests/disclosure_test.sql` (`make db-test`); `crates/api/tests/disclosure_leak.rs` | DF1–DF25; S8 vs control S11 response-by-response equality; identical 404s; co-owner; protected officer |
| AC24 | `db/tests/disclosure_test.sql`; `crates/api/tests/deferral_lifecycle.rs` | Approval, lapse, 90-day and 365-day limits, renewal continuity, early release, oversight listing, administrative entries |

## Section 179 and 107 test table (AC9, AC14)

Values come from `rules/demerit-schedule.yaml` (unverified — tests use the file, so a corrected
schedule updates expectations automatically except where a row names a number for clarity).

| # | Given | When | Then | Source |
| --- | --- | --- | --- | --- |
| D1 | No points | SPEED-20 ticket paid | 7 points (2(e)) dated the payment date | s.179(1) |
| D2 | No points | Court convicts, paragraph 3(a) | 6 points dated the conviction | s.179(1) |
| D3 | 6 points recorded | Appeal filed | Points not counted while pending | s.179(2) |
| D4 | Appeal pending | Conviction upheld | Points counted from the original conviction date | s.179(2) |
| D5 | Appeal pending | Conviction overturned | Points removed permanently | s.179(2) |
| D6 | Same incident: 2(e) (7) and 2(a) (4) | Both convicted | Only 7 counted | s.179(3) |
| D7 | Same incident: three offences worth 6 each | All convicted | 12 counted (at most two) | s.179(3) |
| D8 | 6 points recorded 3 years and 1 day ago, nothing since | Evaluate | 0 points in force | s.179(4) |
| D9 | 6 points 2.5 years ago, 2 points 1 year ago | Evaluate | 8 in force (window restarts — interpretation flagged) | s.179(4) |
| D10 | 11 points within 2 years, under 10 in the last year | Evaluate | Proposed `notice_11_13` | s.179(6) |
| D11 | 14 points within 2 years, under 10 in the last year | Evaluate | Proposed `interview_14_17`, no notice | s.179(7) |
| D12 | Interview required | Driver does not attend after 10-day notice | Proposed `suspend_until_compliance` | s.179(8) |
| D13 | 10 points within 1 year | Evaluate | Proposed `suspend_6m`; no interview proposal | s.179(10); design choice |
| D14 | 18 points within 8 months | Evaluate | Proposed `suspend_6m` only (s.179(11) needs more than one year) | s.179(10)-(11) |
| D15 | 18 points spread over 15 months, under 10 in the last 12 | Evaluate | Proposed `suspend_1y` | s.179(11) |
| D16 | Active 1-year suspension | New `suspend_6m` confirmed | Runs concurrently: end = later of the two ends | s.179(12) |
| D17 | 6-month suspension | It ends | All points cleared | s.179(5) |
| D18 | `suspend_until_compliance` lasting 2 weeks | It ends | Points not cleared | s.179(5) |
| D19 | Proposed `suspend_6m` | No decision | Roadside status unchanged | HL5 |
| D20 | Proposed `suspend_6m` | Officer confirms | Licence action active; appeal deadline = decision + 10 days; card SUSPENDED within 60 s | s.179(13); HL5 |
| D21 | Proposed action | Officer rejects with note | No licence action; decision logged | HL5 |
| D22 | Court fine, proceedings concluded 29 days ago, unpaid | Daily job | Nothing proposed | s.107 |
| D23 | Same fine at 30 days | Daily job | Proposed `disqualify_unpaid_fine` (once; idempotent) | s.107 |
| D24 | Disqualification active | Clerk confirms payment | Disqualification ended | s.107 |
| D25 | Any conviction or proposal | Recorded | `rules_version` equals the schedule file hash | HL11 |

Property tests: points in force are never negative; adding a conviction never lowers points in
force before expiry; evaluation is deterministic for the same history and schedule; expired
points never trigger an action.

## Disclosure-control scenarios (AC23, AC24) — `db/tests/disclosure_test.sql`

Passed on 2 Nov 2026 against PostgreSQL 16 with the schema in this pack.

| # | Scenario | Expected |
| --- | --- | --- |
| DF1–DF2 | INV lookups during the 72 h hold | Withheld; suspect's log identical to a control person's |
| DF3 | Supervisor field set to the requester | Refused |
| DF4–DF6 | Active case deferral | INV lookups and the case unit's pretext stop withheld; uninvolved stop visible; logs identical with and without self views |
| DF7 | Vehicle co-owner | Sees nothing while protected |
| DF8 | Paging with limit 1 | Walks only visible entries, full pages |
| DF9 | Deferral request entry | Never appears, even after release |
| DF10–DF12 | Retroactive coverage; deferring a visible entry; approval over 90 days | Refused |
| DF13–DF14 | Renewal while active; renewal after expiry | Continuous withholding; late renewal refused |
| DF15 | Chain beyond 365 days | Refused without a magistrate order; accepted with one |
| DF16–DF20 | Early release by oversight | Entries appear with original times and deferred_until; protected officer shown as agency only; case number withheld; co-owner now sees it |
| DF21–DF23 | Unapproved request | Withholds until it lapses at 72 h; no deferred_until marker |
| DF24 | Rejected request | Stops withholding once the hold ends |
| DF25 | Delete a withheld entry | Refused (ledger is append-only) |

## Performance and resilience

| Measure | Target | How |
| --- | --- | --- |
| Roadside check p95 | < 2 s (compose, 4 cores, 8 GB, mock latency 50–300 ms) | `oha` or k6, 200 checks, 10 concurrent |
| Roadside check with one agency down | Card returned < 1.5 s, that section `unknown` | `MOCK_DOWN=inspection` |
| Ledger write throughput | > 300 entries/s sustained | Bench in `crates/ledger/benches` |
| Officer status card render | < 3 s on Playwright 3G profile | `apps/web/e2e/perf.spec.ts` |

Results are recorded here in M7 (task T7.3).

## Manual verification (node approve_demo)
Kelvin runs `docs/10-demo-script.md` end to end and signs off, or lists changes.
