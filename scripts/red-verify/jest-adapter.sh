#!/usr/bin/env bash
# jest-adapter.sh — RED-verification adapter for the Jest test framework.
#
# Classifies Jest runner output into one of three tokens per the T09 contract:
#   pass                — all tests passed
#   assertion-failure   — at least one test failed due to assertions
#   infrastructure-failure — module-resolution/syntax error prevented test loading
#
# Call surface (T09 contract):
#   jest-adapter.sh \
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
  printf 'jest-adapter: %s\n' "$1" >&2
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
# Jest output conventions (jest --ci or jest with --json-style output):
#   - Clean run: exit 0; stdout includes "PASS <file>" lines and
#     "Tests: X passed, X total" in summary.
#   - Assertion failures: exit non-zero; stdout includes "FAIL <file>" lines;
#     summary includes "Tests: X failed, X total".
#   - Module-resolution / syntax / import errors (infrastructure):
#     Exit non-zero; stdout/stderr includes:
#       "Cannot find module", "SyntaxError", "ERR_MODULE_NOT_FOUND",
#       "ENOENT", "Cannot resolve module", "Jest encountered an unexpected token",
#       "Your test suite must contain at least one test" (when no tests collected
#       due to parse failure).
#     No "FAIL" or "PASS" summary lines appear when tests cannot load.
#   - Unrecognized fixture: non-zero exit with no FAIL/PASS lines in stdout.
#
# Classification rules (priority order):
#   1. Infrastructure: stdout/stderr contains module/syntax error markers.
#   2. Pass: runner exited 0.
#   3. Assertion failure: "FAIL " line present in stdout.
#   4. Unrecognized: non-zero exit with no FAIL/PASS lines → exit 1.

STDOUT_CONTENT=""
STDERR_CONTENT=""
STDOUT_CONTENT=$(cat "$STDOUT_FILE")
STDERR_CONTENT=$(cat "$STDERR_FILE")

COMBINED="${STDOUT_CONTENT}
${STDERR_CONTENT}"

# Infrastructure signals.
has_infra_error=0
if printf '%s' "$COMBINED" | grep -qiE \
  'Cannot find module|SyntaxError|ERR_MODULE_NOT_FOUND|ENOENT.*module|Cannot resolve module|Jest encountered an unexpected token|Your test suite must contain at least one test|Unexpected token|Cannot use import statement'; then
  has_infra_error=1
fi

# Check for FAIL lines in stdout (assertion failures).
has_fail_line=0
if printf '%s' "$STDOUT_CONTENT" | grep -qE '^[[:space:]]*FAIL[[:space:]]'; then
  has_fail_line=1
fi
# Also check "Tests: X failed" summary.
if printf '%s' "$STDOUT_CONTENT" | grep -qE 'Tests:[[:space:]]+[0-9]+ failed'; then
  has_fail_line=1
fi

# Check for PASS lines (needed to detect pass vs. unrecognized).
has_pass_line=0
if printf '%s' "$STDOUT_CONTENT" | grep -qE '^[[:space:]]*PASS[[:space:]]'; then
  has_pass_line=1
fi
if printf '%s' "$STDOUT_CONTENT" | grep -qE 'Tests:[[:space:]]+[0-9]+ passed'; then
  has_pass_line=1
fi

# Apply classification.
if [ "$has_infra_error" -eq 1 ]; then
  printf 'infrastructure-failure\n'
  exit 0
fi

if [ "$RUNNER_EXIT" -eq 0 ]; then
  printf 'pass\n'
  exit 0
fi

if [ "$has_fail_line" -eq 1 ]; then
  printf 'assertion-failure\n'
  exit 0
fi

# Non-zero exit, no FAIL/PASS lines in stdout — unrecognized per T10 contract.
die "unrecognized Jest output: runner exited $RUNNER_EXIT with no FAIL/PASS lines in stdout (stdout: $STDOUT_FILE, stderr: $STDERR_FILE)"
