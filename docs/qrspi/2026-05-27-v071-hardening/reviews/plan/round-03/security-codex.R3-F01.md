---
finding_id: R3-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 3
reviewer: security-codex
---

Missing auth-failure requirements for Codex dispatch (Tasks 6/7)

Gap: Tasks 6 and 7 define host detection, transport routing, and availability checks but test expectations do not require explicit handling of authentication/authorization failures (invalid/missing token, 401/403 from task-tool/shell dispatch).

Risk: dispatch could fail ambiguously; auth failures hard to distinguish from empty outcomes.

Needed: tests simulating unauthorized Codex calls per host path requiring clear stderr diagnostic + non-zero propagation.
