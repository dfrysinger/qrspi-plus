---
finding_id: R4-F02
severity: medium
change_type: correctness
referenced_files:
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-06-04-v073-release/plan.md:L739-L745
artifact: plan
round: 4
reviewer: test-coverage-codex
---

T29's description says the CI gate must catch non-version drift classes (e.g., build-artifact drift and marketplace `source` field shifts), but test expectations only exercise a hand-edited `version` mismatch. This leaves a required behavior from the task description unverified. Add at least one explicit fail-direction fixture for a non-version divergence scenario.

