---
finding_id: F01
reviewer_tag: silent-failure-codex
round: 3
severity: medium
change_type: test-quality
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
CONVERGENT with code-quality-codex F02. grep-regression tests (lines ~434-451) assert only `status != 0` after `grep -rl ... "$REPO_ROOT/skills"|"$REPO_ROOT/agents"`. Passes on both no-match (exit 1) and grep error (exit 2 — dir missing/unreadable), silently masking test-environment failures. Fix: assert `status -eq 1`; fail on `status -eq 2`; optionally assert target dirs exist first.
