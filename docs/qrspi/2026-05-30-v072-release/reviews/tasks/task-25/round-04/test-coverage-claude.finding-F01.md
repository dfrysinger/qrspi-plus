---
finding_id: R4-F01
severity: low
change_type: test_coverage
referenced_files:
  - tests/unit/test-task-25-round03-fixes.bats
  - skills/prompt-prose-reviewer/SKILL.md
  - skills/prompt-prose-writer/SKILL.md
reviewer_tag: test-coverage-claude
round: 4
task: 25
---

The 20 tests in `test-task-25-round03-fixes.bats` do not pin the guard's
empty-content detection phrase — the critical semantic novelty of the R3 fix.

**Background.** The R3 finding (silent-failure-claude R3-F01) identified that
the old guard text `"if either include above is unavailable"` could not fire on
a partial-include scenario where the `!cat` target file exists but expands to
empty content between its boundary markers. The fix updated the guard to:

> "if you **do not see content between** any INCLUDE-BEGIN/INCLUDE-END pair
> above, do NOT apply this skill. Surface a load error naming the missing block
> and stop — partial context is worse than no skill."

**Gap.** The R3 test suite verifies:

1. `INCLUDE-BEGIN/INCLUDE-END` pattern appears somewhere in the file (guard-scheme
   tests, lines 122–133).
2. `naming the missing block` phrase appears somewhere in the file (naming tests,
   lines 135–143).

Neither of these assertions pins the phrase `do not see content between` (or any
equivalent such as `see content`, `content between`, `no content`) that constitutes
the empty-span detection semantic. The guard-scheme test's regex
`INCLUDE-BEGIN.*INCLUDE-END|INCLUDE-BEGIN/INCLUDE-END|BEGIN.*END.*pair` is satisfied
by the INCLUDE-BEGIN/INCLUDE-END delimiter markers themselves that appear earlier in
the file — it does not require the guard comment to carry the content-detection form.

**Regression surface.** A regressor that changes the guard to:

> "if any INCLUDE-BEGIN/INCLUDE-END pair above is missing or unavailable, naming
> the missing block, stop"

passes all 20 R3 tests. The R2 test `grep -iE 'if.*(include|cat|unavailable|fails)'`
also passes (matches "include" inside "INCLUDE-BEGIN"). The entire behavioral
improvement of the R3 fix — detecting the partial-include case where the file loads
but expands to no content — is unprotected against regression.

**Recommended addition.** Add one test per SKILL.md file that pins the
content-detection phrasing in the guard comment:

```bats
@test "reviewer SKILL.md guard uses content-between detection phrasing" {
  run grep -iE 'do not see content between|no content between|see.*content.*between' \
    "$REVIEWER_SKILL"
  [ "$status" -eq 0 ]
}

@test "writer SKILL.md guard uses content-between detection phrasing" {
  run grep -iE 'do not see content between|no content between|see.*content.*between' \
    "$WRITER_SKILL"
  [ "$status" -eq 0 ]
}
```

This is non-blocking at the batch gate (the production guard text is currently
correct), but the absence leaves the fix's most important behavioral element
unverifiable by the bats suite alone.
