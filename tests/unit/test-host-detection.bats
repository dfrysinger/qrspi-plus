#!/usr/bin/env bats
#
# tests/unit/test-host-detection.bats
# Task 6 — Host-aware Codex availability detection
# Target: scripts/dispatch-agent.sh
#
# Covers every test-expectation bullet from tasks/task-06.md:
#
#   TE1  detect_host emits 'copilot-cli', exits 0 when COPILOT_CLI=1
#   TE2  detect_host emits 'claude-code', exits 0 when COPILOT_CLI is unset
#   TE3  detect_host emits 'claude-code' when COPILOT_CLI is empty string
#   TE4  detect_host emits 'claude-code' for COPILOT_CLI=0 / true / yes
#   TE5  2-branch probe: only the literal string "1" → copilot-cli; all others → claude-code
#   TE6  COPILOT_CLI_BINARY_VERSION alone is not a host-detection trigger
#   TE7  detect_host output is solely determined by COPILOT_CLI; other env vars are irrelevant
#   TE8  check_codex_available 'copilot-cli' returns exit 0 without any filesystem probe
#   TE9  check_codex_available 'claude-code' returns exit 0 when companion glob resolves
#   TE10 check_codex_available 'claude-code' returns non-zero when companion glob is empty
#   TE11 check_codex_available with unrecognized host returns non-zero + single-line stderr diagnostic
#   TE12 dispatch surface emits mismatch warning naming both the detected host and config value;
#        warning is a stderr-only signal — dispatch runs and exits with the transport exit code
#   TE13 claude-code path emits [transport: shell-pipeline] exactly once in stderr;
#        [transport: task-tool] is absent
#   TE14 copilot-cli path emits [transport: task-tool] exactly once in stderr;
#        [transport: shell-pipeline] is absent
#   TE15 detect_host and check_codex_available write nothing to stderr under normal operation
#   TE16 dispatch surface propagates a non-zero transport exit code unchanged (no suppression)
#   TE17 mismatch path does not suppress a non-zero transport exit code
#
# Test strategy:
#   Function-isolation tests (TE1–TE11, TE15):
#     Each test runs a bash -c subshell that exports QRSPI_SOURCE_ONLY=1, sources
#     dispatch-agent.sh to load only function definitions, then calls detect_host or
#     check_codex_available directly.
#
#     The implementer MUST add this guard in dispatch-agent.sh, after the new function
#     definitions and before the argument-parsing block:
#
#         [[ "${QRSPI_SOURCE_ONLY:-}" == "1" ]] && return 0
#
#     RED state: the guard does not exist → sourcing runs the full script → validation
#     calls exit 1 (no --agent-file flag) → bash -c exits non-zero → tests fail. ✓
#
#   Dispatch surface tests (TE12–TE14, TE16–TE17):
#     Invoke dispatch-agent.sh in full dispatch mode (no --dry-run) with
#     QRSPI_REPO_ROOT pointing at a per-test mock directory containing:
#       scripts/dispatch-companion.sh  (mock dispatcher, exits MOCK_TRANSPORT_EXIT)
#       skills/reviewer-protocol/SKILL.md + stdout-fallback-emission.md  (stubs)
#       agents/qrspi-spec-reviewer.md  (minimal, no extra skill deps)
#       artifact-dir/config.md  (second_reviewer: value per test)
#     Stderr from the full invocation is captured to a temp file so transport-marker
#     and mismatch-diagnostic assertions can examine it directly.
#
#     RED state: the new dispatch surface code does not exist → transport markers are
#     never emitted → grep assertions fail. ✓
#
# Carry-forward set-asides from Plan R8:
#   S1: mismatch handling is warning-only; dispatch is not blocked (asserted in TE12, TE17).
#   S2: all four behaviors (host probe, codex check, transport marker, mismatch diagnostic)
#       land in this single task (TE1–TE7 probe; TE8–TE11 check; TE13–TE14 markers; TE12 mismatch).
#
# bash 3.2 portable: no mapfile, no declare -A, no ${var,,}, no coproc, no wait -n.

bats_require_minimum_version 1.5.0

# ---------------------------------------------------------------------------
# Suite setup — resolve the real repo root and wrapper path once.
# ---------------------------------------------------------------------------

setup_file() {
  REAL_REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd -P)"
  export REAL_REPO_ROOT
  WRAPPER="$REAL_REPO_ROOT/scripts/dispatch-agent.sh"
  export WRAPPER
}

# ---------------------------------------------------------------------------
# Per-test setup — build a fresh temp directory with a mock REPO_ROOT skeleton.
# ---------------------------------------------------------------------------

setup() {
  TMP_DIR="$(mktemp -d)"
  export TMP_DIR

  # Subject-code file required by --subject-code for dispatch invocations.
  mkdir -p "$TMP_DIR/src"
  printf 'const x = 1;\n' > "$TMP_DIR/src/subject.ts"

  # Mock reviewer-protocol files (compose_prompt in the wrapper reads these).
  mkdir -p "$TMP_DIR/skills/reviewer-protocol"
  printf '## Reviewer Dispatch Contract\nReviewer protocol stub.\n' \
    > "$TMP_DIR/skills/reviewer-protocol/SKILL.md"
  printf '<<<FINDING-BOUNDARY>>>\nCodex emission override stub.\n' \
    > "$TMP_DIR/skills/reviewer-protocol/stdout-fallback-emission.md"

  # Minimal agent file with no extra skill: dependencies so the skill-load
  # chain stays trivially short and the test fixture stays self-contained.
  mkdir -p "$TMP_DIR/agents"
  printf -- '---\nmodel: sonnet\nskills: []\n---\n\nStub agent body.\n' \
    > "$TMP_DIR/agents/qrspi-spec-reviewer.md"

  # Artifact directory with a default config (second_reviewer: false).
  # Individual tests write a different config.md when they need a specific value.
  mkdir -p "$TMP_DIR/artifact-dir"
  printf -- '---\nsecond_reviewer: false\n---\n' > "$TMP_DIR/artifact-dir/config.md"

  # Mock dispatcher: drains stdin, optionally emits MOCK_TRANSPORT_STDERR to stderr,
  # exits with MOCK_TRANSPORT_EXIT (default 0).  Lives at the path the wrapper expects
  # when QRSPI_REPO_ROOT=$TMP_DIR.
  mkdir -p "$TMP_DIR/scripts"
  cat > "$TMP_DIR/scripts/dispatch-companion.sh" <<'MOCK_DISPATCHER_EOF'
#!/usr/bin/env bash
# Mock dispatch-companion.sh for host-detection tests.
# Drain stdin so the upstream pipe does not block.
cat > /dev/null
if [ -n "${MOCK_TRANSPORT_STDERR:-}" ]; then
  printf '%s\n' "${MOCK_TRANSPORT_STDERR}" >&2
fi
# Emit a JOB_ID line on stdout so the dispatch-agent wrapper can record
# the manifest entry. Real dispatchers emit JOB_ID=<id>; a synthetic value
# is sufficient for tests that only assert dispatch ran and exit code.
printf 'JOB_ID=mock-job-%d\n' "$$"
exit "${MOCK_TRANSPORT_EXIT:-0}"
MOCK_DISPATCHER_EOF
  chmod +x "$TMP_DIR/scripts/dispatch-companion.sh"

  # HOME directory fixture for companion-glob tests (TE9, TE10).
  # Tests that want the companion to exist create the file tree inside here.
  MOCK_HOME="$TMP_DIR/mock-home"
  mkdir -p "$MOCK_HOME"
  export MOCK_HOME

  # Output directory for dispatch invocations (--output-dir must be absolute).
  mkdir -p "$TMP_DIR/out"
}

teardown() {
  cd /
  rm -rf "$TMP_DIR"
}

# ===========================================================================
# SECTION 1: detect_host function
#
# Each test runs a bash -c subshell that sources the wrapper in function-only
# mode (QRSPI_SOURCE_ONLY=1), then calls detect_host with the appropriate
# COPILOT_CLI value.
#
# RED state: no source guard exists → the full argument-parsing body runs →
# require_flag "agent-file" exits 1 → bash -c exits 1 → tests fail. ✓
# ===========================================================================

@test "[host-detect] detect_host emits copilot-cli to stdout when COPILOT_CLI=1" {
  # Test expectation: TE1 — detect_host emits 'copilot-cli' to stdout and
  # exits 0 when COPILOT_CLI=1 is present in the environment.
  #
  # gt.F01/gt.F02/tc.F02 (R12): skip-guard — detect_host requires BOTH COPILOT_CLI=1
  # AND a trusted-prefix gh binary.  On environments without a trusted-prefix gh
  # (alpine CI, minimal base images), this test would fail or pass vacuously.
  # Mirror the precondition check from [r5-sec.F01] in test-codex-review-host-detection.bats.
  # Use `|| true` so the assignment does NOT propagate `command -v`'s exit-1 when
  # gh is absent (bats's errexit would fire before the skip-guard runs).
  _trusted_gh="$(command -v gh 2>/dev/null || true)"
  if [[ -z "$_trusted_gh" ]]; then
    skip "no gh binary on this host (precondition for copilot-cli emission)"
  fi
  _trusted_gh="$(realpath "$_trusted_gh" 2>/dev/null || readlink -f "$_trusted_gh" 2>/dev/null)" || _trusted_gh=""
  case "$_trusted_gh" in
    /usr/* | /opt/* | /Applications/*) ;;
    *) skip "gh ($_trusted_gh) not in trusted prefix on this host" ;;
  esac

  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    export COPILOT_CLI=1
    . \"$WRAPPER\"
    detect_host
  "
  [ "$status" -eq 0 ]
  [ "$output" = "copilot-cli" ]
}

@test "[host-detect] detect_host exits 0 when COPILOT_CLI=1" {
  # Test expectation: TE1 — exit code must be 0 on the copilot-cli path.
  #
  # gt.F01/gt.F02/tc.F02 (R12): skip-guard — same trusted-prefix precondition as
  # the TE1 stdout test above.
  # Use `|| true` so the assignment does NOT propagate `command -v`'s exit-1 when
  # gh is absent (bats's errexit would fire before the skip-guard runs).
  _trusted_gh="$(command -v gh 2>/dev/null || true)"
  if [[ -z "$_trusted_gh" ]]; then
    skip "no gh binary on this host (precondition for copilot-cli emission)"
  fi
  _trusted_gh="$(realpath "$_trusted_gh" 2>/dev/null || readlink -f "$_trusted_gh" 2>/dev/null)" || _trusted_gh=""
  case "$_trusted_gh" in
    /usr/* | /opt/* | /Applications/*) ;;
    *) skip "gh ($_trusted_gh) not in trusted prefix on this host" ;;
  esac

  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    export COPILOT_CLI=1
    . \"$WRAPPER\"
    detect_host
  "
  [ "$status" -eq 0 ]
}

@test "[host-detect] detect_host emits claude-code when COPILOT_CLI is unset" {
  # Test expectation: TE2 — detect_host emits 'claude-code' to stdout and exits 0
  # when COPILOT_CLI is not present in the environment at all.
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    unset COPILOT_CLI
    . \"$WRAPPER\"
    detect_host
  "
  [ "$status" -eq 0 ]
  [ "$output" = "claude-code" ]
}

@test "[host-detect] detect_host emits claude-code when COPILOT_CLI is empty string" {
  # Test expectation: TE3 — COPILOT_CLI="" (set but empty) is treated identically
  # to unset; detect_host must emit 'claude-code'.
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    export COPILOT_CLI=''
    . \"$WRAPPER\"
    detect_host
  "
  [ "$status" -eq 0 ]
  [ "$output" = "claude-code" ]
}

@test "[host-detect] detect_host emits claude-code when COPILOT_CLI=0" {
  # Test expectation: TE4/TE5 — COPILOT_CLI=0 is not the literal string '1'.
  # The 2-branch probe must return claude-code for all non-'1' values.
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    export COPILOT_CLI=0
    . \"$WRAPPER\"
    detect_host
  "
  [ "$status" -eq 0 ]
  [ "$output" = "claude-code" ]
}

@test "[host-detect] detect_host emits claude-code when COPILOT_CLI=true" {
  # Test expectation: TE4 — the string 'true' is not the literal '1' → claude-code.
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    export COPILOT_CLI=true
    . \"$WRAPPER\"
    detect_host
  "
  [ "$status" -eq 0 ]
  [ "$output" = "claude-code" ]
}

@test "[host-detect] detect_host emits claude-code when COPILOT_CLI=yes" {
  # Test expectation: TE4 — the string 'yes' is not the literal '1' → claude-code.
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    export COPILOT_CLI=yes
    . \"$WRAPPER\"
    detect_host
  "
  [ "$status" -eq 0 ]
  [ "$output" = "claude-code" ]
}

@test "[host-detect] 2-branch probe: COPILOT_CLI=11 is not the literal string 1 so emits claude-code" {
  # Test expectation: TE5 — the probe accepts only the EXACT string '1'.
  # '11', ' 1', '1 ', and '01' all fall through to the claude-code branch.
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    export COPILOT_CLI=11
    . \"$WRAPPER\"
    detect_host
  "
  [ "$status" -eq 0 ]
  [ "$output" = "claude-code" ]
}

@test "[host-detect] COPILOT_CLI_BINARY_VERSION set but COPILOT_CLI unset still emits claude-code" {
  # Test expectation: TE6 — COPILOT_CLI_BINARY_VERSION alone is not a host-detection
  # trigger; detect_host must emit 'claude-code' when COPILOT_CLI is absent.
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    unset COPILOT_CLI
    export COPILOT_CLI_BINARY_VERSION=1.0.55-3
    . \"$WRAPPER\"
    detect_host
  "
  [ "$status" -eq 0 ]
  [ "$output" = "claude-code" ]
}

@test "[host-detect] detect_host result is unchanged when other Copilot env vars are present" {
  # Test expectation: TE7 — detect_host output is solely determined by COPILOT_CLI.
  # COPILOT_AGENT_SESSION_ID, COPILOT_RUN_APP, COPILOT_LOADER_PID, and similar
  # env vars must not affect the result.
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    unset COPILOT_CLI
    export COPILOT_AGENT_SESSION_ID=3a8f1c22-dead-beef-cafe-000000000001
    export COPILOT_RUN_APP=1
    export COPILOT_LOADER_PID=99999
    export COPILOT_CLI_BINARY_VERSION=1.0.55-3
    . \"$WRAPPER\"
    detect_host
  "
  [ "$status" -eq 0 ]
  [ "$output" = "claude-code" ]
}

# ===========================================================================
# SECTION 2: check_codex_available function
# ===========================================================================

@test "[codex-availability] check_codex_available returns exit 0 for copilot-cli without filesystem probe" {
  # Test expectation: TE8 — under copilot-cli, Codex is a natively routable model
  # via the task tool; no companion file on disk is required.
  # MOCK_HOME is empty (no companion installed) — the function must NOT probe it.
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    export HOME=\"$MOCK_HOME\"
    . \"$WRAPPER\"
    check_codex_available copilot-cli
  "
  [ "$status" -eq 0 ]
}

@test "[codex-availability] check_codex_available returns exit 0 for claude-code when companion glob resolves" {
  # Test expectation: TE9 — companion-script glob resolves to ≥1 existing file → exit 0.
  # Create a minimal companion stub under the mock HOME to simulate an installed companion.
  mkdir -p "$MOCK_HOME/.claude/plugins/cache/openai-codex/codex/v1.0.55/scripts"
  printf '#!/usr/bin/env node\n// stub companion\n' \
    > "$MOCK_HOME/.claude/plugins/cache/openai-codex/codex/v1.0.55/scripts/codex-companion.mjs"

  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    export HOME=\"$MOCK_HOME\"
    . \"$WRAPPER\"
    check_codex_available claude-code
  "
  [ "$status" -eq 0 ]
}

@test "[codex-availability] check_codex_available returns non-zero for claude-code when companion glob is empty" {
  # Test expectation: TE10 — companion-script glob resolves to no files → non-zero exit.
  # MOCK_HOME has no companion directory tree, so the glob must be empty.
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    export HOME=\"$MOCK_HOME\"
    . \"$WRAPPER\"
    check_codex_available claude-code
  "
  [ "$status" -ne 0 ]
}

@test "[codex-availability] check_codex_available returns non-zero for unrecognized host argument" {
  # Test expectation: TE11 — an unrecognized host string must produce a non-zero exit.
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    . \"$WRAPPER\"
    check_codex_available unknown-host-xyz 2>/dev/null
  "
  [ "$status" -ne 0 ]
}

@test "[codex-availability] check_codex_available emits single-line stderr diagnostic for unrecognized host" {
  # Test expectation: TE11 — the stderr diagnostic must identify the unsupported
  # host value so an operator can diagnose the configuration problem.
  TMP_STDERR="$TMP_DIR/check-avail-stderr.txt"
  bash -c "
    export QRSPI_SOURCE_ONLY=1
    . \"$WRAPPER\" 2>/dev/null
    check_codex_available unknown-host-xyz
  " >/dev/null 2>"$TMP_STDERR" || true

  # Exactly one non-empty line must be written to stderr.
  line_count="$(grep -c '' "$TMP_STDERR" 2>/dev/null || printf '0')"
  [ "$line_count" -eq 1 ]

  # The diagnostic must name the unsupported host value.
  grep -q "unknown-host-xyz" "$TMP_STDERR"
}

# ===========================================================================
# SECTION 3: Stderr cleanliness under normal (non-error) operation
#
# RED state: sourcing exits 1 (no guard) → bash -c subshell exits non-zero
# → the func_status assertion fails before the stderr-empty assertion. ✓
# ===========================================================================

@test "[host-detect] detect_host writes nothing to stderr on copilot-cli path" {
  # Test expectation: TE15 — detect_host must not emit anything to stderr
  # under normal operation; stderr silence is part of the function contract.
  TMP_STDERR="$TMP_DIR/detect-copilot-stderr.txt"
  bash -c "
    export QRSPI_SOURCE_ONLY=1
    export COPILOT_CLI=1
    . \"$WRAPPER\"
    detect_host
  " >/dev/null 2>"$TMP_STDERR"
  func_status=$?
  # RED: detect_host absent → bash -c exits non-zero → func_status != 0 → fails here.
  [ "$func_status" -eq 0 ]
  # GREEN: detect_host ran cleanly; no diagnostic output permitted.
  [ ! -s "$TMP_STDERR" ]
}

@test "[host-detect] detect_host writes nothing to stderr on claude-code path" {
  # Test expectation: TE15 — same stderr-silence contract for the claude-code branch.
  TMP_STDERR="$TMP_DIR/detect-claude-stderr.txt"
  bash -c "
    export QRSPI_SOURCE_ONLY=1
    unset COPILOT_CLI
    . \"$WRAPPER\"
    detect_host
  " >/dev/null 2>"$TMP_STDERR"
  func_status=$?
  [ "$func_status" -eq 0 ]
  [ ! -s "$TMP_STDERR" ]
}

@test "[codex-availability] check_codex_available copilot-cli writes nothing to stderr under normal operation" {
  # Test expectation: TE15 — check_codex_available must not write to stderr when
  # the call succeeds normally (valid host, copilot-cli path).
  TMP_STDERR="$TMP_DIR/check-copilot-stderr.txt"
  bash -c "
    export QRSPI_SOURCE_ONLY=1
    . \"$WRAPPER\"
    check_codex_available copilot-cli
  " >/dev/null 2>"$TMP_STDERR"
  func_status=$?
  [ "$func_status" -eq 0 ]
  [ ! -s "$TMP_STDERR" ]
}

# ===========================================================================
# SECTION 4: Dispatch surface — transport markers, mismatch, exit-code propagation
#
# All tests in this section invoke dispatch-agent.sh in full dispatch mode
# (no --dry-run) with QRSPI_REPO_ROOT=$TMP_DIR so the mock dispatcher at
# $TMP_DIR/scripts/dispatch-companion.sh is used.
#
# Stderr from the whole invocation is captured to a temp file for assertion.
#
# RED state: the new dispatch surface code does not exist in the script →
# transport markers are never emitted → grep assertions fail. ✓
# ===========================================================================

@test "[dispatch-surface] claude-code path emits [transport: shell-pipeline] exactly once in stderr" {
  # Test expectation: TE13 — when the dispatch surface selects the Claude Code
  # shell-pipeline path (detected host = claude-code, COPILOT_CLI unset/empty),
  # the marker '[transport: shell-pipeline]' appears exactly once on stderr.
  TMP_STDERR="$TMP_DIR/t13-stderr.txt"
  QRSPI_REPO_ROOT="$TMP_DIR" \
    COPILOT_CLI="" \
    bash "$WRAPPER" \
      --agent-file agents/qrspi-spec-reviewer.md \
      --reviewer-tag spec-codex \
      --output-dir "$TMP_DIR/out" \
      --round 1 \
      --subject-code "$TMP_DIR/src/subject.ts" \
      --model gpt-5-codex \
      --output-file "$TMP_DIR/result.md" \
      --artifact-dir "$TMP_DIR/artifact-dir" \
    >"$TMP_DIR/t13-stdout.txt" 2>"$TMP_STDERR" || true

  marker_count="$(grep -c '\[transport: shell-pipeline\]' "$TMP_STDERR" 2>/dev/null || printf '0')"
  [ "$marker_count" -eq 1 ]
}

@test "[dispatch-surface] claude-code path does not emit [transport: task-tool] in stderr" {
  # Test expectation: TE13 — '[transport: task-tool]' must be ABSENT from stderr
  # when the claude-code shell-pipeline path is selected.
  TMP_STDERR="$TMP_DIR/t13b-stderr.txt"
  QRSPI_REPO_ROOT="$TMP_DIR" \
    COPILOT_CLI="" \
    bash "$WRAPPER" \
      --agent-file agents/qrspi-spec-reviewer.md \
      --reviewer-tag spec-codex \
      --output-dir "$TMP_DIR/out" \
      --round 1 \
      --subject-code "$TMP_DIR/src/subject.ts" \
      --model gpt-5-codex \
      --output-file "$TMP_DIR/result.md" \
      --artifact-dir "$TMP_DIR/artifact-dir" \
    >"$TMP_DIR/t13b-stdout.txt" 2>"$TMP_STDERR" || true

  ! grep -q '\[transport: task-tool\]' "$TMP_STDERR"
}

@test "[dispatch-surface] copilot-cli path emits [transport: task-tool] exactly once in stderr" {
  # Test expectation: TE14 — when dispatch surface selects the Copilot CLI task-tool
  # path (detected host = copilot-cli, COPILOT_CLI=1), the marker
  # '[transport: task-tool]' appears exactly once on stderr.
  # config.md set to second_reviewer: true so the copilot-cli dispatch is not skipped
  # by an availability gate before the marker can be emitted.
  # The actual task-tool invocation may fail in a non-copilot test environment;
  # this test asserts only on the transport marker, not the final exit code.
  #
  # gt.F01/gt.F02/tc.F02 (R12): skip-guard — detect_host requires a trusted-prefix gh.
  # On CI environments without a trusted-prefix gh binary, COPILOT_CLI=1 falls back
  # to claude-code and the task-tool marker is never emitted.
  # Use `|| true` so the assignment does NOT propagate `command -v`'s exit-1 when
  # gh is absent (bats's errexit would fire before the skip-guard runs).
  _trusted_gh="$(command -v gh 2>/dev/null || true)"
  if [[ -z "$_trusted_gh" ]]; then
    skip "no gh binary on this host (precondition for copilot-cli emission)"
  fi
  _trusted_gh="$(realpath "$_trusted_gh" 2>/dev/null || readlink -f "$_trusted_gh" 2>/dev/null)" || _trusted_gh=""
  case "$_trusted_gh" in
    /usr/* | /opt/* | /Applications/*) ;;
    *) skip "gh ($_trusted_gh) not in trusted prefix on this host" ;;
  esac

  printf -- '---\nsecond_reviewer: true\n---\n' > "$TMP_DIR/artifact-dir/config.md"

  TMP_STDERR="$TMP_DIR/t14-stderr.txt"
  QRSPI_REPO_ROOT="$TMP_DIR" \
    COPILOT_CLI=1 \
    bash "$WRAPPER" \
      --agent-file agents/qrspi-spec-reviewer.md \
      --reviewer-tag spec-codex \
      --output-dir "$TMP_DIR/out" \
      --round 1 \
      --subject-code "$TMP_DIR/src/subject.ts" \
      --model gpt-5-codex \
      --output-file "$TMP_DIR/result.md" \
      --artifact-dir "$TMP_DIR/artifact-dir" \
    >"$TMP_DIR/t14-stdout.txt" 2>"$TMP_STDERR" || true

  marker_count="$(grep -c '\[transport: task-tool\]' "$TMP_STDERR" 2>/dev/null || printf '0')"
  [ "$marker_count" -eq 1 ]
}

@test "[dispatch-surface] copilot-cli path does not emit [transport: shell-pipeline] in stderr" {
  # Test expectation: TE14 — '[transport: shell-pipeline]' must be ABSENT from stderr
  # when the copilot-cli task-tool path is selected.
  #
  # gt.F01/gt.F02/tc.F02 (R12): skip-guard — detect_host requires a trusted-prefix gh.
  # On CI environments without a trusted-prefix gh binary, COPILOT_CLI=1 falls back
  # to claude-code and this assertion would pass vacuously (wrong path was taken).
  # Use `|| true` so the assignment does NOT propagate `command -v`'s exit-1 when
  # gh is absent (bats's errexit would fire before the skip-guard runs).
  _trusted_gh="$(command -v gh 2>/dev/null || true)"
  if [[ -z "$_trusted_gh" ]]; then
    skip "no gh binary on this host (precondition for copilot-cli emission)"
  fi
  _trusted_gh="$(realpath "$_trusted_gh" 2>/dev/null || readlink -f "$_trusted_gh" 2>/dev/null)" || _trusted_gh=""
  case "$_trusted_gh" in
    /usr/* | /opt/* | /Applications/*) ;;
    *) skip "gh ($_trusted_gh) not in trusted prefix on this host" ;;
  esac

  printf -- '---\nsecond_reviewer: true\n---\n' > "$TMP_DIR/artifact-dir/config.md"

  TMP_STDERR="$TMP_DIR/t14b-stderr.txt"
  QRSPI_REPO_ROOT="$TMP_DIR" \
    COPILOT_CLI=1 \
    bash "$WRAPPER" \
      --agent-file agents/qrspi-spec-reviewer.md \
      --reviewer-tag spec-codex \
      --output-dir "$TMP_DIR/out" \
      --round 1 \
      --subject-code "$TMP_DIR/src/subject.ts" \
      --model gpt-5-codex \
      --output-file "$TMP_DIR/result.md" \
      --artifact-dir "$TMP_DIR/artifact-dir" \
    >"$TMP_DIR/t14b-stdout.txt" 2>"$TMP_STDERR" || true

  ! grep -q '\[transport: shell-pipeline\]' "$TMP_STDERR"
}

@test "[dispatch-surface] mismatch warning names both the detected host and the second_reviewer config value" {
  # Test expectation: TE12 — when detect_host output disagrees with the second_reviewer
  # config value, the dispatch surface emits a single line to stderr that names BOTH
  # the detected host value AND the config value so an operator can act on it.
  #
  # Mismatch scenario from the spec example: detected host = 'claude-code' (COPILOT_CLI
  # unset), config second_reviewer = true.  MOCK_HOME has no companion file, so
  # check_codex_available(claude-code) returns non-zero → mismatch with second_reviewer: true.
  printf -- '---\nsecond_reviewer: true\n---\n' > "$TMP_DIR/artifact-dir/config.md"

  TMP_STDERR="$TMP_DIR/t12-stderr.txt"
  QRSPI_REPO_ROOT="$TMP_DIR" \
    COPILOT_CLI="" \
    HOME="$MOCK_HOME" \
    bash "$WRAPPER" \
      --agent-file agents/qrspi-spec-reviewer.md \
      --reviewer-tag spec-codex \
      --output-dir "$TMP_DIR/out" \
      --round 1 \
      --subject-code "$TMP_DIR/src/subject.ts" \
      --model gpt-5-codex \
      --output-file "$TMP_DIR/result.md" \
      --artifact-dir "$TMP_DIR/artifact-dir" \
    >"$TMP_DIR/t12-stdout.txt" 2>"$TMP_STDERR" || true

  # Stderr must contain both the detected host value and the config value.
  grep -q "claude-code" "$TMP_STDERR"
  grep -q "true" "$TMP_STDERR"
  # Both must appear on the SAME line (single-line diagnostic requirement).
  grep -qE "claude-code.*true|true.*claude-code" "$TMP_STDERR"
}

@test "[dispatch-surface] mismatch is warning-only: dispatch runs and exits with transport exit code" {
  # Test expectation: TE12 (warning-only clause) — the mismatch warning must not block
  # dispatch; the dispatch surface must still invoke the transport and propagate its exit
  # code.  Here the mock transport exits 0; the dispatch surface must also exit 0.
  #
  # The grep on 'claude-code' proves the new dispatch surface ran (mismatch path active).
  # If it were missing, the test would fail at the grep line, not at the exit-code check.
  #
  # T7 update: the original scenario (no companion + second_reviewer=true) now triggers
  # the T7 codex-unavailable short-circuit (avail=false AND config=true → exit non-zero
  # before dispatch).  Switch to the avail=true + config=false mismatch scenario so we
  # still exercise warning-only-with-dispatch-continuing: populate the companion path
  # (avail=true via the glob) and set second_reviewer=false → mismatch fires, no
  # short-circuit, transport runs to completion.
  mkdir -p "$MOCK_HOME/.claude/plugins/cache/openai-codex/codex/v1.0.55/scripts"
  printf '// mock codex-companion stub\n' \
    > "$MOCK_HOME/.claude/plugins/cache/openai-codex/codex/v1.0.55/scripts/codex-companion.mjs"
  printf -- '---\nsecond_reviewer: false\n---\n' > "$TMP_DIR/artifact-dir/config.md"

  TMP_STDERR="$TMP_DIR/t12b-stderr.txt"
  QRSPI_REPO_ROOT="$TMP_DIR" \
    COPILOT_CLI="" \
    HOME="$MOCK_HOME" \
    MOCK_TRANSPORT_EXIT=0 \
    bash "$WRAPPER" \
      --agent-file agents/qrspi-spec-reviewer.md \
      --reviewer-tag spec-codex \
      --output-dir "$TMP_DIR/out" \
      --round 1 \
      --subject-code "$TMP_DIR/src/subject.ts" \
      --model gpt-5-codex \
      --output-file "$TMP_DIR/result.md" \
      --artifact-dir "$TMP_DIR/artifact-dir" \
    >"$TMP_DIR/t12b-stdout.txt" 2>"$TMP_STDERR"
  dispatch_status=$?

  # Mismatch warning must be present in stderr (proves the new dispatch path ran).
  grep -q "claude-code" "$TMP_STDERR"
  # Exit code must come from the transport (0), not from mismatch logic.
  [ "$dispatch_status" -eq 0 ]
}

@test "[dispatch-surface] non-zero transport exit code is propagated unchanged on shell-pipeline path" {
  # Test expectation: TE16 — when the dispatch surface invokes the shell-pipeline
  # transport and that transport exits with a non-zero exit code, the dispatch surface
  # propagates that exact code to the caller with no suppression or remapping.
  #
  # The grep on '[transport: shell-pipeline]' proves the T06 dispatch surface ran
  # (not the pre-T06 legacy path which would also propagate the code but not emit the
  # marker).  Without this anchor, TE16 would trivially pass against unmodified code.
  TMP_STDERR="$TMP_DIR/t16-stderr.txt"
  # Use && ... || dispatch_status=$? to capture non-zero exits in bats (which
  # runs test bodies with set -e active; a bare non-zero command would abort
  # the test body before dispatch_status=$? could run).
  dispatch_status=0
  QRSPI_REPO_ROOT="$TMP_DIR" \
    COPILOT_CLI="" \
    MOCK_TRANSPORT_EXIT=42 \
    bash "$WRAPPER" \
      --agent-file agents/qrspi-spec-reviewer.md \
      --reviewer-tag spec-codex \
      --output-dir "$TMP_DIR/out" \
      --round 1 \
      --subject-code "$TMP_DIR/src/subject.ts" \
      --model gpt-5-codex \
      --output-file "$TMP_DIR/result.md" \
      --artifact-dir "$TMP_DIR/artifact-dir" \
    >"$TMP_DIR/t16-stdout.txt" 2>"$TMP_STDERR" && dispatch_status=0 || dispatch_status=$?

  # [transport: shell-pipeline] in stderr confirms the T06 dispatch surface ran.
  grep -q '\[transport: shell-pipeline\]' "$TMP_STDERR"
  # Exit code must be 42 (propagated from mock transport, not suppressed or remapped).
  [ "$dispatch_status" -eq 42 ]
}

@test "[dispatch-surface] mismatch path does not suppress non-zero transport exit code" {
  # Test expectation: TE17 — even when a mismatch warning is emitted, a non-zero exit
  # code from the underlying transport must be propagated to the caller unchanged.
  # The mismatch warning path must not swallow failures.
  #
  # Mismatch scenario: COPILOT_CLI unset (claude-code), companion present so
  # avail=true, second_reviewer: false → mismatch (avail≠config) without triggering
  # the T7 codex-unavailable short-circuit.  Mock transport exits 7.
  #
  # T7 update: the original scenario (no companion + second_reviewer=true) now triggers
  # the codex-unavailable short-circuit, so the transport never runs and there's no
  # transport exit code to suppress.  The avail=true + config=false scenario still
  # exercises the "mismatch warning does not suppress transport failure" contract.
  mkdir -p "$MOCK_HOME/.claude/plugins/cache/openai-codex/codex/v1.0.55/scripts"
  printf '// mock codex-companion stub\n' \
    > "$MOCK_HOME/.claude/plugins/cache/openai-codex/codex/v1.0.55/scripts/codex-companion.mjs"
  printf -- '---\nsecond_reviewer: false\n---\n' > "$TMP_DIR/artifact-dir/config.md"

  TMP_STDERR="$TMP_DIR/t17-stderr.txt"
  # Use && ... || dispatch_status=$? to capture non-zero exits in bats (same
  # rationale as TE16: bats test bodies run with set -e active).
  dispatch_status=0
  QRSPI_REPO_ROOT="$TMP_DIR" \
    COPILOT_CLI="" \
    HOME="$MOCK_HOME" \
    MOCK_TRANSPORT_EXIT=7 \
    bash "$WRAPPER" \
      --agent-file agents/qrspi-spec-reviewer.md \
      --reviewer-tag spec-codex \
      --output-dir "$TMP_DIR/out" \
      --round 1 \
      --subject-code "$TMP_DIR/src/subject.ts" \
      --model gpt-5-codex \
      --output-file "$TMP_DIR/result.md" \
      --artifact-dir "$TMP_DIR/artifact-dir" \
    >"$TMP_DIR/t17-stdout.txt" 2>"$TMP_STDERR" && dispatch_status=0 || dispatch_status=$?

  # Mismatch warning in stderr confirms the mismatch path ran (proves new code active).
  grep -q "claude-code" "$TMP_STDERR"
  # Exit code must be 7 (from transport), not 0 or any other override.
  [ "$dispatch_status" -eq 7 ]
}

# ===========================================================================
# SECTION 5: R2 correctness fixes (T6 R3 fix-cycle)
#
# Six tests — one per R2 finding kept after Hotfix A+B threshold:
#   sec.F01: transport-marker spoofable via COPILOT_CLI (binary-validation gate)
#   sec.F02: HOME glob unvalidated (reject unsafe HOME before glob)
#   sec.F03: mismatch echo injects terminal control chars (strip before echo)
#   sf.F01:  source guard fails open on direct execution (return 0 || exit 0)
#   sf.F02:  pipefail-off masks compose_prompt failure (set -o pipefail subshell)
#   sf.F03:  check_codex_available stderr swallowed by 2>/dev/null at call site
# ===========================================================================

@test "[r3-sec.F01] detect_host emits claude-code when COPILOT_CLI=1 but gh binary not reachable in PATH" {
  # sec.F01: transport-marker is spoofable because detect_host trusts the
  # user-supplied COPILOT_CLI env var without validating that the gh/copilot
  # binary is actually reachable.  After the fix, detect_host checks
  # `command -v gh` before emitting 'copilot-cli'; if gh is absent it falls
  # back to 'claude-code', making the marker harder to forge.
  #
  # RED state: the current code ignores binary reachability and emits
  # 'copilot-cli' whenever COPILOT_CLI=1, regardless of PATH.
  # The assertion `[ "$output" = "claude-code" ]` therefore FAILS. ✓
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    export COPILOT_CLI=1
    export PATH=/usr/bin:/bin
    . \"$WRAPPER\"
    detect_host
  "
  [ "$status" -eq 0 ]
  [ "$output" = "claude-code" ]
}

@test "[r3-sec.F02] check_codex_available emits diagnostic and returns non-zero when HOME contains .. component" {
  # sec.F02: HOME is taken verbatim for the companion-glob path with no
  # path-safety check.  A caller can set HOME to a path with '..' components
  # to probe arbitrary filesystem locations.  After the fix, check_codex_available
  # rejects HOME values containing '..' and emits a diagnostic to stderr.
  #
  # RED state: the current code performs no HOME validation; it silently
  # fails (glob finds nothing) without any stderr diagnostic.
  # grep for "unsafe" therefore FAILS. ✓
  TMP_STDERR="$TMP_DIR/r3-sec-f02-stderr.txt"
  bash -c "
    export QRSPI_SOURCE_ONLY=1
    export HOME=\"$TMP_DIR/../unsafe-home\"
    . \"$WRAPPER\" 2>/dev/null
    check_codex_available claude-code
  " >/dev/null 2>"$TMP_STDERR" || true

  grep -qi "unsafe" "$TMP_STDERR"
}

@test "[r3-sec.F03] second_reviewer value is validated to a safe literal before echoing in mismatch diagnostic" {
  # sec.F03: the _second_reviewer value extracted from config.md is echoed
  # verbatim to stderr without sanitisation.  A crafted config.md value that
  # passes a loose future comparison could inject terminal control sequences.
  # After the fix, _second_reviewer is normalised to exactly "true" or "false"
  # before any use; an out-of-range value is set to "false".
  #
  # The fix must introduce a `true|false` case statement (or equivalent) that
  # is NOT present in the current code.  This structural assertion is the
  # reliable gate for the sanitisation — behavioural injection tests would
  # require the echo to fire with a polluted value, which the strict
  # `== "true"` guard in the current code prevents.
  #
  # RED state: the script does not contain a `true|false` case pattern for
  # _second_reviewer sanitisation.  `grep -qF 'true|false' "$WRAPPER"` FAILS. ✓
  grep -qF 'true|false' "$WRAPPER"
}

@test "[r3-sf.F01] source guard exits cleanly when script is directly executed with QRSPI_SOURCE_ONLY=1" {
  # sf.F01: `return 0` at the source guard is valid only in a sourced context.
  # When the script is executed directly (`bash dispatch-agent.sh`), `return`
  # outside a function emits an error but — because set -e is disabled — does
  # NOT halt execution.  The script falls through into argument parsing and
  # exits 1 on missing --agent-file.  After the fix, the guard uses
  # `return 0 2>/dev/null || exit 0` which correctly exits when run directly.
  #
  # RED state: `bash "$WRAPPER"` (direct execution) with QRSPI_SOURCE_ONLY=1
  # exits 1 (argument-parsing aborts).  `[ "$status" -eq 0 ]` FAILS. ✓
  QRSPI_SOURCE_ONLY=1 run bash "$WRAPPER"
  [ "$status" -eq 0 ]
}

@test "[r3-sf.F02] dispatch section uses a pipefail-safe invocation for compose_prompt pipeline" {
  # sf.F02: `compose_prompt | bash dispatcher` with pipefail OFF means a
  # compose_prompt failure (partial output, file error) is silently masked by
  # the dispatcher's exit code.  After the fix the pipeline runs inside a
  # subshell with `set -o pipefail` so compose_prompt failures are surfaced.
  #
  # RED state: the script contains no `set -o pipefail` statement (the existing
  # comment `# pipefail is off` does not match `set -o pipefail`).
  # `grep -q 'set -o pipefail'` therefore FAILS. ✓
  grep -q 'set -o pipefail' "$WRAPPER"
}

@test "[r3-sf.F03] check_codex_available at dispatch call site does not suppress its stderr diagnostic" {
  # sf.F03: `check_codex_available "$_detected_host" 2>/dev/null` at the
  # dispatch call site silently swallows the TE11 unrecognized-host diagnostic.
  # After the fix the 2>/dev/null redirection is removed so the diagnostic can
  # reach the operator's stderr stream.
  #
  # RED state: the pattern `check_codex_available.*2>/dev/null` IS present in
  # the script.  `! grep` therefore FAILS. ✓
  ! grep -qE 'check_codex_available[^#]*2>/dev/null' "$WRAPPER"
}

# ===========================================================================
# SECTION 6: tc.F04 (R12) — _second_reviewer sanitization injection test
#
# sec.F03 (R3) introduced a `case "$_second_reviewer" in true|false)` normalisation
# that sanitizes any crafted _second_reviewer value to "true" or "false" before use.
# This section adds a runtime assertion proving that a shell-metacharacter-laden
# config value does NOT execute as shell code, complementing the structural
# assertion in [r3-sec.F03] above.
# ===========================================================================

@test "[r12-tc.F04] crafted second_reviewer value with shell metacharacters does not execute injection" {
  # Scenario: config.md contains `second_reviewer: true; echo INJECTED` — a value
  # designed to execute a side-effect command if the extracted value is ever
  # interpolated unsafely into a shell expression.
  #
  # The sec.F03 sanitization normalises _second_reviewer to "true" or "false"
  # via a case statement; values that do not match exactly are replaced with
  # "false".  The injected `; echo INJECTED` suffix makes the raw extracted
  # string `true; echo INJECTED`, which does not match `true` or `false` exactly
  # → it is normalised to "false" → injection is never executed.
  #
  # Assertions:
  #   1. Neither stdout nor stderr contains "INJECTED".
  #   2. The _second_reviewer value was normalised — either to "true" (if the
  #      awk extraction stops at whitespace/semicolon) or to "false" (full
  #      injected string doesn't match), evidenced by no injection side-effect.
  printf -- '---\nsecond_reviewer: true; echo INJECTED\n---\n' > "$TMP_DIR/artifact-dir/config.md"

  TMP_STDOUT="$TMP_DIR/t-f04-stdout.txt"
  TMP_STDERR="$TMP_DIR/t-f04-stderr.txt"
  QRSPI_REPO_ROOT="$TMP_DIR" \
    COPILOT_CLI="" \
    bash "$WRAPPER" \
      --agent-file agents/qrspi-spec-reviewer.md \
      --reviewer-tag spec-codex \
      --output-dir "$TMP_DIR/out" \
      --round 1 \
      --subject-code "$TMP_DIR/src/subject.ts" \
      --model gpt-5-codex \
      --output-file "$TMP_DIR/result.md" \
      --artifact-dir "$TMP_DIR/artifact-dir" \
    >"$TMP_STDOUT" 2>"$TMP_STDERR" || true

  # Primary assertion: "INJECTED" must not appear in any output channel.
  ! grep -q "INJECTED" "$TMP_STDOUT"
  ! grep -q "INJECTED" "$TMP_STDERR"
}
