---
finding: F03
reviewer: cq-claude
round: 2
task: task-03
severity: low
change_type: clarity
file: tests/unit/test-skill-md-content-patterns.bats
lines: 168-172, 189-193
persistence_note: orchestrator-persisted (chat-only fallback)
---

# Double-diagnostic on failure at migrated call sites

## Location

`tests/unit/test-skill-md-content-patterns.bats`, both migrated call sites:

Lines 168–172:
```bash
section=$(extract_section_fence_aware "$DESIGN_FILE" "### Review Round")
if [ -z "$section" ]; then
  echo "Could not extract '### Review Round' subsection from design SKILL.md" >&2
  return 1
fi
```

Lines 189–193 (identical pattern).

## Issue

The old `extract_review_round` was silent on failure — the caller's `echo` was the only diagnostic. After migration, `extract_section_fence_aware` now emits its own named diagnostic to stderr, and then the unchanged caller echo fires a second, vaguer message on the same failure.

The second line adds no new information and slightly obscures the richer first message.

## Fix

Drop the caller's `echo … >&2` block — the new function's stderr output is sufficient.
