---
id: F02
reviewer: code-quality-claude
round: 3
severity: low
area: test-quality / cleanup-discipline
file: tests/unit/test-detect-interaction-mode.bats
line: 354
---

# Tmpdir allocated outside `run` leaks when assertion fails before cleanup

## Location

`tests/unit/test-detect-interaction-mode.bats`:

- **Lines 353–368** (`@test "[T24] Copilot CLI branch creates no .interaction-mode-audit.json"`):

```bash
@test "..." {
  local tmpdir
  tmpdir="$(mktemp -d)"            # line 355 — tmpdir allocated
  run bash -c "
    ...
    cd \"$tmpdir\"
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]              # line 361 — if this fails, set -e fires
  [ ! -f "$tmpdir/.interaction-mode-audit.json" ]
  local n_files
  n_files="$(find "$tmpdir" -maxdepth 1 -type f | wc -l | tr -d ' ')"
  [ "$n_files" -eq 0 ]
  rm -rf "$tmpdir"                 # line 367 — only reached if all assertions pass
}
```

- **Lines 371–384** (`@test "[T24] Unknown host branch creates no files at all"`) — same pattern.

## Problem

BATS test bodies run with `set -e` active. If the assertion at line 361
(`[ "$status" -eq 0 ]`) or any subsequent assertion fails, bash exits the test
function immediately and `rm -rf "$tmpdir"` at line 367 is never executed. The
temp directory leaks for the duration of the process (or until the OS reaps `/tmp`).

In the failure case that these tests exist to catch — the script unexpectedly writing
a file — the cleanup leak is certain: the assertion at line 365 (`[ "$n_files" -eq 0
]`) would fail, aborting before `rm -rf`.

This is the same class of issue the reviewer-protocol skill calls "self-consistent
defense": the cleanup path is only reachable when the test passes, which is precisely
when cleanup is least important.

## Fix

### Option A — Use `$BATS_TEST_TMPDIR` (preferred)

BATS 1.5+ (already required by `bats_require_minimum_version 1.5.0` at line 41)
provides `$BATS_TEST_TMPDIR`: a per-test directory that the framework removes
automatically after each test, regardless of pass/fail.

```bash
@test "Copilot CLI branch creates no .interaction-mode-audit.json" {
  # $BATS_TEST_TMPDIR is auto-cleaned by the BATS framework after every test.
  run bash -c "
    export COPILOT_CLI=1
    unset CLAUDE_PROJECT_DIR QRSPI_INTERACTION_MODE
    cd \"$BATS_TEST_TMPDIR\"
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  [ ! -f "$BATS_TEST_TMPDIR/.interaction-mode-audit.json" ]
  local n_files
  n_files="$(find "$BATS_TEST_TMPDIR" -maxdepth 1 -type f | wc -l | tr -d ' ')"
  [ "$n_files" -eq 0 ]
  # No manual rm -rf needed.
}
```

### Option B — `trap` guard

If keeping `mktemp -d`, add a trap immediately after allocation:

```bash
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
```

Option A is simpler, idiomatic for BATS 1.5+, and eliminates the manual cleanup
entirely.
