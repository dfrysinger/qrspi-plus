#!/usr/bin/env bash
# pytest-adapter.sh — RED-verification adapter for the pytest test framework.
#
# Classifies pytest runner output into one of three tokens per the T09 contract:
#   pass                — all tests passed
#   assertion-failure   — at least one test failed due to assertions
#   infrastructure-failure — collection/import error prevented test loading
#
# Call surface (T09 contract):
#   pytest-adapter.sh \
#     --runner-exit <int> \
#     --stdout-file <path> \
#     --stderr-file <path>
#
# Exit codes:
#   0   classification token emitted on stdout
#   1   unrecognized output or flag validation error; diagnostic on stderr
#
# Bash 3.2 portability: no mapfile, no declare -A, no ${var,,}, no coproc, no wait -n.
#
# pytest exit code reference (documented):
#   0  All tests passed
#   1  Some tests failed
#   2  Test execution interrupted
#   3  Internal error
#   4  Command-line usage error
#   5  No tests collected

set -u

# ---------------------------------------------------------------------------
die() {
  printf 'pytest-adapter: %s\n' "$1" >&2
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
# pytest output conventions:
#   - Clean run: exit 0; stdout includes "passed" in the final summary line,
#     e.g. "1 passed in 0.12s" or "3 passed, 1 warning in 0.45s".
#   - Assertion failures: exit 1; stdout includes "FAILED" markers and
#     "X failed" in the summary (e.g. "1 failed, 2 passed in 0.23s").
#     Also includes "AssertionError" in the failure output.
#   - Collection / import errors (infrastructure failures):
#     Exit non-zero (typically 2 for collection error or 4 for usage error);
#     stdout/stderr includes "ERROR collecting", "ImportError", "ModuleNotFoundError",
#     "SyntaxError", "ERRORS" section header, "collection errors".
#     The summary line shows "error" rather than "failed".
#   - INTERNALERROR: exit non-zero; stdout begins with "INTERNALERROR"
#     (pytest internal crash, not a test failure). This is the unrecognized
#     fixture from the T10 spec — exit 1 with diagnostic.
#   - No-tests-collected: exit 5; stdout includes "no tests ran" or
#     "collected 0 items" — treat as infrastructure-failure (nothing could run).
#
# Classification rules (priority order):
#   1. Unrecognized (INTERNALERROR): stdout begins with INTERNALERROR → exit 1.
#   2. Infrastructure: stdout/stderr contains collection/import error markers,
#      OR runner exit is 2 (execution interrupted), 3 (internal error),
#      4 (usage error), or 5 (no tests collected) — note: 3/4 overlap with
#      INTERNALERROR but are distinct pytest exit codes.
#   3. Pass: runner exited 0.
#   4. Assertion failure: stdout contains "FAILED" or "failed" in summary.
#   5. Unrecognized: exit 1 with diagnostic.

STDOUT_CONTENT=""
STDERR_CONTENT=""
STDOUT_CONTENT=$(cat "$STDOUT_FILE")
STDERR_CONTENT=$(cat "$STDERR_FILE")

COMBINED="${STDOUT_CONTENT}
${STDERR_CONTENT}"

# Check for INTERNALERROR (unrecognized fixture per T10 spec).
has_internal_error=0
if printf '%s' "$STDOUT_CONTENT" | grep -q '^INTERNALERROR'; then
  has_internal_error=1
fi

# Check for collection/import error markers (infrastructure).
has_infra_error=0
if printf '%s' "$COMBINED" | grep -qiE \
  'ERROR collecting|ImportError|ModuleNotFoundError|SyntaxError|collection error|no tests ran|collected 0 items|import file mismatch'; then
  has_infra_error=1
fi
# Pytest exit code 2 = interrupted; 3 = internal error; 4 = usage error;
# 5 = no tests collected. All are infrastructure signals.
if [ "$RUNNER_EXIT" = "2" ] || [ "$RUNNER_EXIT" = "3" ] || \
   [ "$RUNNER_EXIT" = "4" ] || [ "$RUNNER_EXIT" = "5" ]; then
  has_infra_error=1
fi

# Check for assertion-failure markers.
has_fail_marker=0
if printf '%s' "$STDOUT_CONTENT" | grep -qE '^FAILED '; then
  has_fail_marker=1
fi
if printf '%s' "$STDOUT_CONTENT" | grep -qE '[0-9]+ failed'; then
  has_fail_marker=1
fi
if printf '%s' "$STDOUT_CONTENT" | grep -q 'AssertionError'; then
  has_fail_marker=1
fi

# Apply classification.
# INTERNALERROR must be checked before infrastructure-failure classification
# because both are non-zero exits, but INTERNALERROR is explicitly unrecognized.
if [ "$has_internal_error" -eq 1 ]; then
  die "unrecognized pytest output: INTERNALERROR detected (runner exit $RUNNER_EXIT) — this is outside the normal classification surface (stdout: $STDOUT_FILE, stderr: $STDERR_FILE)"
fi

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

# Non-zero exit (1) with no recognized markers.
die "unrecognized pytest output: runner exited $RUNNER_EXIT with no recognized FAILED/collection-error markers (stdout: $STDOUT_FILE, stderr: $STDERR_FILE)"
