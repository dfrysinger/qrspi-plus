---
finding_id: F01
reviewer_tag: code-quality-claude
round: 1
severity: high
change_type: correctness
referenced_files:
  - tests/unit/test-change-type-partition.bats:175
  - tests/unit/test-change-type-partition.bats:186
  - tests/unit/test-change-type-partition.bats:213
  - tests/unit/test-change-type-partition.bats:249
  - tests/unit/test-change-type-partition.bats:296
  - tests/unit/test-change-type-partition.bats:315
  - tests/unit/test-change-type-partition.bats:365
  - tests/unit/test-change-type-partition.bats:397
artifact: tests/unit/test-change-type-partition.bats
---

# ID Hygiene: QRSPI-internal IDs embedded in test names and comments

Every new `@test` block added in this diff carries the QRSPI goal ID `G13` as a
colon-prefixed label inside the test-name string, and the section block comment
also contains a bare `G13` reference as well as a `T04` task-ID reference.

## What the rule says

Per the reviewer-protocol ID hygiene rules, **QRSPI-internal IDs (G/R/D/F/T/Q-prefixed
numeric tokens) are forbidden in test names, `@test` strings, and code comments**
except under `docs/qrspi/`.  `G13` matches the pattern `\bG-?[0-9]+\b`; `T04`
matches `\bT-?[0-9]+\b`.  Both are run-specific tracking tokens that were present
in the task spec and have been copied verbatim into the production test surface.

## Affected locations

| Location | Offending token |
|---|---|
| `# G13 enum-drift hardening …` (block comment, ~line 175) | `G13` |
| `# preserves the T04 schema-failure contract` (block comment, ~line 186) | `T04` |
| `@test "G13: out-of-enum change_type …"` (~line 213) | `G13` |
| `@test "G13: all five canonical change_type …"` (~line 249) | `G13` |
| `@test "G13: missing change_type …"` (~line 296) | `G13` |
| `@test "G13: scripts/verifier-fan-in.sh …"` (~line 315) | `G13` |
| `@test "G13: skills/reviewer-protocol/SKILL.md …"` (~line 365) | `G13` |
| `@test "G13: no duplicated 5-value …"` (~line 397) | `G13` |

Note that the *existing* tests in this file (lines 11–49) do not use any
QRSPI-ID prefix in their names — the `G13:` prefix is inconsistent with the
established naming pattern as well as violating the ID hygiene contract.

## Why this matters

Test names surface in CI output, `bats --tap` logs, and review transcripts.
Embedding run-specific tracking tokens ties the test identity to a transient
planning artefact; if the goal is ever renumbered or the test is moved to a
different task's scope, the name carries a stale ID with no mechanism for
update.  The rule exists precisely to prevent this leakage path.

## Suggested fix

Strip the `G13:` prefix from every `@test` name and rewrite it as a
behaviour-descriptive label — the existing test bodies already carry thorough
inline comments that explain the motivation without needing the ID:

```
@test "out-of-enum change_type triggers change_type_out_of_enum halt and blocks kept-findings.txt"
@test "all five canonical change_type values are accepted through the same parser path"
@test "missing change_type is reported as missing_change_type, not change_type_out_of_enum"
@test "verifier-fan-in.sh declares the canonical enum once and validates against that single set"
@test "reviewer-protocol SKILL.md documents the canonical enum once as the reviewer emission contract"
@test "no duplicated 5-value change_type enum alternation outside canonical sources"
```

In the block comment, replace `G13 enum-drift hardening` with a plain description
(e.g. `enum-drift hardening`) and replace `preserves the T04 schema-failure contract`
with `preserves the distinct missing-field halt cause`.
