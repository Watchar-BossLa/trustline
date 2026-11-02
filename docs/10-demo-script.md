# 10 — Demo script (pitch meeting, about 8 minutes)

Audience: the minister, the Division of Public Sector Modernization, RSLPF and the Division of
Transport. The story: *one stop, one law delivered, one citizen who can see who looked.*
Everything shown is synthetic; say so at the start.

Setup (before the meeting): `make demo` on a laptop; open three browser windows — officer
(phone-sized), Licensing/oversight (desktop), citizen (phone-sized). Print the synthetic demo
cards (QR codes for S2, S6 and S9) from `apps/web/public/demo-cards.pdf`.

The Playwright test `apps/web/e2e/demo-flow.spec.ts` runs steps 1–8 automatically (AC17).

| Step | Screen | Action | What to say |
| --- | --- | --- | --- |
| 1 | Officer (OFF-101) | Reason "Traffic stop" → scan S2's card | "The officer sees what the law allows for this stop — licence suspended, two unpaid tickets, vehicle insured. Nothing else. Not health, not criminal history." Point at the sources row: one agency slow → shown as unknown, never guessed. |
| 2 | Officer | Scan plate SYN-PC 0909 (S4's car) | "A stolen-vehicle match shows as UNCONFIRMED. Dispatch must confirm with the source before anyone acts — no wrongful arrests from stale data." Switch to dispatch, confirm. |
| 3 | Officer | Stop S6 → issue SPEED-20 ticket | "The ticket is digital. The driver gets a QR receipt with the stop reference." |
| 4 | Citizen (S6) | Pay the ticket (simulated) | "Paying is a guilty plea. Points are recorded from Schedule 2 automatically." |
| 5 | Licensing (LIC-501) | Open the queue → confirm the proposed 6-month suspension | "Section 179 has waited years for this ledger. The system proposes; your officer decides. Back on the road, the card now says SUSPENDED." Re-scan S6 on the officer screen. |
| 6 | Citizen (S8) | Open "Who viewed my data" | "Every lookup is visible to the citizen — agency, badge, reason, time. Five lookups by the same officer with no stop record." |
| 7 | Oversight (DPC-701) | Open alerts → repeat_subject alert → review | "Oversight sees it too, automatically. The ledger is tamper-evident; its fingerprints are published monthly." Show ledger status = verified. |
| 8 | EMS (EMS-601) | Active incident → scan S9 | "At a crash, a paramedic sees the emergency card S9 chose to share — blood group, allergy, asthma. A police officer trying the same gets nothing." Show the denied attempt in the ledger. |

Close (30 seconds): "It runs on the infrastructure CARDTP is already building, gives every
driver a reason to sign up for NAF, delivers section 179 — and it is built so that it cannot
become a surveillance database. We propose a one-division pilot."

Note on the banner: every screen shows "Legal values pending verification" until counsel confirms
the Schedule 2 points and fixed penalties. Mention it; it shows the discipline, not a weakness.
