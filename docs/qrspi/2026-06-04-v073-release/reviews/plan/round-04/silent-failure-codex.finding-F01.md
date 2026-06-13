---
finding_id: R4-F01
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L178-L183
  - docs/qrspi/2026-06-04-v073-release/plan.md:L141
artifact: plan
round: 4
reviewer: silent-failure-codex
---

SILENT_FALLBACK in T01 unknown-step handling. T01 explicitly returns success (`exit 0`) for unknown `--step` and emits only always-appended paths. A typoed/invalid step can still produce plausible downstream behavior with missing step-specific inputs, and callers won't know dispatch input selection failed.

