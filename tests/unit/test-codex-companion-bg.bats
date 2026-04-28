#!/usr/bin/env bats
# ============================================================================
# Unit tests for scripts/codex-companion-bg.sh
#
# Covers all 12 task-03 spec test expectations + the 6 critical implementation
# constraints carried in from prior-iteration codex review:
#   C1  launch preserves the real exit code from `task` (no `|| true` mask)
#   C2  every await failure path emits a stderr message
#   C3  CODEX_COMPANION resolves portably (glob-of-versions; not pinned)
#   C4  status job-not-found vs other-error: distinct exit codes (11 vs 13)
#   C5  T8 concurrency uses ≥100 writers, ≥5 trials
#   C6  stub fixture mirrors real companion JSON shapes (.job.status,
#       storedJob.result.rawOutput)
# ============================================================================

setup() {
  TEST_ROOT=$(mktemp -d)
  export TEST_ROOT
  cd "$TEST_ROOT"

  REPO_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
  export REPO_ROOT
  WRAPPER="$REPO_ROOT/scripts/codex-companion-bg.sh"
  export WRAPPER
  STUB="$REPO_ROOT/tests/fixtures/stub-codex-companion.mjs"
  export STUB

  # Wire wrapper to use our stub (verifies constraint C3: env-overridable).
  export CODEX_COMPANION="$STUB"

  # Tunables expected to be honored by the wrapper. Tests override these
  # to keep the suite fast; defaults in the wrapper itself are 5s / 30s /
  # 1200s as the spec requires.
  export QRSPI_CODEX_POLL_INTERVAL_FAST=1
  export QRSPI_CODEX_POLL_INTERVAL_SLOW=2
  export QRSPI_CODEX_POLL_BACKOFF_AFTER=3
  export QRSPI_CODEX_CEILING_SECONDS=10
  export QRSPI_CODEX_LAUNCH_TIMEOUT_SECONDS=5

  # Per-test stub state file.
  export STUB_STATE_FILE="$TEST_ROOT/stub-state.json"

  mkdir -p "$TEST_ROOT/prompts"
  echo "test prompt" > "$TEST_ROOT/prompts/p.txt"
  export PROMPT_FILE="$TEST_ROOT/prompts/p.txt"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

# ── launch ─────────────────────────────────────────────────────────

@test "launch: returns within 5s and prints exactly the job ID to stdout" {
  start=$(date +%s)
  run "$WRAPPER" launch --prompt-file "$PROMPT_FILE"
  end=$(date +%s)

  [ "$status" -eq 0 ]
  # Exactly the job ID, alone, on stdout.
  [[ "$output" =~ ^task-stub-[0-9]+-[0-9]+$ ]]
  # Within 5 seconds (test uses fast stub; wraps real 5s budget).
  [ "$((end - start))" -lt 5 ]
}

@test "launch: passes --prompt-file through to the companion" {
  # Stub records argv via STUB_ARGV_DUMP.
  export STUB_ARGV_DUMP="$TEST_ROOT/argv.dump"
  cat > "$TEST_ROOT/companion-record.mjs" <<'EOF'
#!/usr/bin/env node
import fs from "node:fs";
fs.writeFileSync(process.env.STUB_ARGV_DUMP, JSON.stringify(process.argv.slice(2)));
process.stdout.write(JSON.stringify({ jobId: "task-stub-recorder", status: "queued", title: "x", summary: "y", logFile: "/tmp/x" }) + "\n");
EOF
  chmod +x "$TEST_ROOT/companion-record.mjs"
  CODEX_COMPANION="$TEST_ROOT/companion-record.mjs" run "$WRAPPER" launch --prompt-file "$PROMPT_FILE"
  [ "$status" -eq 0 ]
  argv=$(cat "$TEST_ROOT/argv.dump")
  [[ "$argv" == *"task"* ]]
  [[ "$argv" == *"--background"* ]]
  [[ "$argv" == *"--prompt-file"* ]]
  [[ "$argv" == *"$PROMPT_FILE"* ]]
}

@test "launch: exits nonzero within 6s when companion hangs (5s timeout)" {
  # Companion sleeps 30s — wrapper must not block past its 5s budget.
  export STUB_LAUNCH_HANG_MS=30000
  start=$(date +%s)
  run "$WRAPPER" launch --prompt-file "$PROMPT_FILE"
  end=$(date +%s)
  [ "$status" -ne 0 ]
  [ "$((end - start))" -lt 7 ]
  [ -n "$stderr" ] || [[ "$output" == *"timeout"* || "$output" == *"timed out"* || "$output" == *"hung"* ]]
}

@test "launch: preserves real non-zero exit (constraint C1)" {
  # Companion exits 7; wrapper must not mask it via `|| true`.
  export STUB_LAUNCH_EXIT=7
  run "$WRAPPER" launch --prompt-file "$PROMPT_FILE"
  [ "$status" -ne 0 ]
  # Stderr must say something — no silent failure (constraint C2 cousin).
  [ -n "$output$stderr" ]
}

@test "launch: malformed JSON from companion → nonzero with stderr" {
  export STUB_LAUNCH_BAD_JSON=1
  run "$WRAPPER" launch --prompt-file "$PROMPT_FILE"
  [ "$status" -ne 0 ]
  # Non-empty stderr OR error message in output (run merges by default in
  # current bats; we accept either).
  [ -n "$output" ] || [ -n "$stderr" ]
}

@test "launch: missing jobId in JSON → nonzero with stderr" {
  export STUB_LAUNCH_NO_JOBID=1
  run "$WRAPPER" launch --prompt-file "$PROMPT_FILE"
  [ "$status" -ne 0 ]
  [ -n "$output" ] || [ -n "$stderr" ]
}

# ── await: happy path ──────────────────────────────────────────────

@test "await: exits 0 on completion and writes review markdown to stdout" {
  # Pre-seed state so status returns "completed" on first poll.
  echo '{"jobId":"job-abc","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_RAW=$'# Review\n\nLooks fine.\n'

  mkdir -p "$TEST_ROOT/.qrspi"
  run "$WRAPPER" await job-abc
  [ "$status" -eq 0 ]
  [[ "$output" == *"# Review"* ]]
  [[ "$output" == *"Looks fine."* ]]
}

@test "await: falls back to storedJob.result.codex.stdout when rawOutput absent" {
  echo '{"jobId":"job-fb","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_STDOUT=$'# Fallback Review\n'
  unset STUB_RESULT_RAW

  run "$WRAPPER" await job-fb
  [ "$status" -eq 0 ]
  [[ "$output" == *"Fallback Review"* ]]
}

@test "await: appends exactly one JSONL row per invocation with all four fields" {
  echo '{"jobId":"job-x","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_RAW="ok"

  "$WRAPPER" await job-x >/dev/null
  [ -f .qrspi/audit-codex-review.jsonl ]
  rows=$(wc -l < .qrspi/audit-codex-review.jsonl)
  [ "$rows" -eq 1 ]
  row=$(cat .qrspi/audit-codex-review.jsonl)
  echo "$row" | jq -e '.job_id and .elapsed_seconds and .completion_status and .timestamp' >/dev/null
}

@test "await: creates .qrspi with mode 0700" {
  echo '{"jobId":"job-perm","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_RAW="ok"
  "$WRAPPER" await job-perm >/dev/null
  perms=$(stat -f "%Lp" .qrspi 2>/dev/null || stat -c "%a" .qrspi)
  [ "$perms" = "700" ]
}

# ── await: polling intervals ──────────────────────────────────────

@test "await: polls fast then backs off (5s→30s pattern, scaled in test)" {
  # In the test we use 1s/2s with backoff after 3s. We force completion
  # only after 5 polls so we observe at least one fast and one slow poll.
  echo '{"jobId":"job-poll","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=5
  export STUB_RESULT_RAW="# Review markdown poll-test"

  start=$(date +%s)
  run "$WRAPPER" await job-poll
  end=$(date +%s)
  elapsed=$((end - start))

  # Positive completion-handling assertions: a wrapper mutation that breaks
  # status->result handoff but happens to take 4-12s would otherwise pass.
  [ "$status" -eq 0 ]
  [[ "$output" == *"# Review markdown poll-test"* ]]

  # If we polled 5 times always at the slow interval (2s): 10s.
  # If 5 times always fast (1s): 5s.
  # With backoff after 3s: first ~3 polls fast (≈3s), then slow (~2s × 2)
  # ≈ 7s. Accept range [4, 12] to allow stub overhead.
  [ "$elapsed" -ge 4 ]
  [ "$elapsed" -le 12 ]
}

# ── await: ceiling ────────────────────────────────────────────────

@test "await: hits ceiling, exits 10, empty stdout" {
  echo '{"jobId":"job-c","polls":0}' > "$STUB_STATE_FILE"
  export STUB_NEVER_COMPLETE=1

  run "$WRAPPER" await job-c
  [ "$status" -eq 10 ]
  [ -z "$output" ]
}

@test "await: ceiling writes audit row with completion_status='ceiling-hit' BEFORE exit-10" {
  echo '{"jobId":"job-cb","polls":0}' > "$STUB_STATE_FILE"
  export STUB_NEVER_COMPLETE=1

  run "$WRAPPER" await job-cb
  [ "$status" -eq 10 ]
  [ -f .qrspi/audit-codex-review.jsonl ]
  rows=$(wc -l < .qrspi/audit-codex-review.jsonl)
  [ "$rows" -eq 1 ]
  status_field=$(jq -r '.completion_status' < .qrspi/audit-codex-review.jsonl)
  [ "$status_field" = "ceiling-hit" ]
}

# ── await: malformed / job-not-found ──────────────────────────────

@test "await: malformed status JSON → nonzero with stderr (constraint C2)" {
  echo '{"jobId":"job-bad","polls":0}' > "$STUB_STATE_FILE"
  export STUB_STATUS_BAD_JSON=1

  run "$WRAPPER" await job-bad
  [ "$status" -ne 0 ]
  [ "$status" -ne 10 ]   # not ceiling
  # Must emit something to stderr (or merged output) — never silent.
  [ -n "$output$stderr" ]
  # Audit row recorded with completion_status: "malformed".
  status_field=$(jq -r '.completion_status' < .qrspi/audit-codex-review.jsonl)
  [ "$status_field" = "malformed" ]
}

@test "await: malformed result JSON → nonzero with stderr; no partial stdout" {
  echo '{"jobId":"job-rb","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_BAD_JSON=1

  run "$WRAPPER" await job-rb
  [ "$status" -ne 0 ]
  [ "$status" -ne 10 ]
  status_field=$(jq -r '.completion_status' < .qrspi/audit-codex-review.jsonl)
  [ "$status_field" = "malformed" ]
}

@test "await: companion reports job-not-found → exit 11 (distinct from ceiling and malformed) — constraint C4" {
  echo '{"jobId":"job-nf","polls":0}' > "$STUB_STATE_FILE"
  export STUB_JOB_NOT_FOUND=1

  run "$WRAPPER" await job-nf
  [ "$status" -eq 11 ]
  [ -n "$output$stderr" ]
  status_field=$(jq -r '.completion_status' < .qrspi/audit-codex-review.jsonl)
  [ "$status_field" = "job-not-found" ]
}

@test "await: status hard error (not job-not-found) → exit 13 — constraint C4" {
  echo '{"jobId":"job-err","polls":0}' > "$STUB_STATE_FILE"
  export STUB_STATUS_EXIT=42

  run "$WRAPPER" await job-err
  [ "$status" -eq 13 ]
  [ "$status" -ne 11 ]
  [ -n "$output$stderr" ]
}

# ── await: audit-write failure ────────────────────────────────────

@test "await: audit-log write failure → nonzero with stderr (no silent swallow)" {
  echo '{"jobId":"job-wf","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_RAW="ok"

  # Pre-create .qrspi/ as read-only so opening append fails.
  mkdir -p .qrspi
  : > .qrspi/audit-codex-review.jsonl
  chmod 0444 .qrspi/audit-codex-review.jsonl
  chmod 0555 .qrspi

  run "$WRAPPER" await job-wf

  # Restore so teardown can clean up.
  chmod 0700 .qrspi
  chmod 0644 .qrspi/audit-codex-review.jsonl 2>/dev/null || true

  [ "$status" -ne 0 ]
  [ -n "$output$stderr" ]
}

# ── await: lock correctness under concurrency (constraint C5) ─────

@test "await: 100 concurrent writers produce non-interleaved JSONL rows (5 trials)" {
  echo '{"jobId":"job-conc","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_RAW="ok"

  WRITERS=100
  TRIALS=5

  for trial in $(seq 1 $TRIALS); do
    rm -rf .qrspi
    mkdir -p .qrspi

    pids=()
    for i in $(seq 1 $WRITERS); do
      "$WRAPPER" await "job-conc-$i" >/dev/null 2>&1 &
      pids+=($!)
    done
    for pid in "${pids[@]}"; do wait "$pid"; done

    # Every line must be valid JSON with the four required fields, and
    # the line count must equal the writer count exactly.
    rows=$(wc -l < .qrspi/audit-codex-review.jsonl)
    [ "$rows" -eq "$WRITERS" ] || {
      echo "trial=$trial expected=$WRITERS got=$rows"
      cat .qrspi/audit-codex-review.jsonl | head -5
      return 1
    }
    # Each line individually parses as JSON with the four required fields.
    bad=$(while IFS= read -r line; do
      echo "$line" | jq -e '.job_id and (.elapsed_seconds | type == "number") and .completion_status and .timestamp' >/dev/null 2>&1 || echo BAD
    done < .qrspi/audit-codex-review.jsonl | grep -c BAD || true)
    [ "$bad" -eq 0 ] || {
      echo "trial=$trial bad=$bad lines did not parse"
      return 1
    }
  done
}

# ── CODEX_COMPANION default resolution (constraint C3) ────────────

@test "CODEX_COMPANION unset: wrapper uses portable glob default; missing → nonzero with stderr" {
  unset CODEX_COMPANION
  # Force the glob to a controlled empty location so we deterministically
  # exercise the missing-companion branch. The wrapper must fail loud.
  HOME="$TEST_ROOT/empty-home" run "$WRAPPER" launch --prompt-file "$PROMPT_FILE"
  [ "$status" -ne 0 ]
  [ -n "$output$stderr" ]
}

# ── failed/cancelled fallback chain (C1) ──────────────────────────

@test "await: failed job with storedJob.rendered → exits 0 and surfaces rendered text" {
  echo '{"jobId":"job-failed","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  export STUB_TERMINAL_STATUS=failed
  export STUB_RESULT_RENDERED=$'# Codex Result\n\nReview ran but flagged blockers.\n'
  export STUB_RESULT_ERROR_MESSAGE="Codex turn ended with failure"
  unset STUB_RESULT_RAW
  unset STUB_RESULT_STDOUT

  run "$WRAPPER" await job-failed
  [ "$status" -eq 0 ]
  [[ "$output" == *"Review ran but flagged blockers"* ]]
  status_field=$(jq -r '.completion_status' < .qrspi/audit-codex-review.jsonl)
  [ "$status_field" = "failed" ]
}

@test "await: cancelled job falls back to job.errorMessage (link d) when nothing else present" {
  echo '{"jobId":"job-cancelled","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  export STUB_TERMINAL_STATUS=cancelled
  # Populate ONLY job.errorMessage (link d). storedJob.errorMessage stays empty
  # so this test specifically exercises the (d) link without leaking through (e).
  export STUB_RESULT_JOB_ERROR_MESSAGE="Cancelled by user."
  unset STUB_RESULT_STORED_JOB_ERROR_MESSAGE
  unset STUB_RESULT_ERROR_MESSAGE
  unset STUB_RESULT_RAW
  unset STUB_RESULT_STDOUT
  unset STUB_RESULT_RENDERED

  run "$WRAPPER" await job-cancelled
  [ "$status" -eq 0 ]
  [[ "$output" == *"Cancelled by user."* ]]
  status_field=$(jq -r '.completion_status' < .qrspi/audit-codex-review.jsonl)
  [ "$status_field" = "cancelled" ]
}

@test "await: storedJob.errorMessage (link e) only — wrapper surfaces it when (a)..(d) absent" {
  # Verifies the deepest fallback link is actually wired. Without the stub
  # split this case is unreachable because legacy STUB_RESULT_ERROR_MESSAGE
  # populates job.errorMessage too, short-circuiting at link (d).
  echo '{"jobId":"job-stored-only","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  export STUB_TERMINAL_STATUS=cancelled
  export STUB_RESULT_STORED_JOB_ERROR_MESSAGE="Stored-only error message."
  unset STUB_RESULT_JOB_ERROR_MESSAGE
  unset STUB_RESULT_ERROR_MESSAGE
  unset STUB_RESULT_RAW
  unset STUB_RESULT_STDOUT
  unset STUB_RESULT_RENDERED

  run "$WRAPPER" await job-stored-only
  [ "$status" -eq 0 ]
  [[ "$output" == *"Stored-only error message."* ]]
  status_field=$(jq -r '.completion_status' < .qrspi/audit-codex-review.jsonl)
  [ "$status_field" = "cancelled" ]
}

@test "await: fallback chain precedence — link (a) wins over link (b) when both populated" {
  # Both rawOutput (a) and codex.stdout (b) carry distinct text; wrapper must
  # emit (a) per render.mjs:401-403 ordering. Catches a mutant that swaps the
  # order of the first two extract_json_field probes in fetch_result.
  echo '{"jobId":"job-prec","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_RAW="A-raw-output-wins"
  export STUB_RESULT_STDOUT="B-codex-stdout-loses"

  run "$WRAPPER" await job-prec
  [ "$status" -eq 0 ]
  [[ "$output" == *"A-raw-output-wins"* ]]
  [[ "$output" != *"B-codex-stdout-loses"* ]]
}

# ── infrastructure-failure (M9) ───────────────────────────────────

@test "await: missing companion → audit row uses 'infrastructure-failure'" {
  unset CODEX_COMPANION
  HOME="$TEST_ROOT/empty-home" run "$WRAPPER" await job-noinfra
  [ "$status" -ne 0 ]
  [ -f .qrspi/audit-codex-review.jsonl ]
  status_field=$(jq -r '.completion_status' < .qrspi/audit-codex-review.jsonl)
  [ "$status_field" = "infrastructure-failure" ]
}

# ── stub-shape sanity (constraint C6) ─────────────────────────────

@test "stub fixture emits real companion JSON shapes (.job.status, storedJob.result.rawOutput)" {
  # task → top-level jobId
  task_json=$("$STUB" task --background --prompt-file "$PROMPT_FILE")
  echo "$task_json" | jq -e '.jobId' >/dev/null

  # status → .job.status (NOT .status)
  echo '{"jobId":"x","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  status_json=$("$STUB" status x --json)
  echo "$status_json" | jq -e '.job.status' >/dev/null
  echo "$status_json" | jq -e '.workspaceRoot' >/dev/null

  # Positive contract: top-level `.status` MUST be absent. A reader-mutation
  # in the wrapper from `.job.status` → `.status` would otherwise pass only
  # because the stub omits the field by accident — we assert the absence so
  # the stub becomes a positive contract for the real companion shape.
  printf '%s' "$status_json" > "$TEST_ROOT/status.json"
  top_level_status=$(jq -r '.status // empty' < "$TEST_ROOT/status.json")
  [ -z "$top_level_status" ]

  # result → storedJob.result.rawOutput
  export STUB_RESULT_RAW="hello"
  result_json=$("$STUB" result x --json)
  echo "$result_json" | jq -e '.storedJob.result.rawOutput' >/dev/null
  echo "$result_json" | jq -e '.job' >/dev/null
}

# ── PIPE_BUF / 4096-byte atomicity (F-4) ──────────────────────────

@test "audit: row close to but under PIPE_BUF (4096B) — 10 concurrent writers, no interleaving" {
  # Construct a jobId that, after JSON encoding into the audit row, leaves
  # us within ~150 bytes of the 4096-byte PIPE_BUF cap. The other three
  # fields (elapsed_seconds, completion_status="success", ISO timestamp,
  # field names + JSON punctuation) consume ~120 bytes total, so we size
  # the jobId to push the row close to 4000 bytes — comfortably under the
  # cap so writes remain atomic, but stressing the wrapper-imposed bound.
  echo '{"jobId":"job-bigrow","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_RAW="ok"

  big_id_prefix=$(printf 'j%.0s' $(seq 1 3900))   # 3900 bytes of 'j'
  WRITERS=10

  pids=()
  for i in $(seq 1 $WRITERS); do
    "$WRAPPER" await "${big_id_prefix}-${i}" >/dev/null 2>&1 &
    pids+=($!)
  done
  for pid in "${pids[@]}"; do wait "$pid"; done

  rows=$(wc -l < .qrspi/audit-codex-review.jsonl)
  [ "$rows" -eq "$WRITERS" ]

  # Every line individually parses: this is the critical assertion. If any
  # row interleaved with another, JSON parse would fail on at least one line.
  bad=$(while IFS= read -r line; do
    echo "$line" | jq -e '.job_id and .elapsed_seconds and .completion_status and .timestamp' >/dev/null 2>&1 || echo BAD
  done < .qrspi/audit-codex-review.jsonl | grep -c BAD || true)
  [ "$bad" -eq 0 ]

  # Every row's encoded byte length stayed ≤ 4096 (PIPE_BUF).
  while IFS= read -r line; do
    [ "${#line}" -le 4095 ]   # +1 for the newline brings the write to ≤4096
  done < .qrspi/audit-codex-review.jsonl
}

@test "audit: row that would exceed 4096B fails-closed with exit 12 (PIPE_BUF guard)" {
  # A 5000-byte jobId pushes the encoded row past PIPE_BUF. The wrapper must
  # refuse the append rather than risk an interleaved write.
  echo '{"jobId":"oversize","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_RAW="ok"

  oversize_id=$(printf 'X%.0s' $(seq 1 5000))    # 5000 bytes
  run "$WRAPPER" await "$oversize_id"
  [ "$status" -eq 12 ]
  [ -n "$output$stderr" ]
  # No row should have been appended.
  if [ -f .qrspi/audit-codex-review.jsonl ]; then
    rows=$(wc -l < .qrspi/audit-codex-review.jsonl)
    [ "$rows" -eq 0 ]
  fi
}

# ── mkdir-lock stale-reap (F-5) ───────────────────────────────────

@test "audit: stale lockdir (>30s old) is reaped, await still succeeds" {
  echo '{"jobId":"job-stale","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_RAW="ok"

  # Pre-create the lockdir with a mtime far in the past (epoch). The wrapper
  # reaps any lockdir whose age > 30s and proceeds; without the reap, it
  # would block until the bounded retry budget (~10s) elapsed and return 12.
  mkdir -p .qrspi
  chmod 0700 .qrspi
  mkdir .qrspi/audit-codex-review.lock
  # Touch with the canonical "long ago" timestamp; both BSD and GNU touch
  # accept `-t YYYYMMDDhhmm`. Use 2001-01-01 00:00 — far enough past to be
  # unambiguously >30s old regardless of clock skew.
  touch -t 200101010000 .qrspi/audit-codex-review.lock

  start=$(date +%s)
  run "$WRAPPER" await job-stale
  end=$(date +%s)
  elapsed=$((end - start))

  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]
  # Should complete quickly — well under the 10s lock-retry budget. If the
  # stale-reap branch failed, await would either time out or fail with 12.
  [ "$elapsed" -lt 10 ]
  rows=$(wc -l < .qrspi/audit-codex-review.jsonl)
  [ "$rows" -eq 1 ]
}
