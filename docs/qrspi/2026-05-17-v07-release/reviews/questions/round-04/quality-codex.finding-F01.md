---
finding_id: R4-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L7-L37]
artifact: questions
round: 4
reviewer: quality-codex
---

The question set still violates the Questions step's goal-leakage rule: a researcher reading only these prompts can infer the release agenda almost verbatim, including cheap-model routing policy/mechanism work, post-approval plan splitting, test-writer splitting, reference-gate design, GitHub Actions CI, and evergreen-prose linting. The issue is not just that the questions are specific; many of them name the exact intended intervention surface (`model-routing policies`, `third-party LLM endpoints`, `post-approval split-into-task-files`, `reference_gate`, `GitHub Actions`, `release-version strings`), which reveals what QRSPI is trying to build rather than preserving neutral research framing. Fix by rewriting the questions so they ask for bounded factual reconnaissance about current contracts, framework patterns, and failure modes without telegraphing the planned feature or remediation direction.
