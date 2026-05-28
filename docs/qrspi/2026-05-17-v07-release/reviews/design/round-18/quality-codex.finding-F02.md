---
finding_id: R18-F02
severity: medium
change_type: correctness
referenced_files: [/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L41-L45, /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L1150-L1154]
artifact: design
round: 18
reviewer: quality-codex
---

The cross-cutting routing test strategy switches from G1's concrete schema to an undefined symbolic one. G1 defines `model_routing:` entries as mappings like `<role>: { provider: <provider-name>, model: <model-id> }`, but the end-to-end test later asserts a run with ``model_routing.research-collator: cheap`` dispatches the cheap provider. `cheap` is not a legal value in the schema this design established, so the acceptance test is checking a configuration shape that downstream code should reject. Fix by rewriting the test to use an actual provider/model mapping (or by defining a real symbolic alias layer if that indirection is intended).
