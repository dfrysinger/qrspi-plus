---
status: approved
task: 24
phase: 1
pipeline: full
goal_ids: [G5]
task_type: tdd
tier: low
---

# Task 24b: Create tests/lint/test-obc-script-absent-anchor.bats

- **Target files:** `tests/lint/test-obc-script-absent-anchor.bats` (Create)
- **Dependencies:** T20b, T21, T22
- **LOC estimate:** ~30
- **Description:** A grep audit asserts `skills/implement/SKILL.md`, `skills/integrate/SKILL.md`, and `skills/test/SKILL.md` each carry the verbatim pre-invocation OBC-script-existence check that writes `obc-script-absent:` to `## Dispatch defects` and halts before invocation. The lint locks the consumer-side script-absent dispatch-defect anchor across all three phase-skill prose surfaces against silent SKILL-prose drift that would break the design.md G5 Step-N caller-side existence-check contract. Per structure.md L97 file-map row and the G5 § Acceptance block, this lint is named alongside the phase-base-write lint (T24) as the second G5 anchor-phrase guard — T24 locks the phase-base.txt write step in integrate/test, T24b locks the OBC-script-absent pre-invocation check across implement/integrate/test.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - `skills/implement/SKILL.md`, `skills/integrate/SKILL.md`, and `skills/test/SKILL.md` each contain the verbatim pre-invocation OBC-script-existence check anchor naming `obc-script-absent:` as the named-diagnostic entry written under `## Dispatch defects` when the OBC script is absent or non-executable, and the halt-before-invocation direction (anchor-phrase greps, one per skill file).
  - A fixture skill body missing the OBC-script-absent anchor fails the lint with a named diagnostic identifying which of the three skill files (`skills/implement/SKILL.md`, `skills/integrate/SKILL.md`, or `skills/test/SKILL.md`) is missing the anchor (named-diagnostic discipline; no opaque `FAIL` output).
  - All three SKILLs pass the lint post-T20b / T21 / T22 implementation (positive direction asserts the load-bearing prose installed by the upstream tasks is present and discoverable).
