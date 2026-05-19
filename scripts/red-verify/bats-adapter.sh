#!/usr/bin/env bash
# bats-adapter.sh — RED-verification adapter for the BATS test framework.
#
# Classifies BATS runner output into one of three tokens per the T09 contract:
#   pass                — all tests passed
#   assertion-failure   — at least one test failed due to assertions
#   infrastructure-failure — runner could not execute tests (parse/setup error)
#
# Call surface (T09 contract):
#   bats-adapter.sh \
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
# die <message> — write diagnostic to stderr and exit 1 (no classification token)
die() {
  printf 'bats-adapter: %s\n' "$1" >&2
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

# Validate required flags.
[ -n "$RUNNER_EXIT"  ] || die "missing required flag: --runner-exit"
[ -n "$STDOUT_FILE"  ] || die "missing required flag: --stdout-file"
[ -n "$STDERR_FILE"  ] || die "missing required flag: --stderr-file"

# Validate --runner-exit is numeric.
case "$RUNNER_EXIT" in
  ''|*[!0-9]*) die "--runner-exit must be a non-negative integer (got: $RUNNER_EXIT)" ;;
esac

# Validate files exist.
[ -f "$STDOUT_FILE" ] || die "stdout-file does not exist or is not a file: $STDOUT_FILE"
[ -f "$STDERR_FILE" ] || die "stderr-file does not exist or is not a file: $STDERR_FILE"

# ---------------------------------------------------------------------------
# Classification logic
#
# BATS output conventions:
#   - Each passing test emits:  "ok N test name"
#   - Each failing test emits:  "not ok N test name"
#   - Parse/syntax errors before tests run appear in stderr, typically:
#     "parse error" / "syntax error" / "line N:" diagnostics
#     BATS may also emit on stdout: "1..0" (plan with zero tests)
#   - A clean run with all passing tests exits 0
#   - A run with assertion failures exits non-zero
#   - A parse/syntax/setup error exits non-zero and typically has no
#     "not ok" lines (no tests ran at all)
#
# Classification rules (in priority order):
#   1. Infrastructure: stderr contains "parse error" or "syntax error", OR
#      stdout has no "ok" or "not ok" lines AND runner exited non-zero.
#   2. Pass: runner exited 0.
#   3. Assertion failure: "not ok" lines present in stdout.
#   4. Unrecognized: none of the above — exit 1 with diagnostic.

STDOUT_CONTENT=""
STDERR_CONTENT=""
STDOUT_CONTENT=$(cat "$STDOUT_FILE")
STDERR_CONTENT=$(cat "$STDERR_FILE")

# Check for infrastructure signals in stderr.
has_parse_error=0
if printf '%s' "$STDERR_CONTENT" | grep -qiE 'parse error|syntax error'; then
  has_parse_error=1
fi

# Check for "not ok" lines in stdout (assertion failures).
has_not_ok=0
if printf '%s' "$STDOUT_CONTENT" | grep -q '^not ok'; then
  has_not_ok=1
fi

# Check for any "ok" or "not ok" lines (indicates tests ran).
has_ok_lines=0
if printf '%s' "$STDOUT_CONTENT" | grep -qE '^(ok|not ok)'; then
  has_ok_lines=1
fi

# Apply classification.
if [ "$has_parse_error" -eq 1 ]; then
  printf 'infrastructure-failure\n'
  exit 0
fi

if [ "$RUNNER_EXIT" -eq 0 ]; then
  printf 'pass\n'
  exit 0
fi

# Runner exited non-zero.
if [ "$has_not_ok" -eq 1 ]; then
  printf 'assertion-failure\n'
  exit 0
fi

if [ "$has_ok_lines" -eq 0 ]; then
  # Non-zero exit, no ok/not-ok lines, no parse-error marker — infrastructure failure.
  printf 'infrastructure-failure\n'
  exit 0
fi

# Unrecognized output: non-zero exit, has ok lines but no "not ok" lines.
# This should not normally occur with BATS but per contract we must not
# silently default.
die "unrecognized BATS output: runner exited $RUNNER_EXIT with ok lines present but no 'not ok' lines — cannot classify (stdout: $STDOUT_FILE, stderr: $STDERR_FILE)"
