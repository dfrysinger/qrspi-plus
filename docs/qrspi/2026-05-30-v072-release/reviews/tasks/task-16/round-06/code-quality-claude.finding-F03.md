---
reviewer: code-quality-claude
finding_id: F03
severity: minor
change_type: test-quality
file: tests/unit/test-config-model-routing.bats
lines: 421-428
---

## F02 de-mask test bypasses its own `_exec_resolve_tier` helper via fragile `bash -c` string interpolation

The behavioral suite establishes two clean helpers — `_exec_resolve_model` and
`_exec_resolve_tier` — that handle the unset-CONFIG_MD case (`if [ -n "$cfg" ];
then export ...; else unset CONFIG_MD; fi`). Every sibling [exec] test routes
through them with `run --separate-stderr`. This one test reaches around the helper:

```sh
@test "..._resolve_tier layer 4 warning names CONFIG_MD unset/missing as the cause (F02 de-mask)" {
  local agent="$BATS_TEST_TMPDIR/agent.md"
  printf '# agent with no tier field\n' > "$agent"
  run bash -c 'QRSPI_SOURCE_ONLY=1 source "$RESOLVE_LIB"; unset CONFIG_MD; resolve_tier "'"$agent"'" "" 2>&1 1>/dev/null'
  [[ "$output" == *CONFIG_MD* ]]
}
```

Two quality costs:

1. **Fragility** — `"'"$agent"'"` splices `$agent` into a single-quoted string by
   hand. It happens to work because `BATS_TEST_TMPDIR` has no spaces/quotes, but
   it is the exact pattern that breaks silently the day a path does. The helper
   path passes `$agent` as a positional arg and is immune.
2. **Inconsistency** — readers must context-switch from the established
   helper+`--separate-stderr` idiom used by all 13 other [exec] tests.

The same assertion is expressible through the existing helper:

```sh
run --separate-stderr _exec_resolve_tier "" "$agent" ""
[ "$status" -eq 0 ]
[[ "$stderr" == *CONFIG_MD* ]]
```

`_exec_resolve_tier "" ...` already `unset`s CONFIG_MD, so the manual `bash -c`
and the `2>&1 1>/dev/null` redirect plumbing are unnecessary. Non-blocking — the
test is correct as written; this is a consistency/robustness cleanup.
