---
finding_id: R5-F04
severity: low
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L1114-L1118
artifact: plan
round: 5
reviewer: test-coverage-claude
---

T24 (`test-integrate-test-skill-phase-base-write.bats`) Test Expectations — failure diagnostic does not specify which file is named.

T24's failure test says: "A fixture skill body missing the write step fails the lint with a named diagnostic." This asserts non-zero exit and the existence of some diagnostic, but does not specify whether the diagnostic identifies *which* file failed.

**Why this matters:** T24 checks two separate files — `skills/integrate/SKILL.md` and `skills/test/SKILL.md`. When a developer removes the `reviews/integration/phase-base.txt` write step from one of these files, they need to know which file triggered the failure (particularly if the lint is run as a pre-commit hook or in CI against a large PR). A test asserting only "fails with a named diagnostic" allows an implementation that emits `FAIL` without naming the file.

**Comparison:** T18 says "The lint's failure output names the offending file, line, and the non-enumerated marker text (named-diagnostic discipline)." T12 requires `file:line` in failure output. T24 lacks this parallel discipline.

**Fix:** Add one clause to the failure test bullet specifying that the diagnostic names the failing file (e.g., "…fails with a named diagnostic identifying which of the two skill files is missing the write step").
