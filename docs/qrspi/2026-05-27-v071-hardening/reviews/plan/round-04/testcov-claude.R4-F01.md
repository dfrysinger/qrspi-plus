---
finding_id: R4-F01
severity: medium
change_type: clarity
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 4
reviewer: testcov-claude
---

Transport-marker expectations reference unnamed "dispatch surface" entry point

Task 6 transport-marker assertions live in test-host-detection.bats. The two named functions (detect_host, check_codex_available) explicitly do NOT emit to stderr (per bullet). Markers emit "when the dispatch surface selects a path" — but that surface has no function name in the plan.

Test writer cannot identify which function to call. Fix: name the dispatch-surface function (or named wrapper) in Task 6 description / target files list.
