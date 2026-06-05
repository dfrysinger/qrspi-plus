---
finding: F01
reviewer: code-simplifier-claude
round: 4
severity: advisory
category: dead-code
---

# Redundant first `run grep` in guard-reference test

**File:** `tests/unit/test-task-25-round03-fixes.bats`  
**Lines:** 121–128

## Current pattern

```bash
@test "reviewer SKILL.md guard references INCLUDE-BEGIN" {
  run grep -F 'INCLUDE-BEGIN' "$REVIEWER_SKILL"
  # Must appear in the guard block (at minimum, present in the file)
  [ "$status" -eq 0 ]
  # The guard comment itself must reference the marker scheme
  run grep -iE 'INCLUDE-BEGIN.*INCLUDE-END|INCLUDE-BEGIN/INCLUDE-END|BEGIN.*END.*pair' "$REVIEWER_SKILL"
  [ "$status" -eq 0 ]
}
```

## Why it's redundant

The first assertion (`grep -F 'INCLUDE-BEGIN'`) checks that the literal string `INCLUDE-BEGIN` appears anywhere in the file. The second assertion (`grep -iE 'INCLUDE-BEGIN.*INCLUDE-END|INCLUDE-BEGIN/INCLUDE-END|BEGIN.*END.*pair'`) is strictly more restrictive — every match of the second pattern necessarily contains `INCLUDE-BEGIN` (or `BEGIN`). Consequently:

- If the second grep passes → the first would also pass (dead check).
- If the first grep fails → the second would also fail (no extra signal gained).

Additionally, the 8 marker-presence tests earlier in the file already independently establish that `INCLUDE-BEGIN` exists in `$REVIEWER_SKILL`, so this check carries no new coverage.

## Suggested simplification

Drop the first `run` + assertion pair; keep only the substantive regex:

```bash
@test "reviewer SKILL.md guard references INCLUDE-BEGIN" {
  run grep -iE 'INCLUDE-BEGIN.*INCLUDE-END|INCLUDE-BEGIN/INCLUDE-END|BEGIN.*END.*pair' "$REVIEWER_SKILL"
  [ "$status" -eq 0 ]
}
```

This matches the leaner form already used for the writer counterpart at lines 130–133, making the two tests symmetric.
