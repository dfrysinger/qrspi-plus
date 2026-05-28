#!/usr/bin/env bats
#
# tests/unit/test-codex-review-host-detection.bats
# Task 6 — R5 security fix: sec.F01 — gh path prefix validation in detect_host
# Target: scripts/run-codex-review.sh
#
# RED test for sec.F01: detect_host must reject copilot-cli marker when the
# `gh` binary resolves to a path outside the trusted prefixes /usr/*, /opt/*,
# /Applications/*.  The current code uses `command -v gh` which accepts ANY
# gh in PATH, allowing an attacker who controls PATH to forge the marker.
#
# RED state (before fix):
#   detect_host emits "copilot-cli" for a fake gh in /tmp/fakebins → assertion
#   `[ "$output" = "claude-code" ]` fails → test is RED.
#
# GREEN state (after fix):
#   detect_host validates the resolved path against trusted prefixes; fake gh
#   in /tmp does not match /usr/*, /opt/*, /Applications/* → emits "claude-code".
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

# ---------------------------------------------------------------------------
# Per-test setup: build a temp directory for the fake gh binary.
# ---------------------------------------------------------------------------

setup() {
  TMP_DIR="$(mktemp -d)"
  export TMP_DIR
  FAKE_BIN="$TMP_DIR/fakebins"
  mkdir -p "$FAKE_BIN"
  # Minimal fake gh: exits 0 to satisfy any reachability probe, but lives in
  # an untrusted prefix (/tmp/...) that the fixed code must reject.
  printf '#!/bin/sh\nexit 0\n' > "$FAKE_BIN/gh"
  chmod +x "$FAKE_BIN/gh"
  export FAKE_BIN
}

teardown() {
  cd /
  rm -rf "$TMP_DIR"
}

# ===========================================================================
# sec.F01 — gh path prefix validation
# ===========================================================================

@test "[r5-sec.F01] detect_host rejects copilot-cli marker when gh resolves outside /usr|/opt|/Applications" {
  # RED: current code uses `command -v gh` which accepts the fake gh in FAKE_BIN
  # (an untrusted /tmp path) → emits "copilot-cli".
  # GREEN: fixed code resolves gh's path and validates it against /usr/*, /opt/*,
  # /Applications/*; /tmp/fakebins/gh fails all three → emits "claude-code".
  #
  # PATH is set to FAKE_BIN followed by basic system dirs so the fake gh is
  # found first but normal shell builtins (dirname, pwd) remain reachable.
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    export COPILOT_CLI=1
    export PATH='$FAKE_BIN:/usr/bin:/bin'
    . \"$WRAPPER\"
    detect_host
  "
  [ "$status" -eq 0 ]
  [ "$output" = "claude-code" ]
}
