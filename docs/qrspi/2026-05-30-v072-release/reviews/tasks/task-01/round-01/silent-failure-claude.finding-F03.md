---
finding_id: R1-F03
reviewer_tag: silent-failure-claude
round: 1
task: 1
severity: medium
change_type: correctness
referenced_files: [skills/_shared/verifier-filter-rule.md]
materialized_by: orchestrator
materialized_reason: agent returned findings in chat without writing to disk
---

# F03 — No script exit-code guidance; non-zero exit silently accepted alongside partial output

The snippet describes success-path behavior exclusively and gives no directive about checking script exit status. If `verifier-fan-in.sh` exits non-zero, an orchestrator following this rule has no instruction to check `$?` before consuming `kept-findings.txt`.

**Fix proposal:** include a one-line prescription that consumers must verify zero exit before treating `kept-findings.txt` as authoritative; a non-zero exit is a pipeline error, not a zero-finding result.
