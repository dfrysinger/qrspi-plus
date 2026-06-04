---
finding_id: R4-F01
reviewer: spec-codex
round: 4
severity: high
change_type: correctness
referenced_files:
  - skills/implement/SKILL.md:857-860
---
The fix-cycle implementer dispatch at implement/SKILL.md:858 still uses the retired live `model` argument: `Agent({ subagent_type: "<implementer_subagent>", model: "<model>" })`. This is exactly the `model: <model>/<resolved>` dispatch shape the G22 migration removed elsewhere in the same file (round-03 fixed the test-writer dispatch at 615) and conflicts with the tier-resolved routing contract. CORROBORATES spec-claude R4-F01. ORCHESTRATOR-VERIFIED via sed.
