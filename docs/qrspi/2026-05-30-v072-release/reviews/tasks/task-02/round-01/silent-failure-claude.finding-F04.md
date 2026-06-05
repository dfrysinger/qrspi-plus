---
finding_id: R1-F04
reviewer_tag: silent-failure-claude
round: 1
task: 02
severity: low
change_type: correctness
referenced_files:
  - skills/_shared/verifier-dispatch-prose.md
---

## F04 — Prose contract no fallback for missing audit on non-zero exit

Lines 76-80. Orchestrator told to read .verifier-fan-in-audit.json on non-zero exit. F01/F02 above show realistic failure modes where exit is non-zero but audit absent. Following prose literally → confusing secondary "missing audit" error masks root cause.

Fix: prose guard — if audit absent after non-zero exit, escalate with "fan-in failed before producing diagnostics (likely missing jq or write-perm)".
