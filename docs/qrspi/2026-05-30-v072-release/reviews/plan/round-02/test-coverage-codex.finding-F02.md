---
reviewer_tag: test-coverage-codex
change_type: correctness
severity: medium
artifact: plan.md
location: "Tasks 29 and 37 — Target files vs Test expectations"
referenced_files:
  - plan.md
---

# F02 — Declared deliverables not verified in test expectations

## Defect

- **T29** target files include `tests/lint/test-design-altitude-boundary-include.bats`, but test expectations do not verify that file exists or what it asserts.
- **T37** target files include `skills/structure/owns-defers.md` and `tests/lint/test-structure-altitude-boundary-include.bats`, but test expectations largely verify only the shared boundary file + `skills/structure/SKILL.md`.

## Impact

Parts of each task's intended output go untested. Completion is unverifiable for those declared artifacts.

## Recommended fix

Add explicit test-expectation bullets that pin the existence and required content of each Target file. This is the same defect class quality-claude.F01/F02 flagged from a different angle — they pointed at the contradiction between Target and Out/DoD; this finding points at the contradiction between Target and Test expectations.

## Duplicate-of note

Overlaps with quality-claude.F01 (T37), quality-claude.F02 (T29), and test-coverage-claude.F03. Scope-tagger H2 grouping should collapse.
