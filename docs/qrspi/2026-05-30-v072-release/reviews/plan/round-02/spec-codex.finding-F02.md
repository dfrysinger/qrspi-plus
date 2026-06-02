---
reviewer_tag: spec-codex
change_type: correctness
severity: high
artifact: plan.md
location: "Task 37 — Target files vs Scope-Out vs DoD"
referenced_files:
  - plan.md
---

# F02 — Task 37 self-contradiction (Target adds lint test; Scope/DoD ban it)

## Defect

T37 Target files (line 2266) lists creating `tests/lint/test-structure-altitude-boundary-include.bats`.

Conflicts:
- Scope Out (line 2285): "Test-code or lint-test additions for the include guard — explicitly out of this prompt-prose task."
- DoD (line 2297): "The task does not edit reviewer agents, add test code, ..."

## Impact

Task is not implementable as written. Acceptance audit fails the task either way.

## Recommended fix

Pick one: either keep the lint test in-scope (and update Out/DoD/Test-expectations to allow it; add an In bullet specifying contents), or remove the file from Target files and defer to a follow-up task.

## Duplicate-of note

This is the same defect quality-claude.F01 reported. Verifier should dedupe via scope-tagger H2 grouping.
