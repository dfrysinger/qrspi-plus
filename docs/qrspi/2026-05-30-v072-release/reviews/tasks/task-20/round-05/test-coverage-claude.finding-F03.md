---
reviewer: test-coverage-claude
round: 5
finding_id: R5-F03
severity: low
change_type: correctness
referenced_files: [tests/unit/test-dispatch-agent.bats, scripts/dispatch-agent.sh]
---

# F03 — Batched dispatch relative --output-dir validation not pinned

scripts/dispatch-agent.sh:533-535 rejects relative --output-dir in batched mode; no test exercises this. All 4 batch tests pass absolute paths. Defer-eligible.
