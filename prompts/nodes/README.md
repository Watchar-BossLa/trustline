# Node prompts (rendered — do not hand-edit)

Rendered from graphs/build.graph.yaml and spec/registry.yaml by tools/render_node_prompts.py.

| # | Node | Kind | Implements |
| --- | --- | --- | --- |
| 01 | [plan_build](01-plan_build.md) | prompt | M1, M2, M3, M4, M5, M6, M7 |
| 02 | [verify_plan](02-verify_plan.md) | verifier | M1 |
| 03 | [approve_plan](03-approve_plan.md) | human | M1 |
| 04 | [m1_scaffold](04-m1_scaffold.md) | prompt | R12, T1.1, T1.2, T1.3, T1.4 |
| 05 | [m1_schema](05-m1_schema.md) | prompt | R4, R12, T1.5 |
| 06 | [m1_seed](06-m1_seed.md) | prompt | T1.6 |
| 07 | [verify_m1](07-verify_m1.md) | verifier | V1.1, V1.2, V1.3, R12 |
| 08 | [fix_m1](08-fix_m1.md) | prompt | M1 |
| 09 | [m2_policy](09-m2_policy.md) | prompt | R2, R3, T2.1, T2.2, AC3, AC4 |
| 10 | [m2_ledger](10-m2_ledger.md) | prompt | R5, T2.3, T2.4, AC5, AC6 |
| 11 | [verify_m2](11-verify_m2.md) | verifier | V2.1, V2.2, V2.3, AC3, AC4, AC5, AC6 |
| 12 | [fix_m2](12-fix_m2.md) | prompt | M2 |
| 13 | [m3_agencies](13-m3_agencies.md) | prompt | R4, T3.1, T3.2 |
| 14 | [m3_broker](14-m3_broker.md) | prompt | R1, R9, R11, T3.3, T3.4, T3.5, AC1, AC2, AC11, AC13, AC19 |
| 15 | [m3_offline](15-m3_offline.md) | prompt | R14, T3.6, AC15 |
| 16 | [verify_m3](16-verify_m3.md) | verifier | V3.1, V3.2, V3.3, AC1, AC2, AC11, AC13, AC15, AC19 |
| 17 | [fix_m3](17-fix_m3.md) | prompt | M3 |
| 18 | [m4_tickets](18-m4_tickets.md) | prompt | R7, R13, R18, T4.1, T4.2, T4.3, AC14, AC21 |
| 19 | [m4_demerit](19-m4_demerit.md) | prompt | R8, T4.4, T4.5, T4.6, AC8, AC9, AC10 |
| 20 | [verify_m4](20-verify_m4.md) | verifier | V4.1, V4.2, V4.3, AC8, AC9, AC10, AC14, AC21 |
| 21 | [fix_m4](21-fix_m4.md) | prompt | M4 |
| 22 | [m5_citizen](22-m5_citizen.md) | prompt | R6, R15, R16, R21, R22, T5.1, T5.2, T5.3, AC7, AC16, AC20, AC23, AC24 |
| 23 | [m5_oversight](23-m5_oversight.md) | prompt | R10, T5.4, T5.5, AC12 |
| 24 | [verify_m5](24-verify_m5.md) | verifier | V5.1, V5.2, V5.3, AC7, AC12, AC16, AC20, AC23, AC24 |
| 25 | [fix_m5](25-fix_m5.md) | prompt | M5 |
| 26 | [m6_web](26-m6_web.md) | prompt | R17, T6.1, T6.2, T6.3, T6.4, T6.5, AC17, AC22 |
| 27 | [verify_m6](27-verify_m6.md) | verifier | V6.1, V6.2, V6.3, AC17, AC22 |
| 28 | [fix_m6](28-fix_m6.md) | prompt | M6 |
| 29 | [m7_security](29-m7_security.md) | prompt | R11, R12, T7.1, T7.2, T7.3, AC13, AC18 |
| 30 | [m7_demo](30-m7_demo.md) | prompt | T7.4, T7.5, AC17 |
| 31 | [verify_m7](31-verify_m7.md) | verifier | V7.1, V7.2, V7.3, AC13, AC17, AC18 |
| 32 | [fix_m7](32-fix_m7.md) | prompt | M7 |
| 33 | [approve_demo](33-approve_demo.md) | human | M7, AC17 |
| 34 | [apply_demo_feedback](34-apply_demo_feedback.md) | prompt | M7 |

Terminal nodes (no prompt; the orchestrator performs them):

- `done` (complete): Write hef_state as complete, append the run's lessons to tasks/lessons.md and stop.
- `blocked` (blocked): Write hef_state with the blocker and the exact question for Kelvin, append lessons, and stop.
- `aborted` (failed): Write hef_state with the failure, the last node and its exit, append lessons, and stop.
