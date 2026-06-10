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
# RED state (before implementation):
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
  skip "codex-cli host detection deferred to v0.7.3+ (design.md: Codex CLI support out of scope for v0.7.2); identifier is enumerated but no detection branch ships this release"
  # Test expectation (v0.7.3+): when the Codex CLI env signal is present, detect_host
  # returns 'codex-cli'.  This documents the future signal contract.
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

# Test expectation: CODEX_CLI=1 with no copilot/claude signal → detect_host returns 'unknown'
# This pins the actual v0.7.2 shipped behavior: an unrecognised env signal falls through
# to the 'unknown' default because no codex-cli detection branch exists this release.
@test "_host-detect: CODEX_CLI=1 with no copilot/claude signal returns unknown (v0.7.2 shipped behavior)" {
  # Test expectation: when CODEX_CLI=1 is set but COPILOT_CLI and CLAUDE_PROJECT_DIR are
  # absent, detect_host outputs exactly 'unknown' and exits 0.  The v0.7.2 implementation
  # carries no CODEX_CLI branch; the signal is silently unrecognised and falls through to
  # the default 'unknown' return value.
  # RED: _host-detect.sh does not yet exist; this assertion will go GREEN once the script
  # ships and returns 'unknown' for unrecognised signals.
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    unset COPILOT_CLI CLAUDE_PROJECT_DIR
    export CODEX_CLI=1
    . \"$HOST_DETECT\"
    detect_host
  "
  [ "$status" -eq 0 ]
  [ "$output" = "unknown" ]
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

# Test expectation: Copilot CLI default path exits 0 — the host×vendor matrix names openai-codex
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

# Test expectation: Claude Code default path exits 0 — the host×vendor matrix names openai-codex
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

# Test expectation: unknown host default path — single execution jointly asserts
# non-zero exit, exactly one [second-reviewer-unavailable] line, host=unknown, vendor=none.
@test "second-reviewer-available: unknown host default path jointly asserts single-line host=unknown vendor=none" {
  # Test expectation: when no host-detection env var is set, detect_host returns
  # 'unknown', lookup_default_second_reviewer returns 'none', and the probe emits
  # exactly ONE [second-reviewer-unavailable] line naming host=unknown AND vendor=none
  # in the same execution — asserting the joint single-line contract on the default path.
  local _stderr_file="$TMP_DIR/unknown-host-default-joint-stderr.txt"
  local _status=0
  bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR CODEX_CLI
    \"$SECOND_REVIEWER\"
  " >/dev/null 2>"$_stderr_file" || _status=$?

  # Must exit non-zero — unknown host has no reachable second reviewer
  [ "$_status" -ne 0 ]

  # Exactly one stderr line (single-line diagnostic contract)
  local line_count
  line_count="$(wc -l < "$_stderr_file" | tr -d ' ')"
  [ "$line_count" -eq 1 ]

  # Line must begin with the unavailability tag
  grep -q '^\[second-reviewer-unavailable\]' "$_stderr_file"

  # Line must name host=unknown (the value detect_host returns when no host signal is set)
  grep -q 'host=unknown' "$_stderr_file"

  # Line must name vendor=none (the default lookup result for an unknown host)
  grep -q 'vendor=none' "$_stderr_file"
}

# Test expectation: unknown vendor override exits non-zero with [second-reviewer-unavailable],
# emits exactly one stderr line, and names both host= and vendor= in that line.
@test "second-reviewer-available: unknown vendor override exits non-zero with [second-reviewer-unavailable]" {
  # Test expectation: passing a vendor name that is not in the host×vendor matrix
  # causes the probe to exit non-zero with a [second-reviewer-unavailable] diagnostic.
  # The diagnostic must be exactly ONE line naming host= and vendor= (mirrors the
  # unknown-host single-line contract).
  local _stderr_file="$TMP_DIR/unknown-vendor-stderr.txt"
  local _status=0
  bash -c "
    export COPILOT_CLI=1
    \"$SECOND_REVIEWER\" --vendor nonexistent-vendor-xyz
  " >/dev/null 2>"$_stderr_file" || _status=$?
  [ "$_status" -ne 0 ]
  grep -q '^\[second-reviewer-unavailable\]' "$_stderr_file"
  # Exactly one stderr line (same single-line contract as unknown-host path)
  local line_count
  line_count="$(wc -l < "$_stderr_file" | tr -d ' ')"
  [ "$line_count" -eq 1 ]
  # Diagnostic must name the detected host
  grep -q 'host=' "$_stderr_file"
  # Diagnostic must name the passed vendor (jointly asserts host= AND vendor= in one execution)
  grep -q 'vendor=nonexistent-vendor-xyz' "$_stderr_file"
}

# Test expectation: unavailable vendor diagnostic names the vendor (override case)
@test "second-reviewer-available: unavailable vendor override diagnostic names the vendor argument" {
  # Test expectation: when a vendor override is passed and rejected, the diagnostic
  # names the passed vendor so operators can identify the misconfiguration.
  local _stderr_file="$TMP_DIR/unavail-override-vendor.txt"
  bash -c "
    export COPILOT_CLI=1
    \"$SECOND_REVIEWER\" --vendor nonexistent-vendor-xyz
  " >/dev/null 2>"$_stderr_file" || true
  grep -q 'vendor=nonexistent-vendor-xyz' "$_stderr_file"
}

# Test expectation: explicit 'none' vendor argument exits non-zero with exactly one
# [second-reviewer-unavailable] stderr line naming host= and vendor=none.
@test "second-reviewer-available: explicit 'none' vendor argument exits non-zero with [second-reviewer-unavailable]" {
  # Test expectation: guard clause `[ "$_vendor" = "none" ]` in second-reviewer-available.sh
  # fires when the caller passes literal 'none' as the vendor override — even on a known
  # host with a valid default.  The probe must exit non-zero and emit exactly one
  # [second-reviewer-unavailable] line naming host=copilot-cli and vendor=none.
  local _stderr_file="$TMP_DIR/explicit-none-stderr.txt"
  local _status=0
  bash -c "
    export COPILOT_CLI=1
    \"$SECOND_REVIEWER\" --vendor none
  " >/dev/null 2>"$_stderr_file" || _status=$?

  # Must exit non-zero — 'none' is explicitly unavailable
  [ "$_status" -ne 0 ]

  # Exactly one stderr line beginning with the unavailability tag
  local line_count
  line_count="$(wc -l < "$_stderr_file" | tr -d ' ')"
  [ "$line_count" -eq 1 ]
  grep -q '^\[second-reviewer-unavailable\]' "$_stderr_file"

  # Diagnostic must name the detected host and the passed vendor
  grep -q 'host=copilot-cli' "$_stderr_file"
  grep -q 'vendor=none' "$_stderr_file"
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
    \"$SECOND_REVIEWER\" --vendor openai-codex
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
    \"$SECOND_REVIEWER\" --vendor anthropic-claude
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
    \"$SECOND_REVIEWER\" --vendor anthropic-claude
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
    "$SECOND_REVIEWER" 2>/dev/null || true)"
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

# ===========================================================================
# Unknown-host guard: vendor override must not make an unsupported host appear available
# ===========================================================================

# Test expectation: unknown host + recognized vendor override must still exit non-zero.
# A recognized vendor name passed as override argument cannot compensate for an unknown
# host — reachability is host-dependent, and an unsupported host has no reachable path
# to any second reviewer regardless of which vendor is named.
@test "unknown-host-guard: unknown host with recognized vendor override exits non-zero with [second-reviewer-unavailable]" {
  # Clear all host-detection signals so detect_host returns 'unknown'.
  # Then invoke the probe with 'openai-codex' (a recognized matrix vendor) as override.
  # Expected: non-zero exit AND exactly one stderr line beginning [second-reviewer-unavailable]
  # containing both host=unknown and vendor=openai-codex.
  local _stderr_file="$TMP_DIR/unknown-host-override-stderr.txt"
  local _status=0
  bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR CODEX_CLI
    \"$SECOND_REVIEWER\" --vendor openai-codex
  " >/dev/null 2>"$_stderr_file" || _status=$?

  # Must exit non-zero — an unknown host is never available
  [ "$_status" -ne 0 ]

  # Exactly one stderr line
  local line_count
  line_count="$(wc -l < "$_stderr_file" | tr -d ' ')"
  [ "$line_count" -eq 1 ]

  # Line must begin with the unavailability tag
  grep -q '^\[second-reviewer-unavailable\]' "$_stderr_file"

  # Line must name the detected host
  grep -q 'host=unknown' "$_stderr_file"

  # Line must name the requested vendor
  grep -q 'vendor=openai-codex' "$_stderr_file"
}

# ===========================================================================
# Empty-default-vendor guard: probe must fail closed when lookup yields empty
# ===========================================================================

# Test expectation: an empty string from lookup_default_second_reviewer (simulating
# a future refactor where the lookup silently yields nothing) must be treated as
# unavailable — the probe must exit non-zero and emit exactly one stderr line
# beginning [second-reviewer-unavailable]. This test fault-injects the condition
# using stub copies of the dependency scripts in an isolated TMPDIR.
@test "empty-default-vendor-guard: empty lookup result exits non-zero with [second-reviewer-unavailable]" {
  local _work_dir="$TMP_DIR/stub-env"
  mkdir -p "$_work_dir"

  # Copy the probe script into the isolated work dir
  cp "$SECOND_REVIEWER" "$_work_dir/second-reviewer-available.sh"
  chmod +x "$_work_dir/second-reviewer-available.sh"

  # Stub _host-detect.sh: defines detect_host to return a known host identifier
  cat > "$_work_dir/_host-detect.sh" <<'EOF'
detect_host() { printf 'copilot-cli\n'; }
if [ "${QRSPI_SOURCE_ONLY:-}" = "1" ]; then return 0 2>/dev/null || true; fi
EOF

  # Stub _resolve-lib.sh: lookup_default_second_reviewer yields EMPTY (the fault
  # being injected), but second_reviewer_vendor_known still returns 0 for openai-codex.
  # This simulates the future-refactor scenario where the vendor-known check survives
  # but the default lookup silently yields nothing.
  cat > "$_work_dir/_resolve-lib.sh" <<'EOF'
lookup_default_second_reviewer() { printf ''; }
second_reviewer_vendor_known() {
  case "$1" in
    openai-codex|anthropic-claude) return 0 ;;
    *) return 1 ;;
  esac
}
if [ "${QRSPI_SOURCE_ONLY:-}" = "1" ]; then return 0 2>/dev/null || true; fi
EOF

  local _stderr_file="$TMP_DIR/empty-default-stderr.txt"
  local _status=0
  bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR CODEX_CLI
    \"$_work_dir/second-reviewer-available.sh\" --vendor openai-codex
  " >/dev/null 2>"$_stderr_file" || _status=$?

  # Must exit non-zero — an empty default vendor means no configured second reviewer
  [ "$_status" -ne 0 ]

  # Exactly one stderr line beginning with the unavailability tag
  local line_count
  line_count="$(wc -l < "$_stderr_file" | tr -d ' ')"
  [ "$line_count" -eq 1 ]
  grep -q '^\[second-reviewer-unavailable\]' "$_stderr_file"

  # Diagnostic must name the detected host and the requested vendor (naming contract)
  grep -q 'host=' "$_stderr_file"
  grep -q 'vendor=' "$_stderr_file"
}

# ===========================================================================
# Argument hardening (v0.7.2.4 hotfix) — reject silent flag-typo consumption
# ===========================================================================

# Test expectation: a `--`-prefixed positional (e.g. `--artifact-dir foo`) must
# be rejected with exit 2 and a clear "unknown flag" diagnostic — not silently
# consumed as a vendor name. This is the regression test for the v0.7.2.4
# class-of-bug where a typo'd flag flowed into vendor lookup and produced the
# misleading "no reachable second reviewer" verdict.
@test "argument hardening: --flag-shaped positional is rejected (unknown flag, exit 2)" {
  run bash -c "
    export COPILOT_CLI=1
    \"$SECOND_REVIEWER\" --artifact-dir foo
  "
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown flag"* ]]
  [[ "$output" == *"--artifact-dir"* ]]
}

# Test expectation: a bare positional vendor argument is rejected (the legacy
# back-compat form was deliberately dropped — --vendor is the only accepted form).
@test "argument hardening: bare positional vendor is rejected (positional not accepted, exit 2)" {
  run bash -c "
    export COPILOT_CLI=1
    \"$SECOND_REVIEWER\" openai-codex
  "
  [ "$status" -eq 2 ]
  [[ "$output" == *"positional arguments not accepted"* ]]
}

# Test expectation: --vendor with no value is rejected with exit 2.
@test "argument hardening: --vendor with no value is rejected (exit 2)" {
  run bash -c "
    export COPILOT_CLI=1
    \"$SECOND_REVIEWER\" --vendor
  "
  [ "$status" -eq 2 ]
  [[ "$output" == *"--vendor requires a value"* ]]
}

# Test expectation: --vendor=<value> equals form is accepted.
@test "argument hardening: --vendor=<value> equals-form is accepted (exit 0)" {
  run bash -c "
    export COPILOT_CLI=1
    \"$SECOND_REVIEWER\" --vendor=openai-codex
  "
  [ "$status" -eq 0 ]
  [ "$output" = "openai-codex" ]
}

# Test expectation: unknown flag (any --xxx other than --vendor) exits 2.
@test "argument hardening: unknown --flag is rejected (exit 2)" {
  run bash -c "
    export COPILOT_CLI=1
    \"$SECOND_REVIEWER\" --bogus-flag
  "
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown flag"* ]]
}

# Test expectation: --vendor= (equals form with empty value) is rejected.
# Codex review r1 finding: empty equals-form was silently falling back to
# default, masking typos of the form `--vendor=$UNSET_VAR`.
@test "argument hardening: --vendor= (empty equals-form) is rejected (exit 2)" {
  run bash -c "
    export COPILOT_CLI=1
    \"$SECOND_REVIEWER\" --vendor=
  "
  [ "$status" -eq 2 ]
  [[ "$output" == *"--vendor requires a non-empty value"* ]]
}

# Test expectation: --vendor "" (empty space-form value) is rejected.
@test "argument hardening: --vendor \"\" (empty space-form) is rejected (exit 2)" {
  run bash -c "
    export COPILOT_CLI=1
    \"$SECOND_REVIEWER\" --vendor ''
  "
  [ "$status" -eq 2 ]
  [[ "$output" == *"--vendor requires a non-empty value"* ]]
}

# Test expectation: --vendor --bogus (flag-shaped vendor value) is rejected
# with exit 2 — not exit 1 (substantive unavailability), which would
# reintroduce the misleading-error class the v0.7.2.4 hotfix exists to fix.
# Codex review r1 finding: parser was accepting --bogus as a vendor value,
# then reporting "unrecognized vendor" via exit 1 (substantive) instead of
# rejecting at the invocation boundary via exit 2.
@test "argument hardening: --vendor --bogus (flag-shaped value) is rejected (exit 2)" {
  run bash -c "
    export COPILOT_CLI=1
    \"$SECOND_REVIEWER\" --vendor --bogus
  "
  [ "$status" -eq 2 ]
  [[ "$output" == *"--vendor value must not begin with '-'"* ]]
  [[ "$output" == *"--bogus"* ]]
}

# Test expectation: --vendor=--bogus (flag-shaped value via equals form) is
# rejected with exit 2 — same class as above via the equals-form parse path.
@test "argument hardening: --vendor=--bogus (flag-shaped equals-form) is rejected (exit 2)" {
  run bash -c "
    export COPILOT_CLI=1
    \"$SECOND_REVIEWER\" --vendor=--bogus
  "
  [ "$status" -eq 2 ]
  [[ "$output" == *"--vendor value must not begin with '-'"* ]]
}
