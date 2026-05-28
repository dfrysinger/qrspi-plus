---
finding_id: R12-F02
severity: medium
change_type: correctness
referenced_files: [/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L280-L282, /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/research/summary.md:L160-L168]
artifact: design
round: 12
reviewer: quality-codex
---

G6 describes Implement-phase `qrspi-test-writer` dispatch as if the current agent body already supports `task_definition` as the mode signal, but the research summary says the existing `qrspi-test-writer` contract is still Test-phase-only and does not match an Implement-phase parameter shape. That makes the design misleading for downstream Plan/Implement work: a reader could assume the split only needs orchestration changes, when it also requires an explicit agent-contract update. Fix by rewriting this section to say the test-writer agent must be extended to support a new Implement-phase mode keyed by `task_definition`, with the current Test-phase contract preserved when that field is absent.
