---
finding_id: R4-F01
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/phasing.md:L117]
artifact: phasing
round: 4
reviewer: quality-claude
---

The `## Pruning Summary` section in `phasing.md` states:

> `questions.md` — current-phase: Q1–Q20, Q22. Deferred to `future-questions.md`: Q21.

However, `questions.md` actually contains Q1–Q20 plus Q22 through Q31 (ten questions beyond Q20, with Q21 deferred). The notation "Q1–Q20, Q22" implies exactly two groups — questions 1 through 20 and question 22 only — which omits Q23, Q24, Q25, Q26, Q27, Q28, Q29, Q30, and Q31 from the stated scope.

These nine additional questions are present in `questions.md` and are clearly current-phase (they cover Q22 GitHub Actions CI patterns, Q23 branch-naming conventions, Q24 release-version strings, Q25 lint/CI patterns for markdown, Q26 dispatcher classes, Q27 A/B-comparing LLM agent outputs, Q28 freshness contracts, Q29 in-file token conventions, Q30 reference artifact validation, Q31 config.md default handling — all in support of current-phase goals). None of them appear in `future-questions.md`.

The fix is to correct the range notation to accurately reflect the full current-phase set: "Q1–Q20, Q22–Q31" (or equivalently "Q1–Q31 except Q21").
