---
finding_id: F02
severity: medium
change_type: missing_requirement
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md, docs/qrspi/2026-05-27-v071-hardening/structure.md]
artifact: plan
round: 1
reviewer: security-codex
---

## `check_codex_available()` does not verify Codex access/authorization

Task 6 requires `check_codex_available(copilot-cli)` to return success without verifying actual Codex access/authorization; no test expectation covers unauthorized/forbidden/unreachable for either host.

**Disposition:** Set aside as out-of-G6-scope. G6's goal is "auto-detect which transport to use" (host probe), not "auth-gate Codex dispatch." Adding token/credential validation would expand G6 beyond goals.md and design.md DKR6/DKR7. The existing `codex-broker` transport already surfaces auth failures via its provider machinery; a host-detection function is not the right boundary for an auth check. Note rationale in Task 6 description.
