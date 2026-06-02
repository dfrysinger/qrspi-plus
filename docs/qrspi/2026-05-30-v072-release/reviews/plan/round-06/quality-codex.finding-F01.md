---
finding_id: R6-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

Task 19 still declares no dependency even though it is now explicitly layered on top of Task 16's `_resolve-lib.sh` surface, creating a dep-graph inconsistency that allows unsafe parallel execution.

Evidence from Task 16:
- L973: `**Target files:** ... create/modify \`scripts/_resolve-lib.sh\` ... modify \`tests/unit/test-routing-matrix-application.bats\``
- L974: `**Dependencies:** none.`

Evidence from Task 19:
- L1102: `**Target files:** ... \`scripts/_resolve-lib.sh\` ... \`tests/unit/test-routing-matrix-application.bats\``
- L1116: `Extend \`scripts/_resolve-lib.sh\` with the host × vendor matrix...`
- L1103: `**Dependencies:** none.`

This means both tasks can be scheduled concurrently while editing the same contract-defining files, even though Task 19 is described as an extension of that shared resolver/matrix behavior. Add `Task 16` as a dependency of Task 19 (and update the slice summary line at L65) to keep the graph consistent with the task contracts.
