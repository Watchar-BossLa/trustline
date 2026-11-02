---
description: Run every TRUSTLINE quality gate and summarise in plain language
---
Run `make verify` (before M1 exists: python3 tools/graph_lint.py, cedar validate, python3 tools/policy_matrix.py).
Summarise for Kelvin: overall green or red, then each failing gate in one plain sentence with the fix you propose.
Do not fix anything unless asked.
