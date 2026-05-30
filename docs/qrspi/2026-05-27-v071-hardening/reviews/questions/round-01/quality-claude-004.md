---
id: quality-claude-004
artifact: questions
severity: HIGH
check: comprehensiveness
---

## Finding

No question covers `extract_review_round` — the un-migrated fence-tracking helper that is the core subject of G3. Q5 asks about `extract_section`'s API in `tests/helpers/skill-markdown.bash`, but without parallel research on `extract_review_round`'s current implementation and usage, Design cannot evaluate either G3 migration candidate.

### What the goals require

G3 ("Reusable fence-tracking helper migrated into shared skill-markdown library") is built entirely around closing the gap left by `extract_review_round`:

- It is currently inline (not in the shared helper) because `extract_section` could not handle its fence-anchored exit logic.
- Its start-anchor and exit-anchor conventions are structurally different from `extract_section`'s heading-anchored model.
- Two migration candidates (extend `extract_section` with pluggable exit predicates vs. add a separate `extract_between_fences` family) require knowing what `extract_review_round` currently does, where it lives, and which BATS files call it.

### What is missing

No question asks:
1. Where is `extract_review_round` currently defined (which file(s))?
2. What is its complete implementation — specifically how it identifies the start anchor, how it determines the exit anchor, and how it handles nested fences?
3. Which BATS test files currently call `extract_review_round` (and how many call sites exist)?
4. Are there other inline fence-tracking helpers besides `extract_review_round` that the migration should cover?

### Impact

Without this research, Design will open with no picture of the code it is supposed to migrate. The two candidates in G3 make specific structural assumptions about `extract_review_round`'s interface; those assumptions need grounding in the actual implementation before Design can select one.

### Suggested additional question

> [codebase] Where is `extract_review_round` currently defined, what is its complete implementation (start-anchor logic, exit-anchor logic, fence-nesting handling), and which BATS test files call it — including call-site count and argument patterns used?
