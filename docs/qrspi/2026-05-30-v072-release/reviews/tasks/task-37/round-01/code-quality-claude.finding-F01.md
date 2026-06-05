---
finding_id: F01
reviewer: code-quality-claude
round: 1
severity: routine
change_type: code
file: tests/lint/test-structure-altitude-boundary-include.bats
line: 4
---

# F01 — ID hygiene: QRSPI-internal token `G35` in bats header comment

The header comment opens with:

```
# Task 37 — G35: regression guard for the structure-altitude-boundary `!cat`
# inclusions.
```

Per the ID Hygiene rule, QRSPI-internal IDs (G/R/D/T/Q-prefixed numeric tokens) are forbidden in code comments and test names outside `docs/qrspi/`, "regardless of how scoped the comment is." This bats file lives at `tests/lint/`, not under `docs/qrspi/`, so the `G35` token is a strict-surface violation. The flag-target failure mode — a run-specific token from the task spec (here: the `goal_ids: [G35]` frontmatter of `task-37.md`) leaking into a permanent code-surface artifact — is exactly what occurred.

## Recommended fix

Strip the QRSPI-internal token from the orientation comment. The orientation purpose is preserved without it:

```bash
# Regression guard for the structure-altitude-boundary `!cat` inclusions.
# Asserts that the literal directive
#
#     !cat skills/_shared/structure-altitude-boundary.md
#
# is present in BOTH consumer source files AT THEIR CANONICAL INSERTION POINTS:
# ...
```

(The `Task 37` reference is also low-signal — the filename and git history already orient the reader — but the load-bearing violation is the `G35` token.)
