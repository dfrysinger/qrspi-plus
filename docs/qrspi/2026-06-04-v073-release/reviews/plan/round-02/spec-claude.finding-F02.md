---
finding_id: F02
reviewer: spec-claude
reviewer_tag: spec-claude
artifact: plan.md
round: 2
severity: medium
change_type: defect
category: acceptance-criterion-authoring
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md
tasks_affected: []
---

# F02 — Phase 1 Acceptance Criteria checkbox at L146 mashes a G5 criterion and a G9 criterion into one bullet; second sentence is also a near-duplicate of the G9 bullet at L150

## Summary

The Phase 1 Acceptance Criteria block uses `- [ ]` checkboxes — one
verifiable criterion per box, in keeping with the existing block shape.
The bullet at L146 violates the one-criterion-per-box contract by carrying
two unrelated criteria joined by a sentence break:

> - [ ] The Implement-phase autopilot terminates the wave loop and writes
>   `HALT-orchestration-boundary-undeterminable.md` when the OBC report
>   carries any `## Dispatch defects` entry; no skip-and-continue path
>   exists. **G9 Pass 4 regression-guard execution against the v0.7.2
>   phase-1 acceptance suite stays green across every trim task.**

The first sentence is a G5 acceptance bullet (autopilot unconditional halt
on Dispatch defects); the second sentence is a G9 acceptance bullet (G9
Pass 4 regression-guard against the v0.7.2 acceptance suite). The two
sentences cover different goals, different phases, different verifiers.
Checking one box would require verifying both; failing to verify one
silently fails the other.

The second sentence is also a near-duplicate of the G9-tagged bullet at
L150, which already covers the same criterion in different words:

> - [ ] The v0.7.2 phase-1 acceptance suite (`tests/acceptance/v07-phase1/`)
>   passes against the trimmed skill set with zero regressions;
>   `scripts/measure-active-footprint.sh` reports < 30K tokens per typical
>   session, captured at `docs/qrspi/2026-06-04-v073-release/g9-footprint-report.md`
>   (G9).

So the mashed checkbox is both (a) a non-atomic criterion (two criteria
under one box) AND (b) a duplicate-coverage authoring drift — the same
regression-guard property appears in two places under two different
checkboxes, and the gate cannot tell which is canonical.

## Evidence

`plan.md` § Phase 1 Acceptance Criteria, lines 145–150 (verbatim):

```
- [ ] The v0.7.3 self-host Integrate phase produces an empty
  `reviews/integration/orchestration-boundary.md`; every subagent commit
  in the integration-branch phase range carries the `qrspi-<agent>` author
  marker (G5). Missing/malformed `reviews/<phase>/phase-base.txt` at OBC
  time surfaces as a violation in a distinct `## Dispatch defects` section
  in the report and triggers the autopilot's unconditional dispatch-defect
  halt (G5 fail-loud branch).
- [ ] The Implement-phase autopilot terminates the wave loop and writes
  `HALT-orchestration-boundary-undeterminable.md` when the OBC report
  carries any `## Dispatch defects` entry; no skip-and-continue path
  exists. G9 Pass 4 regression-guard execution against the v0.7.2 phase-1
  acceptance suite stays green across every trim task.
- [ ] Every Implement-wave stage commit in the v0.7.3 self-host passes
  `validate-stage-commit-parents.sh --validate` silently; `parallelization.md`
  is unchanged across the phase (G6).
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

The mashed bullet is at the second item above (L146). The second sentence
of that item is a paraphrase of the regression-guard half of the G9 bullet
at L150 (the "passes against the trimmed skill set with zero regressions"
half).

The round-02 diff shows the mashed bullet was introduced this round — round-01
plan did not carry it (the round-02 diff at L159 of `round-02.diff` shows the
addition: `+ [ ] The Implement-phase autopilot terminates ... G9 Pass 4
regression-guard execution against the v0.7.2 phase-1 acceptance suite stays
green across every trim task.`).

## Why this matters

Three concrete consequences:

1. **The Acceptance gate cannot atomically check the box.** The Acceptance
   block's discipline is one verifiable proposition per checkbox so the
   integration-phase gate can walk the list and discharge each independently.
   A box with two unrelated propositions either over-discharges (check both,
   one fails silently) or under-discharges (verify one, leave the other
   uncovered). The G9 regression-guard runs against a different test surface
   (`tests/acceptance/v07-phase1/`) than the G5 autopilot halt verifies
   (synthetic OBC report → autopilot loop behavior), so an integration-phase
   verifier cannot batch them.

2. **Duplicate coverage hides authoring drift.** The G9 regression-guard
   appears under both the L146 box and the L150 box. If a future amendment
   updates one phrasing (e.g., relaxes the regression-guard scope, adds a
   carve-out for a known-flaky test) and misses the other, the gate has two
   non-identical contracts and the implementer cannot tell which governs.
   The duplicate is also a signal the L146 second sentence was a copy-paste
   artifact rather than an intentional Acceptance bullet.

3. **The G5-fail-loud-branch criterion is itself non-atomic.** The L145
   bullet (immediately above the mashed one) already mashes two criteria
   in the same shape: a G5 empty-report criterion AND a G5 fail-loud-branch
   criterion in a single box, joined by a sentence break. The mashed bullet
   at L146 then continues the pattern. So the authoring drift is structural
   in this round's Acceptance block, not isolated to L146.

## Recommended remediation

Split the L146 box into two separate checkboxes:

```
- [ ] The Implement-phase autopilot terminates the wave loop and writes
  `HALT-orchestration-boundary-undeterminable.md` when the OBC report
  carries any `## Dispatch defects` entry; no skip-and-continue path
  exists (G5).
- [ ] The v0.7.2 phase-1 acceptance suite (`tests/acceptance/v07-phase1/`)
  passes against the trimmed skill set with zero regressions;
  `scripts/measure-active-footprint.sh` reports < 30K tokens per typical
  session, captured at `docs/qrspi/2026-06-04-v073-release/g9-footprint-report.md`
  (G9).
```

— and delete the existing L150 G9 box (the regression-guard half is now in
the new box from the L146 split, leaving the G9 box redundant). OR delete
the second sentence of the L146 box entirely (keep the L150 G9 box as the
sole owner of the regression-guard criterion).

The L145 box (preceding the mashed one) should be reviewed under the same
rule — the post-semicolon "Missing/malformed `reviews/<phase>/phase-base.txt`
at OBC time surfaces ... triggers the autopilot's unconditional dispatch-defect
halt (G5 fail-loud branch)" is a second criterion that overlaps significantly
with the L146 first sentence; the three pieces (empty-report, fail-loud-branch
direction, autopilot unconditional halt) should resolve into two or three
atomic boxes with no overlap rather than two boxes that each carry a sentence
of each criterion.

## Severity

Medium. The Phase 1 Acceptance Criteria block is the contract the
integration-phase gate consumes; non-atomic criteria silently degrade the
gate's ability to discharge each criterion independently. Not high severity
because the constituent criteria are all present and verifiable — the defect
is in the bundling, not in the substance.
