---
finding_id: R1-F01
reviewer_tag: silent-failure-claude
round: 1
task: 1
severity: high
change_type: correctness
referenced_files: [skills/_shared/verifier-filter-rule.md]
materialized_by: orchestrator
materialized_reason: agent returned findings in chat without writing to disk
---

# F01 — Absent vs empty `kept-findings.txt` indistinguishable; silent crash-as-success

The snippet describes the success-path output contract only. Two states are left indistinguishable to consumers:

| Condition | File state |
|---|---|
| Script crashed / not run | File absent |
| Script ran, zero findings passed threshold | File exists, empty |

An orchestrator following only this snippet has no guidance to distinguish these cases. The natural fallback is to treat a missing file as "no findings kept" — silently converting a pipeline failure into a clean review pass.

**Fix proposal:** the snippet should instruct consumers to treat an absent `kept-findings.txt` as a pipeline error distinct from an empty file, and to halt or alert rather than proceeding.
