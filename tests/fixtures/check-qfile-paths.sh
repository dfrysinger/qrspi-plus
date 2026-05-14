#!/usr/bin/env bash
set -euo pipefail

# check-qfile-paths.sh
# Usage: check-qfile-paths.sh <path1> [<path2> ...]
#
# Precondition checker for the research-reviewer companion_qfile_paths
# dispatch parameter. Validates that:
#   1. At least one path is provided (empty list is a precondition failure)
#   2. Every provided path resolves to a readable file
#
# On success (all paths readable, list non-empty): exits 0 with no output.
# On failure: exits 1 with a diagnostic on stderr naming the condition.
#
# This script is the orchestrator-side precondition assertion described in
# skills/research/SKILL.md § Review Round. It is called before the Claude
# quality-reviewer subagent is dispatched. On any failure, dispatch must be
# refused — the caller is responsible for surfacing the failure to the user.

if [[ "$#" -eq 0 ]]; then
  echo "check-qfile-paths: precondition failure — companion_qfile_paths is empty (zero q-files). Dispatch refused. Provide at least one q-file path." >&2
  exit 1
fi

failed=0
for path in "$@"; do
  if [[ ! -r "$path" ]]; then
    echo "check-qfile-paths: precondition failure — unreadable path: $path. Dispatch refused." >&2
    failed=1
  fi
done

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

exit 0
