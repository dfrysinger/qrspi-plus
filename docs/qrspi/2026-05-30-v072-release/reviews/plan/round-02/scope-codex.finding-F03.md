---
reviewer_tag: scope-codex
change_type: scope
severity: low
artifact: plan.md
location: "Plan-wide — Phase 1 Acceptance Criteria + cross-slice narrative"
referenced_files:
  - plan.md
---

# F03 — Phasing/design boundary drift

## Defect

The plan document includes substantial phasing/roadmap and architecture-style content beyond Plan OWNS:
- Phase-wide release governance criteria
- Slice authoring/orchestration narrative
- Cross-slice release management details

These belong to Phasing (phase boundaries, replan-gate criteria) and Design (architecture trade-offs) respectively.

## Impact

Plan's role is decomposition of approved upstream artifacts into task specs, not re-derivation of phase or architecture content.

## Recommended fix

Move phasing/release-governance content into `phasing.md` (already approved) and architecture narrative into `design.md` (already approved). Replace in-plan with one-line references ("Phase 1 acceptance criteria: see phasing.md § Phase 1 Replan Gate").

## Counter-argument to consider

The Phase 1 Acceptance Criteria block aggregates per-task observable behaviors at the phase boundary — scope-claude's round-02 review explicitly cleared this as "a natural extension of Plan's per-task Test Expectations OWNS rather than Phasing's replan-gate-criteria DEFERS." Codex's call may be the false positive of the two.
