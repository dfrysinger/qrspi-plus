---
finding_id: R3-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 3
reviewer: testcov-claude
---

Task 6: COPILOT_CLI_BINARY_VERSION interaction not explicitly named; "unrelated env vars" cover is insufficient

The Copilot CLI launcher sets COPILOT_CLI_BINARY_VERSION alongside COPILOT_CLI=1. Implementation using prefix-match or `${!COPILOT_CLI*}` glob could conflate this var. The generic "unrelated env vars" expectation is question-begging.

Fix: add explicit expectation: "When COPILOT_CLI_BINARY_VERSION is set but COPILOT_CLI is not =1, detect_host emits claude-code — COPILOT_CLI_BINARY_VERSION alone is not a host-detection trigger."
