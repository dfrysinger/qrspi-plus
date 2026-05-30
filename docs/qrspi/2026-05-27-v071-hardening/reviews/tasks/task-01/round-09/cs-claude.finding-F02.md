---
finding: F02
reviewer: cs-claude
round: 9
task: task-01
severity: advisory
change_type: clarity
file: tests/unit/test-run-third-party-llm.bats
lines: "544-558, 631-644"
---

## NUL raw-fixture construction inlined and duplicated in both parametric tests

### Observation

The NUL (0x00) case arm in both parametric tests writes the fixture file via an
identical 10-line block of `printf` calls that differs only in the final header line
(VALUE test: `X-Param-Test: safe\000value`; NAME test: `X-Nul\000Name: safe-value`).
The same boilerplate also appears in the existing Bullet 6 test (lines ~740–751),
making three copies of the same YAML skeleton.

**VALUE test (lines 544–558):**
```bash
{
  printf '%s\n' '---'
  printf '%s\n' 'providers:'
  printf '%s\n' '  ctrl-test-prov:'
  printf '%s\n' '    base_url: https://127.0.0.1/v1'
  printf '%s\n' '    api_key_env: CTRL_TEST_KEY'
  printf '%s\n' '    transport_type: openai-chat-completions'
  printf '%s\n' '    supports_prompt_cache: false'
  printf '%s\n' '    emit_cache_control_markers: false'
  printf '%s\n' '    default_headers:'
  printf '      X-Param-Test: safe'
  printf '\000'
  printf 'value\n'
  printf '%s\n' '---' '' '# Config'
} > "$FIXTURE_DIR/config.md"
```

**NAME test (lines 631–644):** structurally identical, last payload line differs.

The codebase already has `_write_ctrl_config` to encapsulate the normal-path fixture.
The NUL path lacks an equivalent, so the YAML skeleton is copied each time.

### Suggested simplification

A small helper for NUL fixtures, parameterised on just the single line that differs:

```bash
# Write a raw config.md with a NUL byte embedded in the header field line.
# $1 = destination directory
# $2 = literal header line (e.g. '      X-Param-Test: safe' then NUL then 'value')
#      passed as two args: prefix and suffix, NUL is always the separator.
_write_nul_fixture() {
  local _dir="$1" _prefix="$2" _suffix="$3"
  {
    printf '%s\n' '---' 'providers:' '  ctrl-test-prov:'
    printf '%s\n' '    base_url: https://127.0.0.1/v1'
    printf '%s\n' '    api_key_env: CTRL_TEST_KEY'
    printf '%s\n' '    transport_type: openai-chat-completions'
    printf '%s\n' '    supports_prompt_cache: false'
    printf '%s\n' '    emit_cache_control_markers: false'
    printf '%s\n' '    default_headers:'
    printf '%s' "$_prefix"
    printf '\000'
    printf '%s\n' "$_suffix"
    printf '%s\n' '---' '' '# Config'
  } > "$_dir/config.md"
}
```

Call sites collapse to:

```bash
# VALUE test NUL arm:
_write_nul_fixture "$FIXTURE_DIR" '      X-Param-Test: safe' 'value'
# NAME test NUL arm:
_write_nul_fixture "$FIXTURE_DIR" '      X-Nul' 'Name: safe-value'
```

This also aligns the NUL path with the existing `_write_ctrl_config` convention, making
the fixture-setup layer consistent across all byte-path choices.

### Impact

Advisory / style only. No assertion semantics change. The `printf '\000'` emission is
preserved; only the surrounding boilerplate is consolidated.
