---
finding_id: F01
reviewer: test-coverage-claude
reviewer_role: test-coverage
round: 2
task: 40
severity: medium
change_type: completeness
file: tests/unit/test-ci-workflow-shape.bats
lines: "380-395"
status: open
---

# F01 — Regex omits `.pre-commit-config.yaml` and other tracked pre-commit wiring sites

The path filter `^(scripts|\.husky|\.githooks|lefthook)` drops the canonical pre-commit framework config (`.pre-commit-config.yaml`/`.pre-commit-hooks.yaml`) — the most likely real-world C1 violation vector. Test would pass silently if someone lands a `.pre-commit-config.yaml` referencing `body-guard` or `bats-body-assertion`.

This is the *only* automated enforcement point for C1. R1 fixed CI-vacuity; F01 is the residual content-vacuity gap.

**Recommendation:** Add `.pre-commit-config(\.yaml|\.yml)?` and `.pre-commit-hooks(\.yaml|\.yml)?` to alternation, or invert to content-first scan over all tracked files with path allowlist as fast-path.
