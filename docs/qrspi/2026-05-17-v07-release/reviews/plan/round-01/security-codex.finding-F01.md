---
finding_id: R1-F01
severity: high
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L198-L206, docs/qrspi/2026-05-17-v07-release/plan.md:L249-L255]
artifact: plan
round: 1
reviewer: security-codex
---

Task 03 introduces the dispatcher that reads provider credentials from `api_key_env` and calls third-party endpoints, while Task 05 records routing telemetry to disk, but neither task requires secret redaction from stderr diagnostics, output files, request traces, or telemetry. The dispatcher is explicitly required to fail loudly across timeout, hard-error, malformed-result, and missing-key paths; without a redaction requirement, an implementation can accidentally echo the resolved API key, `Authorization` header, or sensitive `default_headers` into CI logs or QRSPI artifacts.

Fix: add dispatcher requirements and tests asserting that resolved secret values never appear in stderr, output files, telemetry JSON, or diagnostic bodies on missing-key, upstream-error, malformed-response, and timeout paths. Diagnostics should name the env var or provider key, not the secret value.
