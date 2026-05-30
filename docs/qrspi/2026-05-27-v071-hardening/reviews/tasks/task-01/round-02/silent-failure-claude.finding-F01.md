---
reviewer: silent-failure-claude
task: 1
round: 2
finding: F01
severity: low
change_type: correctness
status: pending
model: claude-sonnet-4.6
persistence_note: Claude returned findings inline rather than writing to disk. Orchestrator manually persisted from chat output.
referenced_files:
  - scripts/run-third-party-llm.sh
---

## `_control_char_check`: empty `_cc_count` silently treated as 0, bypassing control-char detection

**Location:** `scripts/run-third-party-llm.sh`, `_control_char_check()` function, line ~224

**Code:**
```bash
_cc_count=$(printf '%s' "$_cc_hname$_cc_hval" \
    | LC_ALL=C tr -d '\040-\176' \
    | wc -c \
    | tr -d ' \t')
[ "$_cc_count" -eq 0 ] || \
    die "header-validation: default_headers for provider '${PROVIDER:-}' contains a control character in header '$_cc_hname'"
```

**Failure mode:** The script does not set `set -e`. If any command in the four-stage pipeline fails to produce output (e.g. `wc` or `tr` absent on an unusual platform), the command substitution assigns `_cc_count=""`. Bash integer comparisons treat empty as `0`: `[ "" -eq 0 ]` → true → the `||` branch is not taken, `die` is not called, control-byte detection silently passes.

**Category:** Silent Fallback — Missing Error Path.

**Why existing tests don't catch this:** All 12 `[control-char-detect]` tests use a real environment where `tr` and `wc` are present.

**Suggested fix:** Add a numeric-validity guard:
```bash
case "$_cc_count" in
  ''|*[!0-9]*)
    die "header-validation: control-char scan pipeline produced unexpected output for header '$_cc_hname'; aborting to fail-closed" ;;
esac
```
Or use arithmetic expansion which fails loud on empty/non-numeric:
```bash
if (( _cc_count > 0 )); then
    die "..."
fi
```
