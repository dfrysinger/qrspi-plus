---
finding_id: R8-F04
severity: medium
change_type: silent-failure
referenced_files: ["plan.md (T03 test expectations)"]
artifact: plan
round: 8
reviewer: silent-failure-codex
---
T03 writes multiple artifacts (round-NN.diff, round-NN.absorption-map.tsv) without atomicity/rollback. Mid-op failure leaves partial pre-dispatch state.
