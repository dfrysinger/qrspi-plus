---
finding_id: F02
reviewer_tag: code-quality-codex
round: 3
severity: medium
change_type: test-quality
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
grep-regression tests (lines ~430-451) assert only `status != 0` from `grep -rl <pattern> "$REPO_ROOT/skills"|"$REPO_ROOT/agents"`. grep returns non-zero for BOTH no-match (exit 1, intended) AND error (exit 2, e.g. missing/unreadable dir). Test can pass vacuously without verifying absence of forbidden literals. Fix: assert `status -eq 1`; fail on `status -eq 2`.
