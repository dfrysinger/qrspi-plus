---
finding_id: R4-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 4
reviewer: silent-failure-codex
---

Log-and-continue on host/config mismatch hides a correctness failure (Tasks 6 & 7)

Mismatch now emits stderr line and continues. Reviewer argues warning-only allows wrong routing while returning success; only stderr text indicates the issue.

NOTE FOR FIX-SYNTHESIS: This is set-aside (duplicate of security-codex R4-F01). Design DKR6 line 55 explicitly says "emit a one-line diagnostic naming the disagreement" — the design accepts warning-only behavior as the chosen tradeoff. The R3 fix aligned plan with approved design.
