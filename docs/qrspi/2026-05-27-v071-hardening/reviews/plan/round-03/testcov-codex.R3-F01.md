---
finding_id: R3-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 3
reviewer: testcov-codex
---

Task 1 missing interior-position coverage for header NAMES

Interior-position control-byte coverage was added for header values only, not header names. An implementation that only checks first byte of header names could pass all current name tests while failing to detect mid-name control bytes.

Needed: a deterministic case "header name with printable prefix + control byte + printable suffix exits before dispatch."
