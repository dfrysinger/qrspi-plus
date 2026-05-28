---
finding_id: R2-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L7-L33, docs/qrspi/2026-05-17-v07-release/goals.md:L23-L320]
artifact: questions
round: 2
reviewer: quality-codex
---

The question set leaks the release agenda so directly that a researcher reading only `questions.md` can infer what QRSPI is trying to build: cost-optimized third-party routing, plan splitting, context-shim/index work, a test-writer split, parallelize reviewer fixes, CI, and evergreen-prose linting are all named almost one-for-one in the questions. That violates the questions-step requirement that the goal not be discernible from the question alone. Fix by rewriting the questions to ask for neutral evidence about current behavior, existing patterns, failure modes, and configuration shapes without naming the intended QRSPI feature candidates or issue-driven solution directions so explicitly.
