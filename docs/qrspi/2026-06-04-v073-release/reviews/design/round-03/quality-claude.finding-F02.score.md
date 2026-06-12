---
verifier_status: passed
score: 80
actual_model: unknown
defect_class: internal-inconsistency
---

All cites verified against design.md:
- L316: cross-cutting note for using-qrspi states the hook "runs at every phase boundary" — verbatim match.
- L321: Step N directive scoped to `skills/{integrate,test}/SKILL.md` only — implement excluded.
- L337: Batch-gate menu addition scoped to `skills/{implement,integrate,test}/SKILL.md` — implement included.
- L383: Acceptance criterion names only integrate and test SKILLs for the Step N block.

The contradiction is real and material: (a) the verbatim prose destined for using-qrspi overclaims "every phase boundary"; (b) the batch-gate conditional ("when `reviews/implement/orchestration-boundary.md` is non-empty") cannot ever fire for implement because no Step N produces that file there. Either the prose needs scope correction or implement needs a Step N. Medium-severity correctness issue with clear remediation paths spelled out. Strong, verifiable, not a nitpick.
