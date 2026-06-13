---
finding_id: F01
reviewer: spec-claude
reviewer_tag: spec-claude
artifact: plan.md
round: 3
severity: medium
change_type: defect
category: acceptance-criterion-authoring
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md
tasks_affected: []
---

# F01 — Round-02 F02 mashed-bullet remediation only half-applied: the new L151 G9 box is a near-duplicate of the existing L155 G9 box (regression-guard criterion authored in two places)

## Summary

Round-02 spec-claude.F02 raised two coupled defects against the Phase 1
Acceptance Criteria block: (a) the L146 bullet mashed two unrelated criteria
(G5 autopilot halt + G9 regression-guard) into one checkbox; (b) the
regression-guard half of L146 was a near-duplicate of the L150 G9 box
covering the same `tests/acceptance/v07-phase1/` zero-regression criterion.
The remediation guidance was explicit: **either** delete the L150 G9 box
(after the L146 split makes it redundant) **or** delete the second sentence
of L146 entirely (keep L150 as the sole owner). Round-03 performed the split
(✓) but did neither deduplication option (✗) — the regression-guard criterion
is now authored under both new L151 and pre-existing L155, with the integration
gate still unable to tell which is canonical.

## Evidence

`plan.md` round-03, Phase 1 Acceptance Criteria, lines 150–155 (verbatim):

```
- [ ] The Implement-phase autopilot terminates the wave loop and writes
  `HALT-orchestration-boundary-undeterminable.md` when the OBC report
  carries any `## Dispatch defects` entry; no skip-and-continue path exists
  (G5).
- [ ] G9 Pass 4 regression-guard execution against the v0.7.2 phase-1
  acceptance suite stays green across every trim task (G9).
- [ ] Every Implement-wave stage commit in the v0.7.3 self-host passes
  `validate-stage-commit-parents.sh --validate` silently;
  `parallelization.md` is unchanged across the phase (G6).
- [ ] Every step-12 narrow-round dispatch across the v0.7.3 self-host
  resolves its diff ref by reading `reviews/<step>/round-<NN-1>-commit.txt`
  (G7).
- [ ] `VERSION` is bumped exactly once to `0.7.3`, a single
  `node tools/build-plugin.mjs` invocation propagates to all five consumer
  manifests, and the `.github/workflows/build-then-diff.yml` CI gate passes
  on the release commit; `.github/plugin/*` stays in lockstep with
  `.claude-plugin/*` per `goals.md` § Constraints (G8).
- [ ] The v0.7.2 phase-1 acceptance suite (`tests/acceptance/v07-phase1/`)
  passes against the trimmed skill set with zero regressions;
  `scripts/measure-active-footprint.sh` reports < 30K tokens per typical
  session, captured at `docs/qrspi/2026-06-04-v073-release/g9-footprint-report.md`
  (G9).
```

L151 and L155 each carry a G9-tagged criterion whose load-bearing assertion
is "the v0.7.2 phase-1 acceptance suite stays green / passes with zero
regressions against the trimmed skill set":

- L151: "G9 Pass 4 regression-guard execution against the v0.7.2 phase-1
  acceptance suite **stays green across every trim task**"
- L155 (first half): "The v0.7.2 phase-1 acceptance suite
  (`tests/acceptance/v07-phase1/`) **passes against the trimmed skill set
  with zero regressions**"

The two phrasings are not byte-identical, but they refer to the same
property of the same test surface (the v0.7.2 phase-1 acceptance suite
remaining green after the trim work). L151 can be read as "per-trim-task
checkpoint" and L155 as "end-state acceptance," but the integration gate
has no instruction distinguishing them; both phrase the criterion as a
single boolean over the same test surface, and either can be discharged
by running the same test command against the merged integration branch.

Round-03 diff (`round-03.diff` L80–82) shows the split that introduced
the new L151:

```
+- [ ] The Implement-phase autopilot terminates the wave loop and writes
  `HALT-orchestration-boundary-undeterminable.md` when the OBC report
  carries any `## Dispatch defects` entry; no skip-and-continue path
  exists (G5).
+- [ ] G9 Pass 4 regression-guard execution against the v0.7.2 phase-1
  acceptance suite stays green across every trim task (G9).
```

The L155 G9 box (pre-existing) was not touched by round-03 — the round-03
diff carries no `- [ ] The v0.7.2 phase-1 acceptance suite ...` removal.
So the L151 / L155 pair sits in the post-round-03 state as two G9 boxes
covering the same regression-guard property — exactly the duplicate-coverage
shape round-02 F02 named as defect (b).

The round-02 F02 § Recommended remediation paragraph spelled out the
deduplication choice:

> — and delete the existing L150 G9 box (the regression-guard half is now
> in the new box from the L146 split, leaving the G9 box redundant). OR
> delete the second sentence of the L146 box entirely (keep the L150 G9
> box as the sole owner of the regression-guard criterion).

Neither option was taken.

## Why this matters

Three concrete consequences (the same shape round-02 F02 named, now
explicit in round-03 because the split made the duplicate visible as a
standalone box rather than a buried second sentence):

1. **The integration gate has two non-identical contracts for the same
   property.** L151 says "stays green across every trim task" (a process
   assertion over T32–T36 execution); L155 says "passes against the
   trimmed skill set with zero regressions" (an end-state assertion over
   the merged integration branch). Both reduce to the same test-command
   invocation (run `tests/acceptance/v07-phase1/`) but at different
   moments. Without prose instructing the gate when to discharge each,
   either box can be checked independently and a verifier walking the
   list cannot tell which is the canonical phrasing.

2. **Future amendment drift is now load-bearing on two boxes.** If a
   later round adds a carve-out (e.g., known-flaky test exclusion, scope
   narrowing to a specific test subset, deferral of one test surface to
   a later phase), the amendment author has to update both L151 and L155
   in lockstep. A miss produces two contradictory G9 criteria the
   integration gate cannot resolve.

3. **The L155 box also still mashes the footprint criterion in with the
   regression-guard criterion.** L155 carries two propositions (suite
   passes + footprint < 30K tokens) joined by a semicolon. Even if the
   L151/L155 duplication is fixed by deleting L151, L155's internal
   mashing (which round-02 F02 also flagged structurally) remains. The
   minimum-churn fix is to delete L151 AND split L155 into two boxes:

   ```
   - [ ] The v0.7.2 phase-1 acceptance suite (`tests/acceptance/v07-phase1/`)
     passes against the trimmed skill set with zero regressions (G9).
   - [ ] `scripts/measure-active-footprint.sh` reports < 30K tokens per
     typical session, captured at
     `docs/qrspi/2026-06-04-v073-release/g9-footprint-report.md` (G9).
   ```

## Recommended remediation

Apply round-02 F02's Option A as written:

1. **Delete the L151 box** introduced by round-03's L146 split — the
   regression-guard property is fully owned by L155.

2. **Split L155** into two atomic boxes: one for the suite-passes
   criterion, one for the footprint-measurement criterion (per the L155
   text reproduced above). This finishes the structural one-criterion-
   per-checkbox discipline round-02 F02 named.

If the plan-author prefers L151's per-task framing over L155's end-state
framing as the canonical phrasing, the converse direction also works:
delete L155's first sentence and keep L155 as the standalone
footprint-measurement box; L151 then carries the regression-guard
criterion alone. The deletion direction is the plan-author's call;
*one or the other must be deleted*.

## Severity

Medium. Same severity F02 carried in round-02 — the Phase 1 Acceptance
Criteria block is the contract the integration-phase gate consumes;
duplicate-coverage criteria silently degrade the gate's ability to
discharge each criterion independently. Not high severity because the
constituent criteria are all present and verifiable — the defect is in
the bundling/duplication, not in the substance. Re-raised at the same
severity because round-03 performed only half the F02 remediation
(the split half) and the duplicate half is now more visible as a
standalone box rather than buried as a second sentence.
