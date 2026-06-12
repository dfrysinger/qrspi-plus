---
finding_id: R1-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-06-04-v073-release/phasing.md:L22]
artifact: phasing
round: 1
reviewer: scope-claude
---

The third replan-gate bullet in Phase 1 enumerates specific script file paths and uses subagent-dispatch jargon, crossing two DEFERS boundaries simultaneously:

> "A self-host smoke run executes the universal dispatch chain (`dispatch-agent.sh` → Task fan-out → `await-round.sh` → `verifier-fan-in.sh`) end-to-end against a trivial test artifact and converges without orchestration-boundary breaches (G5) or parent-SHA drift (G6)."

Two distinct boundary breaches in one sentence:

1. **File paths → Structure.** Script names are concrete file paths; OWNS/DEFERS places "File paths, module boundaries, interface contracts, file maps" in Structure.
2. **"Task fan-out" → Implement.** Subagent-dispatch jargon explicitly called out in DEFERS as a boundary-drift signal in phasing.md.

Proposed resolution: rewrite as "A self-host smoke run executes the full QRSPI pipeline end-to-end against a trivial test artifact and converges without orchestration-boundary breaches (G5) or parent-SHA drift (G6)."
