---
reviewer: sec-claude
task: task-09
round: 4
verdict: clean
scope: R3 fixes — jq exit-code guard (run-codex-review.sh) + AC12 test + AC11 grep tightening
---

# Security Review — Task 09, Round 4 — Clean

No security vulnerabilities found in the R3 changes.

## Summary

R3 introduced two changes:

1. **`run-codex-review.sh` lines 619–626** — explicit `|| { echo "error: jq failed ... (jq exit $?)" >&2; exit 1; }` guard on the `jq` command substitution inside `emit_dispatch_manifest_entry`.

2. **`test-phase1-acceptance.bats`** — new AC12 test verifying jq-failure abort; AC11 grep tightened from `'model'` to `'\-\-model'`.

## Analysis

### Guard correctness (`run-codex-review.sh`)

- **`$?` captures the correct value.** In bash a variable assignment propagates the exit code of its command substitution, so `$?` inside `|| { ... }` is exactly jq's exit code. No reset between the assignment and the `||` branch.
- **`exit 1` inside the function is script-terminating.** `emit_dispatch_manifest_entry` is called from the main script body (line 643), not from a subshell. `exit` always terminates the process; the `mkdir -p` and `local tmp=...` lines (628–629) are never reached, meaning no `.tmp.$$` file is created and no prior manifest is overwritten.
- **No user-controlled data in the error message.** Only the literal string and the integer `$?` appear; no expansion of `$REVIEWER_TAG`, `$MODEL`, or `$detected_host` occurs on the error path.
- **R2 defences fully preserved.** The `--reviewer-tag` and `--model` allowlist validators still gate input before it reaches `jq`. `jq --arg` still performs unconditional JSON string escaping. The guard is additive.
- **Hardcoded `exit 1` vs. propagating `$?`.** The script exits with code 1 regardless of jq's actual exit code (127 for missing binary, 2 for bad expression, etc.) while the message correctly prints the actual code. Minor diagnostic inconsistency; not a security issue.

### AC12 test (`test-phase1-acceptance.bats`)

- **`PATH` injection is test-local and controlled.** `TMP_DIR` is from `mktemp -d` (0700 permissions, unpredictable name). Only a controlled stub `jq` is planted; no other binaries. The PATH modification is scoped to the single `bash ...` invocation via env-var prefix.
- **No stub `gh` placed in `$TMP_DIR/bin`.** `detect_host` resolves `gh` from the real PATH, defaulting to `claude-code` as expected.
- **Success-only cleanup** (`rm -rf "$TMP_DIR"` not reached on failure). Pre-existing pattern in other AC tests; leftover dirs are 0700 and not world-readable. Not a security issue.
- **Three assertions correctly verify the security property:** non-zero exit, stderr names `jq`, no manifest written.

### AC11 grep tightening

`grep -qiE 'model'` → `grep -qiE '\-\-model'`. More specific; reduces false-positive matches. No new attack surface. The `\-` escaping inside the regex (hyphen outside a character class) is redundant but harmless.

## Conclusion

No new attack surface introduced. R2's defence-in-depth (input allowlists + `jq --arg` JSON construction) is fully preserved. The guard correctly closes the silent-manifest-corruption window identified in R3.
