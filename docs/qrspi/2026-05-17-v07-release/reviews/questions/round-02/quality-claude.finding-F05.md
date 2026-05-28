---
finding_id: R2-F05
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L21]
artifact: questions
round: 2
reviewer: quality-claude
---

Q12's second clause leaks the G7 fix hypothesis.

The question reads: "How does `skills/implementer-protocol/SKILL.md` thread reviewer-finding and task identifiers into fix-cycle implementer prompts, and what guidance, if any, restricts those identifiers from appearing in edited files?" The second clause "restricts those identifiers from appearing in edited files" presupposes a specific defect class — the G7 "Fix-cycle ID-hygiene leak" problem statement: "implementers have carried those QRSPI-internal tokens into shipped skill files, agent files, and tests while patching prose or comments." It also presupposes the candidate fix shape (G7: "explicit fix-cycle ID-hygiene guidance" + "lint or verification step... grepping edited files before commit for the forbidden token patterns").

A researcher reading only Q12 would correctly infer the project suspects identifiers are leaking into edited files and is looking for the absence of guard rails — that is the G7 fix space, not a neutral state-of-the-codebase question.

Recommend splitting into two neutral codebase questions: (a) "How does implementer-protocol thread reviewer-finding and task identifiers into fix-cycle implementer prompts?" — current-state only; and (b) "What in-file token or identifier conventions, if any, do existing QRSPI implementer agents and protocols document?" — generic, not pre-naming "fix cycle" or "restricts from appearing in edited files." The researcher's findings then reveal whether the gap exists; the question stops asserting that the gap exists.
