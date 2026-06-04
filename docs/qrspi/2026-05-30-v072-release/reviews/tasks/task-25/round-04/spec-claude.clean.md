# Spec Review — Task 25 Round 04 — CLEAN

**Reviewer:** spec-claude  
**Round:** 4 (post-R3-fix verification)  
**Verdict:** CLEAN — no findings

---

## Verification Summary

### (a) Scope — only expected files modified

Diff touches exactly 3 files, all within R3 fix scope:

| File | Change |
|------|--------|
| `skills/prompt-prose-reviewer/SKILL.md` | Added INCLUDE-BEGIN/END markers + updated guard |
| `skills/prompt-prose-writer/SKILL.md` | Added INCLUDE-BEGIN/END markers + updated guard |
| `tests/unit/test-task-25-round03-fixes.bats` | New file, 20 tests |

No other files modified. ✅

### (b) No spec drift

R3 fix requirement: wrap each `!cat` block in `<!-- INCLUDE-BEGIN: name -->` / `<!-- INCLUDE-END: name -->` delimiters and rewrite guard text to reference the BEGIN/END marker scheme.

Verified in both SKILL.md files (lines 7-13, 15-17 in each):
- Each `!cat` directive is bracketed by matching `INCLUDE-BEGIN` / `INCLUDE-END` HTML comment pairs with the correct block name.
- Guard text updated to: *"if you do not see content between any INCLUDE-BEGIN/INCLUDE-END pair above, do NOT apply this skill. Surface a load error naming the missing block and stop — partial context is worse than no skill."*
- This directly satisfies the silent-partial-include finding that triggered the fix. ✅

### (c) Marker scheme consistently applied to both SKILL.md files

**prompt-prose-reviewer/SKILL.md** (lines 7–13):
```
<!-- INCLUDE-BEGIN: prompt-prose-detection -->
!cat skills/_shared/prompt-prose-detection.md
<!-- INCLUDE-END: prompt-prose-detection -->

<!-- INCLUDE-BEGIN: prompt-prose-reviewer-addition -->
!cat skills/_shared/prompt-prose-reviewer-addition.md
<!-- INCLUDE-END: prompt-prose-reviewer-addition -->
```

**prompt-prose-writer/SKILL.md** (lines 7–13):
```
<!-- INCLUDE-BEGIN: prompt-prose-detection -->
!cat skills/_shared/prompt-prose-detection.md
<!-- INCLUDE-END: prompt-prose-detection -->

<!-- INCLUDE-BEGIN: prompt-prose-writer-addition -->
!cat skills/_shared/prompt-prose-writer-addition.md
<!-- INCLUDE-END: prompt-prose-writer-addition -->
```

Both files: correct names, correct order, symmetric structure. ✅

### (d) New tests are behavioral — not vacuous greps of self-constructed fixtures

Test file: `tests/unit/test-task-25-round03-fixes.bats` (143 lines, 20 `@test` blocks)

- `setup_file()` derives `REPO_ROOT` from `BATS_TEST_FILENAME` and sets `REVIEWER_SKILL` / `WRITER_SKILL` to real paths under the worktree. Tests operate on the live production files, not synthetic fixtures.
- **8 marker-presence tests** (4 × SKILL.md × BEGIN+END): straight `grep -F` assertions on exact marker strings. Pass only if the real files contain the expected markers. ✅
- **8 structural-ordering tests** (4 per SKILL.md): use `grep -n` to extract actual line numbers and assert `begin_line -lt cat_line -lt end_line`. The `[ -n "$begin_line" ] && [ -n "$cat_line" ]` guard (without `run`) causes a hard test failure if grep returns nothing, so the ordering check is not vacuously skipped. ✅
- **4 guard-text tests**: assert the guard comment contains `INCLUDE-BEGIN/INCLUDE-END` scheme reference (regex `INCLUDE-BEGIN.*INCLUDE-END|INCLUDE-BEGIN/INCLUDE-END|BEGIN.*END.*pair`) and the phrase "naming the missing block". The actual guard text satisfies both patterns. ✅

Test count: exactly 20, matching the R3 fix claim. ✅

---

## Checklist Disposition

| Check | Result |
|-------|--------|
| All requested changes implemented | PASS |
| Scope — no unrequested changes | PASS |
| No interpretation drift | PASS |
| Test coverage for fix requirements | PASS |
| Tests behavioral (not vacuous) | PASS |
| Target-file deviation | PASS (test file addition is expected auxiliary file) |
