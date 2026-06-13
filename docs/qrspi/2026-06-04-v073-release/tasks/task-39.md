---
status: approved
task: 39
phase: 1
pipeline: full
goal_ids: [G2]
task_type: tdd
tier: low
---

# Task 39: Add tests/unit/test-check-bats-id-hygiene-sweep.bats covering the pre-committed structural-lint script

- **Target files:** `tests/unit/test-check-bats-id-hygiene-sweep.bats` (Create)
- **Dependencies:** none
- **LOC estimate:** ~30
- **Description:** A bats test file exercising the pre-committed `scripts/structural-lints/check-bats-id-hygiene-sweep.sh` against fixture diffs. The script is checked in at the repository root out-of-band of this plan (per `skills/plan/SKILL.md` § Schema-Migration Task Shape Plan-spec defects bullet 4, the structural-lint script must exist at plan-spec review time); T39 adds the CI coverage so the script's behaviour is locked against regressions.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - A fixture diff containing only `@test "..."` description-string token strips inside `.bats` files exits 0 (mechanical-only pass).
  - A fixture diff containing a brand-new file under `tests/fixtures/` plus `@test` description strips exits 0 (fixture-relocation pass).
  - A fixture diff containing a body-content change inside an existing `.bats` test body (not a fixture-construction line) exits non-zero with a named diagnostic naming the offending file and line.
  - A fixture diff containing an edit to a non-`.bats` file outside `tests/fixtures/` exits non-zero with a named diagnostic.
  - An empty diff exits non-zero (vacuous pass forbidden per Plan-spec defects bullet 5).
- **cross_task_consumers:**
  - `plan.md` task T11 — disposition: `pass-through` (T11's `structural_lint:` field cites the pre-committed script; T11 does not edit it; T39 covers the script with bats tests).
- **Author Note:** goal-traceability-codex R8-F01 notes that T39 (bats coverage for the pre-committed `check-bats-id-hygiene-sweep.sh` structural-lint script) is not commitment-named in design.md or structure.md. The upstream authority for the meta-test is `skills/plan/SKILL.md` § Schema-Migration Task Shape — Plan-spec defects bullet 4: "The structural-lint script must exist at plan-spec review time". T11's schema-migration exception cites this script as its `structural_lint:`; T39 adds CI coverage so the script's behaviour is locked against silent regression that would invalidate T11's mandatory-trio existence check. The trace is via SKILL contract (T11's structural_lint dependency) not via design.md G2's three behavioural surfaces. Re-opening to either remove T39 or amend design/structure to introduce a G2 fourth surface is a design-phase decision; this plan honours the SKILL-contract trace.
