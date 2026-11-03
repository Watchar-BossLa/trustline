#!/usr/bin/env python3
"""Evaluate policies/trustline.cedar over the full permission matrix and compare it with the
hand-written intent in policies/expected-permissions.yaml.

Every role × purpose × field group × combination of the six context flags is evaluated
(11 × 11 × 22 × 64 = 170,368 decisions), plus every operation × capability × principal × purpose ×
device attestation. Exit code 0 when policy and intent agree.

Requires:  pip install cedarpy pyyaml
Usage:     python3 tools/policy_matrix.py [--markdown]   (--markdown prints the docs/05 table)
"""
from __future__ import annotations

import itertools
import sys
from pathlib import Path

import yaml

try:
    import cedarpy
except ImportError:  # pragma: no cover
    sys.exit("cedarpy is not installed: pip install cedarpy")

ROOT = Path(__file__).resolve().parent.parent


def main() -> int:
    exp = yaml.safe_load((ROOT / "policies/expected-permissions.yaml").read_text())
    groups_cfg = yaml.safe_load((ROOT / "rules/field-groups.yaml").read_text())["groups"]
    policies = (ROOT / "policies/trustline.cedar").read_text()
    flags = exp["flags"]
    purposes = exp["purposes"]
    groups = list(groups_cfg.keys())
    police = set(exp["police_roles"])

    entities = []
    for g, cfg in groups_cfg.items():
        entities.append({"uid": {"__entity": {"type": "Trustline::FieldGroup", "id": g}},
                         "attrs": {"domain": cfg["domain"]}, "parents": []})
    for p in exp["principals"]:
        uid = {"__entity": {"type": f"Trustline::{p['type']}", "id": p["role"]}}
        attrs = {}
        if p["type"] == "Officer":
            attrs = {"roles": [p["role"]], "agency": "SYN", "unit": "SYN", "badge": "SYN-" + p["role"]}
        elif p["type"] == "Service":
            attrs = {"roles": [p["role"]]}
        entities.append({"uid": uid, "attrs": attrs, "parents": []})

    rows = {(r["role"], r["purpose"]): r for r in exp["rows"]}
    requests, expected, labels = [], [], []
    for p in exp["principals"]:
        for purpose, group in itertools.product(purposes, groups):
            for values in itertools.product([False, True], repeat=len(flags)):
                ctx = dict(zip(flags, values))
                ctx["purpose"] = purpose
                requests.append({
                    "principal": f'Trustline::{p["type"]}::"{p["role"]}"',
                    "action": 'Trustline::Action::"ReadFieldGroup"',
                    "resource": f'Trustline::FieldGroup::"{group}"',
                    "context": ctx,
                })
                row = rows.get((p["role"], purpose))
                ok = bool(row) and group in row["allow"] and all(ctx[f] for f in row["requires"])
                expected.append(ok)
                labels.append((p["role"], purpose, group, ctx))

    # Operations: every action x capability x principal x purpose x attestation.
    caps = exp["capabilities"]
    for c in caps:
        entities.append({"uid": {"__entity": {"type": "Trustline::Capability", "id": c}}, "attrs": {}, "parents": []})
    op_actions = {}
    for op in exp["operations"]:
        op_actions.setdefault(op["action"], []).append(op)
    for action, ops in op_actions.items():
        for p in exp["principals"]:
            if p["type"] == "Citizen":
                continue
            officer_action = action not in ("RecordCourtOutcome", "RecordPayment")
            if officer_action != (p["type"] == "Officer"):
                continue  # schema: officer actions apply only to officers, court actions only to services
            for cap, purpose, attested in itertools.product(caps, purposes, [False, True]):
                requests.append({
                    "principal": f'Trustline::{p["type"]}::"{p["role"]}"',
                    "action": f'Trustline::Action::"{action}"',
                    "resource": f'Trustline::Capability::"{cap}"',
                    "context": {"purpose": purpose, "device_attested": attested},
                })
                ok = any(op["capability"] == cap and any(
                    p["role"] in g["roles"] and ("*" in g["purposes"] or purpose in g["purposes"]) for g in op["grants"])
                    for op in ops)
                if p["type"] == "Officer":
                    ok = ok and attested
                expected.append(ok)
                labels.append((p["role"], purpose, f"{action}:{cap}", {"device_attested": attested}))

    results = cedarpy.is_authorized_batch(requests, policies, entities)
    mismatches = []
    health_leaks = []
    for res, ok, (role, purpose, group, ctx) in zip(results, expected, labels):
        allowed = res.decision == cedarpy.Decision.Allow
        if res.diagnostics.errors:
            mismatches.append(f"ERROR {role} {purpose} {group}: {res.diagnostics.errors}")
        if allowed != ok:
            flags_on = [k for k, v in ctx.items() if v is True]
            mismatches.append(f"{'ALLOWED' if allowed else 'DENIED'} but expected {'allow' if ok else 'deny'}: "
                              f"{role} {purpose} {group} flags={flags_on}")
        if allowed and role in police and group in groups_cfg and groups_cfg[group]["domain"] == "health":
            health_leaks.append(f"{role} {purpose} {group}")

    print(f"evaluated {len(requests):,} decisions")
    if health_leaks:
        print("HEALTH LEAK:", *health_leaks[:20], sep="\n  ")
    for m in mismatches[:40]:
        print("MISMATCH", m)
    if "--markdown" in sys.argv:
        print_table(exp, groups)
    ok = not mismatches and not health_leaks
    print("OK: policy matches expected-permissions.yaml" if ok else f"FAIL: {len(mismatches)} mismatches")
    return 0 if ok else 1


def print_table(exp: dict, groups: list[str]) -> None:
    print("\n| Role | Purpose | Requires | Allowed field groups |\n| --- | --- | --- | --- |")
    for r in exp["rows"]:
        print(f"| {r['role']} | {r['purpose']} | {', '.join(r['requires']) or '—'} | {', '.join(r['allow'])} |")


if __name__ == "__main__":
    sys.exit(main())
