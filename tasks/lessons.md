# Lessons

Rules learned during the build. Read at the start of every session and every node.
Format: `- YYYY-MM-DD · <node> · <rule that prevents the mistake>`

- 2026-11-02 · pack · YAML 1.1 parses an unquoted `on` key as boolean true; use `when` for edge conditions and `trigger` in rules files.
- 2026-11-02 · pack · In YAML flow mappings, quote any value containing a comma, or it silently becomes a new key.
- 2026-11-02 · pack · Legal values (Schedule 2 points, fixed penalties, retention) are unverified; never present them as law (HL11).
