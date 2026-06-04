---
finding_id: R7-F01
severity: medium
change_type: scope
referenced_files: [scripts/lib/path-guard.sh]
status: deferred-v0.7.3
---
QRSPI_REPO_ROOT env override widens boundary trust to caller-controlled value.
Duplicate of sec-codex R3 + R6 deferral. Tracked in v072-issues.md for v0.7.3
hardening (env-source attestation or removal of override surface).
