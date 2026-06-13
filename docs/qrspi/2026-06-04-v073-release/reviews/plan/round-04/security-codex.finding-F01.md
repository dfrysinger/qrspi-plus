---
finding_id: R4-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md
artifact: plan
round: 4
reviewer: security-codex
---

FAIL_OPEN on invalid `--step` in T01. The plan explicitly requires unknown step names to return only always-appended paths and exit 0 with no stderr, and tests enforce that behavior (L623, L627). A typo or malicious step value is treated as success, so callers can't distinguish "valid minimal result" from "invalid input." This can silently drop required upstream artifacts and produce false-clean reviewer/verifier outcomes.

