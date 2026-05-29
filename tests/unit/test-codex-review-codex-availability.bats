#!/usr/bin/env bats
#
# tests/unit/test-codex-review-codex-availability.bats
# Task 6 — R5 security fix: sec.F02 — absolute-path enforcement for HOME in
# check_codex_available.
# Target: scripts/run-codex-review.sh
#
# RED test for sec.F02: check_codex_available(claude-code) must reject a
# relative HOME value with exit 1 and a stderr message containing "absolute".
# The current case guard only rejects HOME values containing '..', empty string,
# or newlines; it does NOT check for a leading '/'.  A value like HOME=relative-dir
# passes all current guards and causes the companion glob to expand relative to
# CWD.
#
# RED state (before fix):
#   HOME=relative-dir passes the case guard → check_codex_available returns 0
#   (or non-zero for a different reason without "absolute" in stderr) → the
#   assertion `[ "$status" -eq 1 ]` or the `grep -q "absolute"` assertion fails.
#
# GREEN state (after fix):
#   An explicit `if [[ "${HOME}" != /* ]]; then ... return 1; fi` check after
#   the case guard rejects relative HOME with exit 1 and a diagnostic containing
#   "absolute" on stderr.
#
# bash 3.2 portable: no mapfile, no declare -A, no ${var,,}, no coproc.

bats_require_minimum_version 1.5.0

# ---------------------------------------------------------------------------
# Suite setup
# ---------------------------------------------------------------------------

setup_file() {
  REAL_REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd -P)"
  export REAL_REPO_ROOT
  WRAPPER="$REAL_REPO_ROOT/scripts/run-codex-review.sh"
  export WRAPPER
}

setup() {
  TMP_DIR="$(mktemp -d)"
  export TMP_DIR
}

teardown() {
  cd /
  rm -rf "$TMP_DIR"
}

# ===========================================================================
# sec.F02 — absolute-path enforcement for HOME
# ===========================================================================

@test "[r5-sec.F02] check_codex_available rejects relative HOME with exit 1 and stderr containing 'absolute'" {
  # RED: current code case guard checks for '..' / empty / newlines but not for
  # a leading '/'.  HOME=relative-dir passes all guards → function either returns
  # 0 (no companion glob matches from CWD) or returns non-zero without emitting
  # "absolute" in stderr.
  # GREEN: fixed code adds `if [[ "${HOME}" != /* ]]; then ... return 1; fi`
  # which rejects relative HOME with a diagnostic containing "absolute".
  local _stderr_file="$TMP_DIR/f02-stderr.txt"
  local _status=0

  bash -c "
    export QRSPI_SOURCE_ONLY=1
    export HOME='relative-dir'
    . \"$WRAPPER\"
    check_codex_available claude-code
  " >/dev/null 2>"$_stderr_file" || _status=$?

  # Must exit non-zero (return 1 from check_codex_available).
  [ "$_status" -ne 0 ]

  # Stderr must contain the word "absolute" to identify the rejection reason.
  grep -qi "absolute" "$_stderr_file"
}

# ===========================================================================
# tc.F03 (R12) — HOME-with-embedded-newline rejection
#
# The `case "${HOME:-}" in *..* | "" | *$'\n'*)` arm in check_codex_available
# rejects HOME values that contain an embedded newline, but this arm had zero
# test coverage.  Adding a direct runtime assertion ensures the guard is
# exercised and does not regress.
# ===========================================================================

@test "[r12-tc.F03] check_codex_available rejects HOME with embedded newline — returns non-zero with 'unsafe' message" {
  # Scenario: HOME contains a literal newline character in the middle of the path
  # (e.g. /tmp/test\nhome).  This is a path-safety violation that the case guard
  # must catch and reject before any filesystem probe can run.
  #
  # GREEN state: the existing `case "${HOME:-}" in *..* | "" | *$'\n'*)` arm
  # fires, returns non-zero, and emits the "unsafe HOME value" diagnostic to stderr.
  local _stderr_file="$TMP_DIR/f03-stderr.txt"
  local _status=0

  bash -c "
    export QRSPI_SOURCE_ONLY=1
    export HOME=$'/tmp/test\nhome'
    . \"$WRAPPER\"
    check_codex_available claude-code
  " >/dev/null 2>"$_stderr_file" || _status=$?

  # Must exit non-zero.
  [ "$_status" -ne 0 ]

  # Stderr must contain the word "unsafe" (from the rejection diagnostic).
  grep -qi "unsafe" "$_stderr_file"
}
