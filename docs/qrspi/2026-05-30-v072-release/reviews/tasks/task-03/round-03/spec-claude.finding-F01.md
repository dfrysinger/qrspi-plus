---
finding_id: R3-F01
severity: low
change_type: scope
referenced_files: [agents/qrspi-design-reviewer.md, agents/qrspi-design-scope-reviewer.md, agents/qrspi-goals-reviewer.md, agents/qrspi-goals-scope-reviewer.md, agents/qrspi-parallelize-reviewer.md, agents/qrspi-parallelize-scope-reviewer.md, agents/qrspi-phasing-reviewer.md, agents/qrspi-phasing-scope-reviewer.md, agents/qrspi-questions-reviewer.md, agents/qrspi-replan-reviewer.md, agents/qrspi-replan-scope-reviewer.md, agents/qrspi-research-reviewer.md, agents/qrspi-structure-reviewer.md, agents/qrspi-structure-scope-reviewer.md]
artifact: task-03
round: 3
reviewer: spec-claude
---

**Advisory scope flag (per Verification Checklist §7) — 14 reviewer-agent files modified outside declared Target files.**

Task 03 declares its Target files as `skills/reviewer-protocol/SKILL.md`, `skills/reviewer-protocol/first-party-emission.md`, `skills/reviewer-protocol/third-party-emission.md`, and `tests/unit/test-per-finding-file-emission.bats`. The R3 implementation also modifies 14 `agents/qrspi-*-reviewer.md` files (mechanical string substitution: `**Per-Finding Disk-Write Contract** in the \`reviewer-protocol\` skill` → `disk-write contract from the reviewer-protocol skill`). These files are NOT in the Target files list.

**Files outside Target list:**
- `agents/qrspi-design-reviewer.md`, `agents/qrspi-design-scope-reviewer.md`
- `agents/qrspi-goals-reviewer.md`, `agents/qrspi-goals-scope-reviewer.md`
- `agents/qrspi-parallelize-reviewer.md`, `agents/qrspi-parallelize-scope-reviewer.md`
- `agents/qrspi-phasing-reviewer.md`, `agents/qrspi-phasing-scope-reviewer.md`
- `agents/qrspi-questions-reviewer.md`
- `agents/qrspi-replan-reviewer.md`, `agents/qrspi-replan-scope-reviewer.md`
- `agents/qrspi-research-reviewer.md`
- `agents/qrspi-structure-reviewer.md`, `agents/qrspi-structure-scope-reviewer.md`

**Implementer rationale (per dispatch prompt):** Fix 3 (in-scope, legitimately closing a spec gap from R2) removed the vacuous `Per-Finding Disk-Write Contract|reviewer-protocol` fallback regex from bats test 1. After that removal, the 14 agents' pre-existing wording matched neither remaining accept path — they would fail the test. The migration brings them into compliance.

**Evaluation of alternatives:**

1. **Keep the hatch loose** (i.e. don't ship Fix 3 fully): undermines the strictness gain the fix was designed to deliver and leaves a spec gap unclosed.
2. **Decompose into a sibling task in v0.7.2**: would have left CI red between this task's merge and the sibling task's merge, blocking the release pipeline.
3. **Update the agents inline** (what was done): mechanical, risk-free, semantically null (the new wording is *more* accurate post-split because no section named "Per-Finding Disk-Write Contract" exists in SKILL.md any longer — it was removed in the split).

Option 3 is the most pragmatic given the final-fix-cycle budget constraint. The migration does not change reviewer-agent behavior — it only updates a reference phrase to match the post-split contract location.

**Recommendation: update the task spec retroactively to reflect the actual modified surface, do NOT rework.** The implementation choice was defensible. For future similar cascades (reviewer-protocol skill edits that force consistent wording across many agents), the task spec should declare the agent surface in `Target files:` up front, OR hoist the migration into a paired sibling task in the same phase so the boundary is explicit.

The 12/12 bats tests pass with this surface; all DoD items and test expectations are satisfied; no new spec gaps were introduced. Gate disposition: **PASS** (advisory finding, not blocking).
