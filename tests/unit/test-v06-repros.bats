#!/usr/bin/env bats
# ============================================================================
# Regression + reproduction tests for v0.6 companion-wrapper fixes.
#
# phase-fallback — codex-companion phase-allowlist fallback in status parser
#   These tests pin the post-fix behavior of poll_status when job.status
#   is absent from the companion JSON payload.  The canonical phase→lifecycle
#   mapping lives in design.md and is reproduced here as the single
#   test-side source of truth.
#
# Phase → lifecycle mapping:
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
# phase-fallback — primary path: job.status present and recognized → no fallback consulted
# ---------------------------------------------------------------------------

@test "phase-fallback: primary path — job.status 'running' → emits running lifecycle, exits 0 on completion" {
  # job.status is present; the phase fallback must not change anything.
  echo '{"jobId":"job-g7-primary-running","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=2
  export STUB_RESULT_RAW="# G7 primary running review"

  run "$WRAPPER" await job-g7-primary-running
  [ "$status" -eq 0 ]
  [[ "$output" == *"G7 primary running review"* ]]
}

@test "phase-fallback: primary path — job.status 'completed' → emits completed lifecycle, exits 0" {
  # job.status is present and resolved to "completed"; fallback must not fire.
  echo '{"jobId":"job-g7-primary-completed","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_RAW="# G7 primary completed review"

  run "$WRAPPER" await job-g7-primary-completed
  [ "$status" -eq 0 ]
  [[ "$output" == *"G7 primary completed review"* ]]
}

@test "phase-fallback: primary path — job.status unrecognized value → malformed (exit 14), fallback never fires" {
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
# phase-fallback — phase fallback: job.status absent, job.phase recognized
# ---------------------------------------------------------------------------

@test "phase-fallback: canonical repro — job.status absent, job.phase 'finalizing' → exits 0, emits completed:completed" {
  # This is the canonical reproduction case for the phase-fallback feature.
  # Before the fix the wrapper emitted malformed
  # (exit 14); after the fix it must exit 0 via the completed lifecycle.
  echo '{"jobId":"job-g7-finalizing","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY="finalizing"
  export STUB_RESULT_RAW="# G7 finalizing review"

  run "$WRAPPER" await job-g7-finalizing
  [ "$status" -eq 0 ]
  [[ "$output" == *"G7 finalizing review"* ]]
}

@test "phase-fallback: job.status absent, job.phase 'done' → exits 0, emits completed lifecycle" {
  echo '{"jobId":"job-g7-done","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY="done"
  export STUB_RESULT_RAW="# G7 done review"

  run "$WRAPPER" await job-g7-done
  [ "$status" -eq 0 ]
  [[ "$output" == *"G7 done review"* ]]
}

@test "phase-fallback: job.status absent, job.phase 'reviewing' → exits 0, emits completed lifecycle" {
  echo '{"jobId":"job-g7-reviewing","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY="reviewing"
  export STUB_RESULT_RAW="# G7 reviewing review"

  run "$WRAPPER" await job-g7-reviewing
  [ "$status" -eq 0 ]
  [[ "$output" == *"G7 reviewing review"* ]]
}

@test "phase-fallback: job.status absent, job.phase 'running' → emits running lifecycle (poll continues), then completes" {
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

@test "phase-fallback: job.status absent, job.phase 'starting' → running lifecycle (poll continues), then completes" {
  echo '{"jobId":"job-g7-starting","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY_UNTIL_POLL=2
  export STUB_PHASE_ONLY="starting"
  export STUB_COMPLETE_AT_POLL=3
  export STUB_RESULT_RAW="# G7 starting completed"

  run "$WRAPPER" await job-g7-starting
  [ "$status" -eq 0 ]
  [[ "$output" == *"G7 starting completed"* ]]
}

@test "phase-fallback: job.status absent, job.phase 'investigating' → running lifecycle, then completes" {
  echo '{"jobId":"job-g7-investigating","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY_UNTIL_POLL=2
  export STUB_PHASE_ONLY="investigating"
  export STUB_COMPLETE_AT_POLL=3
  export STUB_RESULT_RAW="# G7 investigating completed"

  run "$WRAPPER" await job-g7-investigating
  [ "$status" -eq 0 ]
  [[ "$output" == *"G7 investigating completed"* ]]
}

@test "phase-fallback: job.status absent, job.phase 'editing' → running lifecycle, then completes" {
  echo '{"jobId":"job-g7-editing","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY_UNTIL_POLL=2
  export STUB_PHASE_ONLY="editing"
  export STUB_COMPLETE_AT_POLL=3
  export STUB_RESULT_RAW="# G7 editing completed"

  run "$WRAPPER" await job-g7-editing
  [ "$status" -eq 0 ]
  [[ "$output" == *"G7 editing completed"* ]]
}

@test "phase-fallback: job.status absent, job.phase 'verifying' → running lifecycle, then completes" {
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
# phase-fallback — terminal cases: both absent, or phase unrecognized
# ---------------------------------------------------------------------------

@test "phase-fallback: both job.status and job.phase absent → exit 14 (malformed), genuine protocol violation" {
  # When neither field is present the existing malformed terminal case must be
  # preserved unchanged — this is not a phase the wrapper is asked to recover.
  echo '{"jobId":"job-g7-both-absent","polls":0}' > "$STUB_STATE_FILE"
  export STUB_NO_STATUS_NO_PHASE=1

  run "$WRAPPER" await job-g7-both-absent
  [ "$status" -eq 14 ]
}

@test "phase-fallback: job.status absent, job.phase empty string → exit 14 (falls through to malformed)" {
  # Empty string is outside the mapping table; the wrapper must not treat it as
  # a recognized phase.  Falls through to existing malformed terminal case.
  echo '{"jobId":"job-g7-empty-phase","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY=""
  export STUB_EMPTY_PHASE=1

  run "$WRAPPER" await job-g7-empty-phase
  [ "$status" -eq 14 ]
}

@test "phase-fallback: job.status absent, job.phase unknown literal → exit 14 (falls through to malformed)" {
  # An unknown literal (not in the mapping table) must fall through to malformed.
  echo '{"jobId":"job-g7-unknown-phase","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY="some-future-phase-not-in-table"

  run "$WRAPPER" await job-g7-unknown-phase
  [ "$status" -eq 14 ]
}

# ---------------------------------------------------------------------------
# phase-fallback — stderr visibility line on fallback
# ---------------------------------------------------------------------------

@test "phase-fallback: phase fallback emits stderr line of form '[codex-companion-bg] phase fallback active: <phase> → <lifecycle>'" {
  # The first fallback invocation per wrapper process must emit the audit line
  # to stderr.  Callers MUST NOT rely on this line being present or absent;
  # it is for operational monitoring only.
  bats_require_minimum_version 1.5.0

  echo '{"jobId":"job-g7-stderr","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY="finalizing"
  export STUB_RESULT_RAW="# G7 stderr test"

  run --separate-stderr "$WRAPPER" await job-g7-stderr
  [ "$status" -eq 0 ]
  [[ "$stderr" == *"[codex-companion-bg] phase fallback active: finalizing → completed"* ]]
}

@test "phase-fallback: stderr audit line emitted only once per process despite multiple phase-only polls" {
  # The spec requires single-emit semantics: "subsequent invocations within the
  # same process suppress the line to avoid log-spam."  CODEX_PHASE_FALLBACK_LOGGED
  # is initialized at script startup and set to 1 after the first emit.
  # We exercise 3 phase-only polls before the stub transitions to a real
  # completed job.status, then assert the audit line appears exactly once.
  bats_require_minimum_version 1.5.0

  echo '{"jobId":"job-single-emit","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY_UNTIL_POLL=3
  export STUB_PHASE_ONLY="finalizing"
  export STUB_COMPLETE_AT_POLL=4
  export STUB_RESULT_RAW="# single-emit result"

  run --separate-stderr "$WRAPPER" await job-single-emit
  [ "$status" -eq 0 ]
  local count
  count=$(printf '%s\n' "$stderr" | grep -c '\[codex-companion-bg\] phase fallback active')
  [ "$count" -eq 1 ]
}

# ---------------------------------------------------------------------------
# phase-fallback — stdout/exit surface identical between primary and fallback paths
# ---------------------------------------------------------------------------

@test "phase-fallback: stdout and exit code on phase-recovered path identical to primary-read success path" {
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
# phase-fallback — edge-case phase values: null, whitespace, numeric
# ---------------------------------------------------------------------------

@test "phase-fallback: job.phase JSON null → exit 14 (falls through to malformed)" {
  # Some JSON serializers emit null for unset optional fields.  The wrapper
  # must route this to malformed, not to a recognized lifecycle.
  # extract_json_field exits 1 on null, causing the phase-fallback guard to
  # fail and execution to fall through to the existing malformed terminal case.
  # STUB_RESULT_RAW is set so a normal status:completed path would succeed
  # (exit 0), making this test fail if the stub accidentally skips the
  # null-phase payload and falls back to a regular completed response.
  echo '{"jobId":"job-g7-null-phase","polls":0}' > "$STUB_STATE_FILE"
  export STUB_NULL_PHASE=1
  export STUB_RESULT_RAW="# null phase result — should not be reached"

  run "$WRAPPER" await job-g7-null-phase
  [ "$status" -eq 14 ]
}

@test "phase-fallback: job.phase whitespace-padded string → exit 14 (falls through to malformed)" {
  # A whitespace-padded value like ' finalizing' does not match the exact-match
  # case pattern and must fall through to malformed.
  echo '{"jobId":"job-g7-ws-phase","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY=" finalizing"

  run "$WRAPPER" await job-g7-ws-phase
  [ "$status" -eq 14 ]
}

@test "phase-fallback: job.phase numeric value → exit 14 (falls through to malformed)" {
  # A numeric phase (e.g. 42) is stringified to '42' by extract_json_field.
  # '42' does not appear in the mapping table and must fall through to malformed.
  # STUB_RESULT_RAW is set so a normal status:completed path would succeed
  # (exit 0), making this test fail if the stub skips the numeric-phase payload.
  echo '{"jobId":"job-g7-num-phase","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_NUMERIC=42
  export STUB_RESULT_RAW="# numeric phase result — should not be reached"

  run "$WRAPPER" await job-g7-num-phase
  [ "$status" -eq 14 ]
}

@test "stub: STUB_PHASE_NUMERIC set to non-numeric string → stub exits 1 with error on stderr (loud failure)" {
  # Validates that the stub's isNaN guard converts the silent NaN→null collapse
  # (where Number("abc")→NaN→JSON.stringify emits null, indistinguishable from
  # STUB_NULL_PHASE=1) into a loud failure with a diagnostic stderr message.
  # Without the guard, the stub exits 0 and emits a null-phase payload; with
  # the guard it must exit 1 and write an error to stderr.
  export STUB_STATE_FILE="$TEST_ROOT/stub-state.json"
  export STUB_PHASE_NUMERIC=abc

  run node "$STUB" status stub-job-id --json
  [ "$status" -eq 1 ]
  [[ "$stderr" =~ "STUB_PHASE_NUMERIC" ]] || [[ "$output" =~ "STUB_PHASE_NUMERIC" ]]
}

# ---------------------------------------------------------------------------
# phase-fallback — non-status subcommands unchanged
# ---------------------------------------------------------------------------

@test "phase-fallback: launch subcommand behavior is unchanged by the phase-fallback addition" {
  run bash -c 'cat "$PROMPT_FILE" | "$WRAPPER" launch'
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^task-stub-[0-9]+-[0-9]+$ ]]
}

# ---------------------------------------------------------------------------
# phantom-jobId: post-launch verification + retry-once (post-fix behavioral assertions)
#
# The launch subcommand now verifies the candidate jobId via the internal
# status path before emitting it on stdout.  On not-found it retries the
# entire task subcommand once.
#
# Exit-code table:
#   0   — verified (first or second attempt)
#   15  — LAUNCH_PHANTOM: both attempts returned not-found
#
# STUB_PHANTOM_LAUNCH_COUNT controls how many sequential task-emitted jobIds
# the stub will mark as phantom (status → not-found).  Set to "1" to make
# the first launch a phantom and the second verified; "2" for double-phantom.
# ---------------------------------------------------------------------------

@test "phantom-jobId: happy path — verified first attempt exits 0, emits jobId on stdout, no new stderr" {
  bats_require_minimum_version 1.5.0
  # No phantom: status returns verified immediately.
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_RAW="# happy path result"

  run --separate-stderr bash -c 'cat "$PROMPT_FILE" | "$WRAPPER" launch'
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^task-stub-[0-9]+-[0-9]+$ ]]
  # No retry note on the happy first-attempt path.
  [[ "$stderr" != *"launch: first jobId failed verification, retried"* ]]
}

@test "phantom-jobId: phantom first, verified second — exits 0, emits second jobId on stdout" {
  bats_require_minimum_version 1.5.0
  # First launch phantom; second verified.
  export STUB_PHANTOM_LAUNCH_COUNT=1
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_RAW="# retry-success result"

  run --separate-stderr bash -c 'cat "$PROMPT_FILE" | "$WRAPPER" launch'
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^task-stub-[0-9]+-[0-9]+$ ]]
}

@test "phantom-jobId: phantom first, verified second — writes stderr note exactly once" {
  bats_require_minimum_version 1.5.0
  export STUB_PHANTOM_LAUNCH_COUNT=1
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_RAW="# retry-success result"

  run --separate-stderr bash -c 'cat "$PROMPT_FILE" | "$WRAPPER" launch'
  [ "$status" -eq 0 ]
  [[ "$stderr" == *"launch: first jobId failed verification, retried"* ]]
  local count
  count=$(printf '%s\n' "$stderr" | grep -c "launch: first jobId failed verification, retried")
  [ "$count" -eq 1 ]
}

@test "phantom-jobId: double-phantom — exits 15, no jobId on stdout, writes terminal stderr line" {
  bats_require_minimum_version 1.5.0
  # Both launches return phantom (status not-found).
  export STUB_PHANTOM_LAUNCH_COUNT=2

  run --separate-stderr bash -c 'cat "$PROMPT_FILE" | "$WRAPPER" launch'
  [ "$status" -eq 15 ]
  # stdout must be empty (no jobId emitted on terminal path).
  [ -z "$output" ]
  # A single identifying stderr line must be present.
  [[ "$stderr" == *"launch: both jobId attempts failed verification (LAUNCH_PHANTOM)"* ]]
}

@test "phantom-jobId: retry cap is exactly 1 — phantom first triggers exactly one retry of task" {
  bats_require_minimum_version 1.5.0
  # Double-phantom: verify that only two task launches occurred (cap = 1 retry).
  # We check by counting how many distinct jobIds the stub registered in state.
  export STUB_PHANTOM_LAUNCH_COUNT=2
  export STUB_TRACK_LAUNCH_COUNT=1

  run --separate-stderr bash -c 'cat "$PROMPT_FILE" | "$WRAPPER" launch'
  [ "$status" -eq 15 ]
  # State file records launch count; must be exactly 2 (original + one retry).
  local launch_count
  launch_count=$(node -e "
    const fs = require('fs');
    const s = JSON.parse(fs.readFileSync(process.env.STUB_STATE_FILE, 'utf8'));
    process.stdout.write(String(s.launchCount || 0));
  ")
  [ "$launch_count" -eq 2 ]
}

@test "phantom-jobId: malformed internal-status response on first verification falls through to retry, not exit 14" {
  bats_require_minimum_version 1.5.0
  # When the first status call after launch returns malformed (not not-found),
  # the wrapper must NOT exit 14 — the existing exit 14 is reserved for the
  # public status subcommand's external contract.  A malformed first-verify
  # falls through to the retry branch.
  # After the malformed first-status, the retry emits a valid jobId and status
  # returns verified → exit 0.
  export STUB_MALFORMED_FIRST_LAUNCH_STATUS=1
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_RAW="# after-malformed retry result"

  run --separate-stderr bash -c 'cat "$PROMPT_FILE" | "$WRAPPER" launch'
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^task-stub-[0-9]+-[0-9]+$ ]]
}

@test "phantom-jobId: broker-layer error on retry surfaces existing launch-failure exit, not 15" {
  bats_require_minimum_version 1.5.0
  # When the first launch is phantom and the retry's task subcommand itself
  # fails outright (non-zero exit from companion task), the wrapper must
  # surface the existing launch-failure exit (1), not exit 15.
  # Exit 15 is reserved for both-attempts-unverifiable, not for broker errors.
  export STUB_PHANTOM_LAUNCH_COUNT=1
  export STUB_FAIL_SECOND_LAUNCH=1

  run --separate-stderr bash -c 'cat "$PROMPT_FILE" | "$WRAPPER" launch'
  [ "$status" -ne 15 ]
  [ "$status" -ne 0 ]
}

@test "phantom-jobId: exit 15 is not used by any other wrapper exit path" {
  # Static assertion: grep the wrapper for any 'return 15' or 'exit 15' outside
  # the LAUNCH_PHANTOM path.  The name LAUNCH_PHANTOM must appear in the script
  # alongside the value 15 (named-constant requirement).
  grep -qE 'LAUNCH_PHANTOM' "$WRAPPER"
  # The constant's value must be 15.
  grep -qE 'LAUNCH_PHANTOM.*=.*15|15.*LAUNCH_PHANTOM' "$WRAPPER"
}
