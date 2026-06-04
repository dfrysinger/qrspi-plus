---
finding: F03
reviewer: code-simplifier-claude
round: 4
severity: advisory
category: unnecessary-complexity
---

# 8 paired ordering tests duplicate `cat_line` extraction; could be 4 combined tests

**File:** `tests/unit/test-task-25-round03-fixes.bats`  
**Lines:** 107–117, 120–133 (reviewer section); 137–163 (writer section)

## Current pattern

Each include block's ordering is verified as **two separate tests** that each re-extract `cat_line` independently:

```bash
@test "reviewer SKILL.md: INCLUDE-BEGIN for detection precedes its !cat line" {
  begin_line=$(grep -n 'INCLUDE-BEGIN: prompt-prose-detection' "$REVIEWER_SKILL" | head -1 | cut -d: -f1)
  cat_line=$(grep -n '!cat skills/_shared/prompt-prose-detection.md' "$REVIEWER_SKILL" | head -1 | cut -d: -f1)
  [ -n "$begin_line" ] && [ -n "$cat_line" ]
  [ "$begin_line" -lt "$cat_line" ]
}

@test "reviewer SKILL.md: !cat for detection precedes its INCLUDE-END line" {
  cat_line=$(grep -n '!cat skills/_shared/prompt-prose-detection.md' "$REVIEWER_SKILL" | head -1 | cut -d: -f1)
  end_line=$(grep -n 'INCLUDE-END: prompt-prose-detection' "$REVIEWER_SKILL" | head -1 | cut -d: -f1)
  [ -n "$cat_line" ] && [ -n "$end_line" ]
  [ "$cat_line" -lt "$end_line" ]
}
```

The identical `grep -n '!cat skills/_shared/prompt-prose-detection.md' ... | head -1 | cut -d: -f1` call appears in **both** tests. The same duplication exists for all four include blocks (2 blocks × 2 files = 8 tests = 4 duplicated `cat_line` extractions).

## Why it's unnecessarily complex

The invariant under test is **BEGIN < !cat < END** — a single three-value ordering constraint. Splitting it into two tests:
- Doubles the number of test cases (8 instead of 4).
- Duplicates the `grep -n ... | head -1 | cut` shell pipeline for `cat_line` in each pair.
- Adds no extra diagnostic resolution: a combined test names exactly which block failed the ordering check, and the ordering direction is self-evident from the variable names and assertion.

## Suggested simplification

Merge each pair into one combined ordering test:

```bash
@test "reviewer SKILL.md: detection block has BEGIN < !cat < END ordering" {
  begin_line=$(grep -n 'INCLUDE-BEGIN: prompt-prose-detection' "$REVIEWER_SKILL" | head -1 | cut -d: -f1)
  cat_line=$(grep -n '!cat skills/_shared/prompt-prose-detection.md' "$REVIEWER_SKILL" | head -1 | cut -d: -f1)
  end_line=$(grep -n 'INCLUDE-END: prompt-prose-detection' "$REVIEWER_SKILL" | head -1 | cut -d: -f1)
  [ -n "$begin_line" ]
  [ -n "$cat_line" ]
  [ -n "$end_line" ]
  [ "$begin_line" -lt "$cat_line" ]
  [ "$cat_line" -lt "$end_line" ]
}
```

Apply the same merge to the remaining three include blocks (reviewer-addition, writer-detection, writer-addition), reducing 8 ordering tests to 4 while preserving every assertion. Each `cat_line` extraction runs once instead of twice per block.

**Note:** This is advisory only — the existing split structure is correct and the tests pass. The merge is a quality note for the next batch that touches this file.
