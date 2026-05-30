---
id: quality-claude-F04
reviewer: quality-claude
round: 3
severity: low
task: Task 3
status: open
---

# F04 — Task 3: "Distinguishable from the empty-content-after-anchor case" lacks mechanism specification

## Location

`plan.md` § Task 3 — Test expectations block, fifth and sixth bullets (lines 129–130 of current plan)

## Finding

Round 2 added the following test expectation bullet:

> When the target anchor heading string is not present anywhere in the input document, the function emits a diagnostic to stderr naming the missing heading and exits with a non-zero return code (**distinguishable from the empty-content-after-anchor case**)

The adjacent bullet says:

> When the extraction from anchor to boundary produces no content lines, the function emits a diagnostic message to stderr and exits with a non-zero return code

Both bullets specify "non-zero return code" without naming a concrete exit code. "Distinguishable" is not a BATS-assertable predicate: a test-writer cannot write `assert_output --partial` or `assert_equal "$status"` against the word "distinguishable" alone. Specifically, there are three possible distinguishing mechanisms:

1. **Different exit codes** (e.g., `return 1` for empty-content, `return 2` for missing-anchor). A test writer would assert `[ "$status" -eq 2 ]` vs `[ "$status" -eq 1 ]`.
2. **Identical exit code with different stderr message** (e.g., same `return 1` but different message text). A test writer would use `assert_output --partial "not found"` vs `assert_output --partial "no content"`.
3. **Both** (different exit code AND different message).

Without specifying which mechanism is intended, the test-writer will either:
- Pick one arbitrarily, producing an implementation contract not validated by peer review.
- Ask for clarification, consuming a review-cycle round.
- Write only the observable behaviors from the two bullets (both exit non-zero, both emit to stderr) without testing that callers can programmatically distinguish the two cases — which defeats the purpose of the R2 addition.

The purpose of the "distinguishable" requirement is that consuming callers in `test-skill-md-content-patterns.bats` can tell _why_ the function failed: is the anchor missing (a structural problem with the caller's query) or is the section empty (a structural problem with the document)? This is a useful diagnostic distinction but it only provides value if the test pins a concrete mechanism.

## Required Fix

Replace "distinguishable from the empty-content-after-anchor case" with a concrete mechanism. Recommended wording:

> When the target anchor heading string is not present anywhere in the input document, the function emits a diagnostic to stderr that names the missing heading string and exits with a non-zero return code; the stderr diagnostic is textually distinct from the empty-content diagnostic (e.g., includes the phrase "not found" or names the absent heading) so that a caller parsing stderr can distinguish the two error paths without inspecting exit-code differences alone

Alternatively, if a two-exit-code contract is preferred:

> …exits with return code 2 (the empty-content-after-anchor case exits with return code 1), allowing callers to distinguish the two failure modes programmatically without parsing stderr
