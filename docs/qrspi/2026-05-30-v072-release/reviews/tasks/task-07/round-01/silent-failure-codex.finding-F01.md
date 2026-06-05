---
reviewer_tag: silent-failure-codex
round: 1
finding_id: F01
severity: high
change_type: correctness
referenced_files:
  - skills/reviewer-protocol/SKILL.md:L151-L154
  - agents/qrspi-finding-verifier.md:L19-L36
---

Informational findings are explicitly routed to "log-only / no auto-apply / no pause" based solely on a message prefix, with no safeguard that the underlying issue is non-action-bearing. This creates a silent-failure path: a reviewer can (accidentally or otherwise) label a real correctness/intent issue as `Informational:` and the loop will continue without surfacing a decision gate, even when the finding is structurally verified (>=50). The protocol should add a hard guard (for example, disallow Informational for intent/scope/high-severity findings, or force explicit user surfacing when structural confidence is high).

[Materialized from chat-only response by gpt-5.3-codex.]
