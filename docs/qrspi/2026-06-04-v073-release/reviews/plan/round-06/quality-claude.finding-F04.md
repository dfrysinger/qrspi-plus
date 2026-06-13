---
finding_id: R6-F04
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L555
  - docs/qrspi/2026-06-04-v073-release/plan.md:L1388-L1406
artifact: plan
round: 6
reviewer: quality-claude
---

T39 partition-table title (~L555) implies creating the structural-lint script; spec body (~L1393, L1398) creates the bats test only and confirms the script is pre-committed. LOC mismatch: table says ~40, spec says ~30.

Fix: update partition-table title to "Create tests/unit/test-check-bats-id-hygiene-sweep.bats — bats coverage for the pre-committed check-bats-id-hygiene-sweep.sh structural-lint script"; reconcile LOC to ~30.

