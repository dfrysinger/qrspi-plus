---
finding_id: R01-F01
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/parallelization.md:L384-L385
artifact: parallelize
round: 1
reviewer: scope-claude
---

The `## Operational Notes` **Task-00 reservation** bullet crosses into Implement's runtime territory. It describes (a) the condition under which Implement runs baseline tests and what happens on failure, (b) the task-00 runtime injection mechanism ("injects between the feature branch and Wave 1 leaves"), and (c) how Implement must record the injection ("Implement persists the injection via `## Runtime Adjustments` per the skill contract").

Per the Parallelize DEFERS rule: *"Concrete commit hashes, branch creation, worktree creation, baseline tests, runtime-injected `task-00` — owned by Implement at runtime; Parallelize records only symbolic bases."* All three elements of this bullet — baseline-test execution, the task-00 injection step, and the `## Runtime Adjustments` record-keeping obligation — are Implement-owned runtime behaviors.

Parallelize may legitimately reserve a `task-00` slot in the symbolic branch namespace (so the graph topology is coherent if injection occurs), but the runtime trigger condition and Implement's procedural response belong in `implement/SKILL.md`, not here. The fix is to remove this bullet from `parallelization.md`, or reduce it to a single symbolic-reservation note ("The `task-00` branch slot is reserved immediately before Wave 1 task branches if needed") that makes no claim about Implement's runtime behavior.
