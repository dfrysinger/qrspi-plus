---
finding_id: R3-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/parallelization.md:L109-L155]
artifact: parallelize
round: 3
reviewer: quality-codex
---

The Branch Map uses Base values such as `feature branch tip`, `task-01 tip`, and `stage-after-W1`, but the reviewer contract requires plan-time Base values to use the symbolic vocabulary `feature-branch-tip`, `stage-{N}`, and `task-NN-tip`. Leaving the Branch Map in a different vocabulary makes the plan inconsistent with the symbolic-base contract and can mislead downstream automation or reviewers that match the canonical tokens.

Fix: rewrite every Branch Map Base value to the canonical symbolic forms, consistently applying the same vocabulary in the Execution Order and cross-wave chain prose where those base names are referenced.
