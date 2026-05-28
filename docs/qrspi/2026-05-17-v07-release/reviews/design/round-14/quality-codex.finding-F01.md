---
finding_id: R14-F01
severity: high
change_type: correctness
referenced_files: [/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L32-L45, /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L83-L90]
artifact: design
round: 14
reviewer: quality-codex
---

G1's precedence contract is internally inconsistent. The detailed resolution chain says dispatch-time hardcoded overrides are layer 1b, above `config.md` role-map resolution (`model_routing:`), but the summary line later collapses the order to `per-task > per-run > per-agent > built-in default`, omitting the hardcoded dispatch-site layer entirely. The test strategy then reinforces the 1a-over-1b tie-break, so downstream Plan/Implement can derive two different precedence orders from the same design. Fix by restating the precedence in one canonical form that includes the hardcoded dispatch-site override layer and matches the detailed chain plus its tests.
