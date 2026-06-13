#!/usr/bin/env bats
#
# tests/unit/test-dispatch-agent-author-marker.bats
# Task 04b — Subagent author-marker env wrap on scripts/dispatch-agent.sh.
#
# Behaviour under test:
#   - Every dispatched subagent process inherits a GIT_AUTHOR_NAME env var of
#     the form `qrspi-<agent>` so subagent git commits carry the marker the G5
#     orchestration-boundary check filters on.
#   - The `<agent>` interpolation is validated against the agent-name charset
#     (lowercase letters, digits, hyphen) before any GIT_AUTHOR_NAME injection
#     and before any subprocess (including the dispatch-companion) is invoked.
#     Inputs failing the charset check halt dispatch with the
#     `agent-name-charset-invalid:` named diagnostic and exit non-zero.
#   - A zero-length agent name is also rejected (prevents the silent
#     `GIT_AUTHOR_NAME=qrspi-` failure mode where the marker has no
#     discriminator).
#   - The wrap is set on EVERY dispatched git command in the subagent's
#     session (proven by a fixture round in which the mock dispatcher makes
#     multiple commits and every commit's author name carries the marker).
#   - The low-level (non-T04a-high-level) single-reviewer dispatch path is
#     also wrapped — the marker is a G5 invariant independent of CD-2
#     high-level mode.
#
# Strategy:
#   - Function-level tests source dispatch-agent.sh in QRSPI_SOURCE_ONLY=1
#     mode and exercise the new `_validate_agent_name_charset` helper
#     directly (covers the empty-string and out-of-charset rejection paths
#     without needing a full dispatch fixture).
#   - Dispatch-surface tests build a mock REPO_ROOT skeleton (mirroring the
#     pattern used by tests/unit/test-host-detection.bats) with a
#     scripts/dispatch-companion.sh stub that records its inherited
#     GIT_AUTHOR_NAME to a sidecar file. Multi-commit coverage uses a
#     dispatcher stub that runs `git commit` against a fixture repo twice.
#
# bash 3.2 portable: no mapfile, no declare -A, no ${var,,}.

bats_require_minimum_version 1.5.0

setup_file() {
  REAL_REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd -P)"
  export REAL_REPO_ROOT
  WRAPPER="$REAL_REPO_ROOT/scripts/dispatch-agent.sh"
  export WRAPPER
}

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

  # Minimal valid agent fixture.
  mkdir -p "$TMP_DIR/agents"
  printf -- '---\nmodel: sonnet\nskills: []\n---\n\nStub agent body.\n' \
    > "$TMP_DIR/agents/qrspi-spec-reviewer.md"

  # Bad-charset agent fixture: uppercase + underscore in the basename
  # produce an `_agent_name` of `Bad_Agent` which fails the charset check.
  printf -- '---\nmodel: sonnet\nskills: []\n---\n\nBad-name agent.\n' \
    > "$TMP_DIR/agents/Bad_Agent.md"

  # Artifact directory with a default config (codex_reviews: false).
  mkdir -p "$TMP_DIR/artifact-dir"
  printf -- '---\ncodex_reviews: false\n---\n' > "$TMP_DIR/artifact-dir/config.md"

  # Output directory for dispatch invocations.
  mkdir -p "$TMP_DIR/out"

  export AUTHOR_LOG="$TMP_DIR/author.log"
  export DISPATCH_INVOKED_MARKER="$TMP_DIR/dispatcher-was-invoked"
}

teardown() {
  cd /
  rm -rf "$TMP_DIR"
}

# ---------------------------------------------------------------------------
# Helper: install a default recording dispatch-companion.sh stub that drains
# stdin, appends `AUTHOR_NAME=<value>` to AUTHOR_LOG, touches an
# invocation-marker file, and emits a synthetic JOB_ID line.
# ---------------------------------------------------------------------------
_install_recording_dispatcher() {
  mkdir -p "$TMP_DIR/scripts"
  cat > "$TMP_DIR/scripts/dispatch-companion.sh" <<MOCK_EOF
#!/usr/bin/env bash
cat > /dev/null
touch "$DISPATCH_INVOKED_MARKER"
printf 'AUTHOR_NAME=%s\n' "\${GIT_AUTHOR_NAME:-UNSET}" >> "$AUTHOR_LOG"
printf 'JOB_ID=mock-job-%d\n' "\$\$"
exit 0
MOCK_EOF
  chmod +x "$TMP_DIR/scripts/dispatch-companion.sh"
}

# ===========================================================================
# Function-level tests — _validate_agent_name_charset
# ===========================================================================

@test "validator rejects empty agent name with agent-name-charset-invalid: diagnostic" {
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    . \"$WRAPPER\"
    _validate_agent_name_charset ''
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"agent-name-charset-invalid:"* ]]
}

@test "validator rejects agent name containing a space" {
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    . \"$WRAPPER\"
    _validate_agent_name_charset 'bad name'
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"agent-name-charset-invalid:"* ]]
}

@test "validator rejects agent name containing a path separator" {
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    . \"$WRAPPER\"
    _validate_agent_name_charset 'a/b'
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"agent-name-charset-invalid:"* ]]
}

@test "validator rejects agent name containing an uppercase letter" {
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    . \"$WRAPPER\"
    _validate_agent_name_charset 'Bad_Agent'
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"agent-name-charset-invalid:"* ]]
}

@test "validator rejects agent name containing a control byte" {
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    . \"$WRAPPER\"
    _validate_agent_name_charset \$'abc\x01def'
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"agent-name-charset-invalid:"* ]]
}

@test "validator accepts a charset-clean agent name (lowercase + digits + hyphen)" {
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    . \"$WRAPPER\"
    _validate_agent_name_charset 'qrspi-spec-reviewer-2'
  "
  [ "$status" -eq 0 ]
}

# ===========================================================================
# Dispatch-surface tests — single-mode (low-level) path is wrapped
# ===========================================================================

@test "single-mode dispatch exports GIT_AUTHOR_NAME=qrspi-<agent> to the dispatched subagent" {
  _install_recording_dispatcher

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
    >"$TMP_DIR/stdout.txt" 2>"$TMP_DIR/stderr.txt" || true

  [ -f "$AUTHOR_LOG" ]
  grep -q '^AUTHOR_NAME=qrspi-qrspi-spec-reviewer$' "$AUTHOR_LOG"
}

@test "single-mode dispatch with bad-charset agent name halts with named diagnostic and exits non-zero before invoking the dispatcher" {
  _install_recording_dispatcher

  run env QRSPI_REPO_ROOT="$TMP_DIR" COPILOT_CLI="" \
    bash "$WRAPPER" \
      --agent-file agents/Bad_Agent.md \
      --reviewer-tag spec-codex \
      --output-dir "$TMP_DIR/out" \
      --round 1 \
      --subject-code "$TMP_DIR/src/subject.ts" \
      --model gpt-5-codex \
      --output-file "$TMP_DIR/result.md" \
      --artifact-dir "$TMP_DIR/artifact-dir"

  [ "$status" -ne 0 ]
  [[ "$output" == *"agent-name-charset-invalid:"* ]]
  # Dispatcher must NOT have been invoked: no marker file, no AUTHOR_LOG entry.
  [ ! -f "$DISPATCH_INVOKED_MARKER" ]
  [ ! -f "$AUTHOR_LOG" ]
}

@test "subagent author marker is set on every dispatched git command (multi-commit fixture)" {
  # Fixture: build a small git repo the dispatcher stub will commit into
  # twice. If GIT_AUTHOR_NAME were set only on the first dispatched command
  # but lost across subsequent ones, the second commit's author would be
  # the host default rather than the subagent marker.
  FIXTURE_REPO="$TMP_DIR/fixture-repo"
  mkdir -p "$FIXTURE_REPO"
  ( cd "$FIXTURE_REPO"
    git init -q
    git config user.email subagent@example.invalid
    # No user.name set at the repo level — the dispatched env's
    # GIT_AUTHOR_NAME must drive every commit's author.
    git config --unset-all user.name 2>/dev/null || true
  )

  mkdir -p "$TMP_DIR/scripts"
  cat > "$TMP_DIR/scripts/dispatch-companion.sh" <<MOCK_EOF
#!/usr/bin/env bash
cat > /dev/null
cd "$FIXTURE_REPO" || exit 1
# Emulate two distinct subagent git commands in the same session.
echo a > a.txt
git add a.txt
git -c user.email=subagent@example.invalid commit -q -m "subagent change 1"
echo b > b.txt
git add b.txt
git -c user.email=subagent@example.invalid commit -q -m "subagent change 2"
printf 'JOB_ID=mock-job-%d\n' "\$\$"
exit 0
MOCK_EOF
  chmod +x "$TMP_DIR/scripts/dispatch-companion.sh"

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
    >"$TMP_DIR/stdout.txt" 2>"$TMP_DIR/stderr.txt" || true

  # Both commits must carry the subagent author marker.
  authors="$(git -C "$FIXTURE_REPO" log --format='%an')"
  commit_count="$(printf '%s\n' "$authors" | wc -l | tr -d ' ')"
  [ "$commit_count" -eq 2 ]
  marker_count="$(printf '%s\n' "$authors" | grep -c '^qrspi-qrspi-spec-reviewer$' || true)"
  [ "$marker_count" -eq 2 ]
}
