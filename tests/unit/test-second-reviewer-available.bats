#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# tests/unit/test-second-reviewer-available.bats
#
# Covers:
#   - Source-safety and host-signal tests for scripts/_host-detect.sh
#   - Executability and behavior tests for scripts/second-reviewer-available.sh
#   - Override-boundary tests (vendor override; no model_routing: read; no
#     primary/second distinctness enforcement at probe time)
#   - Shared-source guard: probe must consume _resolve-lib.sh helpers; no
#     parallel hardcoded host×vendor table allowed in the probe itself
#
# RED state (before Task 19 implementation):
#   scripts/_host-detect.sh does not exist  → all source-safety / host-signal
#     tests fail at `[ -f ... ]` or at the `bash -c ". $HOST_DETECT ..."` step.
#   scripts/second-reviewer-available.sh does not exist → executability and
#     behavior tests fail at `[ -f ... ]` / `[ -x ... ]` / invocation step.
#
# GREEN state (after implementation):
#   All assertions hold against the implemented scripts.
#
# Bash 3.2 portable: no mapfile, no declare -A, no ${var,,}, no coproc.

load '../helpers/skill-markdown'

# ---------------------------------------------------------------------------
# Suite setup
# ---------------------------------------------------------------------------

setup_file() {
  require_repo_root
  HOST_DETECT="$REPO_ROOT/scripts/_host-detect.sh"
  SECOND_REVIEWER="$REPO_ROOT/scripts/second-reviewer-available.sh"
  RESOLVE_LIB="$REPO_ROOT/scripts/_resolve-lib.sh"
  export HOST_DETECT SECOND_REVIEWER RESOLVE_LIB
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
# _host-detect.sh — file presence and source-safety
# ===========================================================================

# Test expectation: _host-detect.sh exists and is readable
@test "_host-detect: file exists at scripts/_host-detect.sh" {
  [ -f "$HOST_DETECT" ]
  [ -r "$HOST_DETECT" ]
}

# Test expectation: _host-detect.sh is safe to source under QRSPI_SOURCE_ONLY=1
# with no filesystem probe or wrapper side effects — exits 0, produces no output.
@test "_host-detect: safe to source under QRSPI_SOURCE_ONLY=1 (no output, exit 0)" {
  # Test expectation: sourcing _host-detect.sh with QRSPI_SOURCE_ONLY=1 must not
  # print anything to stdout and must exit 0.  The guard prevents any side effects.
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    . \"$HOST_DETECT\"
    exit 0
  "
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# Test expectation: sourcing twice is idempotent (no duplicate-function errors);
# exits 0 with no output.
@test "_host-detect: sourcing twice is idempotent (exit 0, no output)" {
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    . \"$HOST_DETECT\"
    . \"$HOST_DETECT\"
    exit 0
  "
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ===========================================================================
# _host-detect.sh — host-signal tests
# ===========================================================================

# Test expectation: COPILOT_CLI=1 → detect_host returns 'copilot-cli'
@test "_host-detect: COPILOT_CLI=1 returns copilot-cli" {
  # Test expectation: when COPILOT_CLI=1 is set and CLAUDE_PROJECT_DIR is absent,
  # detect_host outputs exactly 'copilot-cli' and exits 0.
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    unset CLAUDE_PROJECT_DIR
    export COPILOT_CLI=1
    . \"$HOST_DETECT\"
    detect_host
  "
  [ "$status" -eq 0 ]
  [ "$output" = "copilot-cli" ]
}

# Test expectation: CLAUDE_PROJECT_DIR set → detect_host returns 'claude-code'
@test "_host-detect: CLAUDE_PROJECT_DIR set returns claude-code" {
  # Test expectation: when CLAUDE_PROJECT_DIR is non-empty and COPILOT_CLI is absent,
  # detect_host outputs exactly 'claude-code' and exits 0.
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    unset COPILOT_CLI
    export CLAUDE_PROJECT_DIR=\"$TMP_DIR\"
    . \"$HOST_DETECT\"
    detect_host
  "
  [ "$status" -eq 0 ]
  [ "$output" = "claude-code" ]
}

# Test expectation: no known signal → detect_host returns 'unknown'
@test "_host-detect: no known signal returns unknown" {
  # Test expectation: when no host signals are set, detect_host returns 'unknown'.
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    unset COPILOT_CLI CLAUDE_PROJECT_DIR CODEX_CLI
    . \"$HOST_DETECT\"
    detect_host
  "
  [ "$status" -eq 0 ]
  [ "$output" = "unknown" ]
}

# Test expectation: future Codex CLI signal → detect_host returns 'codex-cli'
# (v0.7.3+ deferred per design.md; codex-cli host support is not shipped in v0.7.2)
@test "_host-detect: future Codex CLI signal (CODEX_CLI=1) returns codex-cli [v0.7.3+ deferred]" {
  # Test expectation: when the future Codex CLI env signal is present, detect_host
  # returns 'codex-cli'.  This pins the v0.7.3+ signal behavior now.
  # RED: _host-detect.sh does not exist yet; RED after v0.7.2 implementation
  # (codex-cli detection not shipped until v0.7.3+).
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    unset COPILOT_CLI CLAUDE_PROJECT_DIR
    export CODEX_CLI=1
    . \"$HOST_DETECT\"
    detect_host
  "
  [ "$status" -eq 0 ]
  [ "$output" = "codex-cli" ]
}

# Test expectation: _host-detect.sh performs no filesystem probes
# (env-var only signal per design.md CD-1 — no HOME-based glob or path check)
@test "_host-detect: performs no filesystem probes (env-var-only signal)" {
  # Test expectation: detect_host must not read from HOME or probe any filesystem path.
  # Setting HOME to a nonexistent path with COPILOT_CLI=1 must still return 'copilot-cli'.
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    export COPILOT_CLI=1
    export HOME='/nonexistent/probe-guard'
    . \"$HOST_DETECT\"
    detect_host
  "
  [ "$status" -eq 0 ]
  [ "$output" = "copilot-cli" ]
}

# ===========================================================================
# second-reviewer-available.sh — file presence and executability
# ===========================================================================

# Test expectation: scripts/second-reviewer-available.sh exists and is executable
@test "second-reviewer-available: file exists at scripts/second-reviewer-available.sh" {
  [ -f "$SECOND_REVIEWER" ]
}

@test "second-reviewer-available: file is executable (chmod +x)" {
  [ -x "$SECOND_REVIEWER" ]
}

# ===========================================================================
# second-reviewer-available.sh — default-path behavior (exit 0 paths)
# ===========================================================================

# Test expectation: Copilot CLI default path exits 0 — D5 names openai-codex
# as the default second-reviewer vendor for copilot-cli (both Claude and Codex
# are first-party on Copilot CLI).
@test "second-reviewer-available: Copilot CLI default path exits 0" {
  # Test expectation: COPILOT_CLI=1, no vendor override → exits 0 because
  # lookup_default_second_reviewer('copilot-cli') = 'openai-codex' (reachable).
  run bash -c "
    unset CLAUDE_PROJECT_DIR CODEX_CLI
    export COPILOT_CLI=1
    \"$SECOND_REVIEWER\"
  "
  [ "$status" -eq 0 ]
}

# Test expectation: Claude Code default path exits 0 — D5 names openai-codex
# as the default second-reviewer vendor for claude-code (Codex is third-party
# on Claude Code but still potentially reachable via dispatch-companion.sh).
@test "second-reviewer-available: Claude Code default path exits 0" {
  # Test expectation: CLAUDE_PROJECT_DIR set, no vendor override → exits 0 because
  # lookup_default_second_reviewer('claude-code') = 'openai-codex' (reachable).
  run bash -c "
    unset COPILOT_CLI CODEX_CLI
    export CLAUDE_PROJECT_DIR=\"$TMP_DIR\"
    \"$SECOND_REVIEWER\"
  "
  [ "$status" -eq 0 ]
}

# ===========================================================================
# second-reviewer-available.sh — unavailable paths (exit non-zero + diagnostic)
# ===========================================================================

# Test expectation: unknown host exits non-zero
@test "second-reviewer-available: unknown host exits non-zero" {
  # Test expectation: no host signal set → detect_host returns 'unknown' →
  # lookup_default_second_reviewer('unknown') = 'none' → exits non-zero.
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR CODEX_CLI
    \"$SECOND_REVIEWER\"
  "
  [ "$status" -ne 0 ]
}

# Test expectation: unknown host emits exactly one stderr line beginning [second-reviewer-unavailable]
@test "second-reviewer-available: unknown host emits exactly one [second-reviewer-unavailable] stderr line" {
  # Test expectation: the diagnostic must be exactly ONE line on stderr, beginning
  # with the [second-reviewer-unavailable] tag.  Multiple lines, stdout emission,
  # or a missing tag are all failures.
  local _stderr_file="$TMP_DIR/unavail-stderr.txt"
  bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR CODEX_CLI
    \"$SECOND_REVIEWER\"
  " >/dev/null 2>"$_stderr_file" || true
  local line_count
  line_count="$(wc -l < "$_stderr_file" | tr -d ' ')"
  [ "$line_count" -eq 1 ]
  grep -q '^\[second-reviewer-unavailable\]' "$_stderr_file"
}

# Test expectation: [second-reviewer-unavailable] diagnostic names the detected host
@test "second-reviewer-available: [second-reviewer-unavailable] diagnostic names detected host" {
  # Test expectation: the diagnostic line names host=<detected_host> so operators
  # can identify which environment signal was (or was not) found.
  local _stderr_file="$TMP_DIR/unavail-host-stderr.txt"
  bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR CODEX_CLI
    \"$SECOND_REVIEWER\"
  " >/dev/null 2>"$_stderr_file" || true
  grep -qE 'host=' "$_stderr_file"
}

# Test expectation: [second-reviewer-unavailable] diagnostic names the requested/default vendor
@test "second-reviewer-available: [second-reviewer-unavailable] diagnostic names requested vendor" {
  # Test expectation: the diagnostic line names vendor=<vendor> (the default or override
  # vendor that was unavailable) so operators know which vendor to investigate.
  local _stderr_file="$TMP_DIR/unavail-vendor-stderr.txt"
  bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR CODEX_CLI
    \"$SECOND_REVIEWER\"
  " >/dev/null 2>"$_stderr_file" || true
  grep -qE 'vendor=' "$_stderr_file"
}

# Test expectation: unknown vendor override exits non-zero with [second-reviewer-unavailable]
@test "second-reviewer-available: unknown vendor override exits non-zero with [second-reviewer-unavailable]" {
  # Test expectation: passing a vendor name that is not in the host×vendor matrix
  # causes the probe to exit non-zero with a [second-reviewer-unavailable] diagnostic.
  local _stderr_file="$TMP_DIR/unknown-vendor-stderr.txt"
  local _status=0
  bash -c "
    export COPILOT_CLI=1
    \"$SECOND_REVIEWER\" nonexistent-vendor-xyz
  " >/dev/null 2>"$_stderr_file" || _status=$?
  [ "$_status" -ne 0 ]
  grep -q '^\[second-reviewer-unavailable\]' "$_stderr_file"
}

# Test expectation: unavailable vendor diagnostic names the vendor (override case)
@test "second-reviewer-available: unavailable vendor override diagnostic names the vendor argument" {
  # Test expectation: when a vendor override is passed and rejected, the diagnostic
  # names the passed vendor so operators can identify the misconfiguration.
  local _stderr_file="$TMP_DIR/unavail-override-vendor.txt"
  bash -c "
    export COPILOT_CLI=1
    \"$SECOND_REVIEWER\" nonexistent-vendor-xyz
  " >/dev/null 2>"$_stderr_file" || true
  grep -qE 'nonexistent-vendor-xyz|vendor=' "$_stderr_file"
}

# ===========================================================================
# Override-boundary tests
# ===========================================================================

# Test expectation: second-reviewer-available.sh <vendor> supports diagnostic
# vendor override — caller passes a vendor to check, probe uses it instead of
# the default.
@test "override-boundary: explicit vendor override accepted on Copilot CLI (openai-codex exits 0)" {
  # Test expectation: COPILOT_CLI=1 with explicit 'openai-codex' override exits 0.
  run bash -c "
    export COPILOT_CLI=1
    \"$SECOND_REVIEWER\" openai-codex
  "
  [ "$status" -eq 0 ]
}

@test "override-boundary: explicit anthropic-claude override accepted on Copilot CLI (exits 0)" {
  # Test expectation: COPILOT_CLI=1 with 'anthropic-claude' override exits 0 because
  # anthropic-claude is first-party on Copilot CLI (reachable).
  # Validates that the probe only checks reachability, not whether the vendor would
  # equal the primary — that distinctness check lives at dispatch time, not here.
  run bash -c "
    export COPILOT_CLI=1
    \"$SECOND_REVIEWER\" anthropic-claude
  "
  [ "$status" -eq 0 ]
}

# Test expectation: probe works without CONFIG_MD set — it does NOT read model_routing:
@test "override-boundary: probe works without CONFIG_MD (does not read model_routing:)" {
  # Test expectation: unsetting CONFIG_MD entirely does not affect probe exit status.
  # model_routing: is a dispatch-time concern; the probe must not depend on it.
  run bash -c "
    unset CONFIG_MD
    export COPILOT_CLI=1
    \"$SECOND_REVIEWER\"
  "
  [ "$status" -eq 0 ]
}

# Test expectation: probe does NOT enforce primary/second vendor distinctness
# (that invariant is checked at dispatch time by dispatch-agent.sh, not at probe time).
@test "override-boundary: probe does not enforce primary/second vendor distinctness" {
  # Test expectation: if the caller passes a vendor that happens to equal what
  # would be the primary vendor, the probe still exits based on reachability only.
  # On Copilot CLI, both anthropic-claude and openai-codex are first-party → reachable.
  # This test passes anthropic-claude even though the primary Claude reviewer IS
  # anthropic-claude — the probe should not care and should exit 0.
  run bash -c "
    export COPILOT_CLI=1
    \"$SECOND_REVIEWER\" anthropic-claude
  "
  [ "$status" -eq 0 ]
}

# ===========================================================================
# Shared-source guard: probe must consume _resolve-lib.sh, no parallel table
# ===========================================================================

# Test expectation: second-reviewer-available.sh references _resolve-lib.sh
# (sources it or uses its helpers) rather than carrying a duplicate host×vendor table.
@test "shared-source-guard: second-reviewer-available.sh sources or references _resolve-lib.sh" {
  # Test expectation: the probe must call the shared matrix helpers from _resolve-lib.sh.
  # A match on '_resolve-lib.sh' or on its exported function names confirms the probe
  # delegates to the single source of truth.
  run grep -E '_resolve-lib\.sh|lookup_default_second_reviewer|lookup_host_vendor_path' \
    "$SECOND_REVIEWER"
  [ "$status" -eq 0 ]
}

# Test expectation: second-reviewer-available.sh has no inline host×vendor case
# statement (would indicate a parallel hardcoded table, violating single-source rule).
@test "shared-source-guard: second-reviewer-available.sh has no inline host×vendor case for claude-code or copilot-cli" {
  # Test expectation: the probe must not duplicate the matrix.  If the file contains
  # its own case statement branching on 'claude-code' or 'copilot-cli' host names
  # to look up vendors, that is a parallel table — a drift risk and a spec violation.
  # A match here = FAIL (parallel table found).
  local match_count
  match_count="$(grep -cE \
    'claude-code[[:space:]]*\)[[:space:]]*(openai-codex|anthropic-claude)|copilot-cli[[:space:]]*\)[[:space:]]*(openai-codex|anthropic-claude)' \
    "$SECOND_REVIEWER" 2>/dev/null || echo 0)"
  [ "$match_count" -eq 0 ]
}

# Test expectation: second-reviewer-available.sh sources _host-detect.sh rather than
# duplicating env-var detection logic locally.
@test "shared-source-guard: second-reviewer-available.sh references _host-detect.sh" {
  # Test expectation: the probe calls detect_host from _host-detect.sh rather than
  # re-implementing the env-var detection logic inline.
  run grep -E '_host-detect\.sh|detect_host' "$SECOND_REVIEWER"
  [ "$status" -eq 0 ]
}
