---
finding_id: R3-F09
severity: medium
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L21]
artifact: questions
round: 3
reviewer: quality-claude
---

Q15's reference-artifact parenthetical is a direct lift from G10. The question asks where dispatch prompts "treat a reference artifact (screenshot, golden file, fixture) as ground truth" — the triplet `screenshot, golden file, fixture` mirrors G10's "prototype screenshot, golden output file, or contract fixture." Beyond pre-supplying the same examples, the enumeration narrows the researcher's lens to exactly G10's reference-artifact categories rather than letting them discover the breadth of reference inputs the pipeline actually uses. Drop the parenthetical and let the noun "reference artifact" stand alone — for example, "Where in the QRSPI pipeline (Plan, Parallelize, Implement, reviewer agents) do dispatch prompts treat a reference artifact as ground truth, and what kinds of reference artifacts appear today?" — so the research surfaces the artifact taxonomy as a finding.
