---
id: F02
reviewer: code-quality-claude
round: 2
severity: low
area: cleanliness / DRY
file: tests/unit/test-detect-interaction-mode.bats
line: 55
---

# Dead `run_clean_env` helper comment — documents a function that was never implemented

## Location

`tests/unit/test-detect-interaction-mode.bats`, lines 55–59:

```bash
# ---------------------------------------------------------------------------
# Helper: run the script in a clean subshell with only supplied env vars set
# (plus PATH so bash/sh builtins remain reachable).
# Usage: run_clean_env [KEY=VALUE ...] -- [SCRIPT_ARGS ...]
# Sets $output, $status via `run`.
# ---------------------------------------------------------------------------
```

Immediately followed by `# ===========================================================================` —
there is no `run_clean_env()` function definition anywhere in the file.

## Problem

The comment advertises a `run_clean_env` helper that was never written. Every test
in the suite instead uses an inline copy of the same pattern (~25 occurrences):

```bash
run bash -c "
  unset COPILOT_CLI CLAUDE_PROJECT_DIR QRSPI_INTERACTION_MODE
  export SOME_VAR=value
  bash \"$SCRIPT\"
"
```

Two issues stack:

1. **Misleading comment.** A reader seeing the comment expects the helper to exist
   and to be usable from test bodies. It is not. The comment should either describe
   what IS there, or not exist.

2. **Repeated boilerplate.** The inline pattern is copy-pasted across ~25 tests.
   Each test has its own `unset`/`export` setup with slight variations. If the
   invocation pattern changes (e.g., adding `set -euo pipefail` to the subshell, or
   passing `--norc`), every occurrence needs to be updated in sync.

## Fix

**Option A (remove dead comment):** Delete lines 55–59 and leave the tests as-is.
This eliminates the misleading promise with no other change.

**Option B (implement the helper):** Define the function the comment documents:

```bash
# ---------------------------------------------------------------------------
# run_clean_env KEY=VALUE ... -- [SCRIPT_ARGS ...]
# Runs $SCRIPT in a clean subshell with exactly the supplied env vars set.
# Sets $output, $status via `run`.
# ---------------------------------------------------------------------------
run_clean_env() {
  local -a env_pairs=()
  local -a script_args=()
  local in_args=0
  for arg in "$@"; do
    if [[ "$arg" == "--" ]]; then in_args=1; continue; fi
    if [[ "$in_args" -eq 0 ]]; then env_pairs+=("$arg"); else script_args+=("$arg"); fi
  done
  local env_setup=""
  for pair in "${env_pairs[@]:-}"; do env_setup+="export $pair; "; done
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR QRSPI_INTERACTION_MODE
    ${env_setup}
    bash \"$SCRIPT\" ${script_args[*]:-}
  "
}
```

Option A is the lower-risk fix for this round. Option B is the thorough fix if the
test file is opened for further editing.
