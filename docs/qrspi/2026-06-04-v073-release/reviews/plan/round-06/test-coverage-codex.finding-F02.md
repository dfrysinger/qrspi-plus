---
finding_id: R6-F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L713-L719
artifact: plan
round: 6
reviewer: test-coverage-codex
---

T04a missing malformed-CLI-shape expectation (partial high-level flags): T04a introduces a new mode keyed on `--step --round --artifact-dir`, but tests cover only full high-level success/failure and low-level regression. No expectation for partial/invalid flag combinations (e.g., `--step` without `--round`), so caller-visible failure behavior for malformed input is unverifiable.

Fix: add a test expectation bullet covering partial high-level flag combinations.
