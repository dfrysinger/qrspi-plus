---
reviewer_tag: goal-traceability-codex
change_type: correctness
severity: high
artifact: plan.md
location: "Plan Phase 1 Acceptance Criteria, first bullet"
referenced_files:
  - plan.md
  - design.md
---

# F03 — Acceptance criteria still use deprecated `codex_reviews` field

## Defect

Design locks rename `codex_reviews` → `second_reviewer` and says legacy name is deleted from prose/templates (design.md ~2178–2210).

Plan Phase 1 acceptance criteria first bullet still requires `codex_reviews: true`.

## Impact

Plan's Phase 1 gate would pass when the new field name fails. Direct violation of design's locked rename decision.

## Recommended fix

Replace `codex_reviews: true` with `second_reviewer: true` (or whatever the new schema's truthy value is) in the Phase 1 Acceptance Criteria. Sweep the rest of the plan document for other surviving `codex_reviews` references and normalize.

## Severity rationale

High because the acceptance criteria is the phase-completion gate. A gate that checks the wrong field name passes the wrong work and silently misses the rename's enforcement.
