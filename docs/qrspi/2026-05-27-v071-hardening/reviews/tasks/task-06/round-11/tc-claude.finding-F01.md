# tc-claude · Finding F01 · CRITICAL

## Title
`[r3-sec.F01]` test produces the wrong output on CI runners where `gh` lives at `/usr/bin/gh`

## Severity
**Critical** — the test will fail in GREEN state on any machine (including GitHub Actions ubuntu-latest) that has `gh` installed at a trusted-prefix path under `/usr/bin/`.

## Location
`tests/unit/test-host-detection.bats` lines 654–673

## Description
The test intent is:  
> "detect_host emits claude-code when COPILOT_CLI=1 but gh binary **not** reachable in PATH"

The test achieves this by setting `export PATH=/usr/bin:/bin`, expecting that `gh` will not be found there.  
However, on GitHub Actions Ubuntu runners (and many standard Linux systems) `gh` is installed at `/usr/bin/gh`.  
With the production fix in place:

1. `command -v gh` with `PATH=/usr/bin:/bin` → returns `/usr/bin/gh`
2. `realpath /usr/bin/gh` → `/usr/bin/gh` (canonical, no symlinks)
3. `/usr/bin/gh` matches the `/usr/*` trusted prefix → guard passes
4. `detect_host` emits **`copilot-cli`**
5. `[ "$output" = "claude-code" ]` **FAILS**

So a correctly-fixed production script causes this test to fail in the CI environment it is most likely to run in, undermining the test as a regression guard.

## Evidence
```bash
# test line 667 (inlined PATH)
export PATH=/usr/bin:/bin

# On GitHub Actions ubuntu-latest:
which gh        # → /usr/bin/gh
realpath /usr/bin/gh  # → /usr/bin/gh
# matches /usr/* → trusted → "copilot-cli" emitted; test asserts "claude-code" → FAIL
```

## Root Cause
The test implicitly assumes `gh` is **not** present in `/usr/bin`, but GitHub Actions pre-installs it there. The test has no explicit assertion or precondition that verifies gh is absent from the test's PATH before running.

## Fix
Replace the implicit "gh-less" PATH with one that provably cannot resolve to any trusted prefix:

```bash
# Option A — empty a temp dir only, no system bins
local EMPTY_BIN="$TMP_DIR/empty-bin"
mkdir -p "$EMPTY_BIN"
run bash -c "
  export QRSPI_SOURCE_ONLY=1
  export COPILOT_CLI=1
  export PATH='${EMPTY_BIN}'
  . \"$WRAPPER\"
  detect_host
"
[ "$status" -eq 0 ]
[ "$output" = "claude-code" ]
```

Or add a test-skip if gh is present at a trusted prefix in the real system PATH, so the intent is explicit:

```bash
# Before the run:
if command -v gh &>/dev/null; then
  skip "gh is installed in a trusted prefix on this host; not-reachable branch untestable"
fi
```

A concrete empty PATH (Option A) is preferred because it makes the test self-contained.
