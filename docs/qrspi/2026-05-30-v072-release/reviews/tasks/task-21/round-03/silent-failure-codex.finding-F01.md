---
finding_id: F01
reviewer: silent-failure-codex
severity: medium
change_type: correctness
referenced_files: [scripts/dispatch-agent.sh:548-551, scripts/dispatch-agent.sh:657-661, scripts/dispatch-agent.sh:664-670, scripts/dispatch-agent.sh:673-676]
---
**Swallowed source failure on _resolve-lib.sh.** `QRSPI_SOURCE_ONLY=1 . "$_resolve_lib" || true` suppresses load errors; downstream defaults (tier=medium, first-party fallback) can silently produce wrong routing/model. Remove `|| true` or fail loud when resolver funcs are unavailable.

**Adjudication:** OUT-OF-SCOPE for T21 (G16 path-traversal hardening). Defer to v0.7.3 — separate concern from prompt-ingestion path guards.
