---
finding_id: trace-claude-F02
reviewer: qrspi-goal-traceability-reviewer (claude)
artifact: docs/qrspi/2026-06-04-v073-release/plan.md
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md
  - docs/qrspi/2026-06-04-v073-release/design.md
---

# F02 — CD-2 design Acceptance bullet 4 ("≥ 80 lines pre-dispatch Bash redirect prose shrunk vs. v0.7.2") has no plan-authored test expectation; T05's quantitative line-count claim weakens the criterion to "≥ 48 lines"

## Summary

`design.md` § CD-2 Acceptance (line 55) commits the design to:

> Side-by-side comparison: total line count of pre-dispatch Bash redirect prose
> across the 8 artifact-step skills shrinks by ≥ 80 lines vs. v0.7.2 (G9 footprint
> contribution attribution).

No task or phase-level acceptance bullet in `plan.md` carries this ≥ 80-line
quantitative criterion. The closest plan-authored expectation is **T05's detailed
body** at line 948–949:

> The skill-body line count for § Review Round shrinks by ≥6 lines per file
> (total ≥48 lines removed across the 8 files vs. v0.7.2).

48 lines is materially less than 80 lines. T05 — the task that owns the per-skill
diff-emission-prose replacement — has plan-authored the weaker criterion as if it
were the design contract. The phase-1 Acceptance Criteria block (lines 132–145)
covers CD-2 with a single bullet on dispatch-prompt equivalence (line 134) and
does not carry the line-count criterion at all.

## Spec-to-Design Fidelity violation

This is a design-fidelity gap, not a missing-coverage gap: CD-2 *is* covered by
tasks T03 / T04 / T05 / T06, but the **footprint-attribution acceptance bullet**
that design.md commits is silently relaxed in plan.md. Per the strip-from-goals
contract, plan.md is the criterion-authoring source; the criterion plan.md
authors must not be weaker than the criterion design.md committed unless plan.md
explicitly amends design.md and records the amendment.

## Evidence

- `design.md` line 55: "shrinks by ≥ 80 lines vs. v0.7.2 (G9 footprint contribution
  attribution)."
- `plan.md` line 948–949 (T05 detailed body): "(total ≥48 lines removed across the
  8 files vs. v0.7.2)."
- `plan.md` line 134 (Phase 1 Acceptance Criteria, CD-2 bullet): "produces dispatch
  prompts identical in content to the equivalent low-level invocation with pre-
  computed paths (CD-2)." — covers design.md CD-2 Acceptance bullet 2, not bullet 4.
- `plan.md` Phase 1 Acceptance Criteria (lines 132–145) has no bullet referencing
  line-count delta for the 8 artifact-step skill bodies.
- `plan.md` T05 compact body (lines 226–236) — does not mention line-count delta
  at all (which compounds F01: the compact and detailed bodies disagree on whether
  the criterion exists).

## Why this matters

CD-2's "≥ 80 lines shrunk" is a measurable contribution to G9's footprint goal —
design.md explicitly labels it "G9 footprint contribution attribution." The CD-2
extraction is one of the load-bearing structural moves that makes G9's 14-skill
trim achievable. If plan.md authorizes a 48-line shrinkage as acceptable, the
overall G9 footprint math compounds the gap: every CD that under-delivers its
attributed savings forces G9's per-skill trim passes to make up the difference,
which is exactly the regression-risk shape G9's Pass 4 regression guard exists to
catch — but that guard is the last line of defense, not the first.

## Recommended remediation

Either:

1. Lift the ≥ 80-line criterion from design.md verbatim into either T05's
   `Test expectations` block OR the Phase 1 Acceptance Criteria block, and update
   T05's R1 sub-claim to ≥ 80 lines (≥10 per file across 8 files), aligning the
   plan-authored criterion with the design commitment; OR
2. If the ≥ 80-line number is no longer believed achievable, amend design.md
   (proper round-trip: dispatch design Apply-fix to relax the criterion with stated
   rationale), then update plan.md to match the amended design figure. Do not
   silently weaken the criterion in plan.md.

T05's compact body should be reconciled with the detailed body per F01 so the
chosen criterion appears in exactly one place.
