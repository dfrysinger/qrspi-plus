---
status: approved
task: 34
phase: 1
pipeline: full
goal_ids: [G5]
task_type: code
model: sonnet
---

# Task 34: G5 Plan post-approval split idempotency

- **Target files:** modify `skills/plan/post-approval-split-contract.md`; modify `tests/unit/test-plan-post-approval-split.bats`
- **Dependencies:** none
- **LOC estimate:** ~110

**Overview**

Make Plan's post-approval task split safe to re-run after compaction, restart, or a partial crash by documenting the block-hash audit contract and pinning it with unit tests. The task preserves existing per-task files when their source block is unchanged, halts loudly when `plan.md` changed, and prevents stale per-task specs from silently feeding Implementation. (Why: see goals.md ### G5. Approach: see design.md ## G5.)

**Scope**

- **In:**
  - Document the single `# block-hash: <sha256-hex>` header line in `skills/plan/post-approval-split-contract.md`, including its exact position, sha256 hex/no-salt syntax, and normalized source-block hash calculation.
  - Document the idempotent three-case decision rule: absent task file dispatches, present matching hash safe-skips without rewrite, and present mismatching hash halts before approval.
  - Document the exact mismatch and missing-header halt diagnostics, the malformed-header diagnostic requirement, the new `block_hash: <sha256-hex>` sub-subagent dispatch field, and the quick-fix N=1 path.
  - Update `tests/unit/test-plan-post-approval-split.bats` to pin block-hash emission, partial-crash recovery, complete re-run no-op behavior, hand-edit preservation, mismatch/missing/malformed-header failures, and quick-fix parity.

- **Out:**
  - No sibling task shares G5; this task owns the G5 surface in the two target files only.
  - Regenerating existing `tasks/task-NN.md` files automatically on mismatch — design.md ## G5 requires delete-and-rerun or revert-plan-edit as the user-controlled resolution.
  - Adding `.split-conflict-NN.md` sidecar machinery — design.md ## G5 explicitly rejects it in favor of the halt diagnostic plus preserved existing files.
  - Changing unrelated Plan task-shape behavior or editing `plan.md` directly — this task only enhances the post-approval split contract and its tests.

**Definition of done**

- `skills/plan/post-approval-split-contract.md` contains `## Block-Hash Header Format`, `## Idempotent Split Contract`, `## HALT Diagnostic`, `## Pre-G5 Migration Diagnostic`, `## Sub-Subagent Dispatch Contract`, and `## Quick-Fix N=1 Path` sections.
- The block-hash contract states exactly one header line immediately after the closing frontmatter `---` and before body content, with syntax `# block-hash: <sha256-hex>`.
- Hash calculation is documented as sha256 hex, no salt, over the normalized source `### Task N` block; normalization strips trailing whitespace from each line and preserves all other characters and line breaks.
- The idempotent split contract documents absent → dispatch, present + matching hash → safe-skip without rewrite, and present + mismatching hash → halt before approval with the existing file untouched.
- The mismatch diagnostic text is exact: `task-NN.md exists but its source block in plan.md has changed since the last split. To regenerate from the current plan.md, delete tasks/task-NN.md and re-run. To preserve the existing file, revert your plan.md edit.`
- The missing-header diagnostic text is exact: `task-NN.md is present but carries no '# block-hash:' header. This file predates the idempotent-split contract. To regenerate under the current contract, delete tasks/task-NN.md and re-run.`
- Malformed block-hash handling halts with a diagnostic that names `malformed block-hash header` and does not rewrite the existing file.
- The sub-subagent dispatch contract includes `block_hash: <sha256-hex>` and instructs the writer to emit that value immediately after frontmatter close.
- The quick-fix N=1 path emits the same header and applies the same absent, matching, mismatching, missing-header, and malformed-header audit rules on re-run.
- Unit tests cover all behavior above, including partial-split crash recovery, complete-set re-run with zero sub-subagent dispatches, and hand-edit preservation when the stored source block hash still matches.

**Test expectations**

- `tests/unit/test-plan-post-approval-split.bats` verifies every generated `tasks/task-NN.md` contains a single `# block-hash: <sha256-hex>` line immediately after the closing frontmatter `---` and before the first body content.
- The hash calculation is verified as sha256 hex with no salt over the normalized source `### Task N` block, where normalization strips trailing whitespace from each line and preserves all other characters and line breaks.
- A partial split crash scenario with only some task files present dispatches only the missing task files on re-run; existing matching files are not rewritten and exact-set verification still passes once all expected files exist.
- A completed split re-run with all task files present and matching hashes dispatches zero sub-subagents and proceeds to plan reduction plus approval-state completion.
- A hand-edited existing `tasks/task-NN.md` whose stored block hash still matches the current `plan.md` task block is safe-skipped without overwriting the hand edit.
- A changed `plan.md` `### Task N` block with an existing task file whose stored hash no longer matches halts before approval, leaves the existing task file untouched, and emits exactly: `task-NN.md exists but its source block in plan.md has changed since the last split. To regenerate from the current plan.md, delete tasks/task-NN.md and re-run. To preserve the existing file, revert your plan.md edit.`
- An existing task file with no `# block-hash:` line halts with exactly: `task-NN.md is present but carries no '# block-hash:' header. This file predates the idempotent-split contract. To regenerate under the current contract, delete tasks/task-NN.md and re-run.`
- An existing task file with a malformed block-hash line halts with a diagnostic that names `malformed block-hash header` and does not rewrite the file.
- The quick-fix single-task path emits the same `# block-hash:` line and applies the same absent, match, mismatch, missing-header, and malformed-header audit rules on re-run.
- Grep-based documentation audit confirms `skills/plan/post-approval-split-contract.md` documents `## Block-Hash Header Format`, `## Idempotent Split Contract`, `## HALT Diagnostic`, `## Pre-G5 Migration Diagnostic`, `## Sub-Subagent Dispatch Contract`, and `## Quick-Fix N=1 Path` with the required position, syntax, normalization, decision cases, and diagnostics.

**References**

- goals.md ### G5 — problem framing for compaction/restart-safe Plan splitting and data-loss avoidance.
- design.md ## G5 — idempotent decision rule, block-hash audit, halt diagnostics, edge cases, and acceptance criteria.
- structure.md ### `skills/plan/post-approval-split-contract.md` — required contract sections, exact diagnostics, dispatch field, and quick-fix clause.
- structure.md ### `tests/unit/test-plan-post-approval-split.bats` — required unit coverage for block-hash emission, safe re-run, loud conflicts, migration diagnostic, partial recovery, hand-edit preservation, and quick-fix parity.
