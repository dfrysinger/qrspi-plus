---
finding_id: R3-F01
reviewer_tag: spec-codex
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/tasks/task-10.md#L42-L55
  - skills/using-qrspi/SKILL.md#L995-L1004
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L2088-L2100
---

# Score-naming spec mismatch — DoD says "each score" but implementation uses single representative_score:

Task-10 spec L42 (DoD): "...contributing finding paths relative to the artifact directory, each finding's defect class, **each score**, and the threshold that dropped it."

Task-10 spec L54 (test expectations): "...contributing finding paths relative to the artifact directory, `defect_class` tags, **scores**, and threshold."

R2 fix changed the template schema to a single `representative_score:` field per cluster and explicitly states per-finding scores are NOT preserved. The acceptance test enforces this rename and forbids bare `score:`.

This does not match the task spec's "each score" plural requirement on its most literal reading.

**Disposition note:** Spec language is ambiguous between Reading A (per-finding scores required) and Reading B (cluster-level representative with per-finding precision via sidecar file links). spec-claude defended Reading B as G28-intent-satisfied. Orchestrator chose to KEEP `representative_score:` (Reading B) but file PI-V072-T10-005 to disambiguate the spec text in v0.7.3.
