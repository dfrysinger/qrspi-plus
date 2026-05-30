---
finding_id: R3-F03
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 3
reviewer: testcov-claude
---

Task 7: Acceptance test expectations no longer verify dispatch SUCCESS — design integration-test requirement not met

Design Test Strategy for G6: "Integration test that dispatching a Codex review via the host-appropriate transport SUCCEEDS." R3 replaced the success assertion with transport-marker-only assertions. A failing dispatch that emits the right marker and exits non-zero satisfies all current expectations.

Fix: add additive assertions (don't replace marker checks): mocked dispatch exits 0 for each host path; captured output is non-empty.
