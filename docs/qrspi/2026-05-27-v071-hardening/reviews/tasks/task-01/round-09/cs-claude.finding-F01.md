---
finding: F01
reviewer: cs-claude
round: 9
task: task-01
severity: advisory
change_type: style
file: tests/unit/test-run-third-party-llm.bats
lines: "554-563, 584-587, 593-596, 647-650, 673-676, 682-685"
---

## Per-branch assertion pattern duplicated across all 6 case arms

### Observation

Both parametric `@test` blocks each contain three `case` arms (NUL / LF|CR / `*`),
and every arm ends with the same structural assertion pair:

```bash
[ "$status" -eq 1 ] \
  || { printf 'FAIL: <context> (0x%s) ... did not cause exit 1\n' "$_byte_hex" >&2; return 1; }
[[ "$output" == *"header-validation"* ]] \
  || { printf 'FAIL: 0x%s ... — missing header-validation in output\n' "$_byte_hex" >&2; return 1; }
```

That 4-line pattern appears **six times** in the diff (three arms × two tests), varying
only in the context word ("NUL", "LF", "byte") and the field label ("VALUE" / "NAME").
The assertion logic itself is identical.

### Suggested simplification

Extract a small helper above the parametric tests:

```bash
# Assert that the most-recent `run` call produced exit 1 with header-validation output.
# Usage: _assert_ctrl_byte_rejected "$_byte_hex" "<FIELD>"
_assert_ctrl_byte_rejected() {
  local _hex="$1" _field="$2"
  [ "$status" -eq 1 ] \
    || { printf 'FAIL: 0x%s in %s did not cause exit 1\n' "$_hex" "$_field" >&2; return 1; }
  [[ "$output" == *"header-validation"* ]] \
    || { printf 'FAIL: 0x%s in %s — missing header-validation in output\n' "$_hex" "$_field" >&2; return 1; }
}
```

Then each arm collapses to a single call:

```bash
_run_ctrl_check "$FIXTURE_DIR"
_assert_ctrl_byte_rejected "$_byte_hex" "VALUE"   # or "NAME"
```

This makes the unique part of each branch (the fixture-write / run command) stand out
visually, and a future change to the assertion message needs to happen in exactly one
place instead of six.

### Impact

Purely cosmetic — the test semantics are unchanged. The helper relies only on `$status`
and `$output`, which are BATS globals set by `run` and visible inside loop iterations.
