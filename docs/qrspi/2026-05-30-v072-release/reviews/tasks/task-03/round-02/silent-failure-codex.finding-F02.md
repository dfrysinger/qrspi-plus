---
finding_id: R2-F02
reviewer_tag: silent-failure-codex
round: 2
task: 3
severity: medium
change_type: test_coverage
referenced_files:
  - tests/unit/test-per-finding-file-emission.bats
---

# F02 — Vacuous regex in fallback assertion (line 69)

## Location

`tests/unit/test-per-finding-file-emission.bats:69`

```bash
grep -qE 'Per-Finding Disk-Write Contract|reviewer-protocol'
```

## Issue

The fallback alternative `reviewer-protocol` is too broad — almost ANY mention of `reviewer-protocol` (a substring that appears throughout the codebase including in path strings, agent frontmatter, and import statements) satisfies the regex. A reviewer file could lose all real emission-contract deferral text and still pass CI as long as some incidental `reviewer-protocol` substring remains.

## Silent-failure surface

The test is supposed to pin that the file under inspection still references the disk-write contract owner (either by its full historical name or by the protocol-skill name as a deferral pointer). The loose alternative defeats this — the test would pass on a file that has no contract-deferral language at all, as long as it imports from `reviewer-protocol` or references the skill name in unrelated context.

## Suggested fix

Match a strict, load-bearing phrase that ONLY appears when the contract-deferral text is intact. Possible patterns:

```bash
# Option A: match an exact deferral phrase the implementer must include
grep -qF 'emission contracts live in first-party-emission.md and third-party-emission.md'

# Option B: pin both the moved-out concept AND the new owner together
grep -qE 'disk-write contract.*(first-party-emission|third-party-emission)|first-party-emission.*disk-write contract'
```

## Severity rationale

Medium: same class as the T06 R1 sf-codex vacuous-regex findings — test name claims contract enforcement, regex permits passage on weaker evidence.
