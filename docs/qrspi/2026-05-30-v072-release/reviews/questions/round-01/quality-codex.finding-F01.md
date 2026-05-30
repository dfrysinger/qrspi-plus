---
finding_id: R1-F01
severity: medium
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/questions.md
  - docs/qrspi/2026-05-30-v072-release/goals.md
artifact: questions
round: 1
reviewer: quality-codex
---

## Question set leaks the intended build agenda

The question set leaks the intended build agenda. A researcher reading only `questions.md` can infer the exact release intent (verifier sidecars, task-tool disk-write behavior, model-routing drift, bats warning cleanup), which violates the "goal must not be discernible from the question alone" check.

### Evidence

- Questions explicitly name the same target surfaces and failure themes as the goals (e.g., sidecar wiring in Q1, transport branch in Q4, model_routing schema in Q6, shebang deprecation in Q9, codex-availability probe in Q15, contradiction-refusal/system-prompt behavior in Q18) (`questions.md` lines 7–41).
- These map directly to goals G6/G7/G8/G9/G11/G16/G22/G26/G27 and related context (`goals.md` lines 138–175, 177–380, 438–469, 628–799).

### Requested fix

Rewrite questions to be investigatory but less agenda-revealing (reduce issue-number-style specificity and solution-adjacent phrasing), while still preserving research utility.
