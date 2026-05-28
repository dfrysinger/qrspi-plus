---
finding_id: F01
severity: high
change_type: silent_fallback
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md, docs/qrspi/2026-05-27-v071-hardening/design.md]
artifact: plan
round: 1
reviewer: silent-failure-codex
---

## `detect_host()` defaults to claude-code when COPILOT_CLI unset/empty — silent fallback

Convergent with security-claude F02, security-codex F01, silent-failure-claude F01, testcov-claude F07.

**Resolution:** Add explicit "unknown host" return path; require non-zero exit when host signal is ambiguous. Test coverage: COPILOT_CLI unset → claude-code; COPILOT_CLI=1 → copilot-cli; COPILOT_CLI=0 or other value → unknown (non-zero).
