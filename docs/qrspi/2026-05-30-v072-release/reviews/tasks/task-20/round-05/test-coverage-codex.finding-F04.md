---
reviewer: test-coverage-codex
round: 5
finding_id: R5-F04
severity: medium
change_type: correctness
referenced_files: [tests/unit/test-dispatch-agent.bats]
---

# F04 — Batched dispatch lacks "exactly one spec line per first-party reviewer" assertion across multiple reviewers

task-20.md L42, L54 require exactly one first-party spec line per first-party reviewer. tests/unit/test-dispatch-agent.bats:1019-1055 validates spec-line shape with a single reviewer but no multi-reviewer count/assertion. Duplicate/missing lines in multi-agent batches could slip through while single-agent tests pass.
