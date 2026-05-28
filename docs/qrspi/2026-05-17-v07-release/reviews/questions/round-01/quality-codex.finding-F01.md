---
finding_id: R1-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L7-L31]
artifact: questions
round: 1
reviewer: quality-codex
---

The question set leaks the release goals so directly that a researcher reading only `questions.md` can reconstruct the intended workstream instead of investigating neutrally. Across the list, the questions name the exact target surfaces and exemplars from the goals themselves: model-routing policy, DeepSeek/Kimi compatibility, the specific Medium article, the Plan post-approval split, context-summary shims, test-writer split, Parallelize vocabulary, reference-gate mechanics, CI for this repo, and evergreen-prose linting. That violates the Questions contract's goal-leakage rule, because the artifact is no longer a goal-oblivious research brief; it is effectively a decomposed implementation agenda.

Why this matters: once the goal is inferable from the question text, research is biased toward confirming the release framing rather than surfacing neutral facts about the underlying surfaces. The fix is to rewrite the questions so they ask about the observable systems and comparison dimensions without naming the intended release themes, preferred exemplars, or the planned feature buckets so explicitly.
