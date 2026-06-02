---
reviewer_tag: quality-codex
change_type: correctness
severity: medium
artifact: plan.md
location: "Task 43 — Target files"
referenced_files:
  - plan.md
---

# F02 — Task 43 target-file list contains conditional/optional path language

## Defect

T43's Target files row at plan.md:2635 contains:

> `tests/unit/test-using-qrspi-routing-block.bats` **if present after Task 42**

The "**if present after Task 42**" clause makes the file's existence conditional on a sibling task's deliverable, but the Dependencies row doesn't pin T42 as a hard dep, and the conditional logic isn't reflected in the DoD or Test expectations.

## Impact

Spec is not implementable as written: if T42 chooses the other branch from its F01 ambiguity, T43's target doesn't exist and the spec has no fallback. Implementer must make scope decisions the planner should have made.

## Recommended fix

Either (a) make T43 unconditionally responsible for creating the file and add T42 as a hard Dependencies entry, or (b) split T43 into two variants keyed off T42's resolution and make the variant selection explicit. Same pattern as F01.
