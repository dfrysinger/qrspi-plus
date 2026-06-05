---
finding_id: R1-F01
severity: major
change_type: correctness
referenced_files: [scripts/detect-interaction-mode.sh, tasks/task-24.md]
reviewer_tag: spec-codex
---

The override-success path (`QRSPI_INTERACTION_MODE=auto|interactive`, script L98-112)
exits after emitting only `VERDICT` and `EVIDENCE`, but does not emit `DETECTION_TYPE`
(nor `PLATFORM`). The DoD output-shape contract defines
`DETECTION_TYPE ∈ {shell-verdict, llm-context, user-override-only}`, and design.md
CD-4 §I.7 (L675) requires the orchestrator to copy `PLATFORM`, `DETECTION_TYPE`,
`VERDICT`, `EVIDENCE` directly from script stdout to populate the round-start
`.interaction-mode-audit.json` `{platform, detection_type, verdict, evidence}` tuple.
Without `DETECTION_TYPE` (and `PLATFORM`) on the override path, the orchestrator
cannot construct the audit tuple for an override detection cycle. The override is an
environment-computed verdict and should emit `DETECTION_TYPE=shell-verdict` (matching
the design shell-verdict exemplar) plus a `PLATFORM` line.
