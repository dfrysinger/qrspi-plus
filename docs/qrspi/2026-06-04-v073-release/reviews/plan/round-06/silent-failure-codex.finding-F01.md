---
finding_id: R6-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L624-L629
artifact: plan
round: 6
reviewer: silent-failure-codex
---

T01 SILENT_FALLBACK on unknown step names: description + test expectation require unknown `--step` returns always-appended paths and exits 0, no stderr. A typo/miswired step still returns plausible output; callers proceed with incomplete upstream context and never learn dispatch input was invalid.

Note: this is already documented in plan as a defer-to-upstream Author Note citing design.md § CD-1 + CD-2 (intentionally-silent direction).
