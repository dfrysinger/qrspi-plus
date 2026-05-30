---
finding_id: R3-F03
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 3
reviewer: testcov-codex
---

Task 7 dropped G6 integration success assertion from design strategy

Expectations now verify transport markers/mutual exclusion but no longer explicitly assert successful dispatch outcome (exit 0) for each host path. A failing dispatch could still emit the right marker and satisfy current expectations.

Needed: for both Copilot and Claude paths, assert marker correctness AND success result (exit code 0 / expected success signal).
