#!/usr/bin/env bats
# ============================================================================
# Regression + reproduction tests for v0.6 companion-wrapper fixes.
#
# G7 — codex-companion phase-allowlist fallback in status parser
#   These tests pin the post-fix behavior of poll_status when job.status
#   is absent from the companion JSON payload.  The canonical phase→lifecycle
#   mapping lives in design.md § G7 and is reproduced here as the single
#   test-side source of truth.
#
# Phase → lifecycle mapping (design.md § G7):
#   finalizing | done | reviewing          → completed:completed (exits 0 in await)
#   starting | running | investigating |
#     editing | verifying                  → running  (continues polling in await)
#   empty string / any other value         → malformed (exit 14)
#   both job.status and job.phase absent   → malformed (exit 14)
# ============================================================================

setup() {
  TEST_ROOT=$(mktemp -d)
  export TEST_ROOT

  REPO_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
  export REPO_ROOT
  WRAPPER="$REPO_ROOT/scripts/codex-companion-bg.sh"
  export WRAPPER
  STUB="$REPO_ROOT/tests/fixtures/stub-codex-companion.mjs"
  export STUB

  export CODEX_COMPANION="$STUB"

  # Fast tunables so await tests don't time out.
  export QRSPI_CODEX_POLL_INTERVAL_FAST=1
  export QRSPI_CODEX_POLL_INTERVAL_SLOW=2
  export QRSPI_CODEX_POLL_BACKOFF_AFTER=60
  export QRSPI_CODEX_CEILING_SECONDS=30
  export QRSPI_CODEX_LAUNCH_TIMEOUT_SECONDS=5

  export STUB_STATE_FILE="$TEST_ROOT/stub-state.json"

  mkdir -p "$TEST_ROOT/prompts"
  echo "test prompt" > "$TEST_ROOT/prompts/p.txt"
  export PROMPT_FILE="$TEST_ROOT/prompts/p.txt"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

# ---------------------------------------------------------------------------
# G7 — primary path: job.status present and recognized → no fallback consulted
# ---------------------------------------------------------------------------

@test "G7: primary path — job.status 'running' → emits running lifecycle, exits 0 on completion" {
  # job.status is present; the phase fallback must not change anything.
  echo '{"jobId":"job-g7-primary-running","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=2
  export STUB_RESULT_RAW="# G7 primary running review"

  run "$WRAPPER" await job-g7-primary-running
  [ "$status" -eq 0 ]
  [[ "$output" == *"G7 primary running review"* ]]
}

@test "G7: primary path — job.status 'completed' → emits completed lifecycle, exits 0" {
  # job.status is present and resolved to "completed"; fallback must not fire.
  echo '{"jobId":"job-g7-primary-completed","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_RAW="# G7 primary completed review"

  run "$WRAPPER" await job-g7-primary-completed
  [ "$status" -eq 0 ]
  [[ "$output" == *"G7 primary completed review"* ]]
}

@test "G7: primary path — job.status unrecognized value → malformed (exit 14), fallback never fires" {
  # When job.status IS present but carries an unknown value the wrapper must
  # still emit malformed.  The phase fallback must not be consulted at all
  # when job.status is present.
  echo '{"jobId":"job-g7-badstatus","polls":0}' > "$STUB_STATE_FILE"
  export STUB_TERMINAL_STATUS="unknown-status-value"
  export STUB_COMPLETE_AT_POLL=1

  run "$WRAPPER" await job-g7-badstatus
  [ "$status" -eq 14 ]
}

# ---------------------------------------------------------------------------
# G7 — phase fallback: job.status absent, job.phase recognized
# ---------------------------------------------------------------------------

@test "G7: canonical repro — job.status absent, job.phase 'finalizing' → exits 0, emits completed:completed" {
  # This is the canonical reproduction case documented in design.md § G7 and
  # task-20.md Test Expectations.  Before the fix the wrapper emitted malformed
  # (exit 14); after the fix it must exit 0 via the completed lifecycle.
  echo '{"jobId":"job-g7-finalizing","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY="finalizing"
  export STUB_RESULT_RAW="# G7 finalizing review"

  run "$WRAPPER" await job-g7-finalizing
  [ "$status" -eq 0 ]
  [[ "$output" == *"G7 finalizing review"* ]]
}

@test "G7: job.status absent, job.phase 'done' → exits 0, emits completed lifecycle" {
  echo '{"jobId":"job-g7-done","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY="done"
  export STUB_RESULT_RAW="# G7 done review"

  run "$WRAPPER" await job-g7-done
  [ "$status" -eq 0 ]
  [[ "$output" == *"G7 done review"* ]]
}

@test "G7: job.status absent, job.phase 'reviewing' → exits 0, emits completed lifecycle" {
  echo '{"jobId":"job-g7-reviewing","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY="reviewing"
  export STUB_RESULT_RAW="# G7 reviewing review"

  run "$WRAPPER" await job-g7-reviewing
  [ "$status" -eq 0 ]
  [[ "$output" == *"G7 reviewing review"* ]]
}

@test "G7: job.status absent, job.phase 'running' → emits running lifecycle (poll continues), then completes" {
  # Phase 'running' maps to the running lifecycle; the await loop continues
  # polling.  We use STUB_COMPLETE_AT_POLL so the stub transitions from
  # phase-only running to a real job.status completed after 2 polls.
  echo '{"jobId":"job-g7-phase-running","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY_UNTIL_POLL=2
  export STUB_PHASE_ONLY="running"
  export STUB_COMPLETE_AT_POLL=3
  export STUB_RESULT_RAW="# G7 phase-running completed"

  run "$WRAPPER" await job-g7-phase-running
  [ "$status" -eq 0 ]
  [[ "$output" == *"G7 phase-running completed"* ]]
}

@test "G7: job.status absent, job.phase 'starting' → running lifecycle (poll continues), then completes" {
  echo '{"jobId":"job-g7-starting","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY_UNTIL_POLL=2
  export STUB_PHASE_ONLY="starting"
  export STUB_COMPLETE_AT_POLL=3
  export STUB_RESULT_RAW="# G7 starting completed"

  run "$WRAPPER" await job-g7-starting
  [ "$status" -eq 0 ]
  [[ "$output" == *"G7 starting completed"* ]]
}

@test "G7: job.status absent, job.phase 'investigating' → running lifecycle, then completes" {
  echo '{"jobId":"job-g7-investigating","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY_UNTIL_POLL=2
  export STUB_PHASE_ONLY="investigating"
  export STUB_COMPLETE_AT_POLL=3
  export STUB_RESULT_RAW="# G7 investigating completed"

  run "$WRAPPER" await job-g7-investigating
  [ "$status" -eq 0 ]
  [[ "$output" == *"G7 investigating completed"* ]]
}

@test "G7: job.status absent, job.phase 'editing' → running lifecycle, then completes" {
  echo '{"jobId":"job-g7-editing","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY_UNTIL_POLL=2
  export STUB_PHASE_ONLY="editing"
  export STUB_COMPLETE_AT_POLL=3
  export STUB_RESULT_RAW="# G7 editing completed"

  run "$WRAPPER" await job-g7-editing
  [ "$status" -eq 0 ]
  [[ "$output" == *"G7 editing completed"* ]]
}

@test "G7: job.status absent, job.phase 'verifying' → running lifecycle, then completes" {
  echo '{"jobId":"job-g7-verifying","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY_UNTIL_POLL=2
  export STUB_PHASE_ONLY="verifying"
  export STUB_COMPLETE_AT_POLL=3
  export STUB_RESULT_RAW="# G7 verifying completed"

  run "$WRAPPER" await job-g7-verifying
  [ "$status" -eq 0 ]
  [[ "$output" == *"G7 verifying completed"* ]]
}

# ---------------------------------------------------------------------------
# G7 — terminal cases: both absent, or phase unrecognized
# ---------------------------------------------------------------------------

@test "G7: both job.status and job.phase absent → exit 14 (malformed), genuine protocol violation" {
  # When neither field is present the existing malformed terminal case must be
  # preserved unchanged — this is not a phase the wrapper is asked to recover.
  echo '{"jobId":"job-g7-both-absent","polls":0}' > "$STUB_STATE_FILE"
  export STUB_NO_STATUS_NO_PHASE=1

  run "$WRAPPER" await job-g7-both-absent
  [ "$status" -eq 14 ]
}

@test "G7: job.status absent, job.phase empty string → exit 14 (falls through to malformed)" {
  # Empty string is outside the mapping table; the wrapper must not treat it as
  # a recognized phase.  Falls through to existing malformed terminal case.
  echo '{"jobId":"job-g7-empty-phase","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY=""
  export STUB_EMPTY_PHASE=1

  run "$WRAPPER" await job-g7-empty-phase
  [ "$status" -eq 14 ]
}

@test "G7: job.status absent, job.phase unknown literal → exit 14 (falls through to malformed)" {
  # An unknown literal (not in the mapping table) must fall through to malformed.
  echo '{"jobId":"job-g7-unknown-phase","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY="some-future-phase-not-in-table"

  run "$WRAPPER" await job-g7-unknown-phase
  [ "$status" -eq 14 ]
}

# ---------------------------------------------------------------------------
# G7 — stderr visibility line on fallback
# ---------------------------------------------------------------------------

@test "G7: phase fallback emits stderr line of form '[codex-companion-bg] phase fallback active: <phase> → <lifecycle>'" {
  # The first fallback invocation per wrapper process must emit the audit line
  # to stderr.  Callers MUST NOT rely on this line being present or absent;
  # it is for operational monitoring only.
  bats_require_minimum_version 1.5.0

  echo '{"jobId":"job-g7-stderr","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY="finalizing"
  export STUB_RESULT_RAW="# G7 stderr test"

  run --separate-stderr "$WRAPPER" await job-g7-stderr
  [ "$status" -eq 0 ]
  [[ "$stderr" == *"[codex-companion-bg] phase fallback active: finalizing"* ]]
  [[ "$stderr" == *"completed"* ]]
}

# ---------------------------------------------------------------------------
# G7 — stdout/exit surface identical between primary and fallback paths
# ---------------------------------------------------------------------------

@test "G7: stdout and exit code on phase-recovered path identical to primary-read success path" {
  # A caller that parses only stdout and exit code must observe no difference
  # between a broker-served job.status result and a phase-recovered result.
  # We verify this by running two await invocations: one with a real job.status
  # (primary) and one with only job.phase (fallback), asserting the outputs match.
  # --separate-stderr is used so that the phase-fallback's audit stderr line
  # does not contaminate the $output comparison (callers must parse stdout only).

  bats_require_minimum_version 1.5.0

  # Primary path: job.status = "completed"
  echo '{"jobId":"job-g7-primary-cmp","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_RAW="# identical output"
  run --separate-stderr "$WRAPPER" await job-g7-primary-cmp
  local primary_status="$status"
  local primary_output="$output"

  # Reset state for fallback path: job.status absent, job.phase = "finalizing"
  echo '{"jobId":"job-g7-fallback-cmp","polls":0}' > "$STUB_STATE_FILE"
  unset STUB_COMPLETE_AT_POLL
  export STUB_PHASE_ONLY="finalizing"
  export STUB_RESULT_RAW="# identical output"
  run --separate-stderr "$WRAPPER" await job-g7-fallback-cmp
  local fallback_status="$status"
  local fallback_output="$output"

  [ "$primary_status" -eq "$fallback_status" ]
  [ "$primary_output" = "$fallback_output" ]
}

# ---------------------------------------------------------------------------
# G7 — non-status subcommands unchanged
# ---------------------------------------------------------------------------

@test "G7: launch subcommand behavior is unchanged by the phase-fallback addition" {
  run bash -c 'cat "$PROMPT_FILE" | "$WRAPPER" launch'
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^task-stub-[0-9]+-[0-9]+$ ]]
}
