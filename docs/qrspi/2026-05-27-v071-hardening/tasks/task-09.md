---
status: approved
task: 9
phase: 1
pipeline: full
goal_ids: [G7b]
task_type: code
model: opus
sizing_exception: schema migration -- 41 agent frontmatter files each receive an identical single-line `model:` key deletion; bundled for atomicity so the no-model-field invariant is established in one commit and the structural lint (written first in RED) can sweep all 41 files in a single pass.
---

# Task 9: Remove model: field from all agent frontmatters with structural lint coverage

- **Target files:** `agents/qrspi-code-quality-reviewer.md` (modify), `agents/qrspi-code-simplifier.md` (modify), `agents/qrspi-design-reviewer.md` (modify), `agents/qrspi-design-scope-reviewer.md` (modify), `agents/qrspi-finding-verifier.md` (modify), `agents/qrspi-goal-traceability-reviewer.md` (modify), `agents/qrspi-goals-reviewer.md` (modify), `agents/qrspi-goals-scope-reviewer.md` (modify), `agents/qrspi-implement-gate-reviewer.md` (modify), `agents/qrspi-implementer-lightweight.md` (modify), `agents/qrspi-implementer.md` (modify), `agents/qrspi-integration-reviewer.md` (modify), `agents/qrspi-parallelize-reviewer.md` (modify), `agents/qrspi-parallelize-scope-reviewer.md` (modify), `agents/qrspi-phasing-reviewer.md` (modify), `agents/qrspi-phasing-scope-reviewer.md` (modify), `agents/qrspi-plan-goal-traceability-reviewer.md` (modify), `agents/qrspi-plan-reviewer.md` (modify), `agents/qrspi-plan-scope-reviewer.md` (modify), `agents/qrspi-plan-security-reviewer.md` (modify), `agents/qrspi-plan-silent-failure-hunter.md` (modify), `agents/qrspi-plan-spec-reviewer.md` (modify), `agents/qrspi-plan-test-coverage-reviewer.md` (modify), `agents/qrspi-questions-reviewer.md` (modify), `agents/qrspi-replan-analyzer.md` (modify), `agents/qrspi-replan-reviewer.md` (modify), `agents/qrspi-replan-scope-reviewer.md` (modify), `agents/qrspi-research-collator.md` (modify), `agents/qrspi-research-reviewer.md` (modify), `agents/qrspi-research-specialist.md` (modify), `agents/qrspi-scope-tagger.md` (modify), `agents/qrspi-security-integration-reviewer.md` (modify), `agents/qrspi-security-reviewer.md` (modify), `agents/qrspi-silent-failure-hunter.md` (modify), `agents/qrspi-spec-reviewer.md` (modify), `agents/qrspi-structure-reviewer.md` (modify), `agents/qrspi-structure-scope-reviewer.md` (modify), `agents/qrspi-test-coverage-reviewer.md` (modify), `agents/qrspi-test-writer.md` (modify), `agents/qrspi-type-design-analyzer.md` (modify), `agents/qrspi-visual-fidelity-reviewer.md` (modify), `tests/unit/test-agent-frontmatter-no-model.bats` (create)
- **Dependencies:** none
- **LOC estimate:** ~90
- **Description:** The top-level `model:` YAML frontmatter key is deleted from all 41 `agents/qrspi-*.md` files. Tier-name references in dispatcher prose blocks (haiku, sonnet, opus, inherit) within each file are not modified; only the standalone `model:` key in the YAML front matter block is removed. A new structural lint test at `tests/unit/test-agent-frontmatter-no-model.bats` sweeps all files matching `agents/qrspi-*.md` and asserts that no frontmatter carries a top-level `model:` key. The test-writer writes this file in the RED phase (all 41 agents still carry the field, so the test fails); the implementer then removes the field from all 41 files to reach GREEN. The `skills:`, `description:`, `name`, and all other frontmatter fields are unmodified. Dispatch order: test-writer first, implementer second (RED-verification gate between).
- **Test expectations:**
  - `tests/unit/test-agent-frontmatter-no-model.bats` contains a test that sweeps every file matching `agents/qrspi-*.md` and fails if any frontmatter block carries a standalone top-level `model:` key
  - After all 41 agent files are modified, the structural lint test passes with zero violations reported
  - All other frontmatter keys (`skills:`, `description:`, `name:`, and any agent-specific keys) are unmodified
  - The structural lint test fails clearly in RED for each file that still carries a `model:` key, providing a useful per-file failure message

**Manual Validation:**
- Pre-merge: `git diff --stat HEAD~1 -- 'agents/qrspi-*.md'` for the Task 9 commit shows exactly 41 files changed, each with one line removed and zero lines added (verifies that only the `model:` frontmatter line was removed and no body prose was collaterally modified). Operator-verified; BATS-level git introspection is impractical for this scope (mirrors the Task 8 Manual Validation pattern).
