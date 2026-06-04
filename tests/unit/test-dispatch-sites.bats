#!/usr/bin/env bats

# Cross-cutting CI test: verifies no migrated SKILL.md still embeds legacy
# reviewer-boilerplate content or uses the legacy /tmp or .codex-prompts
# prompt-file dispatch patterns. The migrated skills now use the stdin
# pipeline form (commit 18 / issue-110) and reference agent files +
# reviewer-protocol instead.
# Added in commit 22/22 of issue-110 migration.
#
# Task-20 additions (task-20.md Test expectations):
#   - File/rename audit: old script/test paths gone; new paths exist
#   - Grep audit: old script names have no live call sites in migrated skill prose
#   - Consumer-skill migration: all 12 SKILL.md files include
#     !cat skills/_shared/reviewer-dispatch-prose.md at reviewer dispatch
#   - Shared-prose content inspection: reviewer-dispatch-prose.md carries
#     locked dispatch-agent invocation, spec-line parse, iron law, DISPATCH_FILE,
#     await-round follow-up
#   - dispatch-companion JOB_ID=<id> launch contract
#   - third-party-finding-splitter.sh flag-based interface existence

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
}

@test "no migrated SKILL.md embeds the old reviewer-boilerplate content" {
  local skills=(goals questions research design structure phasing plan parallelize implement integrate replan test)
  for skill in "${skills[@]}"; do
    ! grep -qF 'embed reviewer-boilerplate.md verbatim' "skills/${skill}/SKILL.md" \
      || { echo "skills/${skill}/SKILL.md still references reviewer-boilerplate verbatim embed"; return 1; }
    ! grep -qF 'skills/_shared/reviewer-boilerplate.md' "skills/${skill}/SKILL.md" \
      || { echo "skills/${skill}/SKILL.md still references skills/_shared/reviewer-boilerplate.md"; return 1; }
  done
}

@test "no migrated SKILL.md uses the legacy /tmp codex prompt-file pattern" {
  local skills=(goals questions research design structure phasing plan parallelize implement integrate replan test)
  for skill in "${skills[@]}"; do
    ! grep -qE '/tmp/codex-prompt-' "skills/${skill}/SKILL.md" \
      || { echo "skills/${skill}/SKILL.md still uses /tmp/codex-prompt- dispatch pattern"; return 1; }
  done
}

@test "no migrated SKILL.md uses the .codex-prompts worktree-local prompt-file pattern" {
  local skills=(goals questions research design structure phasing plan parallelize implement integrate replan test)
  for skill in "${skills[@]}"; do
    ! grep -qE '\.codex-prompts/codex-prompt-task-' "skills/${skill}/SKILL.md" \
      || { echo "skills/${skill}/SKILL.md still uses .codex-prompts/ dispatch pattern"; return 1; }
  done
}

@test "no migrated SKILL.md references deleted template paths" {
  local skills=(goals questions research design structure phasing plan parallelize implement integrate replan test)
  local deleted_paths=(
    'skills/_shared/templates/scope-reviewer\.md'
    'skills/implement/templates/'
    'skills/integrate/templates/'
    'skills/test/templates/'
    'skills/plan/templates/'
  )
  for skill in "${skills[@]}"; do
    for path in "${deleted_paths[@]}"; do
      ! grep -qE "$path" "skills/${skill}/SKILL.md" \
        || { echo "skills/${skill}/SKILL.md still references deleted template path: $path"; return 1; }
    done
  done
}

# ===========================================================================
# Task-20: File/rename audit
# ===========================================================================

# Test expectation: new dispatch entrypoints exist as live files
@test "task-20 rename-audit: scripts/dispatch-agent.sh exists" {
  # Test expectation: hard rename landed; scripts/dispatch-agent.sh is the live entry point.
  [ -f "scripts/dispatch-agent.sh" ]
  [ -x "scripts/dispatch-agent.sh" ]
}

@test "task-20 rename-audit: scripts/dispatch-companion.sh exists" {
  # Test expectation: scripts/run-third-party-llm.sh renamed to scripts/dispatch-companion.sh.
  [ -f "scripts/dispatch-companion.sh" ]
  [ -x "scripts/dispatch-companion.sh" ]
}

@test "task-20 rename-audit: scripts/third-party-finding-splitter.sh exists" {
  # Test expectation: scripts/codex-finding-splitter.sh renamed to scripts/third-party-finding-splitter.sh.
  [ -f "scripts/third-party-finding-splitter.sh" ]
  [ -x "scripts/third-party-finding-splitter.sh" ]
}

@test "task-20 rename-audit: skills/_shared/reviewer-dispatch-prose.md exists" {
  # Test expectation: shared dispatch-prose snippet created per task-20.md scope bullet.
  [ -f "skills/_shared/reviewer-dispatch-prose.md" ]
}

@test "task-20 rename-audit: tests/unit/test-dispatch-agent.bats exists" {
  # Test expectation: test-run-codex-review.bats renamed to test-dispatch-agent.bats.
  [ -f "tests/unit/test-dispatch-agent.bats" ]
}

@test "task-20 rename-audit: scripts/run-codex-review.sh no longer exists" {
  # Test expectation: hard rename — old path must be completely gone; no shim allowed.
  [ ! -f "scripts/run-codex-review.sh" ]
}

@test "task-20 rename-audit: scripts/run-third-party-llm.sh no longer exists" {
  # Test expectation: hard rename — old path must be completely gone; no shim allowed.
  [ ! -f "scripts/run-third-party-llm.sh" ]
}

@test "task-20 rename-audit: scripts/codex-finding-splitter.sh no longer exists" {
  # Test expectation: hard rename — old path must be completely gone; no shim allowed.
  [ ! -f "scripts/codex-finding-splitter.sh" ]
}

@test "task-20 rename-audit: tests/unit/test-run-codex-review.bats no longer exists" {
  # Test expectation: test file rename completed — old path gone.
  [ ! -f "tests/unit/test-run-codex-review.bats" ]
}

# ===========================================================================
# Task-20: Grep audit — old script names have no live call sites
# ===========================================================================

# Test expectation: no live call sites for run-codex-review.sh in migrated skill prose
@test "task-20 grep-audit: run-codex-review.sh has no live call sites in migrated skill prose" {
  # Test expectation: the 12 consumer SKILL.md files must not reference the old script name
  # (task-20.md grep audit bullet).
  local skills=(goals questions research design structure phasing plan parallelize implement integrate replan test)
  for skill in "${skills[@]}"; do
    ! grep -qF 'run-codex-review.sh' "skills/${skill}/SKILL.md" \
      || { echo "skills/${skill}/SKILL.md still references run-codex-review.sh"; return 1; }
  done
}

@test "task-20 grep-audit: run-third-party-llm.sh has no live call sites in migrated skill prose" {
  # Test expectation: the 12 consumer SKILL.md files must not reference the old companion script name.
  local skills=(goals questions research design structure phasing plan parallelize implement integrate replan test)
  for skill in "${skills[@]}"; do
    ! grep -qF 'run-third-party-llm.sh' "skills/${skill}/SKILL.md" \
      || { echo "skills/${skill}/SKILL.md still references run-third-party-llm.sh"; return 1; }
  done
}

@test "task-20 grep-audit: codex-finding-splitter.sh has no live call sites in migrated skill prose" {
  # Test expectation: the 12 consumer SKILL.md files must not reference the old splitter script name.
  local skills=(goals questions research design structure phasing plan parallelize implement integrate replan test)
  for skill in "${skills[@]}"; do
    ! grep -qF 'codex-finding-splitter.sh' "skills/${skill}/SKILL.md" \
      || { echo "skills/${skill}/SKILL.md still references codex-finding-splitter.sh"; return 1; }
  done
}

@test "task-20 grep-audit: run-codex-review.sh not referenced as live caller in test-dispatch-agent.bats" {
  # Test expectation: test-dispatch-agent.bats must not set WRAPPER to run-codex-review.sh.
  # Historical absence-assertion tests are permitted (they assert the old name is absent).
  # Count of live script-path references (not absence-assertion lines) must be 0.
  local live_refs
  live_refs=$(grep -cE 'WRAPPER=.*run-codex-review\.sh' "tests/unit/test-dispatch-agent.bats" 2>/dev/null || true)
  [ "$live_refs" -eq 0 ]
}

# ===========================================================================
# Task-20: Consumer-skill migration — 12 SKILL.md files use shared include
# ===========================================================================

# Test expectation: every review-producing SKILL.md includes !cat skills/_shared/reviewer-dispatch-prose.md
@test "task-20 skill-migration: all 12 SKILL.md files include reviewer-dispatch-prose.md" {
  # Test expectation: each of the 12 consumer SKILL.md files must have the
  # '!cat skills/_shared/reviewer-dispatch-prose.md' directive at its reviewer
  # dispatch section (task-20.md consumer-skill grep/lint bullet).
  local skills=(goals questions research design structure phasing plan parallelize implement integrate replan test)
  for skill in "${skills[@]}"; do
    grep -qF '!cat skills/_shared/reviewer-dispatch-prose.md' "skills/${skill}/SKILL.md" \
      || { echo "skills/${skill}/SKILL.md missing !cat skills/_shared/reviewer-dispatch-prose.md include"; return 1; }
  done
}

# Test expectation: no SKILL.md carries inline per-reviewer Claude/Codex dispatch blocks
@test "task-20 skill-migration: no SKILL.md carries inline run-codex-review.sh dispatch blocks" {
  # Test expectation: the inline reviewer dispatch invocations using the old script names
  # must be replaced by the thin REVIEW_* preamble + shared include.
  local skills=(goals questions research design structure phasing plan parallelize implement integrate replan test)
  for skill in "${skills[@]}"; do
    ! grep -qF 'scripts/run-codex-review.sh' "skills/${skill}/SKILL.md" \
      || { echo "skills/${skill}/SKILL.md still has inline run-codex-review.sh dispatch block"; return 1; }
  done
}

# Test expectation: no SKILL.md carries old splitter pipe recipes
@test "task-20 skill-migration: no SKILL.md carries old codex-finding-splitter pipe recipes" {
  # Test expectation: old splitter pipe recipes are gone; await-round.sh handles splitting now.
  local skills=(goals questions research design structure phasing plan parallelize implement integrate replan test)
  for skill in "${skills[@]}"; do
    ! grep -qF 'codex-finding-splitter.sh' "skills/${skill}/SKILL.md" \
      || { echo "skills/${skill}/SKILL.md still has codex-finding-splitter.sh pipe recipe"; return 1; }
  done
}

# Test expectation: each migrated SKILL.md sets the required REVIEW_* preamble variables
@test "task-20 skill-migration: all 12 SKILL.md files set REVIEW_OUTPUT_DIR preamble var" {
  # Test expectation: the thin per-skill preamble must at minimum set REVIEW_OUTPUT_DIR
  # so the shared include can reference it when invoking dispatch-agent.sh and await-round.sh
  # (structure.md §skills/_shared/reviewer-dispatch-prose.md preamble contract).
  local skills=(goals questions research design structure phasing plan parallelize implement integrate replan test)
  for skill in "${skills[@]}"; do
    grep -qE 'REVIEW_OUTPUT_DIR' "skills/${skill}/SKILL.md" \
      || { echo "skills/${skill}/SKILL.md missing REVIEW_OUTPUT_DIR preamble variable"; return 1; }
  done
}

# ===========================================================================
# Task-20: Shared-prose content inspection
# ===========================================================================

# Test expectation: skills/_shared/reviewer-dispatch-prose.md contains dispatch-agent.sh command
@test "task-20 shared-prose: reviewer-dispatch-prose.md contains dispatch-agent.sh invocation" {
  # Test expectation: the locked dispatch-agent command must be in the shared snippet
  # (task-20.md shared-prose inspection bullet; structure.md §reviewer-dispatch-prose.md).
  grep -qF 'scripts/dispatch-agent.sh' 'skills/_shared/reviewer-dispatch-prose.md'
}

# Test expectation: shared prose contains spec-line parse instructions (MODE=first_party)
@test "task-20 shared-prose: reviewer-dispatch-prose.md contains MODE=first_party spec-line parse" {
  # Test expectation: the snippet must carry parse instructions for the spec-line format
  # so the orchestrator knows how to iterate (task-20.md shared-prose inspection bullet).
  grep -qF 'MODE=first_party' 'skills/_shared/reviewer-dispatch-prose.md'
}

# Test expectation: shared prose contains DISPATCH_FILE prompt rule
@test "task-20 shared-prose: reviewer-dispatch-prose.md contains DISPATCH_FILE prompt rule" {
  # Test expectation: the iron-law prompt rule 'prompt = "DISPATCH_FILE=<PROMPT_FILE-value>"'
  # must appear in the shared snippet (task-20.md shared-prose inspection bullet).
  grep -qF 'DISPATCH_FILE=' 'skills/_shared/reviewer-dispatch-prose.md'
}

# Test expectation: shared prose contains one Task call per spec line (iron law)
@test "task-20 shared-prose: reviewer-dispatch-prose.md contains one-Task-call-per-spec-line iron law" {
  # Test expectation: the iron law forbidding skipped / deduplicated / modified Task invocations
  # must appear in the shared snippet so every consumer skill inherits it via !cat include
  # (task-20.md shared-prose inspection bullet; design.md CD-1 §3 iron law).
  grep -qiE 'exactly once per.*spec line|one.*Task.*per.*spec line|invoke.*Task.*exactly once' \
    'skills/_shared/reviewer-dispatch-prose.md'
}

# Test expectation: shared prose contains unconditional await-round.sh --round-dir follow-up
@test "task-20 shared-prose: reviewer-dispatch-prose.md contains await-round.sh --round-dir follow-up" {
  # Test expectation: the await-round follow-up is unconditional (no-op-safe for first-party-only
  # rounds) and must appear in the shared snippet (task-20.md shared-prose inspection bullet).
  grep -qF 'scripts/await-round.sh --round-dir' 'skills/_shared/reviewer-dispatch-prose.md'
}

@test "task-20 shared-prose: reviewer-dispatch-prose.md references REVIEW_OUTPUT_DIR in await-round call" {
  # Test expectation: the await-round invocation uses the $REVIEW_OUTPUT_DIR preamble variable
  # so each consumer skill's round-dir is correct.
  grep -qE 'await-round\.sh.*--round-dir.*REVIEW_OUTPUT_DIR' 'skills/_shared/reviewer-dispatch-prose.md'
}

# ===========================================================================
# Task-20: dispatch-companion.sh JOB_ID= launch contract and interface audit
# ===========================================================================

# Test expectation: dispatch-companion.sh exists with the new flag-based interface
@test "task-20 companion: dispatch-companion.sh exists and is executable" {
  # Test expectation: run-third-party-llm.sh renamed to dispatch-companion.sh;
  # the renamed script must exist at the new path.
  [ -f "scripts/dispatch-companion.sh" ]
  [ -x "scripts/dispatch-companion.sh" ]
}

@test "task-20 companion: dispatch-companion.sh accepts launch flags and exits 0 with full flag set" {
  # Test expectation: dispatch-companion.sh accepts the full --vendor/--model/--prompt-file/
  # --round-dir/--tag flag surface and exits 0 when all required flags are present and valid.
  # Strengthened from the original "no 127" vacuous check: exit == 0 proves every required-flag
  # die() guard was satisfied, not merely that the script was found (task-20 R5 F01).
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local prompt_file="$tmp_dir/prompt.txt"
  printf 'Test prompt body\n' > "$prompt_file"
  run scripts/dispatch-companion.sh \
    --vendor stub \
    --model stub-model \
    --prompt-file "$prompt_file" \
    --round-dir "$tmp_dir" \
    --tag test-tag
  rm -rf "$tmp_dir"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# F01 (R5 fix-cycle): dispatch-companion.sh launch — loud failure for each
# individually omitted required flag.  DoD: "loud failure for missing flags"
# (task-20.md §companion/splitter fixture coverage, L55).
# Each test omits exactly one required flag (by passing an empty value) and
# asserts: (a) exit != 0, (b) stderr carries the flag name so the caller
# can diagnose which flag was missing.
# Falsifiability: replace the five `[ -n "$L_<FLAG>" ] || die ...` guards
# in dispatch-companion.sh (lines 582-586) with `:` no-ops; these tests fail.
# ---------------------------------------------------------------------------

@test "task-20 companion (F01): launch dies loudly when --vendor is omitted (empty)" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local prompt_file="$tmp_dir/prompt.txt"
  printf 'Test prompt body\n' > "$prompt_file"
  run --separate-stderr scripts/dispatch-companion.sh \
    --vendor "" \
    --model stub-model \
    --prompt-file "$prompt_file" \
    --round-dir "$tmp_dir" \
    --tag test-tag
  rm -rf "$tmp_dir"
  [ "$status" -ne 0 ]
  [[ "$stderr" == *"--vendor"* ]]
}

@test "task-20 companion (F01): launch dies loudly when --model is omitted (empty)" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local prompt_file="$tmp_dir/prompt.txt"
  printf 'Test prompt body\n' > "$prompt_file"
  run --separate-stderr scripts/dispatch-companion.sh \
    --vendor stub \
    --model "" \
    --prompt-file "$prompt_file" \
    --round-dir "$tmp_dir" \
    --tag test-tag
  rm -rf "$tmp_dir"
  [ "$status" -ne 0 ]
  [[ "$stderr" == *"--model"* ]]
}

@test "task-20 companion (F01): launch dies loudly when --prompt-file is omitted (empty)" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  run --separate-stderr scripts/dispatch-companion.sh \
    --vendor stub \
    --model stub-model \
    --prompt-file "" \
    --round-dir "$tmp_dir" \
    --tag test-tag
  rm -rf "$tmp_dir"
  [ "$status" -ne 0 ]
  [[ "$stderr" == *"--prompt-file"* ]]
}

@test "task-20 companion (F01): launch dies loudly when --round-dir is omitted (empty)" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local prompt_file="$tmp_dir/prompt.txt"
  printf 'Test prompt body\n' > "$prompt_file"
  run --separate-stderr scripts/dispatch-companion.sh \
    --vendor stub \
    --model stub-model \
    --prompt-file "$prompt_file" \
    --round-dir "" \
    --tag test-tag
  rm -rf "$tmp_dir"
  [ "$status" -ne 0 ]
  [[ "$stderr" == *"--round-dir"* ]]
}

@test "task-20 companion (F01): launch dies loudly when --tag is omitted (empty)" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local prompt_file="$tmp_dir/prompt.txt"
  printf 'Test prompt body\n' > "$prompt_file"
  run --separate-stderr scripts/dispatch-companion.sh \
    --vendor stub \
    --model stub-model \
    --prompt-file "$prompt_file" \
    --round-dir "$tmp_dir" \
    --tag ""
  rm -rf "$tmp_dir"
  [ "$status" -ne 0 ]
  [[ "$stderr" == *"--tag"* ]]
}

@test "task-20 companion: dispatch-companion.sh launch output contains only JOB_ID= (no payload echo)" {
  # Test expectation: the companion script's launch subcommand writes exactly 'JOB_ID=<id>'
  # to stdout; payload text must never echo into the orchestrator context (CD-1 #4 output-bound).
  # (This test is inherently network-stubbed; it verifies the contract is wired even under
  # a vendor error — a failed vendor call must not echo the prompt body to stdout.)
  # RED: scripts/dispatch-companion.sh doesn't exist yet.
  [ -f "scripts/dispatch-companion.sh" ]
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local prompt_file="$tmp_dir/prompt.txt"
  # Plant a recognisable sentinel in the prompt body.
  printf 'SECRET-COMPANION-PAYLOAD-XYZZY\n' > "$prompt_file"
  run scripts/dispatch-companion.sh \
    --vendor stub \
    --model stub-model \
    --prompt-file "$prompt_file" \
    --round-dir "$tmp_dir" \
    --tag test-tag 2>/dev/null
  rm -rf "$tmp_dir"
  # The prompt body sentinel must NEVER appear in stdout, regardless of exit code.
  ! [[ "$output" =~ "SECRET-COMPANION-PAYLOAD-XYZZY" ]]
}

@test "task-20 companion: dispatch-companion.sh await subcommand is recognised (no 'unrecognised subcommand')" {
  # Test expectation: 'dispatch-companion.sh await <job-id>' is a valid subcommand
  # (structure.md §dispatch-companion.sh await contract).  A missing job-id may produce
  # a non-zero exit but must not emit 'unrecognised subcommand'.
  # RED: scripts/dispatch-companion.sh doesn't exist yet.
  [ -f "scripts/dispatch-companion.sh" ]
  run scripts/dispatch-companion.sh await __NO_SUCH_JOB__
  [ "$status" -ne 127 ]
  ! [[ "$output" =~ "unrecognised subcommand" ]]
}

# ---------------------------------------------------------------------------
# F02 (round-1 fix-cycle): positive launch / await contract assertions for the
# dispatch-companion vendor-neutral interface. The earlier two companion tests
# above are negative-only (no payload echo / subcommand recognised) — they let
# the await stub pass. The two tests below exercise the codex transport via
# the existing test stub fixture (tests/fixtures/stub-codex-companion.mjs)
# wired through CODEX_COMPANION, then assert:
#   1. launch emits exactly `JOB_ID=<id>` on stdout (positive grammar match);
#   2. await writes raw vendor output to <round-dir>/.dispatch/<tag>.raw and
#      the await invocation itself emits no payload to stdout.
# ---------------------------------------------------------------------------

@test "task-20 companion (F02): launch --vendor codex emits JOB_ID=<id> on stdout via stubbed codex transport" {
  [ -f "scripts/dispatch-companion.sh" ]
  [ -f "tests/fixtures/stub-codex-companion.mjs" ]

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local prompt_file="$tmp_dir/prompt.txt"
  printf 'PROMPT-BODY-SENTINEL-LAUNCH-XYZZY\n' > "$prompt_file"

  # Stub codex broker; speed up codex-companion-bg.sh polling intervals.
  export CODEX_COMPANION="$BATS_TEST_DIRNAME/../fixtures/stub-codex-companion.mjs"
  export STUB_STATE_FILE="$tmp_dir/stub-state.json"
  export QRSPI_CODEX_POLL_INTERVAL_FAST=1
  export QRSPI_CODEX_POLL_INTERVAL_SLOW=1
  export QRSPI_CODEX_POLL_BACKOFF_AFTER=2
  export QRSPI_CODEX_CEILING_SECONDS=10
  export QRSPI_CODEX_LAUNCH_TIMEOUT_SECONDS=5

  run scripts/dispatch-companion.sh \
    --vendor codex \
    --model stub-model \
    --prompt-file "$prompt_file" \
    --round-dir "$tmp_dir" \
    --tag spec-codex

  local job_id_line="$output"
  rm -rf "$tmp_dir"

  [ "$status" -eq 0 ]
  # Exactly one line, exactly the JOB_ID=<id> grammar — no payload prefix/suffix.
  [[ "$job_id_line" =~ ^JOB_ID=[A-Za-z0-9._-]+$ ]]
  # The prompt sentinel must never appear on stdout (output-bound contract).
  ! [[ "$job_id_line" =~ "PROMPT-BODY-SENTINEL" ]]
}

@test "task-20 companion (F02): await captures raw vendor output to <round-dir>/.dispatch/<tag>.raw payload-silently" {
  [ -f "scripts/dispatch-companion.sh" ]
  [ -f "tests/fixtures/stub-codex-companion.mjs" ]

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local prompt_file="$tmp_dir/prompt.txt"
  printf 'launch prompt body\n' > "$prompt_file"

  export CODEX_COMPANION="$BATS_TEST_DIRNAME/../fixtures/stub-codex-companion.mjs"
  export STUB_STATE_FILE="$tmp_dir/stub-state.json"
  export QRSPI_CODEX_POLL_INTERVAL_FAST=1
  export QRSPI_CODEX_POLL_INTERVAL_SLOW=1
  export QRSPI_CODEX_POLL_BACKOFF_AFTER=2
  export QRSPI_CODEX_CEILING_SECONDS=10
  export QRSPI_CODEX_LAUNCH_TIMEOUT_SECONDS=5
  # Drive the stub to terminal status on poll #1 and emit a recognisable
  # rawOutput body so we can positively assert the .raw file content.
  export STUB_COMPLETE_AT_POLL=1
  export STUB_RESULT_RAW='STUB-REVIEWER-RAW-OUTPUT-MARKER-AAA'

  # 1. Launch — capture JOB_ID.
  run scripts/dispatch-companion.sh \
    --vendor codex \
    --model stub-model \
    --prompt-file "$prompt_file" \
    --round-dir "$tmp_dir" \
    --tag spec-codex
  [ "$status" -eq 0 ]
  local job_id="${output#JOB_ID=}"
  [ -n "$job_id" ]

  # 2. Await — must write raw to <round-dir>/.dispatch/<tag>.raw and emit no
  #    payload to stdout OR stderr. await-round.sh runs await_cmd with
  #    cwd=<round-dir>/.dispatch/ (so the .jobs/ record lookup is relative);
  #    we mirror that calling convention here.
  #    R5 F02: use --separate-stderr to capture stdout and stderr independently
  #    so we can assert the raw payload marker is absent from BOTH channels.
  local repo_root_abs
  repo_root_abs="$(pwd)"
  pushd "$tmp_dir/.dispatch" >/dev/null
  run --separate-stderr "$repo_root_abs/scripts/dispatch-companion.sh" await "$job_id"
  local await_status="$status"
  local await_stdout="$output"
  local await_stderr="$stderr"
  popd >/dev/null

  local raw_file="$tmp_dir/.dispatch/spec-codex.raw"
  local raw_exists=0
  local raw_contents=""
  if [ -f "$raw_file" ]; then
    raw_exists=1
    raw_contents="$(cat "$raw_file")"
  fi
  rm -rf "$tmp_dir"

  [ "$await_status" -eq 0 ]
  [ "$raw_exists" -eq 1 ]
  [ -n "$raw_contents" ]
  [[ "$raw_contents" == *"STUB-REVIEWER-RAW-OUTPUT-MARKER-AAA"* ]]
  # Payload-silent on stdout: the raw marker must NOT appear in await's stdout.
  ! [[ "$await_stdout" == *"STUB-REVIEWER-RAW-OUTPUT-MARKER-AAA"* ]]
  # Payload-silent on stderr (R5 F02): the raw marker must NOT appear in await's
  # stderr either.  DoD: "stdout or stderr payload silence" (task-20.md L43, L55).
  ! [[ "$await_stderr" == *"STUB-REVIEWER-RAW-OUTPUT-MARKER-AAA"* ]]
}
