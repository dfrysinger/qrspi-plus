---
finding_id: R4-F02
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L222-L233
artifact: plan
round: 4
reviewer: silent-failure-codex
---

SILENT_FALLBACK in T03 "nothing to produce" path. T03 treats "artifact-dir not in git working tree" and "no diff output" as success with no files emitted, and T04a then omits prompt params. This hides whether inputs were legitimately empty vs. unavailable/misconfigured, so reviewers can run without required context and caller gets no explicit failure signal.

