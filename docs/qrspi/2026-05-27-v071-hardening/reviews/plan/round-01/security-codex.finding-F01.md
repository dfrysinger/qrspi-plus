---
finding_id: F01
severity: high
change_type: missing_requirement
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md, docs/qrspi/2026-05-27-v071-hardening/design.md]
artifact: plan
round: 1
reviewer: security-codex
---

## Host-detection has no fail-closed requirement for unsupported/ambiguous hosts

Task 6/7/10 default to `claude-code` when COPILOT_CLI is absent; no fail-closed path for malformed env or future host values. Tests only cover set/unset COPILOT_CLI. Convergent with security-claude F02, silent-failure-claude F01, silent-failure-codex F01, testcov-claude F07, testcov-codex F02.

**Required fix:** Add explicit requirements/tests that unknown or inconsistent host signals must return non-zero with diagnostic; block dispatch/model resolution until host is valid. Cover malformed COPILOT_CLI value (e.g., `COPILOT_CLI=0`).
