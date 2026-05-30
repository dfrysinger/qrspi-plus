#!/usr/bin/env bats
#
# tests/unit/test-codex-review-source-guard.bats
# Task 6 — R5 security fix: sec.F01 positive path — detect_host trusts gh
# when it resolves to a system-controlled prefix (/usr/*, /opt/*, /Applications/*).
# Target: scripts/run-codex-review.sh
#
# This is a positive regression guard for the sec.F01 fix.  It verifies that
# the path-prefix check does NOT over-restrict: a real gh binary in a trusted
# prefix (/opt/homebrew/bin on macOS Homebrew) must still allow detect_host to
# emit "copilot-cli" when COPILOT_CLI=1.
#
# NOTE on RED state: this test is a positive regression guard, not a strict
# RED test.  The pre-fix code also emits "copilot-cli" for a trusted-path gh
# (since it trusts any gh in PATH).  The test's value is ensuring the fix does
# not over-restrict legitimate installations.  It is included per the R5 TDD
# requirements to document expected positive behavior.
#
# The test skips with a diagnostic reason if no gh binary is found under a
# recognised trusted prefix (/usr/*, /opt/*, /Applications/*) on the host.
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
# sec.F01 positive path — trusted-prefix gh is accepted
# ===========================================================================

@test "[r5-sec.F01] detect_host trusts marker when gh is in a system-controlled prefix (/usr|/opt|/Applications)" {
  # Locate a gh binary under a trusted prefix on the host.  On macOS with
  # Homebrew, gh lives at /opt/homebrew/bin/gh (/opt/* matches).  On Linux
  # systems it is often at /usr/bin/gh or /usr/local/bin/gh (/usr/* matches).
  # Skip if no such binary is found rather than failing the suite — this host
  # simply does not have gh installed in a trusted system location.
  local _trusted_gh=""
  local _candidate
  for _candidate in /usr/bin/gh /usr/local/bin/gh /opt/homebrew/bin/gh /opt/local/bin/gh; do
    if [[ -x "$_candidate" ]]; then
      _trusted_gh="$_candidate"
      break
    fi
  done

  # Also accept any gh found via `command -v gh` if it resolves under a trusted prefix.
  if [[ -z "$_trusted_gh" ]]; then
    local _cv
    # Use `|| true` so the assignment does NOT propagate `command -v`'s exit-1
    # when gh is absent (bats's errexit would fire before the skip-guard runs).
    _cv="$(command -v gh 2>/dev/null || true)"
    case "$_cv" in
      /usr/* | /opt/* | /Applications/*)
        _trusted_gh="$_cv"
        ;;
    esac
  fi

  if [[ -z "$_trusted_gh" ]]; then
    skip "no gh binary found under /usr/*, /opt/*, or /Applications/* on this host — positive-path test skipped"
  fi

  # Derive the directory containing the trusted gh and set PATH to include it
  # together with the basic system dirs (/usr/bin, /bin) required for shell
  # builtins (dirname, pwd) used during script sourcing.
  local _trusted_dir
  _trusted_dir="$(dirname "$_trusted_gh")"

  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    export COPILOT_CLI=1
    export PATH='$_trusted_dir:/usr/bin:/bin'
    . \"$WRAPPER\"
    detect_host
  "
  [ "$status" -eq 0 ]
  [ "$output" = "copilot-cli" ]
}
