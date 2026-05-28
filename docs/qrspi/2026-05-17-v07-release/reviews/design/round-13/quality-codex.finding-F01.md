---
finding_id: R13-F01
severity: high
change_type: correctness
referenced_files: [/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L32-L40]
artifact: design
round: 13
reviewer: quality-codex
---

G1's precedence contract is still ambiguous at the highest-priority layer. The design says the top slot is "Per-invocation override passed by the orchestrator" and gives both per-task `model:` and explicit dispatch-site overrides as examples, but it never defines which one wins if both are present. That matters because the current system already has hardcoded dispatch-site `model: "sonnet"` overrides, and G1 is also generalizing per-task `model:`. Without an explicit tie-breaker, an implementation can silently preserve the hardcoded override and bypass the task-specific routing the schema is supposed to enable. Fix: state the order inside the top layer explicitly, for example "per-task override beats hardcoded dispatch-site default" or the reverse, and call out how existing inline overrides are normalized under the new schema.
