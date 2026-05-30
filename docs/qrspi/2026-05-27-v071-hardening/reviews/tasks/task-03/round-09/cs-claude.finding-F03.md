---
finding_id: R9-F03
severity: low
change_type: style
referenced_files: [tests/unit/test-skill-md-content-patterns.bats]
artifact: task-03/tests/unit/test-skill-md-content-patterns.bats
round: 9
reviewer: cs-claude
non_blocking: true
persistence_note: orchestrator-persisted (chat-only fallback)
---

**Title:** Migrated T36 callers retain redundant guard message duplicating extract_section_fence_aware's own diagnostic

The two T36 tests retain a manual `echo "Could not extract …"` guard that was load-bearing for the old `extract_review_round` (which emitted no diagnostic) but is now redundant on top of `extract_section_fence_aware`'s own built-in error message (`extract_section_fence_aware: <anchor>: not found in <file>` / `: anchor located but region contains no content lines`).

When the function fails, the test run shows TWO error messages — the function's specific machine-greppable one and the test's generic one that adds no info.

**Fix:** Simplify the guard to a single-line idiom:
```bash
section=$(extract_section_fence_aware "$DESIGN_FILE" "### Review Round") || return 1
```
The same simplification applies to the `[T36-2]` test's `extract_section` guard.
