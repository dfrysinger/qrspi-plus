---
finding_id: F01
reviewer: silent-failure-claude
severity: high
change_type: correctness
referenced_files:
  - scripts/dispatch-agent.sh:78
  - scripts/dispatch-companion.sh:65
---

**path-guard.sh sourced without load-failure check — guard silently becomes a no-op on source error.**

Both scripts added in R4:

```bash
# dispatch-agent.sh:78
. "$SCRIPT_DIR/lib/path-guard.sh"

# dispatch-companion.sh:65
. "$_SCRIPT_DIR/lib/path-guard.sh"
```

Neither script enables `set -e` (`dispatch-agent.sh` comments it explicitly disabled; `dispatch-companion.sh` has only `set -u` + `set -o pipefail`). If the `.` source command fails for any reason — file missing, unreadable permissions, or syntax error in the library — bash prints a diagnostic to stderr and continues execution. `assert_path_under_repo_root` is then undefined. Every subsequent call to the guard (eleven call sites in dispatch-agent.sh, one in dispatch-companion.sh) produces "command not found" exit 127, which is also not checked under `set +e`. The entire G16 boundary enforcement silently becomes a no-op: all user-supplied paths pass unchecked and their bytes can enter the sanctioned LLM channel.

This is a silent failure of a security control: the caller receives a zero exit from successful dry-run or dispatch operations with no indication that the boundary guard never ran.

**Fix (either approach):**

Option A — check the source return code inline:
```bash
. "$SCRIPT_DIR/lib/path-guard.sh" \
  || { printf 'error: failed to load path-guard.sh; aborting (fail-closed).\n' >&2; exit 1; }
```

Option B — assert the function is defined after the source:
```bash
. "$SCRIPT_DIR/lib/path-guard.sh"
command -v assert_path_under_repo_root >/dev/null 2>&1 \
  || { printf 'error: assert_path_under_repo_root not defined after sourcing path-guard.sh; aborting.\n' >&2; exit 1; }
```

Option B is preferable because it catches both a missing file and a silent syntax error that leaves the function undefined without exiting.

Apply the same fix in `dispatch-companion.sh:65`.
