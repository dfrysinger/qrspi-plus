---
finding_id: R1-F04
reviewer_tag: spec-claude
round: 1
task: 34
severity: low
change_type: correctness
referenced_files:
  - skills/plan/post-approval-split-contract.md
---

## F04 — Pre-G5 missing-header section missing regeneration instruction phrase

`## HALT Diagnostic` includes regeneration phrase (`delete tasks/task-NN.md and re-run`). `## Pre-G5 Migration Diagnostic` for missing-header does NOT include the equivalent regeneration instruction.

Spec consistency: pre-G5 migration users hitting missing-header should get the same actionable guidance.

Fix: add regeneration instruction to pre-G5 missing-header diagnostic OR explicitly note divergence is intentional.
