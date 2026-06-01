---
finding_id: quality-claude-r03-F02
severity: medium
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/phasing.md
  - docs/qrspi/2026-05-30-v072-release/roadmap.md
artifact: phasing
---

# Slice 1.2 lists G29, but Surface + Demonstrable-by don't address G29's dispatch-contract surface

## Where

`phasing.md` § "### Slice 1.2 — Verifier rubric calibration + instrumentation":

> **Goals:** G19, G20, G28, G29
> **Surface:** verifier scoring rubric (hallucination class detection, model calibration), and the dispositions + sub-threshold-observations instrumentation formalized in G28.
> **Demonstrable by:** a review round that produces both above-threshold and sub-threshold findings; confirming the dispositions document fires the Sub-Threshold Observations block correctly and the verifier rejects fabricated or hallucinated findings.

`roadmap.md` slice 1.2 theme column similarly: "Hallucination class + model calibration + dispositions instrumentation."

## What

Slice 1.2's goal list includes **G29** ("Reviewer dispatch contract has no escape hatch for large artifacts (canonize `artifact_path`)") — a reviewer-protocol dispatch-contract change adding an `artifact_path` escape hatch for artifacts above a size threshold. But the slice's Surface line and Demonstrable-by criteria cover only G19 (hallucination cite-check), G20 (substituted-model calibration), and G28 (convergent-evidence / sub-threshold-observations). G29's contribution is invisible in both descriptors:

- **Surface:** names "verifier scoring rubric" and "dispositions + sub-threshold-observations instrumentation" — neither covers reviewer-dispatch ingress shape.
- **Demonstrable by:** "a review round that produces both above-threshold and sub-threshold findings" exercises G19/G20/G28 only. A review round against a small artifact does NOT exercise the `artifact_path` escape hatch (the wrapped-body path remains the default). G29 needs a review round against a large artifact (>30 KB per the goals.md candidate threshold) to actually exercise.

This creates two downstream-consumer problems:

1. **Implicit goal — high omission risk in Plan.** A Plan task author reading slice 1.2 sees three rubric/instrumentation goals + an unmentioned G29; the natural carving will produce tasks for G19/G20/G28 surface and miss G29's reviewer-protocol contract edit + per-skill dispatch-contract migrations across the 8 dispatching skills.
2. **Acceptance gate doesn't cover G29.** Phase 1's acceptance gate item 3 (Instrumentation completeness) inherits slice 1.2's framing — it requires sub-threshold-observations + verifier-fan-in + interaction-mode audit, but never asserts the artifact_path escape hatch is exercised. G29 ships untested by the phase-level gate.

## Why it matters

goals.md's Cross-Cutting Notes block contains an explicit cross-link that contradicts G29's current placement:

> G6 and G29 share the same dispatch-contract surface (`skills/reviewer-protocol/SKILL.md`) and are likely co-scheduled.

That is, G29's natural co-slice is **G6** (in slice 1.1 — apply-fix / verifier backbone, which already includes reviewer-protocol disk-write contract work) — not the rubric-calibration cluster. Placing G29 in slice 1.2 splits the reviewer-protocol edit surface across two slices for no apparent benefit, while leaving G29 under-described in its assigned slice.

## Suggested fix

Choose one:

(a) **Relocate G29 to slice 1.1** (apply-fix / verifier backbone). The slice 1.1 Surface already names "reviewer disk-write reliability" and "the apply-fix protocol's core data shape" — both of which extend cleanly to cover dispatch-ingress shape (the reciprocal of disk-write egress). Update slice 1.1 demonstrable-by to add a clause exercising the artifact_path escape hatch against a >threshold artifact. Update slice 1.2 goal list to remove G29 and roadmap.md row to match.

(b) **Keep G29 in slice 1.2, but expand Surface + Demonstrable-by to name it.** Add a clause to Surface: "...and the reviewer dispatch-contract escape hatch for large artifacts (G29)." Add a clause to Demonstrable-by: "...and dispatching a reviewer round against a >threshold artifact via the `artifact_path` form confirms the wrapped-body / path-based escape hatch routes correctly." Also extend Phase 1 acceptance gate item 3 to assert the escape hatch fires.

Option (a) matches goals.md's cross-link guidance and produces tighter slice cohesion (slice 1.2 becomes a clean rubric/instrumentation cluster; slice 1.1 absorbs the reviewer-protocol dispatch-contract work alongside the reviewer-protocol disk-write work it already owns). Option (b) preserves the current slice-assignment table but trades slice cohesion for less churn.
