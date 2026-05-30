---
finding_id: F02
severity: high
change_type: swallowed_error
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md, docs/qrspi/2026-05-27-v071-hardening/goals.md]
artifact: plan
round: 1
reviewer: silent-failure-codex
---

## Caller obligation undefined when `check_codex_available()` returns non-zero

Convergent with silent-failure-claude F01.

**Resolution:** Specify caller obligation on non-zero: emit a one-line diagnostic to stderr naming the missing Codex transport for the detected host AND propagate non-zero exit. The pipeline must not degrade to log-and-continue or config-driven skip. Add unit test pin in Task 7 acceptance test for the unavailable-Codex path.
