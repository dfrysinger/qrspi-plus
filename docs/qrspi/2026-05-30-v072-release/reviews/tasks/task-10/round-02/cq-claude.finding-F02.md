---
finding_id: R2-F02
reviewer_tag: cq-claude
severity: low
change_type: clarity
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L104-L196
---

# QRSPI-internal G28 IDs in bats test names

The diff adds or re-emits five `@test` names carrying the QRSPI-internal goal ID `G28`:

| Diff line | Test name | Status |
|-----------|-----------|--------|
| +104 | `"[G28 AC1] verifier agent body documents defect_class field + regex …"` | re-emitted (description renamed) |
| +139 | `"[G28 AC2] verifier agent body documents the ≤30-character cap…"` | **net-new** |
| +170 | `"[G28 AC3] verifier agent body documents 'defect_class: unspecified' fallback"` | **net-new** |
| +175 | `"[G28 AC4] sub-threshold findings cannot reach kept-findings.txt…"` | re-emitted |
| +196 | `"[G28 AC5] SKILL.md documents optional ## Sub-Threshold Observations…"` | re-emitted |

`G28` matches the QRSPI-internal pattern `\b[GRDFTQ]-?[0-9]+\b`. Per ID hygiene rules, G-prefixed numeric tokens are forbidden in test names outside `docs/qrspi/`. The two net-new test functions (`AC2`, `AC3`) introduce new violations in this diff; the three others re-emit pre-existing violations during rename.

The block comment header `# G28 —` at line 1957 is an unchanged context line (pre-existing) and is noted for completeness but is not a new violation in this diff.

**Fix:** Strip the `[G28 ACN]` prefix from all five test names; AC numbering and description alone are sufficient. E.g.: `"[AC2] verifier agent body documents the ≤30-character cap on defect_class tokens"`. If traceability to the goal is desired, a code comment above the block (outside the test-name string) is the appropriate location.

**Convergent with cq-codex R2-F01 (severity HIGH there, LOW here).**
