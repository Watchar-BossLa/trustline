#!/usr/bin/env python3
"""Build testing/trustline-test-console.html, the offline HTML5 test console.

The console is one self-contained file: tools/test-console/template.html with the pack's rules
and intended permissions embedded as JSON, so its reference model always runs on the same data
as the build. Output is deterministic (no timestamps), so --check can detect drift in CI.

Usage:
  python3 tools/build_test_console.py           # write testing/trustline-test-console.html
  python3 tools/build_test_console.py --check   # exit 1 if the committed file is out of date
Requires: pip install pyyaml
"""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
TEMPLATE = ROOT / "tools/test-console/template.html"
OUTPUT = ROOT / "testing/trustline-test-console.html"
RULE_FILES = [
    "rules/reason-codes.yaml", "rules/field-groups.yaml", "rules/demerit-schedule.yaml", "rules/offences.yaml",
    "rules/anomaly-rules.yaml", "rules/retention.yaml", "rules/disclosure.yaml", "policies/expected-permissions.yaml",
]
WINDOW_UNITS = {"h": 3600_000, "d": 86400_000}


def load(rel: str) -> dict:
    return yaml.safe_load((ROOT / rel).read_text())


def window_ms(text: str) -> int:
    return int(text[:-1]) * WINDOW_UNITS[text[-1]]


def build() -> str:
    registry = load("spec/registry.yaml")
    groups = load("rules/field-groups.yaml")
    anomaly = {r["code"]: r for r in load("rules/anomaly-rules.yaml")["rules"]}
    repeat = anomaly["repeat_subject"]

    rules = []
    for rel in RULE_FILES:
        raw = (ROOT / rel).read_bytes()
        doc = yaml.safe_load(raw)
        rules.append({"file": rel, "version": doc.get("version"), "verified": doc.get("verified"),
                      "sha256": hashlib.sha256(raw).hexdigest()})
    digest = hashlib.sha256("".join(r["sha256"] for r in rules).encode()).hexdigest()

    data = {
        "version": registry["meta"]["version"],
        "digest": digest,
        "rules": rules,
        "allVerified": all(r["verified"] is True for r in rules if r["verified"] is not None),
        "fieldGroups": groups["groups"],
        "requestKinds": groups["request_kinds"],
        "reasonCodes": load("rules/reason-codes.yaml")["codes"],
        "demerit": load("rules/demerit-schedule.yaml"),
        "offences": load("rules/offences.yaml")["offences"],
        "disclosure": load("rules/disclosure.yaml"),
        "anomaly": {"repeat_subject": {"count": repeat["threshold"]["count"],
                                       "window_ms": window_ms(repeat["threshold"]["window"])}},
        "expected": load("policies/expected-permissions.yaml"),
    }
    payload = json.dumps(data, ensure_ascii=False, sort_keys=True, separators=(",", ":"), default=str)
    payload = payload.replace("<", "\\u003c")  # valid JSON; nothing can close the <script> element
    template = TEMPLATE.read_text()
    assert template.count("__TRUSTLINE_DATA__") == 1, "template placeholder missing"
    return template.replace("__TRUSTLINE_DATA__", payload)


def main() -> int:
    html = build()
    if "--check" in sys.argv:
        if not OUTPUT.exists() or OUTPUT.read_text() != html:
            print(f"{OUTPUT.relative_to(ROOT)} is out of date: run python3 tools/build_test_console.py")
            return 1
        print(f"OK: {OUTPUT.relative_to(ROOT)} is up to date")
        return 0
    OUTPUT.parent.mkdir(exist_ok=True)
    OUTPUT.write_text(html)
    print(f"wrote {OUTPUT.relative_to(ROOT)} ({len(html.encode()):,} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
