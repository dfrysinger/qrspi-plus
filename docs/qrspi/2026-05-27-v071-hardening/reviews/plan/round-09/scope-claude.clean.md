---
status: clean
reviewer: scope-claude
artifact: plan.md
round: 9
---

# Scope review — clean

Reviewed the R8→R9 diff against `skills/plan/owns-defers.md` (Plan OWNS / Plan DEFERS / lexical leakage signals).

## Diff summary

Two changes, both in Task 9:

1. Removed Test Expectations bullet that required each modified `agents/qrspi-*.md` file to contain `haiku`, `sonnet`, and `opus` tokens outside the YAML frontmatter block (verifying dispatcher prose was not collaterally removed).
2. Expanded the Manual Validation parenthetical from the diff-stat invariant with verification intent: "(verifies that only the `model:` frontmatter line was removed and no body prose was collaterally modified)".

## Boundary-drift detection

No DEFERS items crossed:

- No function signatures, type definitions, or parameter shapes introduced (no Structure leak).
- No `expect(...)`, `assert.`, `toBe(`, or other assertion-code text introduced (no Implement-TDD leak).
- No `if/else`, `for`, `while`, or line-numbered logic walkthroughs introduced (no Implement leak).
- No "trade-off", "we considered", or "alternative approach" framing introduced (no Design leak).
- No "phase 2 will...", "future phases", or forward roadmap references introduced (no Phasing leak).

The expanded parenthetical describes the **intent** of the operator-visible diff-stat invariant in plain language — it does not encode an assertion, a function call, or a control-flow step. It is operator validation guidance, which sits inside Plan OWNS test-expectations territory.

## Scope compliance per OWNS

The removal of the over-constrained bullet is scope-positive: it withdraws a Plan-level specification that was attempting to dictate **how** Implement verifies non-collateral modification (token presence outside YAML), restoring the "conversation, not contract" framing from the INVEST Negotiable rule. Task 9 still owns the behavioral expectation (only the `model:` frontmatter key is removed; dispatcher prose, `skills:`, `description:`, `name:`, and other keys are unmodified) — that expectation remains expressed in the Description block and in the surviving "All other frontmatter keys [...] are unmodified" Test Expectations bullet, and is operator-verified pre-merge via the diff-stat invariant. No OWNS item is now missing.

## Lexical scan

Clean. The added parenthetical fragment ("verifies that only the `model:` frontmatter line was removed and no body prose was collaterally modified") contains no leakage-signal tokens.

## Set-asides

S1–S5 confirmed unchanged in this diff and not raised.
