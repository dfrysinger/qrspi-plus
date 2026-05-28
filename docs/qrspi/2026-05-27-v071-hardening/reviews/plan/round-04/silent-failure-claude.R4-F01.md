---
finding_id: R4-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 4
reviewer: silent-failure-claude
---

SWALLOWED_ERROR: Task 7 has no test pinning propagation of failed-but-correctly-routed dispatch exit codes

R4 added success-path assertions (mocked dispatch exits 0, non-empty stdout). Missing case: routing correct, Codex available, transport command RUNS but exits non-zero (API failure, timeout, bad model). No expectation requires dispatch surface to propagate non-zero exit to caller.

A dispatcher that swallows non-zero (e.g., calls run-codex-review.sh which exits 1, emits marker, returns 0) passes every existing assertion. Orchestrator treats failed review as successful, no reviewer output, reports green.

Fix: Add to Task 6/7: "When the mocked transport command (correctly-routed, Codex available) exits non-zero, the dispatch surface returns that same non-zero exit code without suppression or log-and-continue."
