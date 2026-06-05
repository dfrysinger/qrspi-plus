# Security Review — Task 24 · Round 2
**Reviewer:** security-claude  
**Artifact:** `scripts/detect-interaction-mode.sh` + `tests/unit/test-detect-interaction-mode.bats`  
**Verdict:** ✅ Clean — no security findings

## Analysis summary

### Printf format-string
All `printf` calls use a literal format string as the first argument (`%s` for variable
substitution). No user-controlled value is ever placed in the format-string position.
Safe on every path.

### Output injection via `QRSPI_INTERACTION_MODE`
The `case "${QRSPI_INTERACTION_MODE}" in auto|interactive)` allowlist is evaluated
**before** any stdout is emitted in the override branch. The case pattern matches the
full value string; a crafted value like `$'auto\nEVIL=injected'` does not match `auto`
and falls to `*` → exit 1. The allowlist correctly gates every echo path, including the
`VERDICT=` and `EVIDENCE=` lines.

### `COPILOT_CLI` and `CLAUDE_PROJECT_DIR` injection
Both vars are used only in `[[ ... ]]` equality/presence checks. Neither value is ever
written to stdout. No injection surface.

### PLATFORM token in override branch
`_override_platform` is set from one of three hardcoded string literals
(`copilot-cli`, `claude-code`, `unknown`). It is not user-controlled.

### Unquoted variable expansions
All variable expansions with external provenance are double-quoted in `[[ ]]`
comparisons or passed as `%s`-guarded `printf` arguments. No word-splitting or
glob-expansion attack surface.

### Command injection
No `eval`, no `$(...)` or backtick subshells that consume user-controlled data.

### File I/O / TOCTOU
The script is stdout/stderr-only; it performs no file operations and has no
TOCTOU window.

### EVIDENCE line embedded `=` (informational, not a finding)
`EVIDENCE=QRSPI_INTERACTION_MODE=auto override` places `=` inside the value
portion. This is a design/interop concern for consumers using `cut -d= -f2`; the
value is fully static and contains no attacker-controlled data, so it is not an
exploitable vulnerability.
