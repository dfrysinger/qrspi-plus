---
finding_id: R2-F04
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L20]
artifact: questions
round: 2
reviewer: quality-claude
---

Q11's parenthetical reveals G6's "Why we care" framing.

The question reads: "What does published research and developer-tooling literature say about quality and failure-mode differences when test authoring is split from production-code authoring in LLM coding agents (shared context loss vs. separation of concerns)?" The parenthetical "shared context loss vs. separation of concerns" lifts the exact dichotomy G6 names in its "Why we care" section ("through separation of concerns... or hurt it through loss of shared context"). A researcher reading only this question would correctly infer the project has already framed the test-writer split as a tradeoff between those two specific properties — which is the G6 framing, not a neutral input.

The naked question — "What does published research and developer-tooling literature say about quality and failure-mode differences when test authoring is split from production-code authoring in LLM coding agents?" — is already complete. Drop the parenthetical and let the researcher surface whatever tradeoffs the literature actually names; they may include shared-context-loss and separation-of-concerns but may also include others (e.g., test-spec drift, prompt-budget effects, agent confusion under role switching) that the goal has not pre-named.
