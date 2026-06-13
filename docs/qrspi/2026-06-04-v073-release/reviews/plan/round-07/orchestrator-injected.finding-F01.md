---
finding_id: R7-F-ORCHESTRATOR-01
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/structure.md:L97
  - docs/qrspi/2026-06-04-v073-release/plan.md (G5 task chain)
artifact: plan
round: 7
reviewer: orchestrator-injected
---

Structure.md hotfix (commits da1e980 → a8dbce6 → dda4373 → ae593d1, aligning OBC contract with d3fff0d design amendment + dual-reviewed clean over 4 rounds) introduced a new file-table Create row at structure.md L97:

```
| `tests/lint/test-obc-script-absent-anchor.bats` | Create | T2 lint: anchor-phrase grep asserting `skills/implement/SKILL.md`, `skills/integrate/SKILL.md`, and `skills/test/SKILL.md` each carry the verbatim pre-invocation OBC-script-existence check that writes `obc-script-absent:` to `## Dispatch defects` and halts before invocation. | G5 |
```

Plan.md has no task creating this file. Sibling lint `tests/lint/test-integrate-test-skill-phase-base-write.bats` is carved as T24; the new lint needs a parallel task.

**Fix.** Add a new task T24b parallel to T24 in plan.md:
- Title: `Create tests/lint/test-obc-script-absent-anchor.bats`
- goal_id(s): G5
- task_type: tdd
- task_class: lightweight
- LOC: ~30
- dependencies: T20b, T21, T22 (must follow SKILL-prose tasks that install the anchor)
- target files: `tests/lint/test-obc-script-absent-anchor.bats` (Create)
- Description: Mirror T24's shape but target the `obc-script-absent:` pre-invocation check anchor across all three SKILLs (implement/integrate/test).
- Test expectations: per-SKILL anchor-phrase grep; fail-direction fixture (a SKILL.md missing the anchor → lint failure with named diagnostic); fixture asserting all three SKILLs pass post-T20b/T21/T22 implementation.

Update the partition table header to `(45 tasks)` (post the goal-traceability-claude R7-F01 fix that will already update from 43 → 44 — T24b adds one more, so 44 → 45). Update the Dependency graph G5 chain to add `T20b + T21 + T22 → T24b` alongside the existing `T21 + T22 → T24` edge. Add `cross_task_consumers:` per Sweep+consumer composition rule.
