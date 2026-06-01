---
finding_id: R7-F02
reviewer_tag: stitching-audit
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
artifact: structure
---

## Summary

`agents/qrspi-plan-test-coverage-reviewer.md` has no File Map row for G31 Addition C. Design.md Distribution Table row 9 requires a permanent inline addition to this agent — structure.md is entirely silent on it.

## Detail

Design.md G31 Distribution Table (line 2625) lists nine consumers. Row 9 is:

| # | Consumer | Mechanism | Placement |
|---|---|---|---|
| 9 | `agents/qrspi-plan-test-coverage-reviewer.md` | Addition C ONLY (no wrapper SKILL preload) | TOP of review-procedure section |

Addition C prose is defined at design.md line 2582 ("Addition C — plan-test-coverage-reviewer scope guard") and its acceptance condition is verified at design.md line 2704 (anchor phrase: *"Scope: only `task_type: code` tasks."*).

Structure.md has no row for `agents/qrspi-plan-test-coverage-reviewer.md` under G31 in any slice. The agent does appear in the Slice 1.4 sweep row (`agents/*.md sweep — all 41 files`, line 93) which adds `tier:` frontmatter and DISPATCH_FILE first-action, but that sweep row carries only G22 — it does not deliver Addition C. With no individual row, the Addition C inline content will not be authored during Implement and the G31 acceptance check (design.md line 2704) will fail.

This gap was not present before R6 because R6 introduced the two new explicit G31 rows (lines 132–133) without also adding the missing row for consumer #9, which was already absent in earlier rounds and escaped detection until the R6 delta surfaces were audited against the full design.md Distribution Table.

## Fix

Add a new File Map row in Slice 1.5 for `agents/qrspi-plan-test-coverage-reviewer.md`:

```
| `agents/qrspi-plan-test-coverage-reviewer.md` | Modify | Add Addition C scope guard (inline, TOP of review-procedure section): "Scope: only `task_type: code` tasks. Skip evaluation of any task with `task_type: lightweight`…" per design.md G31 Addition C. No `skills:` frontmatter change (standalone addition only). | G31 |
```
