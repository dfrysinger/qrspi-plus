---
reviewer: test-coverage-codex
round: 5
finding_id: R5-F01
severity: medium
change_type: correctness
referenced_files: [scripts/third-party-finding-splitter.sh, tests/unit/test-third-party-finding-splitter.bats]
---

# F01 — Splitter write-error path is not tested

Spec (task-20.md L55, L44) requires loud failure on write errors. Current splitter tests at tests/unit/test-third-party-finding-splitter.bats:64-212 cover missing flags / raw / malformed / empty, but no permission-denied / disk-write failure case. Regressions in output-write-failure handling could ship unpinned.
