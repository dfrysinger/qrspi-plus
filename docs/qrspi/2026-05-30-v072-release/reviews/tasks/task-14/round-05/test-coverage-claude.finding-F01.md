---
finding_id: R5-F01
reviewer_tag: test-coverage-claude
round: 5
severity: medium
change_type: correctness
referenced_files: [tests/integration/test-reference-gate-pause.bats]
---

# F01: Three G15-sweep tests are file-scope where section-scope is required

Three tests use bare `grep -E ... "$PLAN_REVIEWER_AGENT"` for attributes that must be confirmed in the `Sweep-task detection` section specifically. Risk: tests pass vacuously because target strings exist elsewhere in the agent file pre-T14.

## Affected tests

1. **L284-288** `[G15-sweep] Plan reviewer agent body uses strict >5 same-extension threshold`
   - Uses `grep -E ">5|more than (five|5)|strictly greater than (five|5)" "$PLAN_REVIEWER_AGENT"` — file-scope

2. **L302-305** `[G15-sweep] Plan reviewer agent body specifies case-insensitive word-boundary matching`
   - Two bare greps for `case-insensitive` and `word-boundary` — file-scope

3. **L307-312** `[G15-sweep] Plan reviewer agent body emits high-severity correctness finding for missing dependent_tests:`
   - `grep -E "severity: high"` and `grep -E "change_type: correctness"` — these strings exist throughout the file pre-T14 (Tasks 3/4/5 reviewers). Pin is vacuous for the sweep case.

## Fix pattern

Replace bare greps with `extract_and_grep "$PLAN_REVIEWER_AGENT" H3 "Sweep-task detection" <pattern>` (same helper used by 10+ other G15-sweep tests in the same file).
