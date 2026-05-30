# Goal-Traceability Review — Task 03 — Round 9

**Reviewer:** gt-claude  
**Task:** task-03 — Promote fence-aware section extractor to shared test-helper library  
**Round:** 9  
**Commit under review:** a4fa25c  
**Goal:** G3 — Reusable fence-tracking helper migrated into shared skill-markdown library (#187)

---

## Summary

The traceability chain from G3 through plan.md Phase 1 Criterion 7 through task-03.md test
expectations to `test-helpers-skill-markdown.bats` through `tests/helpers/skill-markdown.bash`
is **complete and unbroken**. No scope drift was detected; every behavior implemented in
`extract_section_fence_aware` is demanded by the task spec or by correctness/security review
findings that are themselves traceable back to G3's goal. Three minor findings are raised
(one medium correctness, two low style).

---

## 1. Forward Trace: G3 → Criterion → Tests → Implementation

```
G3 (goals.md §G3)
  ↓ goal_ids: [G3] (task-03.md frontmatter)
plan.md Phase 1 Acceptance Criterion 7:
  "The fence-aware section-extraction helper exists as a dedicated function
   in the shared test-helper library, the inline duplicate is removed from
   the consuming unit suite, and unit coverage pins the helper's behavior
   including fenced-code blocks."
  ↓
task-03.md Test Expectations (10 bullets)
  ↓
tests/unit/test-helpers-skill-markdown.bats  (24 @test blocks)
  ↓
tests/helpers/skill-markdown.bash extract_section_fence_aware() (lines 221–313)
tests/unit/test-skill-md-content-patterns.bats (inline extract_review_round removed,
  2 call sites migrated to extract_section_fence_aware at lines ~168, ~189)
```

### Per-expectation trace

| Task spec expectation (task-03.md) | Covering test(s) | Impl location |
|---|---|---|
| 1. Returns content from anchor (inclusive) through next out-of-fence boundary | `[fence-aware-extractor] basic extraction` (line 224) | awk rule `!in_b && !fence && $0==anchor { in_b=1; print }` + boundary exit (line 259) |
| 2. `###`/`##` inside open code fence not treated as boundary | `[fence-aware-extractor] H3 and H2 heading-shaped lines inside a code fence` (line 248) | awk `in_b && !fence && (…)` — fence=0 required (line 259) |
| 3. Closing fence restores boundary detection | `[fence-aware-extractor] closing triple-backtick fence restores heading-boundary detection` (line 276) | `/^```/ { fence = !fence … }` toggle (line 250) |
| 4. EOF: extracts through last line of file | `[fence-aware-extractor] section extending to EOF extracts through the last line of the file` (line 300) | awk runs to EOF; `FOUND_WITH_CONTENT` written in END block |
| 5a. Missing-anchor: exits non-zero, `extract_section_fence_aware:` prefix, anchor text, "not found" body | `[fence-aware-extractor] missing anchor` (line 321) | `case *) printf '…not found in %s\n'` (line 309) |
| 5b. Empty-region: exits non-zero, `extract_section_fence_aware:` prefix, anchor text, NOT "not found" | `[fence-aware-extractor] empty region` (line 338) | `case FOUND_EMPTY) printf '…anchor located but region contains no content lines\n'` (line 305) |
| 5c. Two paths distinguishable by message body | `[fence-aware-extractor] missing-anchor and empty-region error messages are distinguishable` (line 356) | Same two case branches |
| 6. Whitespace-only region triggers no-content error path | `[fence-aware-extractor] whitespace-only region…` (line 380) — **partial; see F01** | `$0 ~ /[^[:space:]]/ has_content = 1` (line 273) |
| 7. Anchor line included in output (parity with prior `extract_review_round`) | `[fence-aware-extractor] basic extraction` (`[[ "$out" == *"### Review Round"* ]]`) | `print` inside anchor match rule (line 266) |
| 8. Both migrated call sites produce output identical to prior inline helper | `[fence-aware-extractor] fenced-code fixture output matches parity contract` (line 397) | call sites at test-skill-md-content-patterns.bats lines ~168, ~189 |
| 9. Inline `extract_review_round` definition removed, no test failures | `[fence-aware-extractor] inline extract_review_round definition removed…` (line 439) | diff confirms removal; grep asserts absence |
| 10. All pre-existing `extract_section` tests continue to pass | Tests lines 26–208 (10 pre-existing tests, unchanged) | `extract_section` function untouched |

---

## 2. Backward Trace: Implementation → Tests → Spec → Goal

### `extract_section_fence_aware` function (skill-markdown.bash lines 221–313)

Every branch traced:

| Implementation behavior | Test(s) exercising it | Spec expectation | Goal |
|---|---|---|---|
| 2-arg guard + unreadable-file guard | (implicit; `run` with wrong arg count would fail) | Expectation 5 (error path) | G3 |
| mktemp guard with named diagnostic | `[r7-sf.F01] mktemp failure…` | Correctness finding round 7 → G3 | G3 |
| awk fence toggle `/^```/` | `[fence-aware-extractor] H3/H2 inside code fence` | Expectation 2 | G3 |
| `in_b && !fence && heading` → exit | `[fence-aware-extractor] fence-restore` | Expectation 3 | G3 |
| `!in_b && !fence && $0==anchor` → `in_b=1; print` | `[fence-aware-extractor] basic extraction` | Expectations 1, 7 | G3 |
| `has_content` set for non-whitespace lines | `[fence-aware-extractor] whitespace-only` | Expectation 6 | G3 |
| Fence delimiter counts as content (`has_content=1`) | `[sf-F03] empty fenced block…` | sf.F03 correctness finding → G3 | G3 |
| `FOUND_WITH_CONTENT` → print + return 0 | `[fence-aware-extractor] basic extraction` | Expectation 1 | G3 |
| `FOUND_EMPTY` → empty-region diagnostic | `[fence-aware-extractor] empty region` | Expectation 5b | G3 |
| `*` case → not-found diagnostic | `[fence-aware-extractor] missing anchor` | Expectation 5a | G3 |
| awk exit status check → `awk failed` diagnostic | `[sf-F01] awk crash…` | sf.F01 correctness finding → G3 | G3 |
| mktemp generates unguessable path (TOCTOU fix) | `[sec-F01] mktemp-generated signal-tmp…` | sec.F01 security finding → G3 | G3 |

**No YAGNI signals identified.** All implementation behaviors are demanded by spec
expectations or by correctness/security review findings that trace to G3.

### Migration in `test-skill-md-content-patterns.bats`

| Change | Test | Spec expectation | Goal |
|---|---|---|---|
| `extract_review_round()` definition removed | `[fence-aware-extractor] inline extract_review_round definition removed…` | Expectation 9 | G3 |
| Call site 1 migrated: `extract_section_fence_aware "$DESIGN_FILE" "### Review Round"` | `[T36-1] design SKILL Review Round…` exercises the migrated call | Expectation 8 | G3 |
| Call site 2 migrated (same function, same file, same anchor) | `[T36-1] design SKILL Review Round…` (second assert block) | Expectation 8 | G3 |

---

## 3. Gap Analysis: Uncovered Acceptance Criteria

### Phase 1 Criterion 7 (plan.md line 68)

> The fence-aware section-extraction helper exists as a dedicated function in the shared
> test-helper library, the inline duplicate is removed from the consuming unit suite, and
> unit coverage pins the helper's behavior including fenced-code blocks.

Sub-condition audit:

| Sub-condition | Satisfied? |
|---|---|
| Dedicated function in shared helper | ✓ `extract_section_fence_aware` in `tests/helpers/skill-markdown.bash` |
| Inline duplicate removed from consuming suite | ✓ `extract_review_round()` deleted from `test-skill-md-content-patterns.bats` |
| Unit coverage includes fenced-code blocks | ✓ 14 fence-aware @test blocks in `test-helpers-skill-markdown.bats` |

**Phase 1 Criterion 7 is fully satisfied.**

### Task spec test expectations: all 10 covered

No task-spec test expectation is left without a covering test. (See section 1 table above.)

---

## 4. Spec-to-Test Fidelity

10 of 10 expectations are covered. One partial-fidelity gap identified:

- **Expectation 6 (whitespace-only):** Test asserts non-zero exit + prefix + anchor text but
  omits `[[ "$output" != *"not found"* ]]`. The spec specifically names the empty-region path.
  See **finding F01** for details.

---

## 5. Scope Drift Check

No scope drift detected. Every change in the round-09 diff falls within one of:
- Adding `extract_section_fence_aware` to `tests/helpers/skill-markdown.bash` (G3)
- Adding fence-aware tests to `tests/unit/test-helpers-skill-markdown.bats` (G3 coverage)
- Removing inline `extract_review_round` and migrating call sites in
  `tests/unit/test-skill-md-content-patterns.bats` (G3 migration)

No changes touch any file outside the G3 scope (G1–G2, G4, G6, G7a, G7b are unaffected).

---

## 6. Goal Coverage Check

Task-03 is assigned `goal_ids: [G3]` only. G3's problem statement and "What we know so far"
section enumerate:
- fence-tracking helper as inline duplicate → **resolved** (function promoted to shared helper)
- `extract_section` could not handle it → **resolved** (new dedicated function with different signature)
- Either Candidate A or B acceptable → **Candidate B shipped** (separate `extract_section_fence_aware`, heading-only `extract_section` unchanged)
- Bash 3.2 portability → **confirmed** (awk-only, no bash4+ features)
- empty-extract guard semantics → **preserved** (FOUND_EMPTY path matches intent)

No G3 sub-requirements were dropped. G3 closure criterion ("dedicate function in shared
helper, inline removed, unit coverage") is met.

---

## Findings

| ID | Severity | Type | File | Summary |
|---|---|---|---|---|
| F01 | medium | correctness | tests/unit/test-helpers-skill-markdown.bats | Whitespace-only test missing `!= "not found"` assertion — spec-to-test fidelity gap |
| F02 | low | style | reviews/tasks/task-03/done-report.md | done-report implementation note is stale (PID-scoped path superseded by mktemp) |
| F03 | low | style | tests/unit/test-helpers-skill-markdown.bats | `[r7-sf.F01]` test name has inconsistent round-prefix vs sibling finding tests |

**Blocking findings:** 0  
**Non-blocking findings:** 3 (1 medium, 2 low)

The traceability chain from G3 → Phase 1 Criterion 7 → task-03 spec → tests → implementation
is complete and intact. The task is effectively at terminal-clean state; F01 is the only
finding that reduces spec-to-test confidence, and it does not affect production correctness.
