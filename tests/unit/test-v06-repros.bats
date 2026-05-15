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
  echo '{"jobId":"job-phase-primary-running","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=2
  export STUB_RESULT_RAW="# phase-fallback primary running review"

  run "$WRAPPER" await job-phase-primary-running
  [ "$status" -eq 0 ]
  [[ "$output" == *"phase-fallback primary running review"* ]]
}

@test "phase-fallback: primary path — job.status 'completed' → emits completed lifecycle, exits 0" {
  # job.status is present and resolved to "completed"; fallback must not fire.
  echo '{"jobId":"job-phase-primary-completed","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_RAW="# phase-fallback primary completed review"

  run "$WRAPPER" await job-phase-primary-completed
  [ "$status" -eq 0 ]
  [[ "$output" == *"phase-fallback primary completed review"* ]]
}

@test "phase-fallback: primary path — job.status unrecognized value → malformed (exit 14), fallback never fires" {
  # When job.status IS present but carries an unknown value the wrapper must
  # still emit malformed.  The phase fallback must not be consulted at all
  # when job.status is present.
  echo '{"jobId":"job-phase-badstatus","polls":0}' > "$STUB_STATE_FILE"
  export STUB_TERMINAL_STATUS="unknown-status-value"
  export STUB_COMPLETE_AT_POLL=1

  run "$WRAPPER" await job-phase-badstatus
  [ "$status" -eq 14 ]
}

# ---------------------------------------------------------------------------
# phase-fallback — phase fallback: job.status absent, job.phase recognized
# ---------------------------------------------------------------------------

@test "phase-fallback: canonical repro — job.status absent, job.phase 'finalizing' → exits 0, emits completed:completed" {
  # This is the canonical reproduction case for the phase-fallback feature.
  # Before the fix the wrapper emitted malformed
  # (exit 14); after the fix it must exit 0 via the completed lifecycle.
  echo '{"jobId":"job-phase-finalizing","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY="finalizing"
  export STUB_RESULT_RAW="# phase-fallback finalizing review"

  run "$WRAPPER" await job-phase-finalizing
  [ "$status" -eq 0 ]
  [[ "$output" == *"phase-fallback finalizing review"* ]]
}

@test "phase-fallback: job.status absent, job.phase 'done' → exits 0, emits completed lifecycle" {
  echo '{"jobId":"job-phase-done","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY="done"
  export STUB_RESULT_RAW="# phase-fallback done review"

  run "$WRAPPER" await job-phase-done
  [ "$status" -eq 0 ]
  [[ "$output" == *"phase-fallback done review"* ]]
}

@test "phase-fallback: job.status absent, job.phase 'reviewing' → exits 0, emits completed lifecycle" {
  echo '{"jobId":"job-phase-reviewing","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY="reviewing"
  export STUB_RESULT_RAW="# phase-fallback reviewing review"

  run "$WRAPPER" await job-phase-reviewing
  [ "$status" -eq 0 ]
  [[ "$output" == *"phase-fallback reviewing review"* ]]
}

@test "phase-fallback: job.status absent, job.phase 'running' → emits running lifecycle (poll continues), then completes" {
  # Phase 'running' maps to the running lifecycle; the await loop continues
  # polling.  We use STUB_COMPLETE_AT_POLL so the stub transitions from
  # phase-only running to a real job.status completed after 2 polls.
  echo '{"jobId":"job-phase-phase-running","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY_UNTIL_POLL=2
  export STUB_PHASE_ONLY="running"
  export STUB_COMPLETE_AT_POLL=3
  export STUB_RESULT_RAW="# phase-fallback phase-running completed"

  run "$WRAPPER" await job-phase-phase-running
  [ "$status" -eq 0 ]
  [[ "$output" == *"phase-fallback phase-running completed"* ]]
}

@test "phase-fallback: job.status absent, job.phase 'starting' → running lifecycle (poll continues), then completes" {
  echo '{"jobId":"job-phase-starting","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY_UNTIL_POLL=2
  export STUB_PHASE_ONLY="starting"
  export STUB_COMPLETE_AT_POLL=3
  export STUB_RESULT_RAW="# phase-fallback starting completed"

  run "$WRAPPER" await job-phase-starting
  [ "$status" -eq 0 ]
  [[ "$output" == *"phase-fallback starting completed"* ]]
}

@test "phase-fallback: job.status absent, job.phase 'investigating' → running lifecycle, then completes" {
  echo '{"jobId":"job-phase-investigating","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY_UNTIL_POLL=2
  export STUB_PHASE_ONLY="investigating"
  export STUB_COMPLETE_AT_POLL=3
  export STUB_RESULT_RAW="# phase-fallback investigating completed"

  run "$WRAPPER" await job-phase-investigating
  [ "$status" -eq 0 ]
  [[ "$output" == *"phase-fallback investigating completed"* ]]
}

@test "phase-fallback: job.status absent, job.phase 'editing' → running lifecycle, then completes" {
  echo '{"jobId":"job-phase-editing","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY_UNTIL_POLL=2
  export STUB_PHASE_ONLY="editing"
  export STUB_COMPLETE_AT_POLL=3
  export STUB_RESULT_RAW="# phase-fallback editing completed"

  run "$WRAPPER" await job-phase-editing
  [ "$status" -eq 0 ]
  [[ "$output" == *"phase-fallback editing completed"* ]]
}

@test "phase-fallback: job.status absent, job.phase 'verifying' → running lifecycle, then completes" {
  echo '{"jobId":"job-phase-verifying","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY_UNTIL_POLL=2
  export STUB_PHASE_ONLY="verifying"
  export STUB_COMPLETE_AT_POLL=3
  export STUB_RESULT_RAW="# phase-fallback verifying completed"

  run "$WRAPPER" await job-phase-verifying
  [ "$status" -eq 0 ]
  [[ "$output" == *"phase-fallback verifying completed"* ]]
}

# ---------------------------------------------------------------------------
# phase-fallback — terminal cases: both absent, or phase unrecognized
# ---------------------------------------------------------------------------

@test "phase-fallback: both job.status and job.phase absent → exit 14 (malformed), genuine protocol violation" {
  # When neither field is present the existing malformed terminal case must be
  # preserved unchanged — this is not a phase the wrapper is asked to recover.
  echo '{"jobId":"job-phase-both-absent","polls":0}' > "$STUB_STATE_FILE"
  export STUB_NO_STATUS_NO_PHASE=1

  run "$WRAPPER" await job-phase-both-absent
  [ "$status" -eq 14 ]
}

@test "phase-fallback: job.status absent, job.phase empty string → exit 14 (falls through to malformed)" {
  # Empty string is outside the mapping table; the wrapper must not treat it as
  # a recognized phase.  Falls through to existing malformed terminal case.
  echo '{"jobId":"job-phase-empty-phase","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY=""
  export STUB_EMPTY_PHASE=1

  run "$WRAPPER" await job-phase-empty-phase
  [ "$status" -eq 14 ]
}

@test "phase-fallback: job.status absent, job.phase unknown literal → exit 14 (falls through to malformed)" {
  # An unknown literal (not in the mapping table) must fall through to malformed.
  echo '{"jobId":"job-phase-unknown-phase","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY="some-future-phase-not-in-table"

  run "$WRAPPER" await job-phase-unknown-phase
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

  echo '{"jobId":"job-phase-stderr","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY="finalizing"
  export STUB_RESULT_RAW="# phase-fallback stderr test"

  run --separate-stderr "$WRAPPER" await job-phase-stderr
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
  echo '{"jobId":"job-phase-primary-cmp","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_RAW="# identical output"
  run --separate-stderr "$WRAPPER" await job-phase-primary-cmp
  local primary_status="$status"
  local primary_output="$output"

  # Reset state for fallback path: job.status absent, job.phase = "finalizing"
  echo '{"jobId":"job-phase-fallback-cmp","polls":0}' > "$STUB_STATE_FILE"
  unset STUB_COMPLETE_AT_POLL
  export STUB_PHASE_ONLY="finalizing"
  export STUB_RESULT_RAW="# identical output"
  run --separate-stderr "$WRAPPER" await job-phase-fallback-cmp
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
  echo '{"jobId":"job-phase-null-phase","polls":0}' > "$STUB_STATE_FILE"
  export STUB_NULL_PHASE=1
  export STUB_RESULT_RAW="# null phase result — should not be reached"

  run "$WRAPPER" await job-phase-null-phase
  [ "$status" -eq 14 ]
}

@test "phase-fallback: job.phase whitespace-padded string → exit 14 (falls through to malformed)" {
  # A whitespace-padded value like ' finalizing' does not match the exact-match
  # case pattern and must fall through to malformed.
  echo '{"jobId":"job-phase-ws-phase","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_ONLY=" finalizing"

  run "$WRAPPER" await job-phase-ws-phase
  [ "$status" -eq 14 ]
}

@test "phase-fallback: job.phase numeric value → exit 14 (falls through to malformed)" {
  # A numeric phase (e.g. 42) is stringified to '42' by extract_json_field.
  # '42' does not appear in the mapping table and must fall through to malformed.
  # STUB_RESULT_RAW is set so a normal status:completed path would succeed
  # (exit 0), making this test fail if the stub skips the numeric-phase payload.
  echo '{"jobId":"job-phase-num-phase","polls":0}' > "$STUB_STATE_FILE"
  export STUB_PHASE_NUMERIC=42
  export STUB_RESULT_RAW="# numeric phase result — should not be reached"

  run "$WRAPPER" await job-phase-num-phase
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
  # Assert the emitted jobId is NOT the phantom (first) jobId. Without this,
  # a regression that silently emits job_id_1 (the unverified phantom) would
  # still pass the regex check above, since both jobIds match
  # task-stub-<pid>-<ts>. Verify against the phantomJobIds list the stub
  # persists in state (stub-codex-companion.mjs line ~171).
  local phantom_ids
  phantom_ids=$(node -e "
    const fs = require('fs');
    const s = JSON.parse(fs.readFileSync(process.env.STUB_STATE_FILE, 'utf8'));
    process.stdout.write((s.phantomJobIds || []).join('\n'));
  ")
  # The emitted jobId (output) must not appear in the phantom list.
  ! printf '%s\n' "$phantom_ids" | grep -qFx "$output"
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

@test "phantom-jobId: hard-error internal-status response on first verification falls through to retry" {
  bats_require_minimum_version 1.5.0
  # A companion crash / network timeout / permissions failure during the
  # first verification call must NOT be treated as a broker acknowledgement.
  # poll_status emits 'error' lifecycle on any non-zero status exit whose
  # stderr does NOT match /No (finished )?job found/. verify_job_id MUST
  # treat 'error' as unverified (not as the broker confirming the job).
  #
  # Setup: the first jobId emitted by task is NOT phantom (no STUB_PHANTOM_*),
  # but the very first status call hard-errors. The retry's task launches a
  # second jobId which verifies cleanly. Expected: exit 0, second jobId on
  # stdout, retry note on stderr.
  export STUB_ERROR_FIRST_LAUNCH_STATUS=1
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_RAW="# after-hard-error retry result"

  run --separate-stderr bash -c 'cat "$PROMPT_FILE" | "$WRAPPER" launch'
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^task-stub-[0-9]+-[0-9]+$ ]]
  # The retry note proves the wrapper went through the retry path (rather than
  # silently emitting the unverified first jobId).
  [[ "$stderr" == *"launch: first jobId failed verification, retried"* ]]
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
  # Positive assertion. The negative-only checks below would silently accept
  # e.g. exit 13 or 14, which would indicate the wrapper misroutes the
  # retry-launch failure through a different error handler. The stub's
  # STUB_FAIL_SECOND_LAUNCH path calls fail(..., 1); run_task_once propagates
  # the companion's exit (return "$SPAWN_RC"); launch_subcommand returns 1.
  [ "$status" -eq 1 ]
  [ "$status" -ne 15 ]
  [ "$status" -ne 0 ]
}

@test "phantom-jobId: LAUNCH_PHANTOM constant exists, equals 15, and no other exit path emits 15" {
  # The name LAUNCH_PHANTOM must appear in the script (named-constant requirement).
  grep -qE 'LAUNCH_PHANTOM' "$WRAPPER"
  # The constant's value must be 15.
  grep -qE 'LAUNCH_PHANTOM.*=.*15|15.*LAUNCH_PHANTOM' "$WRAPPER"

  # Actively assert no other code path emits exit 15. Strip comments (anything
  # from '#' to end-of-line) before scanning so that prose mentions of
  # "exit 15" in comments don't trip the assertion. The only legitimate path
  # to exit 15 must go through "$LAUNCH_PHANTOM".
  local bare_15_lines
  bare_15_lines=$(sed 's/#.*$//' "$WRAPPER" | grep -nE '(\<return\>|\<exit\>)[[:space:]]+15(\>|$)' || true)
  if [ -n "$bare_15_lines" ]; then
    printf 'unexpected bare return/exit 15 outside LAUNCH_PHANTOM:\n%s\n' "$bare_15_lines" >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# disk-state fallback — await recovers from broker not-found via on-disk state
#
# The disk-fallback path activates only when:
#   1. The `await` subcommand polls a jobId and poll_status returns not-found.
#   2. $CLAUDE_PLUGIN_DATA is set and non-empty.
#   3. The resolved broker state-file path is absolute.
#
# Path layout mirrors the broker (lib/state.mjs:29-43):
#   $CLAUDE_PLUGIN_DATA/state/<slug>-<sha256(realpath)[:16]>/state.json
#   $CLAUDE_PLUGIN_DATA/state/<slug>-<sha256(realpath)[:16]>/jobs/<jobId>.json
#
# Helpers: _disk_state_dir, _write_disk_completed_fixtures, _write_disk_failed_fixtures
#   Compute the broker state-dir path and write test fixtures at that path.
# ---------------------------------------------------------------------------

# Compute the broker state-dir path the same way lib/state.mjs does, from a
# given realpath-canonical workspace root.  Emits the absolute state-dir path
# on stdout (no trailing slash).
# Both slugSource and the hash use canonicalRoot (the argument) so the
# computation matches the production code exactly.
_disk_state_dir() {
  local plugin_data="$1" workspace_realpath="$2"
  node -e "
const crypto = require('crypto');
const path = require('path');
const pluginData = process.argv[1];
const canonicalRoot = process.argv[2];
const slugSource = path.basename(canonicalRoot) || 'workspace';
const slug = slugSource.replace(/[^a-zA-Z0-9._-]+/g, '-').replace(/^-+|-+$/, '') || 'workspace';
const hash = crypto.createHash('sha256').update(canonicalRoot).digest('hex').slice(0, 16);
process.stdout.write(path.join(pluginData, 'state', slug + '-' + hash));
" -- "$plugin_data" "$workspace_realpath"
}

# Write valid disk fixtures for a completed job at the broker-canonical path.
# Args: <plugin_data_dir> <job_id> <raw_output_text> [<workspace_realpath>]
# The wrapper runs from $REPO_ROOT; we use its realpath as the workspace root.
# Uses jq to build JSON so that metacharacter values in raw_output are safe.
_write_disk_completed_fixtures() {
  local plugin_data="$1" job_id="$2" raw_output="$3"
  local workspace="${4:-$(cd "$REPO_ROOT" && pwd -P)}"
  local state_dir
  state_dir=$(_disk_state_dir "$plugin_data" "$workspace")
  mkdir -p "$state_dir/jobs"
  # state.json: jobs array with an entry whose id matches jobId
  jq -n --arg id "$job_id" \
    '{"version":1,"config":{"stopReviewGate":false},"jobs":[{"id":$id,"status":"completed","updatedAt":"2026-05-14T00:00:00.000Z","createdAt":"2026-05-14T00:00:00.000Z"}]}' \
    > "$state_dir/state.json"
  # jobs/<jobId>.json: per-job record with result.rawOutput
  jq -n --arg id "$job_id" --arg raw "$raw_output" \
    '{"id":$id,"status":"completed","result":{"rawOutput":$raw}}' \
    > "$state_dir/jobs/$job_id.json"
}

# Write disk fixtures for a failed job (no rawOutput, has errorMessage).
# Uses jq to build JSON so that metacharacter values in error_message are safe.
_write_disk_failed_fixtures() {
  local plugin_data="$1" job_id="$2" error_message="$3"
  local workspace="${4:-$(cd "$REPO_ROOT" && pwd -P)}"
  local state_dir
  state_dir=$(_disk_state_dir "$plugin_data" "$workspace")
  mkdir -p "$state_dir/jobs"
  jq -n --arg id "$job_id" \
    '{"version":1,"config":{"stopReviewGate":false},"jobs":[{"id":$id,"status":"failed","updatedAt":"2026-05-14T00:00:00.000Z","createdAt":"2026-05-14T00:00:00.000Z"}]}' \
    > "$state_dir/state.json"
  jq -n --arg id "$job_id" --arg err "$error_message" \
    '{"id":$id,"status":"failed","errorMessage":$err}' \
    > "$state_dir/jobs/$job_id.json"
}

# ---------------------------------------------------------------------------
# disk-state fallback — hit path: state.json lists jobId, jobs/<id>.json
# has status completed and populated rawOutput → exit 0, recovered output,
# recovery note on stderr
# ---------------------------------------------------------------------------

@test "disk-state fallback: recovers completed jobId from disk on broker not-found (hit path)" {
  bats_require_minimum_version 1.5.0
  command -v jq >/dev/null 2>&1 || skip "jq not on PATH — required for fixture construction"

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  local job_id="job-disk-hit-completed"
  # Broker always returns not-found for this jobId.
  export STUB_JOB_NOT_FOUND=1

  # Write valid completed fixtures to disk.
  _write_disk_completed_fixtures "$plugin_data" "$job_id" "# disk-fallback recovered output"

  run --separate-stderr "$WRAPPER" await "$job_id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"disk-fallback recovered output"* ]]
  [[ "$stderr" == *"await: recovered $job_id from disk (broker reported not-found)"* ]]
}

# ---------------------------------------------------------------------------
# disk-state fallback — miss path: state.json absent → exit 11, no recovery
# ---------------------------------------------------------------------------

@test "disk-state fallback: state.json absent → exits 11, no recovery note" {
  bats_require_minimum_version 1.5.0

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  local job_id="job-disk-no-state-file"
  export STUB_JOB_NOT_FOUND=1
  # No fixtures written: state.json does not exist.

  run --separate-stderr "$WRAPPER" await "$job_id"
  [ "$status" -eq 11 ]
  [[ "$stderr" != *"await: recovered"* ]]
}

# ---------------------------------------------------------------------------
# disk-state fallback — miss path: state.json contains invalid JSON → exit 11
# ---------------------------------------------------------------------------

@test "disk-state fallback: invalid JSON in state.json → exits 11, no recovery note" {
  bats_require_minimum_version 1.5.0

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  local job_id="job-disk-invalid-state-json"
  local workspace
  workspace=$(cd "$REPO_ROOT" && pwd -P)
  local state_dir
  state_dir=$(_disk_state_dir "$plugin_data" "$workspace")
  mkdir -p "$state_dir/jobs"
  printf 'not valid json at all' > "$state_dir/state.json"

  export STUB_JOB_NOT_FOUND=1

  run --separate-stderr "$WRAPPER" await "$job_id"
  [ "$status" -eq 11 ]
  [[ "$stderr" != *"await: recovered"* ]]
}

# ---------------------------------------------------------------------------
# disk-state fallback — miss path: state.json valid but jobId not in jobs[]
# → exit 11
# ---------------------------------------------------------------------------

@test "disk-state fallback: jobId absent from state.json jobs array → exits 11, no recovery note" {
  bats_require_minimum_version 1.5.0

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  local job_id="job-disk-not-in-jobs-array"
  local workspace
  workspace=$(cd "$REPO_ROOT" && pwd -P)
  local state_dir
  state_dir=$(_disk_state_dir "$plugin_data" "$workspace")
  mkdir -p "$state_dir/jobs"
  # state.json lists a different jobId
  printf '%s\n' '{"version":1,"config":{},"jobs":[{"id":"some-other-job-id","status":"completed"}]}' \
    > "$state_dir/state.json"

  export STUB_JOB_NOT_FOUND=1

  run --separate-stderr "$WRAPPER" await "$job_id"
  [ "$status" -eq 11 ]
  [[ "$stderr" != *"await: recovered"* ]]
}

# ---------------------------------------------------------------------------
# disk-state fallback — miss path: state.json lists jobId but jobs/<id>.json
# absent → exit 11, no recovery note
# ---------------------------------------------------------------------------

@test "disk-state fallback: per-job record absent when jobId in state.json → exits 11, no recovery note" {
  bats_require_minimum_version 1.5.0

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  local job_id="job-disk-job-file-absent"
  local workspace
  workspace=$(cd "$REPO_ROOT" && pwd -P)
  local state_dir
  state_dir=$(_disk_state_dir "$plugin_data" "$workspace")
  mkdir -p "$state_dir/jobs"
  # state.json lists the jobId, but jobs/<id>.json does not exist
  printf '%s\n' "{\"version\":1,\"config\":{},\"jobs\":[{\"id\":\"$job_id\",\"status\":\"completed\"}]}" \
    > "$state_dir/state.json"
  # Intentionally NO jobs/$job_id.json

  export STUB_JOB_NOT_FOUND=1

  run --separate-stderr "$WRAPPER" await "$job_id"
  [ "$status" -eq 11 ]
  [[ "$stderr" != *"await: recovered"* ]]
}

# ---------------------------------------------------------------------------
# disk-state fallback — miss path: state.json lists jobId but jobs/<id>.json
# contains invalid JSON → exit 11, no recovery note
# ---------------------------------------------------------------------------

@test "disk-state fallback: per-job record invalid JSON → exits 11 (miss), stderr diagnostic, no recovery note" {
  bats_require_minimum_version 1.5.0

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  local job_id="job-disk-job-file-bad-json"
  local workspace
  workspace=$(cd "$REPO_ROOT" && pwd -P)
  local state_dir
  state_dir=$(_disk_state_dir "$plugin_data" "$workspace")
  mkdir -p "$state_dir/jobs"
  printf '%s\n' "{\"version\":1,\"config\":{},\"jobs\":[{\"id\":\"$job_id\",\"status\":\"completed\"}]}" \
    > "$state_dir/state.json"
  printf 'not valid json' > "$state_dir/jobs/$job_id.json"

  export STUB_JOB_NOT_FOUND=1

  run --separate-stderr "$WRAPPER" await "$job_id"
  # Spec bullet 9: invalid JSON in the per-job record is treated as a miss
  # equivalent to jobId-not-in-state-json → exit 11 (terminal not-found).
  # A stderr diagnostic is permitted (not the "disk-recovery note"); the
  # "without emitting the disk-recovery stderr note" clause bars only the
  # "await: recovered <jobId> from disk..." success-recovery line.
  [ "$status" -eq 11 ]
  [[ "$stderr" == *"malformed status field"* ]]
  [[ "$stderr" != *"await: recovered"* ]]
}

# ---------------------------------------------------------------------------
# disk-state fallback — $CLAUDE_PLUGIN_DATA unset → path unresolvable, exit 11,
# no file read attempt (path-resolution hard-stop)
# ---------------------------------------------------------------------------

@test "disk-state fallback: CLAUDE_PLUGIN_DATA unset → exits 11 without reading any disk file" {
  bats_require_minimum_version 1.5.0

  # Unset CLAUDE_PLUGIN_DATA so the fallback cannot resolve the state path.
  unset CLAUDE_PLUGIN_DATA

  local job_id="job-disk-no-plugin-data"
  export STUB_JOB_NOT_FOUND=1

  run --separate-stderr "$WRAPPER" await "$job_id"
  [ "$status" -eq 11 ]
  [[ "$stderr" != *"await: recovered"* ]]

  # Structural: verify the wrapper contains an explicit path-resolution hard-stop
  # for absent/empty CLAUDE_PLUGIN_DATA — confirming no file under /tmp or any
  # relative path is read when the env var is unset.  This pins the guard contract
  # against regression: if the guard is removed the assertion fails explicitly,
  # naming the broken invariant rather than relying on incidental ENOENT behavior.
  grep -qE '\[ -z.*CLAUDE_PLUGIN_DATA' "$WRAPPER" \
    || { printf 'CLAUDE_PLUGIN_DATA path-resolution hard-stop guard absent from wrapper\n' >&2; return 1; }
  # The guard must be immediately followed by a bare return (not a path assignment or
  # /tmp fallback).  Extract the two lines after the guard and assert return 1 is present.
  local guard_line_num
  guard_line_num=$(grep -n '\[ -z.*CLAUDE_PLUGIN_DATA' "$WRAPPER" | head -1 | cut -d: -f1)
  local after_guard
  after_guard=$(sed -n "$((guard_line_num+1)),$((guard_line_num+2))p" "$WRAPPER")
  printf '%s\n' "$after_guard" | grep -qE 'return 1' \
    || { printf 'CLAUDE_PLUGIN_DATA guard does not immediately return 1 — /tmp or relative path construction possible\n' >&2; return 1; }
}

@test "disk-state fallback: CLAUDE_PLUGIN_DATA empty string → exits 11 without reading any disk file" {
  bats_require_minimum_version 1.5.0

  export CLAUDE_PLUGIN_DATA=""

  local job_id="job-disk-empty-plugin-data"
  export STUB_JOB_NOT_FOUND=1

  run --separate-stderr "$WRAPPER" await "$job_id"
  [ "$status" -eq 11 ]
  [[ "$stderr" != *"await: recovered"* ]]
}

# ---------------------------------------------------------------------------
# disk-state fallback — failed status in per-job record: exit matches
# broker-served failed path, errorMessage on stderr, nothing on stdout
# ---------------------------------------------------------------------------

@test "disk-state fallback: failed status in disk record → non-zero exit, errorMessage on stderr, nothing on stdout" {
  bats_require_minimum_version 1.5.0
  command -v jq >/dev/null 2>&1 || skip "jq not on PATH — required for fixture construction"

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  local job_id="job-disk-failed-record"
  export STUB_JOB_NOT_FOUND=1
  _write_disk_failed_fixtures "$plugin_data" "$job_id" "disk-fallback failed error message"

  run --separate-stderr "$WRAPPER" await "$job_id"
  # Non-zero exit (failed path)
  [ "$status" -ne 0 ]
  # errorMessage surfaced on stderr
  [[ "$stderr" == *"disk-fallback failed error message"* ]]
  # Nothing on stdout
  [ -z "$output" ]
}

# ---------------------------------------------------------------------------
# disk-state fallback — happy path unchanged: broker-served completed result
# does NOT consult state.json at all (no CLAUDE_PLUGIN_DATA read)
# ---------------------------------------------------------------------------

@test "disk-state fallback: happy path (broker serves result) → no disk read, no recovery note" {
  bats_require_minimum_version 1.5.0

  # No CLAUDE_PLUGIN_DATA set; if the fallback fires incorrectly it will fail
  # to resolve the path and could alter behavior.
  unset CLAUDE_PLUGIN_DATA

  echo '{"jobId":"job-disk-happy-path","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_RAW="# disk-fallback happy path broker result"

  run --separate-stderr "$WRAPPER" await job-disk-happy-path
  [ "$status" -eq 0 ]
  [[ "$output" == *"disk-fallback happy path broker result"* ]]
  # No recovery note in stderr
  [[ "$stderr" != *"await: recovered"* ]]
}

# ---------------------------------------------------------------------------
# disk-state fallback — stderr-once semantics: recovery note emitted exactly
# once per recovery event
# ---------------------------------------------------------------------------

@test "disk-state fallback: recovery note emitted exactly once per recovery event" {
  bats_require_minimum_version 1.5.0
  command -v jq >/dev/null 2>&1 || skip "jq not on PATH — required for fixture construction"

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  local job_id="job-disk-stderr-once"
  export STUB_JOB_NOT_FOUND=1
  _write_disk_completed_fixtures "$plugin_data" "$job_id" "# disk-fallback stderr-once test"

  run --separate-stderr "$WRAPPER" await "$job_id"
  [ "$status" -eq 0 ]

  local count
  count=$(printf '%s\n' "$stderr" | grep -c "await: recovered $job_id from disk")
  [ "$count" -eq 1 ]
}

# ---------------------------------------------------------------------------
# disk-state fallback — disk-read budget: exactly 2 reads per not-found event
# (verified by inspecting wrapper source for absence of glob/scan patterns)
# ---------------------------------------------------------------------------

@test "disk-state fallback: no glob or directory-scan in the not-found fallback code path" {
  # Structural assertion: the disk-state fallback must not use glob patterns,
  # find, ls, or directory enumeration. Verify by inspecting the wrapper source.
  # The fallback logic should only do targeted reads of state.json and
  # jobs/<jobId>.json.
  local fallback_code
  fallback_code=$(sed 's/#.*$//' "$WRAPPER")
  # Must not contain glob patterns (*/jobs/* or find/ls in the disk fallback).
  # We check that the only path construction is a direct concatenation, not a glob.
  ! printf '%s\n' "$fallback_code" | grep -qE 'jobs/\*|find.*jobs|ls.*jobs'
}

# ---------------------------------------------------------------------------
# disk-state fallback — scope: direct poll_status callers are unaffected;
# only await invokes the disk fallback
# ---------------------------------------------------------------------------

@test "disk-state fallback: poll_status function does not invoke disk_state_fallback helper" {
  # Structural: the phase-fallback branch (job.phase extraction) and the
  # disk-state fallback are mutually independent. Verify that the
  # disk_state_fallback helper is NOT called from poll_status.
  local poll_body
  poll_body=$(awk '/^poll_status\(\)/{found=1} found{print} /^}$/{if(found){exit}}' "$WRAPPER")
  # Sanity guard: extraction must be non-empty and contain a known marker.
  [ -n "$poll_body" ] || { echo "poll_body extraction failed — awk returned empty output"; return 1; }
  printf '%s\n' "$poll_body" | grep -qE 'poll_interval|not-found|completed' \
    || { echo "poll_body appears truncated — known marker absent; check awk extraction"; return 1; }
  ! printf '%s\n' "$poll_body" | grep -qE 'disk_state_fallback|disk.*fallback|state\.json'
}

# ---------------------------------------------------------------------------
# disk-state fallback — symlinked-workspace regression: wrapper reads from
# canonical path even when workspace root is accessed via a symlink
# ---------------------------------------------------------------------------

@test "disk-state fallback: symlinked workspace root — broker writes to canonical path, wrapper reads correctly" {
  bats_require_minimum_version 1.5.0
  command -v jq >/dev/null 2>&1 || skip "jq not on PATH — required for fixture construction"

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  # Create a real directory and a symlink to it.
  local real_dir="$TEST_ROOT/real-workspace"
  local sym_dir="$TEST_ROOT/sym-workspace"
  mkdir -p "$real_dir"
  ln -s "$real_dir" "$sym_dir"

  local job_id="job-symlink-regression"
  export STUB_JOB_NOT_FOUND=1

  # Write fixtures using the canonical (real) path — as the broker would.
  local canonical_path
  canonical_path=$(cd "$real_dir" && pwd -P)
  local state_dir
  state_dir=$(_disk_state_dir "$plugin_data" "$canonical_path")
  mkdir -p "$state_dir/jobs"
  jq -n --arg id "$job_id" \
    '{"version":1,"config":{},"jobs":[{"id":$id,"status":"completed"}]}' \
    > "$state_dir/state.json"
  jq -n --arg id "$job_id" --arg raw "symlink regression output" \
    '{"id":$id,"status":"completed","result":{"rawOutput":$raw}}' \
    > "$state_dir/jobs/$job_id.json"

  # Run the wrapper from the symlinked path — the wrapper must resolve to
  # canonical path and find the fixtures the broker wrote at canonical path.
  run --separate-stderr env -C "$sym_dir" "$WRAPPER" await "$job_id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"symlink regression output"* ]]
  [[ "$stderr" == *"await: recovered $job_id from disk (broker reported not-found)"* ]]
}

# ---------------------------------------------------------------------------
# disk-state fallback — metacharacter-safe fixtures: rawOutput and
# errorMessage containing JSON metacharacters survive fixture construction
# and hit-path recovery
# ---------------------------------------------------------------------------

@test "disk-state fallback: rawOutput containing JSON metacharacters recovered correctly" {
  bats_require_minimum_version 1.5.0
  command -v jq >/dev/null 2>&1 || skip "jq not on PATH — required for fixture construction"

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  local job_id="job-metachar-raw"
  export STUB_JOB_NOT_FOUND=1

  # Build fixtures with jq so metacharacters are properly escaped.
  local raw_output
  raw_output='output with "quotes" and \backslash and newline'
  local workspace
  workspace=$(cd "$REPO_ROOT" && pwd -P)
  local state_dir
  state_dir=$(_disk_state_dir "$plugin_data" "$workspace")
  mkdir -p "$state_dir/jobs"
  jq -n --arg id "$job_id" \
    '{"version":1,"config":{},"jobs":[{"id":$id,"status":"completed"}]}' \
    > "$state_dir/state.json"
  jq -n --arg id "$job_id" --arg raw "$raw_output" \
    '{"id":$id,"status":"completed","result":{"rawOutput":$raw}}' \
    > "$state_dir/jobs/$job_id.json"

  run --separate-stderr "$WRAPPER" await "$job_id"
  [ "$status" -eq 0 ]
  [[ "$output" == *'output with "quotes"'* ]]
  [[ "$stderr" == *"await: recovered $job_id from disk (broker reported not-found)"* ]]
}

@test "disk-state fallback: errorMessage containing JSON metacharacters emitted correctly on stderr" {
  bats_require_minimum_version 1.5.0
  command -v jq >/dev/null 2>&1 || skip "jq not on PATH — required for fixture construction"

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  local job_id="job-metachar-err"
  export STUB_JOB_NOT_FOUND=1

  local error_message
  error_message='failed with "quoted error" and \escape'
  local workspace
  workspace=$(cd "$REPO_ROOT" && pwd -P)
  local state_dir
  state_dir=$(_disk_state_dir "$plugin_data" "$workspace")
  mkdir -p "$state_dir/jobs"
  jq -n --arg id "$job_id" \
    '{"version":1,"config":{},"jobs":[{"id":$id,"status":"failed"}]}' \
    > "$state_dir/state.json"
  jq -n --arg id "$job_id" --arg err "$error_message" \
    '{"id":$id,"status":"failed","errorMessage":$err}' \
    > "$state_dir/jobs/$job_id.json"

  run --separate-stderr "$WRAPPER" await "$job_id"
  [ "$status" -eq 13 ]
  [[ "$stderr" == *'failed with "quoted error"'* ]]
  [ -z "$output" ]
}

# ---------------------------------------------------------------------------
# disk-state fallback — jobId traversal guard: malformed jobId values are
# rejected at function entry without any disk read
# ---------------------------------------------------------------------------

@test "disk-state fallback: jobId with path separator rejected even when state.json lists it" {
  bats_require_minimum_version 1.5.0
  command -v jq >/dev/null 2>&1 || skip "jq not on PATH — required for fixture construction"

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  # A jobId with a slash: path-traversal attempt.
  # The guard must fire even if an attacker has planted the traversal jobId in state.json.
  local traversal_id="../etc/passwd"
  export STUB_JOB_NOT_FOUND=1

  # Seed a state.json that lists the traversal jobId (attacker-controlled state).
  local workspace
  workspace=$(cd "$REPO_ROOT" && pwd -P)
  local state_dir
  state_dir=$(_disk_state_dir "$plugin_data" "$workspace")
  mkdir -p "$state_dir/jobs"
  jq -n --arg id "$traversal_id" \
    '{"version":1,"config":{},"jobs":[{"id":$id,"status":"completed"}]}' \
    > "$state_dir/state.json"

  run --separate-stderr "$WRAPPER" await "$traversal_id"
  # Must exit with not-found (11) — jobId guard fires before file path construction.
  [ "$status" -eq 11 ]
  [[ "$stderr" != *"await: recovered"* ]]
}

@test "disk-state fallback: empty jobId is rejected by wrapper before disk read" {
  bats_require_minimum_version 1.5.0

  # Empty string jobId: the wrapper's argument parsing must reject this.
  export STUB_JOB_NOT_FOUND=1

  run --separate-stderr "$WRAPPER" await ""
  # Wrapper requires a non-empty jobId; must exit non-zero
  [ "$status" -ne 0 ]
  [[ "$stderr" != *"await: recovered"* ]]
}

@test "disk-state fallback: jobId with dotdot sequence rejected even when state.json lists it" {
  bats_require_minimum_version 1.5.0
  command -v jq >/dev/null 2>&1 || skip "jq not on PATH — required for fixture construction"

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  local traversal_id="job..bad"
  export STUB_JOB_NOT_FOUND=1

  # Seed a state.json that lists the traversal jobId.
  local workspace
  workspace=$(cd "$REPO_ROOT" && pwd -P)
  local state_dir
  state_dir=$(_disk_state_dir "$plugin_data" "$workspace")
  mkdir -p "$state_dir/jobs"
  jq -n --arg id "$traversal_id" \
    '{"version":1,"config":{},"jobs":[{"id":$id,"status":"completed"}]}' \
    > "$state_dir/state.json"

  run --separate-stderr "$WRAPPER" await "$traversal_id"
  [ "$status" -eq 11 ]
  [[ "$stderr" != *"await: recovered"* ]]
}

# ---------------------------------------------------------------------------
# disk-state fallback — CLAUDE_PLUGIN_DATA nonexistent-path guard: path with ..
# that resolves to a nonexistent directory → realpathSync fails → exit 11.
# (Tests the realpathSync-failure branch, not the containment-check branch.)
# ---------------------------------------------------------------------------

@test "disk-state fallback: CLAUDE_PLUGIN_DATA resolving to nonexistent path → exit 11 (realpathSync failure)" {
  bats_require_minimum_version 1.5.0

  # CLAUDE_PLUGIN_DATA contains '..' and resolves to a path that does not exist.
  # The wrapper's Node snippet calls realpathSync(pluginData) which throws ENOENT,
  # causing process.exit(1) → disk_state_fallback returns 1 → await exits 11.
  # This tests the realpathSync-failure path, not the containment check.
  local real_plugin="$TEST_ROOT/plugin-data"
  mkdir -p "$real_plugin"
  export CLAUDE_PLUGIN_DATA="$TEST_ROOT/plugin-data/../other-dir"

  local job_id="job-traversal-enoent-test"
  export STUB_JOB_NOT_FOUND=1

  # The traversal path resolves to /tmp/.../other-dir which does not exist.
  # The wrapper exits 11 via the realpathSync failure path, not the containment check.
  run --separate-stderr "$WRAPPER" await "$job_id"
  [ "$status" -eq 11 ]
  [[ "$stderr" != *"await: recovered"* ]]
}

# ---------------------------------------------------------------------------
# disk-state fallback — state.json parse error emits diagnostic to stderr
# ---------------------------------------------------------------------------

@test "disk-state fallback: corrupt state.json emits parse-error diagnostic to stderr" {
  bats_require_minimum_version 1.5.0

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  local job_id="job-corrupt-state-json"
  local workspace
  workspace=$(cd "$REPO_ROOT" && pwd -P)
  local state_dir
  state_dir=$(_disk_state_dir "$plugin_data" "$workspace")
  mkdir -p "$state_dir/jobs"
  # Write a corrupt (non-JSON) state.json that is present but unparseable.
  printf 'this is not valid json {{{' > "$state_dir/state.json"

  export STUB_JOB_NOT_FOUND=1

  run --separate-stderr "$WRAPPER" await "$job_id"
  # Must take the terminal not-found exit — corrupt state.json treated as miss.
  [ "$status" -eq 11 ]
  # Must emit a parse-error diagnostic on stderr (not silent).
  [[ "$stderr" == *"state.json"* ]]
  [[ "$stderr" != *"await: recovered"* ]]
}

# ---------------------------------------------------------------------------
# disk-state fallback — failed-status exit code is exact match (not just non-zero)
# ---------------------------------------------------------------------------

@test "disk-state fallback: failed status in disk record → exact exit code 13" {
  bats_require_minimum_version 1.5.0
  command -v jq >/dev/null 2>&1 || skip "jq not on PATH — required for fixture construction"

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  local job_id="job-exact-exit-failed"
  export STUB_JOB_NOT_FOUND=1

  local workspace
  workspace=$(cd "$REPO_ROOT" && pwd -P)
  local state_dir
  state_dir=$(_disk_state_dir "$plugin_data" "$workspace")
  mkdir -p "$state_dir/jobs"
  jq -n --arg id "$job_id" \
    '{"version":1,"config":{},"jobs":[{"id":$id,"status":"failed"}]}' \
    > "$state_dir/state.json"
  jq -n --arg id "$job_id" --arg err "exact exit test error" \
    '{"id":$id,"status":"failed","errorMessage":$err}' \
    > "$state_dir/jobs/$job_id.json"

  run --separate-stderr "$WRAPPER" await "$job_id"
  # Exact exit code must be 13 (not merely non-zero).
  [ "$status" -eq 13 ]
  [[ "$stderr" == *"exact exit test error"* ]]
  [ -z "$output" ]
}

# ---------------------------------------------------------------------------
# disk-state fallback — permission-error diagnostic: file present but
# unreadable emits a stderr note (EACCES vs ENOENT distinction)
# ---------------------------------------------------------------------------

@test "disk-state fallback: unreadable state.json emits permission-error diagnostic" {
  bats_require_minimum_version 1.5.0

  # Skip if running as root (root can read any file regardless of permissions).
  if [ "$(id -u)" -eq 0 ]; then
    skip "skipping permission test when running as root"
  fi

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  local job_id="job-unreadable-state"
  local workspace
  workspace=$(cd "$REPO_ROOT" && pwd -P)
  local state_dir
  state_dir=$(_disk_state_dir "$plugin_data" "$workspace")
  mkdir -p "$state_dir/jobs"
  printf '{}' > "$state_dir/state.json"
  chmod 000 "$state_dir/state.json"

  export STUB_JOB_NOT_FOUND=1

  run --separate-stderr "$WRAPPER" await "$job_id"
  # Must take the terminal not-found exit.
  [ "$status" -eq 11 ]
  # Must emit a stderr note distinguishing presence-but-unreadable from absent.
  [[ "$stderr" == *"state.json"* ]]
  [[ "$stderr" != *"await: recovered"* ]]

  chmod 644 "$state_dir/state.json"
}

# ---------------------------------------------------------------------------
# disk-state fallback — cancelled-status exit code matches broker-served
# cancelled path: exit 13 (hard error via _status_to_exit_code helper)
# ---------------------------------------------------------------------------

@test "disk-state fallback: cancelled status in disk record → exact exit code 13 via status helper" {
  bats_require_minimum_version 1.5.0
  command -v jq >/dev/null 2>&1 || skip "jq not on PATH — required for fixture construction"

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  local job_id="job-cancelled-disk-record"
  export STUB_JOB_NOT_FOUND=1

  local workspace
  workspace=$(cd "$REPO_ROOT" && pwd -P)
  local state_dir
  state_dir=$(_disk_state_dir "$plugin_data" "$workspace")
  mkdir -p "$state_dir/jobs"
  jq -n --arg id "$job_id" \
    '{"version":1,"config":{},"jobs":[{"id":$id,"status":"cancelled"}]}' \
    > "$state_dir/state.json"
  jq -n --arg id "$job_id" --arg err "cancelled job error message" \
    '{"id":$id,"status":"cancelled","errorMessage":$err}' \
    > "$state_dir/jobs/$job_id.json"

  run --separate-stderr "$WRAPPER" await "$job_id"
  # Cancelled status with errorMessage: exit 13 (matches broker-served hard-error path)
  [ "$status" -eq 13 ]
  [[ "$stderr" == *"cancelled job error message"* ]]
  [ -z "$output" ]
}

@test "disk-state fallback: cancelled status in disk record with no output and no errorMessage → exit 13 via status helper" {
  bats_require_minimum_version 1.5.0
  command -v jq >/dev/null 2>&1 || skip "jq not on PATH — required for fixture construction"

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  local job_id="job-cancelled-no-output"
  export STUB_JOB_NOT_FOUND=1

  local workspace
  workspace=$(cd "$REPO_ROOT" && pwd -P)
  local state_dir
  state_dir=$(_disk_state_dir "$plugin_data" "$workspace")
  mkdir -p "$state_dir/jobs"
  jq -n --arg id "$job_id" \
    '{"version":1,"config":{},"jobs":[{"id":$id,"status":"cancelled"}]}' \
    > "$state_dir/state.json"
  # No rawOutput, no errorMessage — only status field
  jq -n --arg id "$job_id" \
    '{"id":$id,"status":"cancelled"}' \
    > "$state_dir/jobs/$job_id.json"

  run --separate-stderr "$WRAPPER" await "$job_id"
  # Cancelled with no extractable output: _status_to_exit_code maps cancelled → 13
  [ "$status" -eq 13 ]
  [ -z "$output" ]
}

# ---------------------------------------------------------------------------
# disk-state fallback — completed disk record with no extractable output → exit 14
# (pins the disk_rc=14 arm in await_subcommand's not-found handler)
# ---------------------------------------------------------------------------

@test "disk-state fallback: completed disk record with no extractable output → exit 14, stderr diagnostic" {
  bats_require_minimum_version 1.5.0
  command -v jq >/dev/null 2>&1 || skip "jq not on PATH — required for fixture construction"

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  local job_id="job-completed-no-output"
  export STUB_JOB_NOT_FOUND=1

  local workspace
  workspace=$(cd "$REPO_ROOT" && pwd -P)
  local state_dir
  state_dir=$(_disk_state_dir "$plugin_data" "$workspace")
  mkdir -p "$state_dir/jobs"
  # state.json lists the job as completed
  jq -n --arg id "$job_id" \
    '{"version":1,"config":{},"jobs":[{"id":$id,"status":"completed"}]}' \
    > "$state_dir/state.json"
  # Per-job record: status completed, but NO result.rawOutput, result.codex.stdout,
  # rendered, or errorMessage field — no extractable output from any source.
  jq -n --arg id "$job_id" \
    '{"id":$id,"status":"completed"}' \
    > "$state_dir/jobs/$job_id.json"

  run --separate-stderr "$WRAPPER" await "$job_id"
  # _status_to_exit_code("completed") → 14; disk_rc=14 → final_rc=14.
  [ "$status" -eq 14 ]
  # Nothing on stdout (no recovered output).
  [ -z "$output" ]
}

# ---------------------------------------------------------------------------
# disk-state fallback — unknown status in disk record → exit 14, stderr diagnostic
# (unknown-status must not silently map to exit 11 "not found")
# ---------------------------------------------------------------------------

@test "disk-state fallback: unknown status in disk record (e.g. 'paused') → exit 14, stderr diagnostic" {
  bats_require_minimum_version 1.5.0
  command -v jq >/dev/null 2>&1 || skip "jq not on PATH — required for fixture construction"

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  local job_id="job-unknown-status"
  export STUB_JOB_NOT_FOUND=1

  local workspace
  workspace=$(cd "$REPO_ROOT" && pwd -P)
  local state_dir
  state_dir=$(_disk_state_dir "$plugin_data" "$workspace")
  mkdir -p "$state_dir/jobs"
  jq -n --arg id "$job_id" \
    '{"version":1,"config":{},"jobs":[{"id":$id,"status":"paused"}]}' \
    > "$state_dir/state.json"
  # Per-job record with a future/unknown status — no output fields.
  jq -n --arg id "$job_id" \
    '{"id":$id,"status":"paused"}' \
    > "$state_dir/jobs/$job_id.json"

  run --separate-stderr "$WRAPPER" await "$job_id"
  # Unknown status must map to exit 14 (malformed/unrecognized), NOT exit 11 (not-found).
  # This distinguishes "job record present with unrecognized status" from "job not found".
  [ "$status" -eq 14 ]
  # Stderr must carry an actionable diagnostic mentioning the unknown status.
  [[ "$stderr" == *"paused"* ]]
  # Nothing on stdout.
  [ -z "$output" ]
}

# ---------------------------------------------------------------------------
# disk-state fallback — jq guard: tests that use jq skip cleanly when jq absent
# Structural lint: count of jq-call-using tests must not exceed guard occurrences.
# ---------------------------------------------------------------------------

@test "disk-state fallback: jq guard fires when jq is unavailable (structural test)" {
  # Structural lint: each @test block that calls jq (jq -n or jq -r) must include
  # the jq guard so it skips cleanly when jq is absent.  Uses awk to count @test
  # blocks containing jq calls and compare against @test blocks containing guards.
  # The counts must be equal: no jq-using test without a guard, no spare guards.
  #
  # Helper functions (_write_disk_*_fixtures, _disk_state_dir) use jq internally
  # but are not @test blocks; tests that invoke them include the guard explicitly.
  # Those helper jq calls are intentionally excluded from this count because it is
  # the @test-level guard that controls skip behaviour, not a guard inside helpers.
  local jq_test_count guard_test_count
  # Count @test blocks that use jq — either directly (jq -n / jq -r calls) or
  # indirectly via the fixture-writing helpers (_write_disk_*_fixtures) which
  # themselves invoke jq.  _disk_state_dir uses Node, not jq, so it is excluded.
  jq_test_count=$(awk '
    /^@test / { in_test=1; has_jq=0; has_guard=0 }
    in_test && (/jq -[nr]/ || /_write_disk_(completed|failed)_fixtures/) { has_jq=1 }
    in_test && /command -v jq/ { has_guard=1 }
    /^}$/ && in_test { if (has_jq) count++; in_test=0 }
    END { print count+0 }
  ' "$BATS_TEST_FILENAME")
  guard_test_count=$(awk '
    /^@test / { in_test=1; has_guard=0 }
    in_test && /command -v jq/ { has_guard=1 }
    /^}$/ && in_test { if (has_guard) count++; in_test=0 }
    END { print count+0 }
  ' "$BATS_TEST_FILENAME")
  # Counts must be equal: every jq-needing test must have exactly one guard,
  # and no guard should appear in a test that does not need jq.  Adding a new
  # jq-dependent test (direct or via helper) without a guard increases
  # jq_test_count above guard_test_count, tripping this assertion.
  [ "$jq_test_count" -eq "$guard_test_count" ]
}

# ---------------------------------------------------------------------------
# disk-state fallback — real symlink resolution: non-vacuous canonicalization
# (tmpdir-based, asserts sym_dir path differs from canonical path used by broker)
# ---------------------------------------------------------------------------

@test "disk-state fallback: symlink resolution is non-vacuous — symlink path differs from canonical path" {
  bats_require_minimum_version 1.5.0
  command -v jq >/dev/null 2>&1 || skip "jq not on PATH — required for fixture construction"

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  # Use a tmpdir-based symlink so the symlink path differs from the realpath
  # on all platforms (including Linux where env -C may resolve getcwd to realpath).
  local real_dir sym_dir
  real_dir=$(mktemp -d -t real-workspace-XXXXXX)
  sym_dir=$(mktemp -d -t sym-workspace-XXXXXX)
  trap 'rm -rf "$real_dir" "$sym_dir"' EXIT
  # Remove the mktemp-created sym_dir placeholder and replace with symlink
  rm -r "$sym_dir"
  ln -s "$real_dir" "$sym_dir"

  local canonical_path
  canonical_path=$(cd "$real_dir" && pwd -P)
  local sym_path
  sym_path="$sym_dir"

  # Assert the symlink path differs from the canonical path (non-vacuous test).
  # If these were the same, the test would not exercise canonicalization.
  [ "$sym_path" != "$canonical_path" ] || skip "symlink path equals canonical path on this platform — test is vacuous"

  # Compute state dir using canonical path (as the broker would write).
  local state_dir_canonical
  state_dir_canonical=$(_disk_state_dir "$plugin_data" "$canonical_path")

  # Compute state dir using symlink path (what would be wrong without canonicalization).
  local state_dir_sym
  state_dir_sym=$(_disk_state_dir "$plugin_data" "$sym_path")

  # Assert the two paths differ — confirms symlink resolution changes the hash.
  [ "$state_dir_canonical" != "$state_dir_sym" ] || skip "canonical and symlink state dirs are identical — canonicalization is a no-op on this platform"

  local job_id="job-symlink-nonvacuous"
  export STUB_JOB_NOT_FOUND=1

  # Write fixtures at the CANONICAL path (as broker would write).
  mkdir -p "$state_dir_canonical/jobs"
  jq -n --arg id "$job_id" \
    '{"version":1,"config":{},"jobs":[{"id":$id,"status":"completed"}]}' \
    > "$state_dir_canonical/state.json"
  jq -n --arg id "$job_id" --arg raw "canonical path output" \
    '{"id":$id,"status":"completed","result":{"rawOutput":$raw}}' \
    > "$state_dir_canonical/jobs/$job_id.json"

  # Assert no fixtures at the symlink-derived path (proves canonicalization matters).
  [ ! -f "$state_dir_sym/state.json" ]

  # Run wrapper from the SYMLINK directory — must canonicalize and find fixtures.
  run --separate-stderr env -C "$sym_dir" "$WRAPPER" await "$job_id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"canonical path output"* ]]
  [[ "$stderr" == *"await: recovered $job_id from disk (broker reported not-found)"* ]]

  rm -rf "$real_dir" "$sym_dir"
}

# ---------------------------------------------------------------------------
# disk-state fallback — real containment rejection: state-dir symlink inside
# CLAUDE_PLUGIN_DATA that escapes the canonical prefix (containment check exercised)
#
# The containment check fires when the state-dir slot inside CLAUDE_PLUGIN_DATA
# is itself a symlink pointing OUTSIDE the canonical plugin-data tree.  The
# wrapper canonicalizes the resolved state-dir path and rejects it when it lies
# outside canonicalPluginData, preventing reads from attacker-controlled paths.
#
# Inversion property: removing the containment guard from production code would
# cause the wrapper to follow the symlink and successfully read the planted
# fixtures (exit 0), making this test fail — the guard is the only barrier.
# ---------------------------------------------------------------------------

@test "disk-state fallback: state-dir slot symlink escaping canonical plugin-data prefix → containment check fires, exit 11" {
  bats_require_minimum_version 1.5.0
  command -v jq >/dev/null 2>&1 || skip "jq not on PATH — required for fixture construction"

  # real_plugin_data: the canonical CLAUDE_PLUGIN_DATA root (the intended prefix).
  # outside_dir: separate real directory outside real_plugin_data (escape target).
  # Both are placed under TEST_ROOT so teardown() cleans them up unconditionally.
  local real_plugin_data outside_dir
  real_plugin_data="$TEST_ROOT/containment-plugin-data"
  outside_dir="$TEST_ROOT/containment-escape-target"
  mkdir -p "$real_plugin_data"
  mkdir -p "$outside_dir"

  export CLAUDE_PLUGIN_DATA="$real_plugin_data"

  # Compute the state-dir slot the wrapper will look for (based on workspace root).
  # The wrapper runs from cwd = worktree root (test harness invokes bats from there).
  local workspace
  workspace=$(cd "$REPO_ROOT" && pwd -P)
  local expected_state_dir
  expected_state_dir=$(_disk_state_dir "$real_plugin_data" "$workspace")

  # Create the CLAUDE_PLUGIN_DATA/state/ prefix, but make the specific state-dir
  # slot (the per-workspace directory) a symlink pointing OUTSIDE real_plugin_data.
  # This is the escape scenario: an attacker who can write inside CLAUDE_PLUGIN_DATA
  # replaces the state-dir slot with a symlink to an arbitrary location.
  mkdir -p "$(dirname "$expected_state_dir")"
  ln -s "$outside_dir" "$expected_state_dir"

  # Plant valid completed fixtures at the symlink target (outside_dir).
  # If the containment guard were absent, the wrapper would follow the symlink,
  # find these fixtures, and exit 0.  The guard must prevent this.
  local job_id="job-containment-escape"
  export STUB_JOB_NOT_FOUND=1
  mkdir -p "$outside_dir/jobs"
  jq -n --arg id "$job_id" \
    '{"version":1,"config":{},"jobs":[{"id":$id,"status":"completed"}]}' \
    > "$outside_dir/state.json"
  jq -n --arg id "$job_id" --arg raw "escaped output must not appear" \
    '{"id":$id,"status":"completed","result":{"rawOutput":$raw}}' \
    > "$outside_dir/jobs/$job_id.json"

  # The wrapper's Node snippet computes the state dir as a string path inside
  # real_plugin_data, but then canonicalizes that path (realpathSync) to detect
  # the symlink escape.  The canonical result is outside_dir (outside
  # real_plugin_data), so the containment guard must fire and exit non-zero.
  run --separate-stderr "$WRAPPER" await "$job_id"

  # Containment guard fires → wrapper exits 11 (miss) — NOT 0 (recovery).
  [ "$status" -eq 11 ]
  # The escaped fixture output must NOT appear on stdout.
  [[ "$output" != *"escaped output"* ]]
  # No recovery note (containment rejection not equal to successful disk recovery).
  [[ "$stderr" != *"await: recovered"* ]]
}

@test "disk-state fallback: CLAUDE_PLUGIN_DATA with dotdot resolves to nonexistent path → exit 11" {
  bats_require_minimum_version 1.5.0

  # This test documents that CLAUDE_PLUGIN_DATA containing '..' that resolves
  # to a nonexistent directory causes the wrapper to exit 11 via the
  # CLAUDE_PLUGIN_DATA canonicalization failure path (realpathSync throws).
  # The test name and description accurately reflect what is tested.
  local real_plugin="$TEST_ROOT/plugin-data"
  mkdir -p "$real_plugin"
  export CLAUDE_PLUGIN_DATA="$TEST_ROOT/plugin-data/../other-dir-nonexistent"

  local job_id="job-dotdot-nonexistent"
  export STUB_JOB_NOT_FOUND=1

  run --separate-stderr "$WRAPPER" await "$job_id"
  [ "$status" -eq 11 ]
  [[ "$stderr" != *"await: recovered"* ]]
}

# ---------------------------------------------------------------------------
# disk-state fallback — dotfile jobId rejection: leading-dot names are rejected
# ---------------------------------------------------------------------------

@test "disk-state fallback: dotfile jobId (.foo) is rejected by the guard even with fixtures planted" {
  bats_require_minimum_version 1.5.0
  command -v jq >/dev/null 2>&1 || skip "jq not on PATH — required for fixture construction"

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  # Plant fixtures that WOULD be found if the guard did not fire.
  # The guard must reject .hidden-job before any disk read occurs.
  local dotfile_id=".hidden-job"
  export STUB_JOB_NOT_FOUND=1

  local workspace
  workspace=$(cd "$REPO_ROOT" && pwd -P)
  local state_dir
  state_dir=$(_disk_state_dir "$plugin_data" "$workspace")
  mkdir -p "$state_dir/jobs"
  # Plant fixtures — the guard must fire before these are read.
  jq -n --arg id "$dotfile_id" \
    '{"version":1,"config":{},"jobs":[{"id":$id,"status":"completed"}]}' \
    > "$state_dir/state.json"
  jq -n --arg id "$dotfile_id" --arg raw "should not appear — guard must fire" \
    '{"id":$id,"status":"completed","result":{"rawOutput":$raw}}' \
    > "$state_dir/jobs/${dotfile_id}.json"

  run --separate-stderr "$WRAPPER" await "$dotfile_id"
  # Leading-dot jobId must be rejected by the guard: exit 11, no recovery note.
  [ "$status" -eq 11 ]
  [[ "$stderr" != *"await: recovered"* ]]
  # Guard fires before disk read: output must not contain the planted fixture text.
  [[ "$output" != *"should not appear"* ]]
}

@test "disk-state fallback: single-dot jobId (.) is rejected by the guard" {
  bats_require_minimum_version 1.5.0

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  export STUB_JOB_NOT_FOUND=1

  run --separate-stderr "$WRAPPER" await "."
  # Single-dot jobId must be rejected by the .* guard pattern: exit 11, no recovery.
  [ "$status" -eq 11 ]
  [[ "$stderr" != *"await: recovered"* ]]
}

@test "disk-state fallback: bare double-dot jobId (..) is rejected by the guard" {
  bats_require_minimum_version 1.5.0

  local plugin_data="$TEST_ROOT/plugin-data"
  mkdir -p "$plugin_data"
  export CLAUDE_PLUGIN_DATA="$plugin_data"

  export STUB_JOB_NOT_FOUND=1

  run --separate-stderr "$WRAPPER" await ".."
  # Bare '..' is caught by both *..*  and .* patterns: exit 11, no recovery.
  [ "$status" -eq 11 ]
  [[ "$stderr" != *"await: recovered"* ]]
}
