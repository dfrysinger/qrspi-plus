---
finding_id: R2-F03
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/parallelization.md:L105-L116]
artifact: parallelize
round: 2
reviewer: quality-claude
---

All 12 Wave 1 Branch Map entries use `feature branch tip` (space-separated) as the Base value. The symbolic vocabulary defined in the parallelize reviewer protocol requires `feature-branch-tip` (hyphen-separated). The space form is not part of the canonical vocabulary: `feature-branch-tip`, `stage-{N}`, and `task-NN-tip` are the three recognized symbolic Base values.

This affects every Wave 1 task: task-01 through task-41 (12 rows). The Branch Map should be updated to use `feature-branch-tip` consistently so the Base vocabulary is unambiguous and machine-parseable.
