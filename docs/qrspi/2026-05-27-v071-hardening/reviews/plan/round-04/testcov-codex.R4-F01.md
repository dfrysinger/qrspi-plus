---
finding_id: R4-F01
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 4
reviewer: testcov-codex
---

Task 6 expectation is too broad/unfalsifiable

"detect_host produces the same result regardless of other unrelated environment variables being set or unset" — "other unrelated environment variables" is unbounded and undefined.

Fix: replace with finite explicit matrix (specific env vars set/unset) or constrain to "when only COPILOT_CLI changes, output follows the defined 2-branch rules."
