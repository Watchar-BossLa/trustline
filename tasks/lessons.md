# Lessons

Rules learned during the build. Read at the start of every session and every node.
Format: `- YYYY-MM-DD · <node> · <rule that prevents the mistake>`

- 2026-11-02 · pack · YAML 1.1 parses an unquoted `on` key as boolean true; use `when` for edge conditions and `trigger` in rules files.
- 2026-11-02 · pack · In YAML flow mappings, quote any value containing a comma, or it silently becomes a new key.
- 2026-11-02 · pack · Legal values (Schedule 2 points, fixed penalties, retention) are unverified; never present them as law (HL11).
- 2026-11-02 · pack · Write permits as exact action-resource pairs; `action in [...]` with `resource in [...]` grants the cross product (the policy matrix caught oversight being able to review alerts on the deferrals capability).
- 2026-11-02 · pack · Anything that touches a subject but is not a lookup of them (deferral handling) must use subject relation `administrative`, or it appears in their access log and tips them off.
- 2026-11-02 · pack · Time-based visibility must also ignore records created after `now` (future-dated entries and later renewals), or tests and replays give wrong answers.
