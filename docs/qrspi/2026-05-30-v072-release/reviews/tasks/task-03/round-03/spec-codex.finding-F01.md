---
finding_id: R3-F01
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/tasks/task-03.md:L13
  - docs/qrspi/2026-05-30-v072-release/reviews/tasks/task-03/round-03.diff:L1-L182
artifact: task-03
round: 3
reviewer: spec-codex
---

# F01 — 14-agent-file scope expansion outside declared Target files (medium · scope)

Task-03's declared Target files are limited to four paths (`SKILL.md`, the two emission siblings, and `tests/unit/test-per-finding-file-emission.bats`) at `task-03.md:L13`, but this round's implementation also edits 14 reviewer agent files (`round-03.diff:L1-L182`). That is significant out-of-target-file scope expansion.

The edits appear mechanical (phrase migration: `"Per-Finding Disk-Write Contract" in the \`reviewer-protocol\` skill` → `disk-write contract from the reviewer-protocol skill`), but this still violates the task's "not more, not less" scope contract unless explicitly authorized.

**Coupling rationale:** Fix 3 in R3 removed the vacuous `Per-Finding Disk-Write Contract|reviewer-protocol` regex hatch from test 1. Agent bodies that previously matched the now-removed alternative would fail the now-stricter test. The implementer concluded the only way to keep tests passing was to migrate those 14 agent bodies to wording that matches the inline-deferral hatch.

**Recommendation:** Either
- (a) revert the 14 agent-file edits and keep Task-03 confined to declared targets (would require Fix 3 to ALSO be reverted or rewritten to preserve test passes on the existing agent wording)
- (b) accept the scope expansion as an in-scope cascade of Fix 3 and retroactively amend the task spec to include those agent files with explicit rationale; flag for v0.7.3 plan-improvement: "Plan should anticipate test-hatch tightening cascades into reviewer agent body wording"
- (c) split the migration into a separate hygiene task/changelog entry (task-03b)

**Orchestrator note:** Option (b) is the pragmatic call — the migration is mechanical, doesn't change agent behavior, and is logically required by Fix 3 (which was an in-scope test fix). Flag for v0.7.3 process improvement: plan author should anticipate cross-file cascades when prescribing test-hatch tightening.
