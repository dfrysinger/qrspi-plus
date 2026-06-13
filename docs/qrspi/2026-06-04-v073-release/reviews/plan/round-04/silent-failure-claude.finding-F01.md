---
finding_id: R4-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L601-L612
  - docs/qrspi/2026-06-04-v073-release/plan.md:L614-L625
  - docs/qrspi/2026-06-04-v073-release/plan.md:L149
  - docs/qrspi/2026-06-04-v073-release/plan.md:L597-L599
artifact: plan
round: 4
reviewer: silent-failure-claude
---

T21 and T22 each add OBC batch-gate prose to integrate/test skills, but their test
expectations omit the explicit enforcement bullet that T20b carries for the
implement phase — leaving a runtime silent-failure path where dispatch defects in
the integration and test phases are ignored without halt.

**The gap in detail**

T20b (plan.md:L597-L599) adds this binding enforcement bullet to its test
expectations:

> "The autopilot branched-default contains a third branch keyed on the
> `## Dispatch defects` section of the OBC report: any non-empty Dispatch-defects
> section triggers an unconditional halt — `HALT-orchestration-boundary-undeterminable.md`
> is written and the autopilot loop exits — with no operator override or
> skip-and-continue branch (silent-claude F02 unconditional-halt direction)."

T20b's *description* also explicitly names all three branches (clean → proceed;
commit/workspace only → surface + operator confirmation; dispatch defects →
unconditional halt).

T21 (plan.md:L601-L612) uses only the vague phrase "batch-gate section gains
interactive-menu and autopilot branched-default additions surfacing the OBC
report" in its description — no three-branch structure is named. Its test
expectations verify: R1 anchor-phrase preservation, R2 HARD-RULE block
self-containment, R3 HARD-RULE top-of-skill positioning, R7 phase-base.txt write
phrasing, R8 prose density, and the phase-base.txt write step. None of these
require the reviewer to confirm the unconditional dispatch-defect halt branch.

T22 (plan.md:L614-L625) has the same omission, with "batch-gate interactive and
autopilot additions" as the description and the same R1–R8 + phase-base.txt
test set.

**Runtime silent-failure path**

T19's script exits 0 for both (a) clean reports and (b) commit/workspace-only
reports. Only dispatch-defect entries cause non-zero exit. An implementer of T21
could write "additions surfacing the OBC report" that log the report and
unconditionally proceed to the next phase, exit-code-check only — this would
satisfy every stated T21 test expectation but silently ignore dispatch defects
(missing/malformed `phase-base.txt`, wave-1 sidecar problems) during the
integrate phase.

The G5 acceptance criterion at plan.md:L149 requires: "Missing/malformed
`reviews/<phase>/phase-base.txt` at OBC time surfaces as a violation in a
distinct `## Dispatch defects` section in the report and triggers the autopilot's
unconditional dispatch-defect halt (G5 fail-loud branch)." The placeholder
`<phase>` spans all three phases, but only T20b's test expectations enforce this
halt at the task level.

**Fix**

Add an explicit enforcement bullet to T21 and T22's test expectations — parallel
to T20b's bullet at L599 — requiring the reviewer to verify:
1. The three-branch autopilot structure is present (named explicitly in the
   description as well, matching T20b's naming of all three branches).
2. Any `## Dispatch defects` entry triggers an unconditional halt, writing a
   named halt file, with no skip-and-continue path.

The description bodies of T21 and T22 should also be tightened to name all three
branches explicitly rather than using the vague "surfacing the OBC report"
construction that elides the halt direction.
