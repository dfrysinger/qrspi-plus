---
status: clean
reviewer: spec-claude
round: 9
artifact: plan.md
---

# Spec Review — Round 9 — Clean

## Summary

No findings. The R9 diff surgically addresses R8-F01 on Task 9 and introduces no new spec-review issues.

## What changed in R8 → R9

The diff modifies exactly one task (Task 9) with two coordinated edits:

1. **Removed over-constrained test expectation** (diff line 7): The bullet asserting that each modified `agents/qrspi-*.md` file contains `haiku`, `sonnet`, and `opus` tokens outside the YAML frontmatter is deleted. This was the exact over-constraint flagged in R8-F01 — not every agent's prose naturally references all three tier names, so the assertion would have produced false positives unrelated to the no-collateral-changes property it was meant to defend.

2. **Strengthened Manual Validation** (diff line 13): The `git diff --stat HEAD~1 -- 'agents/qrspi-*.md'` bullet now explicitly states it verifies "only the `model:` frontmatter line was removed and no body prose was collaterally modified". The "exactly 41 files changed, each with one line removed and zero lines added" stat is a tighter, more accurate signal for the no-collateral-changes invariant than per-file token scanning. The "Operator-verified; BATS-level git introspection is impractical for this scope (mirrors the Task 8 Manual Validation pattern)" framing preserves the plan-wide convention for whole-commit git-introspection invariants.

## Verification checklist

- **Completeness (G7b coverage):** Task 9 still carries the no-model-key invariant (expectation 1: structural lint sweep; expectation 2: lint passes after edits) and the other-key-preservation invariant (expectation 3). G7b acceptance criteria remain intact.
- **Scope:** No new tasks, files, or features introduced. Change is a pure test-expectation tightening within Task 9.
- **Interpretation:** The no-collateral-changes goal-derivable property is now verified at the correct scope (whole-commit operator review), not at an incorrect scope (per-file token presence that doesn't actually distinguish a clean frontmatter-key deletion from a deletion plus unrelated prose edit).
- **Test coverage mapping:** Task 9's four remaining test expectations plus the Manual Validation bullet cover the G7b deletion invariant, the no-other-key-modification invariant, the RED-phase per-file diagnostic quality requirement, and the no-collateral-prose-changes property. No coverage gap introduced by removing the over-constrained bullet.
- **Placeholder detection:** No TBD/TODO/vague content introduced. The new Manual Validation bullet uses concrete file globs, exact stat predicates (41 files, one line removed, zero added), and a named operator-verification mode.
- **Task sizing:** Task 9 sizing unchanged (~90 LOC; 41-file schema-migration exception still applies and is well-justified in the existing `Sizing exception` bullet).

## Set-asides

S1–S5 unchanged and not raised, per dispatch instruction.

## Recommendation

Plan is ready to advance from spec-review perspective. R8-F01 fully resolved.
