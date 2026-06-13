---
finding_id: R6-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L686-L700
artifact: plan
round: 6
reviewer: test-coverage-codex
---

T03 missing explicit malformed-input/unknown-step test case: description/notes define intentionally silent behavior for unknown `--step` values, but Test expectations do not include a dedicated unknown-step fixture. Without it the silent-on-unknown-step contract is not directly verifiable and could regress to erroring (or writing wrong files) unnoticed.

Fix: add a test expectation bullet covering the unknown-step case (silent exit 0 with no files emitted).
