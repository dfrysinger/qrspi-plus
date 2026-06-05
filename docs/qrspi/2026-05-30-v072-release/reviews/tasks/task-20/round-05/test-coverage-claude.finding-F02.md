---
reviewer: test-coverage-claude
round: 5
finding_id: R5-F02
severity: low
change_type: correctness
referenced_files: [tests/unit/test-dispatch-sites.bats, scripts/dispatch-companion.sh]
---

# F02 — await malformed-record and unwired-vendor exit-13 paths untested

scripts/dispatch-companion.sh:517-521 (missing tag=/round_dir= in record) and :553-558 (vendor != codex) both exit 13. Only not-found exit 11 path is tested at test-dispatch-sites.bats:313-322. Defer-eligible.
