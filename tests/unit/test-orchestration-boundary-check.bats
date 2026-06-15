#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# Tests for scripts/orchestration-boundary-check.sh — the phase-end OBC script.
# Behavior pins:
#   - Closed enumeration of --phase values; unknown values halt with the
#     obc-unknown-phase: named diagnostic and never read a phase-base.
#   - Per-phase phase-base resolution: implement reads the wave-1 sidecar at
#     <artifact-dir>/reviews/implement/wave-state/wave-1.txt; integration/test
#     read <artifact-dir>/reviews/<phase>/phase-base.txt.
#   - Every SHA read from disk is validated against the well-formed git
#     object-name shape (lowercase hex, 7-64 chars) BEFORE any git invocation;
#     malformed SHAs trigger sha-format-invalid: under ## Dispatch defects.
#   - Missing/malformed phase-base.txt produces phase-base-missing: or
#     phase-base-malformed: under ## Dispatch defects (integration/test).
#   - Missing/malformed wave-1 sidecar produces wave-1-sidecar-missing: or
#     wave-1-sidecar-malformed: under ## Dispatch defects (implement).
#   - Author-marker filter excludes commits whose author starts with the
#     subagent prefix qrspi-; non-marker commits surface under
#     ## Commit violations.
#   - Author-name records carrying newline, multiple consecutive whitespace,
#     or control bytes trigger obc-author-name-malformed: under
#     ## Dispatch defects (fail-loud, never silently excluded).
#   - reviews/ tree is excluded from workspace violations (allowlisted
#     bookkeeping).
#   - Exit 0 fail-soft when only commit/workspace entries are present;
#     non-zero when ## Dispatch defects is non-empty.
#   - Atomic report write: structural grep asserts the script body contains
#     a temp-file mv into the final report path.
#   - Failed rename produces report-write-failed: named diagnostic and
#     non-zero exit.
#
# Bash 3.2 portable.

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
  SCRIPT="$REPO_ROOT/scripts/orchestration-boundary-check.sh"
  export SCRIPT
}

setup() {
  TMP_DIR="$(mktemp -d "$REPO_ROOT/.bats-tmp-obc.XXXXXX")"
  cd "$TMP_DIR"
  # Create a self-contained git repo to act as the artifact-dir's containing repo.
  git init -q .
  git config user.email "human@example.com"
  git config user.name "Human Author"
  echo "seed" > seed.txt
  git add seed.txt
  git commit -q -m "seed"
  PHASE_BASE_SHA="$(git rev-parse HEAD)"
  export PHASE_BASE_SHA TMP_DIR
}

teardown() {
  cd "$REPO_ROOT"
  rm -rf "$TMP_DIR"
}

valid_phases_helper() {
  # Print a baseline integration phase-base.txt with the seed SHA.
  mkdir -p reviews/integration
  printf '%s\n' "$PHASE_BASE_SHA" > reviews/integration/phase-base.txt
}

# -----------------------------------------------------------------------------
# Existence + structural pins
# -----------------------------------------------------------------------------

@test "orchestration-boundary-check.sh exists and is executable" {
  [ -x "$SCRIPT" ]
}

@test "script body uses atomic temp-file rename for report writes" {
  # Structural-grep: a temp-file path is renamed into the final report path
  # via mv (POSIX rename(2)). Either form `mv ... "$tmp..." "$..."` accepted.
  grep -E 'mv[[:space:]]+(-[a-zA-Z]+[[:space:]]+)?"?\$\{?[A-Za-z_]*[Tt][Mm][Pp]' "$SCRIPT"
}

@test "script body validates SHA shape with a 7-64 lowercase-hex anchor regex" {
  grep -E '\[0-9a-f\]\{7,64\}|0-9a-f.*7,64' "$SCRIPT"
}

# -----------------------------------------------------------------------------
# Argument validation
# -----------------------------------------------------------------------------

@test "unknown --phase value halts with obc-unknown-phase named diagnostic and lists valid phases" {
  run "$SCRIPT" --phase deploy --artifact-dir "$TMP_DIR"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q 'obc-unknown-phase:'
  echo "$output" | grep -q 'implement'
  echo "$output" | grep -q 'integration'
  echo "$output" | grep -q 'test'
  # No report should be written under the bogus phase directory.
  [ ! -e "$TMP_DIR/reviews/deploy/orchestration-boundary.md" ]
}

@test "missing --phase or --artifact-dir exits non-zero with usage" {
  run "$SCRIPT" --artifact-dir "$TMP_DIR"
  [ "$status" -ne 0 ]
}

# -----------------------------------------------------------------------------
# Clean tree (integration phase) — empty report, exit 0
# -----------------------------------------------------------------------------

@test "clean integration tree produces an empty report and exits 0" {
  valid_phases_helper
  run "$SCRIPT" --phase integration --artifact-dir "$TMP_DIR"
  [ "$status" -eq 0 ]
  [ -r "$TMP_DIR/reviews/integration/orchestration-boundary.md" ]
  report="$(cat "$TMP_DIR/reviews/integration/orchestration-boundary.md")"
  echo "$report" | grep -q '## Dispatch defects'
  echo "$report" | grep -q '## Commit violations'
  echo "$report" | grep -q '## Workspace violations'
  # No defect / commit / workspace entries.
  ! echo "$report" | grep -E '^- ' | grep -v '^_None_'
}

# -----------------------------------------------------------------------------
# Commit violations — non-subagent commit named under commit section
# -----------------------------------------------------------------------------

@test "non-subagent commit appears under commit-violations section, fail-soft exit 0" {
  valid_phases_helper
  echo "drift" > drift.txt
  git add drift.txt
  git -c user.name="Human Author" -c user.email="h@e.com" commit -q -m "drift commit"
  drift_sha="$(git rev-parse HEAD)"
  run "$SCRIPT" --phase integration --artifact-dir "$TMP_DIR"
  [ "$status" -eq 0 ]
  report="$(cat "$TMP_DIR/reviews/integration/orchestration-boundary.md")"
  echo "$report" | grep -q "$drift_sha"
  echo "$report" | grep -q "Human Author"
  echo "$report" | grep -q "drift commit"
}

@test "subagent qrspi- commit is excluded by the author-marker filter" {
  valid_phases_helper
  echo "subagent" > sub.txt
  git add sub.txt
  git -c user.name="qrspi-implementer" -c user.email="s@e.com" commit -q -m "subagent commit"
  sub_sha="$(git rev-parse HEAD)"
  run "$SCRIPT" --phase integration --artifact-dir "$TMP_DIR"
  [ "$status" -eq 0 ]
  report="$(cat "$TMP_DIR/reviews/integration/orchestration-boundary.md")"
  ! echo "$report" | grep -q "$sub_sha"
}

# -----------------------------------------------------------------------------
# Workspace violations
# -----------------------------------------------------------------------------

@test "uncommitted edit outside reviews tree appears under workspace section, exit 0" {
  valid_phases_helper
  echo "untracked" > stray.txt
  run "$SCRIPT" --phase integration --artifact-dir "$TMP_DIR"
  [ "$status" -eq 0 ]
  report="$(cat "$TMP_DIR/reviews/integration/orchestration-boundary.md")"
  echo "$report" | grep -q "stray.txt"
}

@test "uncommitted file under reviews tree is excluded as allowlisted bookkeeping" {
  valid_phases_helper
  mkdir -p reviews/integration
  echo "bookkeeping" > reviews/integration/note.md
  run "$SCRIPT" --phase integration --artifact-dir "$TMP_DIR"
  [ "$status" -eq 0 ]
  report="$(cat "$TMP_DIR/reviews/integration/orchestration-boundary.md")"
  ! echo "$report" | grep -q "reviews/integration/note.md"
}

# -----------------------------------------------------------------------------
# Phase-base file (integration/test) — missing / malformed / SHA-format
# -----------------------------------------------------------------------------

@test "missing phase-base.txt produces phase-base-missing under Dispatch defects, exit non-zero" {
  run "$SCRIPT" --phase integration --artifact-dir "$TMP_DIR"
  [ "$status" -ne 0 ]
  report="$(cat "$TMP_DIR/reviews/integration/orchestration-boundary.md")"
  # Defect entry must appear under ## Dispatch defects, not under Commit/Workspace.
  defects_section="$(echo "$report" | awk '/^## Dispatch defects/{flag=1;next} /^## /{flag=0} flag')"
  echo "$defects_section" | grep -q 'phase-base-missing:'
}

@test "empty phase-base.txt produces phase-base-malformed under Dispatch defects, exit non-zero" {
  mkdir -p reviews/integration
  : > reviews/integration/phase-base.txt
  run "$SCRIPT" --phase integration --artifact-dir "$TMP_DIR"
  [ "$status" -ne 0 ]
  report="$(cat "$TMP_DIR/reviews/integration/orchestration-boundary.md")"
  defects_section="$(echo "$report" | awk '/^## Dispatch defects/{flag=1;next} /^## /{flag=0} flag')"
  echo "$defects_section" | grep -q 'phase-base-malformed:'
}

@test "malformed SHA in phase-base.txt (uppercase hex) triggers sha-format-invalid, no git command runs against it" {
  mkdir -p reviews/integration
  printf '%s\n' "ABCDEF1234567" > reviews/integration/phase-base.txt
  run "$SCRIPT" --phase integration --artifact-dir "$TMP_DIR"
  [ "$status" -ne 0 ]
  report="$(cat "$TMP_DIR/reviews/integration/orchestration-boundary.md")"
  defects_section="$(echo "$report" | awk '/^## Dispatch defects/{flag=1;next} /^## /{flag=0} flag')"
  echo "$defects_section" | grep -q 'sha-format-invalid:'
}

@test "malformed SHA in phase-base.txt (length < 7) triggers sha-format-invalid" {
  mkdir -p reviews/integration
  printf '%s\n' "abc123" > reviews/integration/phase-base.txt
  run "$SCRIPT" --phase integration --artifact-dir "$TMP_DIR"
  [ "$status" -ne 0 ]
  report="$(cat "$TMP_DIR/reviews/integration/orchestration-boundary.md")"
  defects_section="$(echo "$report" | awk '/^## Dispatch defects/{flag=1;next} /^## /{flag=0} flag')"
  echo "$defects_section" | grep -q 'sha-format-invalid:'
}

@test "malformed SHA in phase-base.txt (non-hex chars) triggers sha-format-invalid" {
  mkdir -p reviews/integration
  printf '%s\n' "zzzzzzzzzzzz" > reviews/integration/phase-base.txt
  run "$SCRIPT" --phase integration --artifact-dir "$TMP_DIR"
  [ "$status" -ne 0 ]
  report="$(cat "$TMP_DIR/reviews/integration/orchestration-boundary.md")"
  defects_section="$(echo "$report" | awk '/^## Dispatch defects/{flag=1;next} /^## /{flag=0} flag')"
  echo "$defects_section" | grep -q 'sha-format-invalid:'
}

@test "test phase reads from reviews/test/phase-base.txt and produces empty report on clean tree" {
  mkdir -p reviews/test
  printf '%s\n' "$PHASE_BASE_SHA" > reviews/test/phase-base.txt
  run "$SCRIPT" --phase test --artifact-dir "$TMP_DIR"
  [ "$status" -eq 0 ]
  [ -r "$TMP_DIR/reviews/test/orchestration-boundary.md" ]
}

# -----------------------------------------------------------------------------
# Wave-1 sidecar (implement phase) — symmetric defect direction
# -----------------------------------------------------------------------------

@test "implement phase reads phase-base from wave-1 sidecar and produces empty report on clean tree" {
  mkdir -p reviews/implement/wave-state
  printf 'integration_base: %s\ntask_tips:\n' "$PHASE_BASE_SHA" > reviews/implement/wave-state/wave-1.txt
  run "$SCRIPT" --phase implement --artifact-dir "$TMP_DIR"
  [ "$status" -eq 0 ]
  [ -r "$TMP_DIR/reviews/implement/orchestration-boundary.md" ]
}

@test "missing wave-1 sidecar produces wave-1-sidecar-missing under Dispatch defects, exit non-zero" {
  run "$SCRIPT" --phase implement --artifact-dir "$TMP_DIR"
  [ "$status" -ne 0 ]
  report="$(cat "$TMP_DIR/reviews/implement/orchestration-boundary.md")"
  defects_section="$(echo "$report" | awk '/^## Dispatch defects/{flag=1;next} /^## /{flag=0} flag')"
  echo "$defects_section" | grep -q 'wave-1-sidecar-missing:'
}

@test "malformed wave-1 sidecar (no integration_base line) produces wave-1-sidecar-malformed under Dispatch defects, exit non-zero" {
  mkdir -p reviews/implement/wave-state
  printf 'task_tips:\n' > reviews/implement/wave-state/wave-1.txt
  run "$SCRIPT" --phase implement --artifact-dir "$TMP_DIR"
  [ "$status" -ne 0 ]
  report="$(cat "$TMP_DIR/reviews/implement/orchestration-boundary.md")"
  defects_section="$(echo "$report" | awk '/^## Dispatch defects/{flag=1;next} /^## /{flag=0} flag')"
  echo "$defects_section" | grep -q 'wave-1-sidecar-malformed:'
}

@test "malformed SHA in wave-1 sidecar integration_base value triggers sha-format-invalid" {
  mkdir -p reviews/implement/wave-state
  printf 'integration_base: ABCDEF1234567\n' > reviews/implement/wave-state/wave-1.txt
  run "$SCRIPT" --phase implement --artifact-dir "$TMP_DIR"
  [ "$status" -ne 0 ]
  report="$(cat "$TMP_DIR/reviews/implement/orchestration-boundary.md")"
  defects_section="$(echo "$report" | awk '/^## Dispatch defects/{flag=1;next} /^## /{flag=0} flag')"
  echo "$defects_section" | grep -q 'sha-format-invalid:'
}

# -----------------------------------------------------------------------------
# F02: End-to-end bridge from validate-stage-commit-parents.sh capture/seed
# into OBC's implement-phase wave-1 read. Closes the F02 detection gap.
# -----------------------------------------------------------------------------

@test "F02 end-to-end: capture --wave-id W1 satisfies OBC implement-phase (Dispatch defects empty)" {
  bridge="$REPO_ROOT/scripts/validate-stage-commit-parents.sh"
  # --capture with no task branches still resolves the integration-base SHA
  # from HEAD and (via the F02 dual-write bridge) emits wave-1.txt.
  run "$bridge" --capture --wave-id W1 --wave-state-dir "$TMP_DIR/reviews/implement/wave-state"
  [ "$status" -eq 0 ]
  [ -f "$TMP_DIR/reviews/implement/wave-state/wave-1.txt" ]

  run "$SCRIPT" --phase implement --artifact-dir "$TMP_DIR"
  [ "$status" -eq 0 ]
  report="$(cat "$TMP_DIR/reviews/implement/orchestration-boundary.md")"
  defects_section="$(echo "$report" | awk '/^## Dispatch defects/{flag=1;next} /^## /{flag=0} flag')"
  # No named defect should appear; the wave-1-sidecar/sha diagnostics must
  # NOT fire under the bridge.
  ! echo "$defects_section" | grep -q 'wave-1-sidecar-missing:'
  ! echo "$defects_section" | grep -q 'wave-1-sidecar-malformed:'
  ! echo "$defects_section" | grep -q 'sha-format-invalid:'
}

@test "F02 end-to-end: --seed-wave-1-obc satisfies OBC implement-phase (fan-out-only Wave 1)" {
  bridge="$REPO_ROOT/scripts/validate-stage-commit-parents.sh"
  run "$bridge" --seed-wave-1-obc --integration-base "$PHASE_BASE_SHA" --artifact-dir "$TMP_DIR"
  [ "$status" -eq 0 ]
  [ -f "$TMP_DIR/reviews/implement/wave-state/wave-1.txt" ]

  run "$SCRIPT" --phase implement --artifact-dir "$TMP_DIR"
  [ "$status" -eq 0 ]
  report="$(cat "$TMP_DIR/reviews/implement/orchestration-boundary.md")"
  defects_section="$(echo "$report" | awk '/^## Dispatch defects/{flag=1;next} /^## /{flag=0} flag')"
  ! echo "$defects_section" | grep -q 'wave-1-sidecar-missing:'
  ! echo "$defects_section" | grep -q 'wave-1-sidecar-malformed:'
  ! echo "$defects_section" | grep -q 'sha-format-invalid:'
}

# -----------------------------------------------------------------------------
# Author-name fail-loud
# -----------------------------------------------------------------------------

@test "author name with embedded newline triggers obc-author-name-malformed under Dispatch defects" {
  # Real `git` sanitizes newlines from author names at commit time, so we
  # exercise the script's malformed-record detection by shadowing `git`
  # with a deterministic stub on PATH that emits a NUL-separated record
  # whose author field contains an embedded newline. The script must
  # surface obc-author-name-malformed: under ## Dispatch defects rather
  # than silently dropping or splitting the record.
  valid_phases_helper
  STUB_DIR="$TMP_DIR/stub-bin"
  mkdir -p "$STUB_DIR"
  cat > "$STUB_DIR/git" <<'STUB'
#!/usr/bin/env bash
# Match `git log <range> -z --format='%H %an'` exactly; delegate everything
# else to the real git so status/rev-parse/log-of-single-sha still work.
real_git="$(command -v -- /usr/bin/git || command -v -- /opt/homebrew/bin/git)"
[ -x "$real_git" ] || real_git="$(/usr/bin/which -a git | grep -v "$(dirname "$0")" | head -1)"
if [ "${1:-}" = "log" ] && [ "${2:-}" != "-n" ]; then
  for arg in "$@"; do
    case "$arg" in
      *..HEAD)
        # Emit one NUL-terminated record with an embedded newline in the
        # author-name field.
        printf 'deadbeef1234567 line1\nline2\0'
        exit 0
        ;;
    esac
  done
fi
exec "$real_git" "$@"
STUB
  chmod +x "$STUB_DIR/git"
  PATH="$STUB_DIR:$PATH" run "$SCRIPT" --phase integration --artifact-dir "$TMP_DIR"
  [ "$status" -ne 0 ]
  report="$(cat "$TMP_DIR/reviews/integration/orchestration-boundary.md")"
  defects_section="$(echo "$report" | awk '/^## Dispatch defects/{flag=1;next} /^## /{flag=0} flag')"
  echo "$defects_section" | grep -q 'obc-author-name-malformed:'
}

@test "author name with multiple consecutive whitespace bytes triggers obc-author-name-malformed" {
  valid_phases_helper
  echo "double" > double.txt
  git add double.txt
  git -c "user.name=foo   bar" -c user.email="d@e.com" commit -q -m "double-space commit"
  run "$SCRIPT" --phase integration --artifact-dir "$TMP_DIR"
  [ "$status" -ne 0 ]
  report="$(cat "$TMP_DIR/reviews/integration/orchestration-boundary.md")"
  defects_section="$(echo "$report" | awk '/^## Dispatch defects/{flag=1;next} /^## /{flag=0} flag')"
  echo "$defects_section" | grep -q 'obc-author-name-malformed:'
}

@test "author name with embedded control byte triggers obc-author-name-malformed under Dispatch defects" {
  # Real `git` rejects control bytes in author names at commit time, so we
  # shadow `git` with a stub that emits a NUL-separated record whose author
  # field contains a control byte (\x01). The script's control-byte arm of
  # author_name_is_malformed must surface obc-author-name-malformed: under
  # ## Dispatch defects rather than silently passing the record.
  valid_phases_helper
  STUB_DIR="$TMP_DIR/stub-bin"
  mkdir -p "$STUB_DIR"
  cat > "$STUB_DIR/git" <<'STUB'
#!/usr/bin/env bash
real_git="$(command -v -- /usr/bin/git || command -v -- /opt/homebrew/bin/git)"
[ -x "$real_git" ] || real_git="$(/usr/bin/which -a git | grep -v "$(dirname "$0")" | head -1)"
if [ "${1:-}" = "log" ] && [ "${2:-}" != "-n" ]; then
  for arg in "$@"; do
    case "$arg" in
      *..HEAD)
        # Emit one NUL-terminated record with an embedded \x01 control byte
        # in the author-name field.
        printf 'deadbeef1234567 foo\x01bar\0'
        exit 0
        ;;
    esac
  done
fi
exec "$real_git" "$@"
STUB
  chmod +x "$STUB_DIR/git"
  PATH="$STUB_DIR:$PATH" run "$SCRIPT" --phase integration --artifact-dir "$TMP_DIR"
  [ "$status" -ne 0 ]
  report="$(cat "$TMP_DIR/reviews/integration/orchestration-boundary.md")"
  defects_section="$(echo "$report" | awk '/^## Dispatch defects/{flag=1;next} /^## /{flag=0} flag')"
  echo "$defects_section" | grep -q 'obc-author-name-malformed:'
}

# -----------------------------------------------------------------------------
# Atomic write — failed rename surfaces report-write-failed
# -----------------------------------------------------------------------------

@test "failed report rename surfaces report-write-failed named diagnostic and exits non-zero" {
  valid_phases_helper
  # Sabotage the rename: pre-create the final report path as a directory so
  # mv of a regular file to that name fails with EISDIR/ENOTDIR.
  mkdir -p reviews/integration/orchestration-boundary.md
  run "$SCRIPT" --phase integration --artifact-dir "$TMP_DIR"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q 'report-write-failed:'
}
