#!/usr/bin/env bash
# vitest-adapter.sh — RED-verification adapter for the Vitest test framework.
#
# Classifies Vitest runner output into one of three tokens per the T09 contract:
#   pass                — all tests passed
#   assertion-failure   — at least one test failed due to assertions
#   infrastructure-failure — module-resolution/syntax error prevented test loading
#
# Call surface (T09 contract):
#   vitest-adapter.sh \
#     --runner-exit <int> \
#     --stdout-file <path> \
#     --stderr-file <path>
#
# Exit codes:
#   0   classification token emitted on stdout
#   1   unrecognized output or flag validation error; diagnostic on stderr
#
# Bash 3.2 portability: no mapfile, no declare -A, no ${var,,}, no coproc, no wait -n.

set -u

# ---------------------------------------------------------------------------
die() {
  printf 'vitest-adapter: %s\n' "$1" >&2
  exit 1
}

# ---------------------------------------------------------------------------
# Argument parsing
RUNNER_EXIT=""
STDOUT_FILE=""
STDERR_FILE=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --runner-exit)
      [ "$#" -ge 2 ] || die "missing value for --runner-exit"
      RUNNER_EXIT="$2"; shift 2 ;;
    --stdout-file)
      [ "$#" -ge 2 ] || die "missing value for --stdout-file"
      STDOUT_FILE="$2"; shift 2 ;;
    --stderr-file)
      [ "$#" -ge 2 ] || die "missing value for --stderr-file"
      STDERR_FILE="$2"; shift 2 ;;
    *)
      die "unrecognised argument: $1 (accepted flags: --runner-exit --stdout-file --stderr-file)" ;;
  esac
done

[ -n "$RUNNER_EXIT"  ] || die "missing required flag: --runner-exit"
[ -n "$STDOUT_FILE"  ] || die "missing required flag: --stdout-file"
[ -n "$STDERR_FILE"  ] || die "missing required flag: --stderr-file"

case "$RUNNER_EXIT" in
  ''|*[!0-9]*) die "--runner-exit must be a non-negative integer (got: $RUNNER_EXIT)" ;;
esac

[ -f "$STDOUT_FILE" ] || die "stdout-file does not exist or is not a file: $STDOUT_FILE"
[ -f "$STDERR_FILE" ] || die "stderr-file does not exist or is not a file: $STDERR_FILE"

# ---------------------------------------------------------------------------
# Classification logic
#
# Vitest output conventions:
#   - Clean run: exit 0; stdout includes "Test Files ... passed" and "Tests ... passed"
#   - Assertion failures: exit non-zero; stdout includes "FAIL" lines and "× test name"
#     (or "✗ test name" in some versions); summary includes "Tests X failed"
#   - Module-resolution / syntax / import errors (infrastructure failures):
#     Exit non-zero; stdout/stderr includes one of:
#       "Failed to resolve import", "Cannot find module", "SyntaxError",
#       "Error: Cannot find", "ERR_MODULE_NOT_FOUND", "transform failed"
#     These errors typically prevent any test from being evaluated.
#   - "ANSI-escape-only" output (unrecognized fixture): output contains only
#     ANSI escape sequences with no classification markers — must exit 1.
#
# Classification rules (priority order):
#   1. Infrastructure: stdout or stderr contains module/syntax error markers.
#   2. Pass: runner exited 0.
#   3. Assertion failure: "FAIL" line present in stdout, or "× " / "✗ " test markers.
#   4. Unrecognized: exit 1.

STDOUT_CONTENT=""
STDERR_CONTENT=""
STDOUT_CONTENT=$(cat "$STDOUT_FILE")
STDERR_CONTENT=$(cat "$STDERR_FILE")

# Check for infrastructure signals.
has_infra_error=0
COMBINED="${STDOUT_CONTENT}
${STDERR_CONTENT}"
if printf '%s' "$COMBINED" | grep -qiE \
  'Failed to resolve import|Cannot find module|SyntaxError|ERR_MODULE_NOT_FOUND|transform failed|Error: Cannot find|Cannot resolve|Module not found|import error|compilation error'; then
  has_infra_error=1
fi

# Check for assertion-failure markers in stdout.
has_fail_marker=0
if printf '%s' "$STDOUT_CONTENT" | grep -qE '^[[:space:]]*(FAIL|× |✗ )'; then
  has_fail_marker=1
fi
# Also check "Tests X failed" summary line.
if printf '%s' "$STDOUT_CONTENT" | grep -qE 'Tests[[:space:]]+[0-9]+[[:space:]]+failed'; then
  has_fail_marker=1
fi
# Also plain "× " or "✗ " prefix lines anywhere in stdout.
if printf '%s' "$STDOUT_CONTENT" | grep -q '^[[:space:]]*[×✗] '; then
  has_fail_marker=1
fi

# Check for recognizable pass marker.
has_pass_marker=0
if printf '%s' "$STDOUT_CONTENT" | grep -qE 'Tests[[:space:]]+[0-9]+[[:space:]]+passed'; then
  has_pass_marker=1
fi
if printf '%s' "$STDOUT_CONTENT" | grep -q 'All files pass'; then
  has_pass_marker=1
fi

# Strip ANSI escapes to check if output has any non-ANSI content.
STRIPPED=""
STRIPPED=$(printf '%s' "$STDOUT_CONTENT" | sed 's/\x1B\[[0-9;]*[mK]//g' | tr -d '\r')

# Check if stripped output is empty (ANSI-only fixture case).
STRIPPED_TRIMMED=""
STRIPPED_TRIMMED=$(printf '%s' "$STRIPPED" | tr -d ' \n\t')

# Apply classification.
if [ "$has_infra_error" -eq 1 ]; then
  printf 'infrastructure-failure\n'
  exit 0
fi

if [ "$RUNNER_EXIT" -eq 0 ]; then
  printf 'pass\n'
  exit 0
fi

if [ "$has_fail_marker" -eq 1 ]; then
  printf 'assertion-failure\n'
  exit 0
fi

# Non-zero exit, ANSI-only output (no classification markers).
if [ -z "$STRIPPED_TRIMMED" ]; then
  die "unrecognized Vitest output: runner exited $RUNNER_EXIT with ANSI-escape-only stdout and no classification markers (stdout: $STDOUT_FILE, stderr: $STDERR_FILE)"
fi

# Non-zero exit, non-ANSI content but no recognized markers.
die "unrecognized Vitest output: runner exited $RUNNER_EXIT with no recognized FAIL/pass markers (stdout: $STDOUT_FILE, stderr: $STDERR_FILE)"
