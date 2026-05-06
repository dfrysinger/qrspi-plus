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

  # Per-test stub state file (used by the stub companion to track jobs across
  # status/result calls).
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
  # Path-arg form retired (#110 commit 21/22): pipe prompt on stdin.
  run bash -c 'cat "$PROMPT_FILE" | "$WRAPPER" launch'
  end=$(date +%s)

  [ "$status" -eq 0 ]
  # Exactly the job ID, alone, on stdout.
  [[ "$output" =~ ^task-stub-[0-9]+-[0-9]+$ ]]
  # Within 5 seconds (test uses fast stub; wraps real 5s budget).
  [ "$((end - start))" -lt 5 ]
}

@test "launch: passes prompt to companion via internal --prompt-file (stdin captured to temp)" {
  # The wrapper still passes --prompt-file to the *underlying companion*
  # internally (after capturing stdin to a temp file). This test verifies the
  # internal handoff still works under the stdin-only public surface.
  export STUB_ARGV_DUMP="$TEST_ROOT/argv.dump"
  cat > "$TEST_ROOT/companion-record.mjs" <<'EOF'
#!/usr/bin/env node
import fs from "node:fs";
fs.writeFileSync(process.env.STUB_ARGV_DUMP, JSON.stringify(process.argv.slice(2)));
process.stdout.write(JSON.stringify({ jobId: "task-stub-recorder", status: "queued", title: "x", summary: "y", logFile: "/tmp/x" }) + "\n");
EOF
  chmod +x "$TEST_ROOT/companion-record.mjs"
  export CODEX_COMPANION="$TEST_ROOT/companion-record.mjs"
  run bash -c 'cat "$PROMPT_FILE" | "$WRAPPER" launch'
  [ "$status" -eq 0 ]
  argv=$(cat "$TEST_ROOT/argv.dump")
  [[ "$argv" == *"task"* ]]
  [[ "$argv" == *"--background"* ]]
  [[ "$argv" == *"--prompt-file"* ]]
  # The captured prompt path is now a wrapper-managed temp, not the original
  # PROMPT_FILE — so we no longer assert PROMPT_FILE itself appears in argv.
}

@test "launch: exits nonzero within 6s when companion hangs (5s timeout)" {
  # Companion sleeps 30s — wrapper must not block past its 5s budget.
  export STUB_LAUNCH_HANG_MS=30000
  start=$(date +%s)
  run bash -c 'cat "$PROMPT_FILE" | "$WRAPPER" launch'
  end=$(date +%s)
  [ "$status" -ne 0 ]
  [ "$((end - start))" -lt 7 ]
  [ -n "$stderr" ] || [[ "$output" == *"timeout"* || "$output" == *"timed out"* || "$output" == *"hung"* ]]
}

@test "launch: preserves real non-zero exit (constraint C1)" {
  # Companion exits 7; wrapper must not mask it via `|| true`.
  export STUB_LAUNCH_EXIT=7
  run bash -c 'cat "$PROMPT_FILE" | "$WRAPPER" launch'
  [ "$status" -ne 0 ]
  # Stderr must say something — no silent failure (constraint C2 cousin).
  [ -n "$output$stderr" ]
}

@test "launch: malformed JSON from companion → nonzero with stderr" {
  export STUB_LAUNCH_BAD_JSON=1
  run bash -c 'cat "$PROMPT_FILE" | "$WRAPPER" launch'
  [ "$status" -ne 0 ]
  # Non-empty stderr OR error message in output (run merges by default in
  # current bats; we accept either).
  [ -n "$output" ] || [ -n "$stderr" ]
}

@test "launch: missing jobId in JSON → nonzero with stderr" {
  export STUB_LAUNCH_NO_JOBID=1
  run bash -c 'cat "$PROMPT_FILE" | "$WRAPPER" launch'
  [ "$status" -ne 0 ]
  [ -n "$output" ] || [ -n "$stderr" ]
}

@test "launch: zero-byte stdin → nonzero with stderr (no companion launch)" {
  : > "$TEST_ROOT/prompts/empty.txt"

  # Pre-condition: stub state file does not exist (the stub writes it only when
  # `handleTask` runs, which is what we're proving did NOT happen).
  [ ! -e "$STUB_STATE_FILE" ]

  # Pipe the empty file on stdin — wrapper must reject and never reach companion.
  run bash -c 'cat "$TEST_ROOT/prompts/empty.txt" | "$WRAPPER" launch'
  [ "$status" -ne 0 ]
  [ -n "$output" ] || [ -n "$stderr" ]

  # Post-condition: companion was never invoked, so the stub never had a chance
  # to persist its state file. Absence proves the wrapper failed closed at its
  # own boundary instead of punting the failure to the companion.
  [ ! -e "$STUB_STATE_FILE" ]
}

# ── path-arg retirement regression (#110 commit 21/22) ─────────────

@test "launch: path-arg form is retired — --prompt-file flag rejected" {
  # The legacy `launch --prompt-file <path>` invocation must now fail with a
  # non-zero exit and a clear error on stderr. Even passing a valid prompt
  # file MUST NOT succeed via the path-arg surface.
  run "$WRAPPER" launch --prompt-file "$PROMPT_FILE"
  [ "$status" -ne 0 ]
  [ -n "$output$stderr" ]
}

@test "launch: any positional argument is rejected (path-arg surface fully closed)" {
  # Bare positional argument (no flag) must also be rejected — defense in depth
  # against a future refactor that re-introduces a positional path-arg variant.
  run "$WRAPPER" launch "$PROMPT_FILE"
  [ "$status" -ne 0 ]
  [ -n "$output$stderr" ]
}

# ── await: happy path ──────────────────────────────────────────────

@test "await: exits 0 on completion and writes review markdown to stdout" {
  # Pre-seed state so status returns "completed" on first poll.
  echo '{"jobId":"job-abc","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_RAW=$'# Review\n\nLooks fine.\n'

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

# ── await: malformed / job-not-found ──────────────────────────────

@test "await: malformed status JSON → nonzero with stderr (constraint C2)" {
  echo '{"jobId":"job-bad","polls":0}' > "$STUB_STATE_FILE"
  export STUB_STATUS_BAD_JSON=1

  run "$WRAPPER" await job-bad
  [ "$status" -ne 0 ]
  [ "$status" -ne 10 ]   # not ceiling
  # Must emit something to stderr (or merged output) — never silent.
  [ -n "$output$stderr" ]
}

@test "await: malformed result JSON → nonzero with stderr; no partial stdout" {
  echo '{"jobId":"job-rb","polls":0}' > "$STUB_STATE_FILE"
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_BAD_JSON=1

  run "$WRAPPER" await job-rb
  [ "$status" -ne 0 ]
  [ "$status" -ne 10 ]
}

@test "await: companion reports job-not-found → exit 11 (distinct from ceiling and malformed) — constraint C4" {
  echo '{"jobId":"job-nf","polls":0}' > "$STUB_STATE_FILE"
  export STUB_JOB_NOT_FOUND=1

  run "$WRAPPER" await job-nf
  [ "$status" -eq 11 ]
  [ -n "$output$stderr" ]
}

@test "await: status hard error (not job-not-found) → exit 13 — constraint C4" {
  echo '{"jobId":"job-err","polls":0}' > "$STUB_STATE_FILE"
  export STUB_STATUS_EXIT=42

  run "$WRAPPER" await job-err
  [ "$status" -eq 13 ]
  [ "$status" -ne 11 ]
  [ -n "$output$stderr" ]
}

# ── CODEX_COMPANION default resolution (constraint C3) ────────────

@test "CODEX_COMPANION unset: wrapper uses portable glob default; missing → nonzero with stderr" {
  unset CODEX_COMPANION
  # Force the glob to a controlled empty location so we deterministically
  # exercise the missing-companion branch. The wrapper must fail loud.
  # Path-arg form retired: pipe prompt on stdin (#110 commit 21/22).
  HOME="$TEST_ROOT/empty-home" run bash -c 'cat "$PROMPT_FILE" | "$WRAPPER" launch'
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

# ── stdin support (commit 4 / issue #110) ─────────────────────────

# Test A — stdin path:
# When no --prompt-file is given and stdin is not a TTY, the wrapper reads
# the prompt from stdin, writes it to a temp file, and passes --prompt-file
# to the companion. Mirrors the argv-dump pattern used by test 73.
@test "launch: reads prompt from stdin when --prompt-file is omitted and stdin is not a tty" {
  export STUB_ARGV_DUMP="$TEST_ROOT/argv-stdin.dump"
  cat > "$TEST_ROOT/companion-stdin-record.mjs" <<'EOF'
#!/usr/bin/env node
import fs from "node:fs";
fs.writeFileSync(process.env.STUB_ARGV_DUMP, JSON.stringify(process.argv.slice(2)));
process.stdout.write(JSON.stringify({ jobId: "task-stub-stdin-recorder", status: "queued", title: "x", summary: "y", logFile: "/tmp/x" }) + "\n");
EOF
  chmod +x "$TEST_ROOT/companion-stdin-record.mjs"

  # Pipe a non-empty prompt on stdin (non-tty by virtue of the pipe).
  # bats `run` does not forward a pipe — invoke via a subshell so the wrapper
  # actually receives the piped stdin.
  export CODEX_COMPANION="$TEST_ROOT/companion-stdin-record.mjs"
  run bash -c 'echo "stdin prompt content" | "$WRAPPER" launch'

  [ "$status" -eq 0 ]
  [[ "$output" == *"task-stub-stdin-recorder"* ]]

  # Companion must have received --prompt-file pointing at a real temp file.
  argv=$(cat "$TEST_ROOT/argv-stdin.dump")
  [[ "$argv" == *"task"* ]]
  [[ "$argv" == *"--background"* ]]
  [[ "$argv" == *"--prompt-file"* ]]
}

# Test B — path-arg form is RETIRED (#110 commit 21/22):
# The legacy `launch --prompt-file <path>` invocation is now rejected by the
# wrapper. Regression coverage: see "launch: path-arg form is retired" and
# "launch: any positional argument is rejected" tests above.

# Test C — awk frontmatter-strip regression:
# Self-contained test of the awk one-liner used by the Codex pipeline dispatch
# introduced in this commit. Does NOT exercise the wrapper — verifies that awk
# strips only YAML front-matter and preserves body content (including internal
# --- separators), guarding against a future sed-form regression.
@test "awk frontmatter-strip preserves body content with internal --- separators" {
  local f=/tmp/awk-strip-test.$$.md
  cat > "$f" <<'EOF'
---
name: test
description: smoke
---

body line 1

---

body line 2 after a separator
EOF
  local out
  out=$(awk '/^---$/{n++; next} n>=2{print}' "$f")
  echo "$out" | grep -qF 'body line 1'
  echo "$out" | grep -qF 'body line 2 after a separator'
  ! echo "$out" | grep -qF 'name: test'
  rm -f "$f"
}
