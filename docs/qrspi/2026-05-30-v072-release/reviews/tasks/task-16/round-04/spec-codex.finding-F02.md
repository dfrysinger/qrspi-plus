---
finding_id: R4-F02
reviewer: spec-codex
round: 4
severity: medium
change_type: correctness
referenced_files:
  - skills/implement/SKILL.md:541
---
implement/SKILL.md:541 (§ Missing-routing-table fallback) correctly states missing model_routing: "validation fails loudly" but then cross-references using-qrspi "for the warning text and the runtime-backfill recovery contract." Post-G22, missing model_routing: is FAIL-LOUD with NO runtime-backfill (the warn-once-then-proceed-with-layers behavior was the retired four-layer-chain semantics). Referencing a "runtime-backfill recovery contract" for model_routing is a dangling/contradictory cross-ref to retired behavior. FIX: remove the "warning text and runtime-backfill recovery contract" clause (or narrow to the fail-loud validation procedure). ORCHESTRATOR-VERIFIED via sed.
