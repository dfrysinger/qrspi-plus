---
reviewer_tag: quality-codex
change_type: correctness
severity: medium
artifact: plan.md
location: "Task 42 — Target files"
referenced_files:
  - plan.md
---

# F01 — Task 42 uses non-deterministic target-file selector instead of exact paths

## Defect

T42's Target files row at plan.md:2577 uses placeholder/selector language:

> `tests/unit/test-agent-frontmatter-no-model.bats` **or** `tests/acceptance/v07-phase1/test-t10-*.bats` successor

The "**or**" plus the `*` glob means the spec doesn't pin which file the implementer is expected to create/edit, and the auto-applied check "No placeholders / exact file paths" cannot pass deterministically.

## Impact

Implementer ambiguity — two implementers would defensibly produce two different file layouts. Downstream test selectors (acceptance harnesses, lint harnesses) cannot be wired against an unknown path.

## Recommended fix

Pick one exact path. If the choice is genuinely conditional on T40's outcome, document the resolution rule in the Dependencies section ("If T40 produced X, target is Y; otherwise target is Z") and pin both candidates as explicit conditional targets, not an `or`.
