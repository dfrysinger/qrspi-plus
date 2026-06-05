---
finding_id: R1-F02
reviewer: spec-codex
round: 1
severity: high
change_type: correctness
referenced_files:
  - skills/using-qrspi/SKILL.md:510-522
  - skills/_shared/config-validation-procedure.md:11-20
---
skills/using-qrspi/SKILL.md (lines 510-522, "#### Missing model_routing: block") still documents missing model_routing: as a one-time in-memory WARNING + backfill-defaults behavior. T16 + the newly-created skills/_shared/config-validation-procedure.md require missing AND malformed model_routing: to FAIL LOUDLY with repair-or-abort guidance. The two surfaces now contradict each other. ORCHESTRATOR-VERIFIED via grep.
