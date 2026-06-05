---
finding_id: R2-F01
reviewer_tag: sf-codex
severity: medium
change_type: correctness
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L2023-L2028
---

The AC4 assertions use `if grep -q ... "$tmp/kept-findings.txt" 2>/dev/null; then ... fi`. This suppresses grep errors and treats exit `2` (file missing/unreadable) the same as exit `1` (string absent), so a broken/missing `kept-findings.txt` can pass silently.

**Impact and fix:** This masks fan-in/output regressions. Fail fast on unreadable/missing file (e.g., `[[ -r "$tmp/kept-findings.txt" ]] || return 1`) and/or branch on grep status so exit `2` fails the test instead of being silently ignored.

Note: This is the same anti-pattern class flagged in v0.7.3 backlog (PI-V072-T09-004) — `grep -qF` exit-2 silent-pass — now appearing in T10's new test code.
