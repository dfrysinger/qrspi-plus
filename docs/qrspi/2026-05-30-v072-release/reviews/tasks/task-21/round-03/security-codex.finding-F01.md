---
finding_id: F01
reviewer: security-codex
severity: medium
change_type: correctness
referenced_files: [scripts/dispatch-agent.sh:69-72, scripts/dispatch-companion.sh:60-63, scripts/lib/path-guard.sh:63-97]
---
**QRSPI_REPO_ROOT env override allows boundary bypass.** Setting `QRSPI_REPO_ROOT=/` makes assert_path_under_repo_root permit any file. Hardening: lock to git-discovered toplevel or require flag opt-in.

**Adjudication:** DEFER to v0.7.3. Threat model — attacker with env-var control already has equivalent capabilities (LD_PRELOAD, PATH); env var is needed for legitimate worktree/non-git-root dispatch. T21's spec scope is prompt-ingestion path guards (delivered); environment-trust hardening is a separate threat-model expansion.
