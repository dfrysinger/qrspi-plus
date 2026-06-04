---
reviewer: test-coverage-claude
round: 5
finding_id: R5-F01
severity: medium
change_type: correctness
referenced_files: [tests/unit/test-dispatch-sites.bats, scripts/dispatch-companion.sh]
---

# F01 — Missing loud-failure tests for dispatch-companion.sh new launch interface required flags

DoD: "loud failure for missing flags/raw output/boundaries/write errors". Splitter half is thorough (6 tests). Companion half: 5 required flags (--vendor, --model, --prompt-file, --round-dir, --tag) at scripts/dispatch-companion.sh:582-586 each have die() guards, none triggered by T20 tests. test-dispatch-sites.bats:271-288 only checks exit!=127. Add 5 tests, one per omitted flag.
