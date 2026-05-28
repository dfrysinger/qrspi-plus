---
finding_id: R2-F06
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L23]
artifact: questions
round: 2
reviewer: quality-claude
---

Q14's "define or contradict" phrasing reveals G9's known-defect hypothesis.

The question reads: "What Branch Map vocabulary is canonical in `skills/parallelize/SKILL.md` Branch Model and Worked Example, and where do `agents/qrspi-parallelize-reviewer.md` and `skills/reviewer-protocol/SKILL.md` define or contradict that vocabulary?" Including "contradict" in the question presupposes the G9 problem statement: "The Parallelize reviewer or its preloaded protocol uses Branch Map vocabulary that contradicts the canonical vocabulary in `skills/parallelize/SKILL.md`." A researcher reading only Q14 would correctly infer the project already knows there is a vocabulary contradiction and is asking the researcher to locate it — which is the G9 fix space.

Recommend neutralizing: "What Branch Map vocabulary is canonical in `skills/parallelize/SKILL.md` Branch Model and Worked Example, and what Branch Map vocabulary, if any, is defined or assumed in `agents/qrspi-parallelize-reviewer.md` and `skills/reviewer-protocol/SKILL.md`?" The researcher then reports the vocabulary surfaces side by side; the cross-check (do they match? do they conflict?) becomes the Design step's job, not a pre-baked finding handed to the researcher.
