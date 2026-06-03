#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# tests/unit/test-dispatch-companion-availability.bats
#
# Migrated and updated availability tests for host-aware second-reviewer probing.
# Renamed from test-codex-review-codex-availability.bats, which tested
# check_codex_available in scripts/run-codex-review.sh.  This file pins the
# second-reviewer-available.sh availability contract introduced by the
# vendor-neutral probe migration.
#
# Preserved intent from the original file:
#   - Availability probe exits 0 on supported hosts (Copilot CLI, Claude Code)
#   - Availability probe exits non-zero with the named diagnostic on unsupported paths
#   - Single-source-of-truth invariant: probe reads the CD-1 host×vendor matrix
#     from _resolve-lib.sh, not a parallel hardcoded table
#
# RED state (before Task 19 implementation):
#   scripts/second-reviewer-available.sh does not exist → all invocation-based
#     tests fail; the skills grep audits fail because the old Codex glob is still
#     present and second_reviewer: is not yet the canonical field.
#
# GREEN state (after implementation):
#   scripts/second-reviewer-available.sh exists, exits 0 for Copilot CLI / Claude
#   Code, exits non-zero with [second-reviewer-unavailable] for unknown host, and
#   the skills prose no longer contains the Claude-only Codex glob.
#
# Bash 3.2 portable: no mapfile, no declare -A, no ${var,,}, no coproc.

load '../helpers/skill-markdown'

# ---------------------------------------------------------------------------
# Suite setup
# ---------------------------------------------------------------------------

setup_file() {
  require_repo_root
  SECOND_REVIEWER="$REPO_ROOT/scripts/second-reviewer-available.sh"
  GOALS_SKILL="$REPO_ROOT/skills/goals/SKILL.md"
  USING_SKILL="$REPO_ROOT/skills/using-qrspi/SKILL.md"
  REVIEWER_PROTOCOL="$REPO_ROOT/skills/reviewer-protocol/SKILL.md"
  export SECOND_REVIEWER GOALS_SKILL USING_SKILL REVIEWER_PROTOCOL
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
# Host-aware availability: Copilot CLI exits 0 (D5 default = openai-codex)
# ===========================================================================

# Test expectation: COPILOT_CLI=1 bash scripts/second-reviewer-available.sh returns 0
# because D5 names openai-codex as the default second-reviewer vendor for copilot-cli.
@test "availability: Copilot CLI (COPILOT_CLI=1) exits 0 for default second-reviewer vendor" {
  # Test expectation: on Copilot CLI both Claude and Codex are first-party; D5 maps
  # copilot-cli → openai-codex as the default second-reviewer vendor → probe exits 0.
  run bash -c "
    unset CLAUDE_PROJECT_DIR CODEX_CLI
    export COPILOT_CLI=1
    \"$SECOND_REVIEWER\"
  "
  [ "$status" -eq 0 ]
}

# ===========================================================================
# Host-aware availability: Claude Code exits 0 (D5 default = openai-codex)
# ===========================================================================

# Test expectation: CLAUDE_PROJECT_DIR set → bash scripts/second-reviewer-available.sh
# returns 0 because D5 names openai-codex as the default for claude-code.
@test "availability: Claude Code (CLAUDE_PROJECT_DIR set) exits 0 for default second-reviewer vendor" {
  # Test expectation: on Claude Code, Codex is third-party but reachable via
  # dispatch-companion.sh; D5 maps claude-code → openai-codex → probe exits 0.
  run bash -c "
    unset COPILOT_CLI CODEX_CLI
    export CLAUDE_PROJECT_DIR=\"$TMP_DIR\"
    \"$SECOND_REVIEWER\"
  "
  [ "$status" -eq 0 ]
}

# ===========================================================================
# Unknown-host fixture: exits non-zero with [second-reviewer-unavailable]
# ===========================================================================

# Test expectation: no host signal → probe exits non-zero and emits
# [second-reviewer-unavailable] diagnostic to stderr.
@test "availability: unknown host exits non-zero with [second-reviewer-unavailable] on stderr" {
  # Test expectation: when no environment host signal is present, detect_host returns
  # 'unknown', lookup_default_second_reviewer('unknown') returns 'none', and the probe
  # emits exactly one [second-reviewer-unavailable] stderr line and exits non-zero.
  local _stderr_file="$TMP_DIR/unknown-host-stderr.txt"
  local _status=0
  bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR CODEX_CLI
    \"$SECOND_REVIEWER\"
  " >/dev/null 2>"$_stderr_file" || _status=$?
  # Exit must be non-zero
  [ "$_status" -ne 0 ]
  # Stderr must carry the [second-reviewer-unavailable] tag
  grep -q '^\[second-reviewer-unavailable\]' "$_stderr_file"
}

# ===========================================================================
# Single-source-of-truth invariant: probe reads _resolve-lib.sh matrix
# ===========================================================================

# Test expectation: probe reads the CD-1 host×vendor matrix from _resolve-lib.sh
# rather than maintaining a parallel hardcoded table.  This invariant prevents
# the matrix from drifting between the probe and the dispatcher.
@test "availability: probe references _resolve-lib.sh (single-source-of-truth invariant)" {
  # Test expectation: second-reviewer-available.sh must call helpers from _resolve-lib.sh
  # (or source it) so there is no parallel host×vendor table in the probe.
  run grep -E '_resolve-lib\.sh|lookup_default_second_reviewer|lookup_host_vendor_path' \
    "$SECOND_REVIEWER"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# Grep audit — skills/goals/SKILL.md no longer contains the Claude-only glob
# ===========================================================================

# Test expectation: skills/goals/SKILL.md must not contain the Claude-only inline
# Codex availability glob after the D3 migration.
@test "grep-audit: skills/goals/SKILL.md does not contain Claude-only Codex availability glob" {
  # Test expectation: the legacy glob
  # ~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs
  # must be absent from skills/goals/SKILL.md after the D3 migration.
  # RED: the glob is still present in the file today.
  local match_count
  match_count="$(grep -c 'codex-companion\.mjs' "$GOALS_SKILL" 2>/dev/null || true)"
  [ "$match_count" -eq 0 ]
}

# Test expectation: skills/goals/SKILL.md must reference scripts/second-reviewer-available.sh
# after the D3 migration (vendor-neutral probe replaces the inline glob).
@test "grep-audit: skills/goals/SKILL.md references scripts/second-reviewer-available.sh" {
  # Test expectation: the D3 migration replaces the inline glob with a call to
  # bash scripts/second-reviewer-available.sh; confirm the reference is present.
  run grep -q 'second-reviewer-available\.sh' "$GOALS_SKILL"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# Grep audit — skills/using-qrspi/SKILL.md no longer contains the Claude-only glob
# ===========================================================================

# Test expectation: skills/using-qrspi/SKILL.md must not contain the Claude-only inline
# Codex availability glob after the D3 migration.
@test "grep-audit: skills/using-qrspi/SKILL.md does not contain Claude-only Codex availability glob" {
  # Test expectation: the legacy glob is absent from skills/using-qrspi/SKILL.md
  # at L405 (the second drift site identified in design.md G27 References).
  # RED: the glob is still present in the file today.
  local match_count
  match_count="$(grep -c 'codex-companion\.mjs' "$USING_SKILL" 2>/dev/null || true)"
  [ "$match_count" -eq 0 ]
}

# Test expectation: skills/using-qrspi/SKILL.md references scripts/second-reviewer-available.sh
@test "grep-audit: skills/using-qrspi/SKILL.md references scripts/second-reviewer-available.sh" {
  # Test expectation: the D3 migration adds a bash scripts/second-reviewer-available.sh
  # invocation at the Codex-detection paragraph site.
  run grep -q 'second-reviewer-available\.sh' "$USING_SKILL"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# Grep audit — skills/reviewer-protocol/SKILL.md no longer contains codex_reviews
# ===========================================================================

# Test expectation: grep -nE 'codex_reviews' skills/reviewer-protocol/SKILL.md returns
# no matches after the D6 Expected-Reviewer Matrix column-header sweep.
@test "grep-audit: skills/reviewer-protocol/SKILL.md contains no codex_reviews field references" {
  # Test expectation: the D6 sweep renames all 'codex_reviews: true | false' column
  # headers in the Expected-Reviewer Matrix to 'second_reviewer: true | false'.
  # Any remaining codex_reviews occurrence is a D6 miss.
  # RED: one match still present today at line 23.
  local match_count
  match_count="$(grep -cE 'codex_reviews' "$REVIEWER_PROTOCOL" 2>/dev/null || true)"
  [ "$match_count" -eq 0 ]
}

# Test expectation: skills/reviewer-protocol/SKILL.md Expected-Reviewer Matrix now uses
# second_reviewer: true | false as the column headers.
@test "grep-audit: skills/reviewer-protocol/SKILL.md Expected-Reviewer Matrix uses second_reviewer column headers" {
  # Test expectation: after the D6 migration, the matrix column headers name
  # 'second_reviewer: true' and 'second_reviewer: false' (vendor-neutral).
  run grep -qE 'second_reviewer:[[:space:]]*(true|false)' "$REVIEWER_PROTOCOL"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# Config-validation prose: stray codex_reviews: rejected, not aliased
# ===========================================================================

# Test expectation: skills/using-qrspi/SKILL.md documents second_reviewer: as the
# canonical config field (not codex_reviews:).
@test "config-field-naming: skills/using-qrspi/SKILL.md documents second_reviewer: as the canonical field" {
  # Test expectation: the config schema documentation in using-qrspi shows
  # 'second_reviewer:' as the field name (vendor-neutral).
  run grep -qE '^second_reviewer:' "$USING_SKILL"
  [ "$status" -eq 0 ]
}

# Test expectation: skills/using-qrspi/SKILL.md Config Validation Procedure rejects
# a stray codex_reviews: field loudly with a rename-naming diagnostic.  It must NOT
# silently alias codex_reviews: to second_reviewer:.
@test "config-field-naming: using-qrspi config-validation prose rejects legacy codex_reviews: with rename-naming error" {
  # Test expectation: the Config Validation Procedure (inside using-qrspi) documents
  # that an unknown 'codex_reviews:' field is a hard validation error with a message
  # that names the rename — e.g., 'renamed to second_reviewer:' or 'use second_reviewer:'.
  # A silent alias would violate CD-1's no-silent-fallback rule and D1's clean-break design.
  # RED: using-qrspi still treats codex_reviews: as a known valid field today.
  run grep -qE "renamed.*second_reviewer|second_reviewer.*renamed|rename.*codex_reviews|codex_reviews.*rename" \
    "$USING_SKILL"
  [ "$status" -eq 0 ]
}
