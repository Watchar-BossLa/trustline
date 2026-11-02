#!/usr/bin/env python3
"""Regenerate the registry-backed sections of TRUSTLINE.hef.md.

Rewrites the text between <!-- BEGIN:spec -->/<!-- END:spec -->,
<!-- BEGIN:execution -->/<!-- END:execution --> and
<!-- BEGIN:verification -->/<!-- END:verification --> from spec/registry.yaml.
Run after any registry change:  python3 tools/sync_hef.py
"""
from __future__ import annotations

import re
from pathlib import Path
from xml.sax.saxutils import escape

import yaml

ROOT = Path(__file__).resolve().parent.parent
HEF = ROOT / "TRUSTLINE.hef.md"


def spec_block(reg: dict) -> str:
    out = ["<hef_specification>", "  <core_requirements>"]
    for r in reg["requirements"]:
        out.append(f'    <requirement id="{r["id"]}" priority="{r["priority"]}" milestone="{r["milestone"]}">'
                   f'{escape(" ".join(r["text"].split()))}</requirement>')
    out.append("  </core_requirements>")
    out += [
        "  <user_flows>",
        '    <flow id="UF1" name="Roadside check">Officer signs in on an enrolled device → picks reason TS or CP → scans the',
        "      driver's ID card or licence QR, or types the plate → TRUSTLINE returns the status card in under 2 s →",
        "      a possible warrant or stolen match shows UNCONFIRMED and prompts a dispatch call → officer issues a",
        "      ticket or lets the driver go → driver receives a QR receipt with the stop's reference.</flow>",
        '    <flow id="UF2" name="Ticket to points">Ticket issued → driver pays online (guilty plea) or the court convicts →',
        "      points recorded from the schedule → thresholds evaluated → proposed action appears in the Licensing",
        "      Authority queue → officer confirms or rejects with a note → if confirmed, the roadside card shows",
        "      SUSPENDED and the driver is notified with the appeal deadline.</flow>",
        '    <flow id="UF3" name="Citizen sees who looked">Citizen signs in with NAF → My Record shows licence, vehicles,',
        "      tickets, points and court dates → Access log lists every lookup (time, agency, badge, reason, case) →",
        "      citizen can dispute an entry, which opens an oversight item.</flow>",
        '    <flow id="UF4" name="Oversight catches misuse">An officer looks up the same person repeatedly with no stop,',
        "      ticket or case → the anomaly rule fires → alert in the oversight console → reviewer records the outcome →",
        "      the monthly transparency report counts it.</flow>",
        '    <flow id="UF5" name="Crash scene emergency card">EMS responder with an active incident scans the casualty\'s ID →',
        "      if the person opted in, the emergency card (blood group, allergies, critical conditions, emergency",
        "      contact) appears → the opening is logged and shown to the citizen.</flow>",
        "  </user_flows>",
        "  <data_model>See db/schema.sql (canonical) and docs/03-data-model.md. TRUSTLINE owns only: officers,",
        "    devices, reason codes, keyed subject references, the access ledger and checkpoints, hits, tickets,",
        "    payments, court referrals, convictions, incidents, proposed and effective licence actions,",
        "    deferrals, disputes, alerts, reports, emergency-card consents and offline-bundle records.</data_model>",
        "  <api_surface>See api/openapi.yaml (canonical) and docs/04-api.md.</api_surface>",
        "  <ui_specification>See docs/10-demo-script.md and the M6 tasks; screens per role: officer, dispatch,",
        "    licensing, citizen, EMS, oversight.</ui_specification>",
        "</hef_specification>",
    ]
    return "\n".join(out)


def execution_block(reg: dict) -> str:
    out = ["<hef_execution>"]
    for m in reg["milestones"]:
        out.append(f'  <phase id="{m["id"]}" name="{escape(m["name"])}">')
        out.append(f"    <objective>{escape(m['objective'])}</objective>")
        out.append("    <tasks>")
        for t in m["tasks"]:
            out.append(f'      <task id="{t["id"]}">{escape(t["text"])}</task>')
        out.append("    </tasks>")
        out.append("    <verification>")
        for c in m["checks"]:
            out.append(f'      <check id="{c["id"]}">{escape(c["text"])}</check>')
        out.append("    </verification>")
        out.append(f"    <deliverables>{escape(m['deliverables'])}</deliverables>")
        out.append("  </phase>")
    out.append("</hef_execution>")
    return "\n".join(out)


def verification_block(reg: dict) -> str:
    out = ["<hef_verification>", "  <acceptance_criteria>"]
    for a in reg["acceptance_criteria"]:
        out.append(f'    <criterion id="{a["id"]}" verifies="{",".join(a["verifies"])}">'
                   f'{escape(" ".join(a["text"].split()))}</criterion>')
    out += [
        "  </acceptance_criteria>",
        "  <quality_gates>",
        '    <gate name="Rust">cargo fmt --check; cargo clippy --workspace --all-targets -- -D warnings; cargo test --workspace</gate>',
        '    <gate name="Supply chain">cargo deny check; pnpm audit --prod (no high or critical)</gate>',
        '    <gate name="Secrets">gitleaks detect on the full history</gate>',
        '    <gate name="Contracts">cedar validate; OpenAPI lint; response contract tests; migration drift check</gate>',
        '    <gate name="Web">pnpm lint; pnpm typecheck; pnpm test; Playwright demo flow; axe</gate>',
        '    <gate name="Graph">python3 tools/graph_lint.py</gate>',
        '    <gate name="Manual">Kelvin runs docs/10-demo-script.md and signs off (node approve_demo)</gate>',
        "  </quality_gates>",
        "  <known_risks>",
        '    <risk id="RK1" severity="high">Legal values unverified (Schedule 2 points matched from a garbled web copy).'
        " Mitigation: verified flags, banner, counsel review before the pilot (HL11).</risk>",
        '    <risk id="RK2" severity="high">Scope creep in a long agent build. Mitigation: graph scope locks, one node at a'
        " time, verifiers between milestones, needs_input instead of improvisation.</risk>",
        '    <risk id="RK3" severity="high">Security mistakes in AI-written code. Mitigation: security-reviewer subagent per'
        " milestone, M7 gates, independent human review and penetration test before any pilot.</risk>",
        '    <risk id="RK4" severity="medium">Founder cannot judge Rust code quality directly. Mitigation: make verify as the'
        " single green/red signal; plain-language node summaries; external code review (e.g. SpireHub) before the pilot.</risk>",
        '    <risk id="RK5" severity="medium">X-Road not exercised in this build. Mitigation: adapters send X-Road-shaped'
        " headers behind one trait (ADR 0002); pilot replaces the transport only.</risk>",
        '    <risk id="RK6" severity="medium">Synthetic names could coincide with real people. Mitigation: SYN identifiers,'
        " fictional name list, SYNTHETIC banners, no photos of real people (generated placeholders only).</risk>",
        "  </known_risks>",
        "</hef_verification>",
    ]
    return "\n".join(out)


def main() -> None:
    reg = yaml.safe_load((ROOT / "spec/registry.yaml").read_text(encoding="utf-8"))
    text = HEF.read_text(encoding="utf-8")
    for key, block in (("spec", spec_block(reg)), ("execution", execution_block(reg)),
                       ("verification", verification_block(reg))):
        pat = re.compile(rf"(<!-- BEGIN:{key} -->)(.*?)(<!-- END:{key} -->)", re.S)
        if not pat.search(text):
            raise SystemExit(f"marker {key} missing in {HEF}")
        text = pat.sub(lambda m: f"{m.group(1)}\n{block}\n{m.group(3)}", text)
    HEF.write_text(text, encoding="utf-8")
    print("TRUSTLINE.hef.md sections synced from spec/registry.yaml")


if __name__ == "__main__":
    main()
