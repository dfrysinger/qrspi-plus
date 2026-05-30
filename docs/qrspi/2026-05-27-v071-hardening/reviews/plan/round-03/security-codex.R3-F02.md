---
finding_id: R3-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 3
reviewer: security-codex
---

No fail-closed runtime validation for malformed/overridden model_routing config (Task 10)

Gap: Task 10 validates entries exist in repo docs/lint but does not require runtime rejection for invalid operator config (missing host/tier entry, malformed model ID, unknown tier).

Risk: runtime may silently fall back to unintended defaults; insecure default behavior; hard-to-detect misconfiguration.

Needed: runtime tests requiring explicit error / non-zero when model_routing resolution is missing/invalid instead of fallback substitution.
