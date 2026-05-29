# tc-claude · Finding F03 · MEDIUM

## Title
`check_codex_available` newline-in-HOME rejection branch has no test

## Severity
**Medium** — a production code path exists to reject `HOME` values containing embedded newlines, but the branch has zero test coverage. A future refactor that drops or weakens the newline arm goes undetected.

## Location
### Production code
`scripts/run-codex-review.sh` lines 157–162:
```bash
case "${HOME:-}" in
  *..* | "" | *$'\n'*)
    echo "check_codex_available: unsafe HOME value …" >&2
    return 1
    ;;
esac
```

### Test suites — no test present for the newline arm
- `tests/unit/test-host-detection.bats` — tests `HOME` with `..` (line 684) and relative path (via codex-availability suite), not newline
- `tests/unit/test-codex-review-codex-availability.bats` — tests relative `HOME`, not newline

## Description
The `*$'\n'*` arm in the case statement is intended to block glob expansion from a multi-line HOME value that could probe unexpected filesystem paths. The test suite covers:
- `HOME` with `..` component → `[r3-sec.F02]` ✓
- Relative `HOME` (no leading `/`) → `[r5-sec.F02]` ✓
- Empty `HOME` (empty string matches the `""` arm)

But **no test supplies `HOME` with an embedded newline**. Without it a mutation that deletes just the `*$'\n'*` pattern from the case arm — or that accidentally reorders case arms so the newline arm is shadowed — would pass the full suite.

## Reproduction / expected test
```bash
@test "[sec.F02] check_codex_available rejects HOME containing embedded newline" {
  local _stderr_file
  _stderr_file="$(mktemp)"
  local _status=0

  bash -c $'
    export QRSPI_SOURCE_ONLY=1
    export HOME=$\'/some-path\\ninjection\'
    . "$1"
    check_codex_available claude-code
  ' -- "$WRAPPER" >/dev/null 2>"$_stderr_file" || _status=$?

  [ "$_status" -ne 0 ]
  grep -qi "unsafe" "$_stderr_file"
  rm -f "$_stderr_file"
}
```

The test should be added to `tests/unit/test-host-detection.bats` alongside the existing `[r3-sec.F02]` and `[r5-sec.F02]` tests.
