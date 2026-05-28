---
finding_id: R3-F01
severity: medium
change_type: boundary-drift
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/phasing.md]
artifact: phasing
round: 3
reviewer: scope-codex
defers_to: [parallelize]
disposition: DISMISS
---

## Original finding

Residual boundary drift remains in Slice 4 and replan criterion 8. The OWNS/DEFERS contract explicitly defers "Dependency graph, Wave decisions, branch maps" to Parallelize, but the phasing text still specifies Parallelize-internal presentation shape ("Branch Map grouped per Wave") and downstream reviewer/example update details.

Resolution direction (per reviewer): keep Slice 4 / criterion 8 framed as a phase-level outcome keyed to G4 without prescribing Branch-Map/Wave presentation mechanics or reviewer/example artifact updates.

## Disposition: DISMISS

Reasoning:

1. **Canonical G4 vocabulary derives from goals.md.** Goal G4 is titled "Wave-grouped task presentation in `parallelization.md` (#42)" and frames the problem in terms of "flat Branch Map" vs Wave grouping. The deliverable's identity is the change to Parallelize SKILL prose about Wave/Branch Map presentation. Phasing's OWNS bullet for vertical-slice authoring requires naming the slice's end-to-end deliverable. Stripping Wave and Branch Map vocabulary from the slice descriptor reduces the deliverable identity to opaque language ("parallelization guidance is reorganized and validated") that no longer ties traceably to G4.

2. **Spirit-of-rule reading of owns-defers.md L17.** "Dependency graph, Wave decisions, branch maps -> owned by Parallelize" is the dispatch surface for the THIS-PIPELINE-RUN's parallelization plan (which tasks run in which Wave, with which Branch Map for THIS hardening effort). Slice 4 here is a meta-change to the Parallelize SKILL's documentation surface, not a wave decision for this run. The G4 work itself will be consumed BY a future pipeline's Parallelize step; phasing.md naming what the SKILL prose will become does not encroach on parallelization-decision authority for v0.7.1.

3. **Reviewer-pair convergence pattern.** Three of four R3 reviewers cleared this surface explicitly. Claude scope R3: "softening moves away from Implement/Plan boundaries, not toward them. OWNS coverage preserved -- G4 attribution and DKR4 binding intact. No lexical drift signals." Claude scope R2 explicitly evaluated the prior version with stronger Wave/Branch Map vocabulary and called it "borderline but acceptable -- the slice is naming the deliverable, not making Wave assignments." Codex scope is the lone persistent dissent.

4. **Contradictory Codex pair.** Codex quality R3 simultaneously flagged criterion 8 as "weaker than DKR4 specifies concrete target shape" and recommended adding back "required Wave-subsection structure, required table shape, and the corresponding structural lint/test pass signal." Codex scope R3 (this finding) wants the opposite (less Wave/Branch Map vocabulary). The two Codex reviewers cannot both be satisfied; any R4 fix would re-trigger one or the other. Oscillating contradictory single-reviewer findings against a stable two-reviewer-clean baseline are dismissal candidates per the QRSPI convergence pattern.

Conclusion: Slice 4 + criterion 8 retain the canonical G4 vocabulary (Wave, Branch Map) that traces directly to goals.md G4's framing. Implement-mechanic details (pinning rule, Worked Example pair specifics, structural lint test) were stripped in R3. No further changes.

(Disposition added by orchestrator after R3 convergence analysis.)
