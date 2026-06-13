---
status: approved
task: 8
phase: 1
pipeline: full
goal_ids: [CD-3]
task_type: tdd
tier: low
---

# Task 08: Create tests/lint/test-prompt-design-rules-r8.bats

- **Target files:** `tests/lint/test-prompt-design-rules-r8.bats` (Create)
- **Dependencies:** T07
- **LOC estimate:** ~35
- **Description:** An anchor-phrase grep test asserts the R8 section is present and exact in `skills/_shared/prompt-design-rules.md`: the heading `### R8 — Prose density: short declarative sentences, full behavioral precision`, the tightening-pattern table header `| Pattern in current prose | Tightened form | Why it works |`, the `What NOT to tighten` subheading, the reviewer-test sentence, the literal `R1-R8` substring in the finding-type gate `rule-violation` row, no duplicated R-rule headings (R1–R8 each appear exactly once), and every R-ID cited in the finding-type gate exists as a heading.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - The R8 heading is present verbatim (CD-3 Acceptance bullet 1, first sub-clause).
  - The tightening-pattern table header is present verbatim (CD-3 Acceptance bullet 1, second sub-clause).
  - The `What NOT to tighten` subheading is present verbatim (CD-3 Acceptance bullet 1, third sub-clause).
  - The reviewer-test sentence is present exact (CD-3 Acceptance bullet 1, fourth sub-clause).
  - The `rule-violation` row of the finding-type gate cites the literal substring `R1-R8` (CD-3 Acceptance bullet 2).
  - No R-rule heading is duplicated and every R-ID cited in the finding-type gate exists as a section heading (CD-3 Acceptance bullet 4).
  - A fixture file with a duplicated R3 heading fails the lint (fail-direction guard).
