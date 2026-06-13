---
finding_id: F01
reviewer: spec-claude
reviewer_tag: spec-claude
artifact: plan.md
round: 2
severity: high
change_type: defect
category: design-fidelity
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md
  - docs/qrspi/2026-06-04-v073-release/design.md
tasks_affected: [T01]
---

# F01 — T01 unknown-step contract contradicts design.md CD-1 Acceptance bullet 2 (fail-loud plan vs. fail-soft design); plan footnote misattributes the new direction to the unchanged design bullet

## Summary

Plan T01 (round-02) commits T01 to a **fail-loud** unknown-step contract for
`scripts/upstream-paths.sh`. `design.md` § CD-1 commits the **opposite** —
fail-soft, returning the always-appended SKILL paths and exiting 0. The plan
authored its acceptance criterion citing "CD-1 Acceptance bullet 2 — fail-loud
direction," but that design bullet itself is fail-soft (verbatim: "Unknown step
name returns the always-appended SKILL paths + exit 0"). Plan has reversed the
design contract without amending design, so the Phase 1 Acceptance Criteria
block becomes internally contradictory: bullet 1 ("Every goal-level
`**Acceptance.**` subsection in `design.md` passes") cannot be satisfied
simultaneously with bullet 2 (plan's new fail-loud T01 criterion).

## Evidence

`design.md` § CD-1 **Acceptance bullet 2** (line 25):

> Unknown step name returns the always-appended SKILL paths + exit 0 (covered
> by a bats case).

`design.md` § CD-1 **Dependencies + edge cases** (line 20) — load-bearing
rationale for the fail-soft choice:

> Edge case: a step name not in the table (e.g. `plan` today) returns the
> always-appended SKILL paths only. The script must handle unknown step names
> by printing the always-appended set and exiting 0, **not by erroring** —
> orchestrator failure on an absent step would be a regression vs. today's
> prose behavior.

`plan.md` T01 description (line 172):

> An unknown `--step` value exits non-zero with a `upstream-paths-unknown-step:`
> named diagnostic listing the valid step values and emits empty stdout —
> **there is no SKILL-only fallback**.

`plan.md` T01 Test Expectations (line 176):

> Unknown step name exits non-zero with the `upstream-paths-unknown-step:`
> named diagnostic listing valid step values; stdout is empty
> **(CD-1 Acceptance bullet 2 — fail-loud direction)**.

`plan.md` Phase 1 Acceptance Criteria (line 137):

> An unknown `--step` value exits non-zero with the
> `upstream-paths-unknown-step:` diagnostic and empty stdout
> (no SKILL-only fallback)

The parenthetical "CD-1 Acceptance bullet 2 — fail-loud direction" attributes
the new contract to a design bullet that says the opposite. There is no
amendment to design.md in this round's diff (`reviews/plan/round-02/round-02.diff`
shows only `plan.md` edits) and no entry in `## Amendments introduced during
Plan` (the plan's overview carries no amendments section).

This direction was **not** present in plan.md round-01 — the round-02 diff
(L185 of `round-02.diff`) shows the deletion of "`Unknown step name returns
the always-appended SKILL paths and exits 0 (CD-1 Acceptance bullet 2).`" and
its replacement with the new fail-loud bullet. So the contradiction was
introduced this round.

## Why this matters

Three concrete consequences:

1. **Phase 1 Acceptance Criteria becomes internally contradictory.** Bullet 1
   requires "Every goal-level `**Acceptance.**` subsection in `design.md`
   passes against the merged integration branch (G1–G9, CD-1–CD-3)." CD-1
   Acceptance bullet 2 in design.md requires unknown-step → exit 0 with
   always-appended paths. Plan's new T01 bullet requires unknown-step → exit
   non-zero with empty stdout. The two acceptance criteria are mutually
   exclusive — no implementation can satisfy both.

2. **Test writers receive contradictory contracts.** The TDD subagent for T01
   reads the plan's Test Expectations (which mandate fail-loud) and writes
   bats fixtures asserting non-zero exit + empty stdout. The same subagent,
   if it cross-reads design.md per the always-appended SKILL paths it is
   supposed to honor, sees the opposite contract. There is no precedent in
   the plan for "ignore design.md when it conflicts with plan.md."

3. **Design's load-bearing rationale is silently overruled.** Design's edge
   case explicitly names the regression risk: "orchestrator failure on an
   absent step would be a regression vs. today's prose behavior." The plan
   does not address that rationale — there is no "why fail-loud is better
   than fail-soft" paragraph in T01 or in any plan-level amendment block.
   The plan-author cannot unilaterally overrule a design decision whose
   rationale is named in design.md without round-tripping through Apply-fix
   on design.

## Two ways to remediate

Either:

**Option A — Plan reverts to match design.** Restore T01 to the round-01
fail-soft contract: unknown step name returns the always-appended SKILL paths
and exits 0. Restore the Test Expectations bullet. Remove the new fail-loud
Phase 1 Acceptance Criteria bullet. This is the minimum-churn path and
preserves the design contract.

**Option B — Design is amended via Apply-fix to design.md.** A separate
Apply-fix round on design.md changes CD-1 Acceptance bullet 2 and the
Dependencies + edge cases rationale to the fail-loud direction, with stated
rationale (presumably some safety property the plan-author noticed that the
design dialog missed). Then plan.md's current T01 contract is correct against
the amended design, and the "(CD-1 Acceptance bullet 2 — fail-loud direction)"
footnote becomes accurate. The plan's `## Amendments introduced during Plan`
overview block (currently absent) must record the round-trip.

The "fail-loud direction" footnote in T01 Test Expectations should not
survive in any case — either the bullet matches design (Option A; remove the
footnote) or design is amended to match (Option B; the footnote becomes a
plain `(CD-1 Acceptance bullet 2)` citation without the now-redundant
"fail-loud direction" qualifier).

## Severity

High. The contradiction sits in the plan's Phase 1 Acceptance Criteria block
— the contract the integration-phase gate reads. Two acceptance criteria
that cannot simultaneously hold is a fail-shape the Acceptance gate cannot
discharge; downstream test-writers will author tests against one of the two
contracts and the other will mechanically fail at integration time.
