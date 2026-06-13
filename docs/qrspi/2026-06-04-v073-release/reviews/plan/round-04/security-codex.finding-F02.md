---
finding_id: R4-F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md
artifact: plan
round: 4
reviewer: security-codex
---

FAIL_OPEN when review diff cannot be produced in T03. The plan requires "artifact-dir not in a git working tree" to emit no files and exit 0, with dispatch omitting `*_path` params (L667, L677). "No diff because no changes" is indistinguishable from "no diff because environment/setup failure." Reviewers may run without critical context and silently miss regressions.

