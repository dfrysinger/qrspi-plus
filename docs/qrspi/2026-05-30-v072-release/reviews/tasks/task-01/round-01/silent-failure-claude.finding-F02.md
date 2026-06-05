---
finding_id: R1-F02
reviewer_tag: silent-failure-claude
round: 1
task: 1
severity: medium
change_type: correctness
referenced_files: [skills/_shared/verifier-filter-rule.md]
materialized_by: orchestrator
materialized_reason: agent returned findings in chat without writing to disk
---

# F02 — Missing verifier sidecar causes silent finding-drop; kept set appears complete

The snippet says the script processes each finding via its sidecar but says nothing about findings whose sidecar is absent. If the script silently skips findings with no matching sidecar, those findings vanish from `kept-findings.txt` with no indication they were dropped rather than threshold-filtered.

**Fix proposal:** specify that findings with absent sidecars are treated as an error condition — either the script halts, or they are logged as `sidecar-missing` rather than silently skipped. Consumers should be directed to check for that condition.
