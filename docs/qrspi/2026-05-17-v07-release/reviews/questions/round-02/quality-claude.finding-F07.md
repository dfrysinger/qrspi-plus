---
finding_id: R2-F07
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L24]
artifact: questions
round: 2
reviewer: quality-claude
---

Q15's second clause reveals the G10 problem framing.

The question reads: "Where in the QRSPI pipeline (Plan, Parallelize, Implement, reviewer agents) do dispatch prompts treat a reference artifact (screenshot, golden file, fixture) as ground truth, and what gating, if any, validates the reference itself before downstream consumers fire?" The second clause "what gating, if any, validates the reference itself before downstream consumers fire" presupposes the G10 problem: "QRSPI can ask downstream reviewers to treat a reference artifact as ground truth... without any gate that verifies the reference itself" and the candidate fix shape ("Implement responsibilities include halting after the producing task reaches terminal state... and requiring explicit approval before dependents are eligible").

The phrasing "before downstream consumers fire" is especially load-bearing — it specifies the exact gating semantics G10's candidate Plan/Parallelize/Implement responsibilities encode. A researcher reading only Q15 would correctly infer the project has identified an ungated-reference defect and is shopping for the absence of a wave-boundary gate.

Recommend splitting: (a) "Where in the QRSPI pipeline do dispatch prompts treat a reference artifact (screenshot, golden file, fixture) as ground truth?" — current-state only; and (b) "How does the QRSPI pipeline today validate or version reference artifacts that downstream reviewers compare against?" — neutral, no "before downstream consumers fire" wording that pre-names the candidate gate semantics.
