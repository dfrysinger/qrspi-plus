---
finding_id: R6-F05
severity: low
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L877-L882
artifact: plan
round: 6
reviewer: quality-claude
---

T11's `dependent_tests: none` proof covers only `[F<digits>]` tokens, but the sweep targets both `[T<digits>]` and finding-ID tokens. The proof `grep -rn -- '@test "[^"]*\[F[0-9]+' tests/` doesn't catch a consumer test asserting on a `[T...]` description.

Fix: add a second proof line `grep -rn -- '@test "[^"]*\[T[0-9]+' tests/` OR justify omission with structural evidence.
