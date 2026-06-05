# Silent Failure Hunter — Task 30 Round 2 — clean

Round-2 diff is a prose-only edit to `skills/design/SKILL.md` replacing two stale cross-references:

1. Line 30: `(see G35)` → `(see Structure's owns/defers contract)`
2. Line 208: `G3-class concerns` → `orchestrator-context-budget concerns`

Both edits are evergreen rephrasings of internal references. No code paths, no error handling, no fallback logic, no state transitions. The replacements preserve the surrounding loud-failure guidance verbatim ("Silent fallback is never the answer — name the diagnostic"; "leak prompt content silently") rather than weakening it.

No swallowed errors, silent fallbacks, missing error paths, inappropriate error transformations, log-and-continue patterns, or partial-state risks introduced or exposed by this diff.

Clean.
