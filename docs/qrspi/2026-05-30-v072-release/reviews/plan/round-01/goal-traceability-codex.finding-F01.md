---
finding_id: R1-F01
reviewer_tag: goal-traceability-codex
artifact: plan.md
round: 1
severity: high
change_type: clarity
location: "All task References blocks (systemic) — e.g. T01 lines 170-174; T25 lines 1587-1590"
---

## Issue

Plan References blocks cite anchors as full heading strings (e.g. `goals.md ### G7`, `design.md ## G7`) and prose phrases (e.g. T25 `structure.md per-file blocks for the 6 new files...`), not as § form. The dispatch shim asserted §-anchor traceability as load-bearing.

## Why

If §-anchor format is the contract, automated anchor-resolution scripts that match on `§G<N>` will not find these references — the trace graph can appear complete while containing unresolvable references at the literal-syntax level. Non-heading prose citations (T25's "per-file blocks for the 6 new files") have no anchor to resolve to at all.

## Fix

Either (a) normalize the contract: confirm that "`goals.md ### G7`" is the canonical anchor form (not "`§G7`"), and update any §-form references in the dispatch shim and reviewer prompts to match; or (b) rewrite plan References to use §-form. Replace prose-citation forms ("per-file blocks for the 6 new files") with enumerated anchor lists.

## Disposition note (orchestrator)

Counter-evidence: goal-traceability-claude verified all anchors DO resolve (the `### G7` heading exists in goals.md). The §-shorthand was my dispatch-shim notation, not the literal format used in plan.md. The substantive concern is the non-heading prose citation in T25, not the cross-form mismatch.
