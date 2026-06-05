---
finding_id: R1-F01
reviewer: spec-codex
round: 1
severity: high
change_type: correctness
referenced_files:
  - skills/using-qrspi/SKILL.md:480
  - skills/using-qrspi/SKILL.md:499-508
  - skills/using-qrspi/SKILL.md:524-548
---
The retired host-keyed routing schema was NOT removed from skills/using-qrspi/SKILL.md — it now coexists with the new five-tier block (lines 450-462), making the document internally contradictory. Still present: the old precedence chain (step 3 "model_routing: host/tier lookup", `inherit`), `model_role:` role-matching (line 480), and the entire `#### Model Routing` host-column section (lines 524-548) describing `detect_host`, `claude-code`/`copilot-cli` columns, and `haiku`/`sonnet`/`opus`/`inherit` tier rows. T16 requires these superseded surfaces REPLACED by tier-based resolution (`--tier-override → agent tier → default_tier → hardcoded medium`), not added alongside. ORCHESTRATOR-VERIFIED via grep.
