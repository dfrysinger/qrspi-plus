---
finding_id: F01
reviewer: silent-failure-codex
severity: medium
change_type: correctness
referenced_files: [scripts/dispatch-agent.sh:78, scripts/dispatch-companion.sh:65]
---
**Source of path-guard.sh fails open on load failure.** `. "$_path_guard_lib"` without return-code check in scripts that don't `set -e`. If lib unreadable/missing/syntax-error, dispatch continues; later assert_path_under_repo_root → "command not found" silently. Fail-open on security control. Fix: check `. "$lib" || { echo error >&2; exit 1; }` OR assert function defined after source: `command -v assert_path_under_repo_root >/dev/null || { echo "path-guard.sh failed to load" >&2; exit 1; }`.
