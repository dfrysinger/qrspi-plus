---
reviewer: test-coverage-claude
round: 5
finding_id: R5-F04
severity: low
change_type: correctness
referenced_files: [tests/unit/test-dispatch-agent.bats, scripts/dispatch-agent.sh]
---

# F04 — Multiple --agents entries in one batched call not tested (CONVERGES with tc-codex F04)

scripts/dispatch-agent.sh:583-723 --agents loop accumulates manifest entries for N reviewers. Every batch test passes single tag=file. Mixed first-party + third-party batch is the actual production usage path; loop-continuation + accumulation untested.
