#!/usr/bin/env bats
#
# tests/unit/test-codex-review-host-detection.bats
# Task 6 — R5/R7 security fixes: sec.F01 — gh path prefix validation in detect_host
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

# ===========================================================================
# sec.F01 (R7) — PATH with /usr/../ injection rejected
# ===========================================================================

@test "[r7-sec.F01] PATH with /usr/../ injection rejected" {
  # Attack: PATH=/usr/../<tmpdir>/fakebins:...
  # command -v gh returns "/usr/../<tmpdir>/fakebins/gh"
  # [[ ... == /usr/* ]] is a string match → TRUE (bypass without realpath fix).
  # GREEN: realpath normalises "/usr/../<tmpdir>/fakebins/gh" → "<tmpdir>/fakebins/gh"
  # which does NOT match any trusted prefix → detect_host emits "claude-code".
  local injected_path="/usr/../${FAKE_BIN}"
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    export COPILOT_CLI=1
    export PATH='${injected_path}:/usr/bin:/bin'
    . \"$WRAPPER\"
    detect_host
  "
  [ "$status" -eq 0 ]
  [ "$output" = "claude-code" ]
}

# ===========================================================================
# sec.F02 (R7) — symlink in /opt to /tmp rejected
# ===========================================================================

# ===========================================================================
# sec.F01 (R8) — fail-closed when both realpath and readlink -f are absent
# ===========================================================================

@test "[r8-sec.F01] detect_host fail-closed when realpath and readlink-f both absent" {
  # Attack: PATH=/usr/../<tmpdir>/fakebins:... (..‑injection, R7 vector)
  # On this test platform, realpath and readlink are normally available and
  # would normalise the path and reject it.  This test simulates an environment
  # where BOTH are absent / non-functional by placing failing shims ahead of
  # the real binaries on PATH.
  #
  # RED (before fix): the fallback `|| printf '%s' "$_gh_path"` preserves the
  # raw "/usr/../<tmpdir>/fakebins/gh" string, which matches /usr/* → emits
  # "copilot-cli".
  #
  # GREEN (after fix): the fail-closed assignment produces an empty string when
  # both tools fail; the -n guard short-circuits and detect_host emits
  # "claude-code".

  # Build failing shims for realpath and readlink.
  local shim_dir="$TMP_DIR/no-norm-shims"
  mkdir -p "$shim_dir"
  printf '#!/bin/sh\nexit 1\n' > "$shim_dir/realpath"
  printf '#!/bin/sh\nexit 1\n' > "$shim_dir/readlink"
  chmod +x "$shim_dir/realpath" "$shim_dir/readlink"

  # Injected PATH: the shims precede real system bins so realpath/readlink fail,
  # but the fake gh (in FAKE_BIN prepended via /usr/../) is found first.
  local injected_path="/usr/../${FAKE_BIN}:${shim_dir}:/usr/bin:/bin"
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    export COPILOT_CLI=1
    export PATH='${injected_path}'
    . \"$WRAPPER\"
    detect_host
  "
  [ "$status" -eq 0 ]
  [ "$output" = "claude-code" ]
}

@test "[r7-sec.F02] symlink in trusted prefix pointing to untrusted dir rejected" {
  # Attack: place a symlink inside a trusted-prefix directory (simulated via
  # a symlink inside the test tmp dir itself) that points to the fake gh binary.
  # realpath must follow the symlink and expose the real location, which is
  # outside all trusted prefixes → detect_host emits "claude-code".
  #
  # We simulate the trusted-prefix symlink attack entirely within $TMP_DIR
  # (no /opt write needed).  We create:
  #   $TMP_DIR/trusted-sim/usr/bin/ → symlink named "gh" → $FAKE_BIN/gh
  # Then we set PATH so command -v gh returns the symlink path
  # ($TMP_DIR/trusted-sim/usr/bin/gh) which starts with a /usr/ look-alike
  # string — but after realpath resolution points to $FAKE_BIN/gh (untrusted).
  #
  # Because the actual path of $TMP_DIR starts with /tmp (or /private/tmp on
  # macOS), neither the raw string nor the resolved path matches a trusted prefix.
  local trusted_sim="$TMP_DIR/trusted-sim/usr/bin"
  mkdir -p "$trusted_sim"
  ln -s "$FAKE_BIN/gh" "$trusted_sim/gh"

  # Construct a PATH entry that looks like /usr/... at string level only when
  # we fake it via /usr/../$TMP_DIR/trusted-sim/usr/bin.  The symlink itself
  # lives at $trusted_sim/gh; realpath($trusted_sim/gh) = $FAKE_BIN/gh.
  local injected_path="/usr/../${TMP_DIR}/trusted-sim/usr/bin"
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    export COPILOT_CLI=1
    export PATH='${injected_path}:/usr/bin:/bin'
    . \"$WRAPPER\"
    detect_host
  "
  [ "$status" -eq 0 ]
  [ "$output" = "claude-code" ]
}
