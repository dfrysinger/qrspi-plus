---
severity: high
change_type: correctness
location: plan.md § T05 (lines 254–272)
---

# F01 — T05 is sweep-shaped but missing the `dependent_tests:` field

## What

T05 ("Replace per-skill diff-emission prose with high-level dispatch in 8 artifact-step SKILLs") satisfies both Sweep Task Contract triggers but the spec body does not declare a `dependent_tests:` field at all.

Detection re-check:

- **File-count trigger:** `Target files:` enumerates eight `.md` files (`skills/{goals,questions,research,design,phasing,structure,parallelize,replan}/SKILL.md`) — strictly greater than 5 of the same file type. ✓
- **Keyword trigger:** the title contains `Replace` and the description body contains `replaced` / `replacement`. ✓

Per `skills/plan/SKILL.md` § Sweep Task Contract, a sweep-shaped task MUST carry a `dependent_tests:` field whose value is either (a) a list of test file paths with per-file dispositions, or (b) the literal `none` followed by a reproducible `grep -rn -- '<pattern>' tests/` proof. T05 carries neither.

T05 does declare `cross_task_consumers:` (pointing to the T06 lint and the structural-lint script) and `sizing_exception: schema-migration` with rationale and `structural_lint:` path — so the omission is not a wholesale failure to apply the contract surfaces, only a missing `dependent_tests:` field. The two clauses are independent per the protocol; the presence of `cross_task_consumers:` does not satisfy the sweep rubric.

## Why it matters

Without `dependent_tests:`, the plan does not document which existing bats files break when the eight artifact-step SKILL bodies have their § Review Round § Pre-dispatch diff-file emission paragraphs deleted. The companion structure document already calls out an at-risk test: `tests/unit/test-diff-file-emission.bats` (it asserts every in-scope per-step SKILL.md references `round-NN.diff` — that assertion breaks for the eight files T05 modifies). A reader of the plan should not have to discover that test from the structure document; the sweep contract exists exactly so dependent tests get a documented disposition in the plan body.

The omission also short-circuits the schema-migration review path: when the Implement-phase reviewer applies the sweep rubric against the T05 PR diff, the missing field surfaces as a defect at the very moment fixing it requires re-opening Plan.

## Suggested change

Add a `dependent_tests:` block to the T05 spec listing each consuming bats file (path + one-sentence disposition) — or, if the consensus is that the test-name updates are out-of-scope-of-T05 and ride on T06 / other tasks, encode the `none` form with a properly-shaped `grep -rn -- '<pattern>' tests/` proof. The Apply-fix should not invent a `none` claim if `test-diff-file-emission.bats` does in fact need a paired edit.
