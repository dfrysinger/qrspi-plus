---
reviewer_tag: test-coverage-claude
round: 8
finding_id: R8-F03
severity: low
change_type: scope
referenced_files: [tests/acceptance/v07-phase1/test-phase1-acceptance.bats]
---

# F03 — First-party `dispatch_spec` exact key count not pinned (AC9 asymmetry)

## Finding

AC9 (third-party) pins exact key count (`keys | length == 8` top-level, `keys | length == 4` in dispatch_spec) explicitly as defense-in-depth against injection forging extra audit fields. AC2/AC5 (first-party) verify all five `dispatch_spec` fields by value but do NOT pin the key count.

## Severity

LOW: AC9 inline comment makes the defense-in-depth rationale explicit; asymmetry weakens that argument for first-party auditing.

## Suggested test additions

In AC2 and AC5:
```bash
jq -e '.[0].dispatch_spec | keys | length == 5' "$manifest" >/dev/null
jq -e '.[0] | keys | length == 5' "$manifest" >/dev/null
```
