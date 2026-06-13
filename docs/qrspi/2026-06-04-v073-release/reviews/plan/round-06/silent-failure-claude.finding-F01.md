---
finding_id: R6-F01
severity: medium
change_type: correctness
referenced_files:
  - "docs/qrspi/2026-06-04-v073-release/plan.md:L1107-L1131"
artifact: plan
round: 6
reviewer: silent-failure-claude
---

T25 (`validate-stage-commit-parents.sh`) specifies test coverage for `--validate` failure modes but leaves `--capture` failure modes completely unspecified. The wave-dispatch sequence is: (1) `--capture`, (2) `git merge --no-ff`, (3) `--validate`. If `--capture` fails (git rev-parse error, unwritable sidecar dir, disk full) and exits 0 without writing the sidecar, the merge in step (2) still proceeds. Step (3) then halts with `sidecar-missing:` (fail-loud), but the merge has already been applied — leaving the wave merged-but-unvalidated. Fix: add test expectations requiring `--capture` to exit non-zero with a named diagnostic (e.g., `capture-git-error:`) on git failure or sidecar-write failure, so T20a can abort before merge.

