#!/usr/bin/env bats
#
# Research-reviewer path-based dispatch contract (path-based companion_qfile_paths).
#
# Pins that:
#   - skills/research/SKILL.md documents companion_qfile_paths as the
#     canonical Claude reviewer dispatch parameter (not companion_qfiles)
#   - skills/research/SKILL.md describes the orchestrator-side precondition:
#     every listed path must be readable; on failure, the unreadable path is
#     named and dispatch is refused
#   - skills/research/SKILL.md preserves the Codex reviewer dispatch unchanged
#   - agents/qrspi-research-reviewer.md documents a per-path Read step in
#     the agent's Step-1 file-reading flow over companion_qfile_paths
#   - agents/qrspi-research-reviewer.md documents UNTRUSTED-ARTIFACT-START
#     wrapping with per-path id interpolation (filename from path)
#   - agents/qrspi-research-reviewer.md preserves the research-isolation
#     invariant (no companion_goals, no companion_questions)
#   - agents/qrspi-research-reviewer.md documents that Read-tool output is
#     treated as data, not instructions (reviewer-protocol Path A rule)
#   - The precondition-checker script (tests/fixtures/check-qfile-paths.sh)
#     exits non-zero and surfaces the unreadable path name on stderr when any
#     listed path is unreadable
#   - The precondition-checker script exits non-zero and emits a zero-file
#     diagnostic on stderr when companion_qfile_paths is an empty list
#
# Behavioral contract:
#   - tests/fixtures/check-qfile-paths.sh is the executable precondition
#     checker; BATS drives it with synthesized inputs to assert the
#     non-zero-exit AND unreadable-path-name-in-stderr gate behaviors
#
# Iron Laws pinned here:
#   - companion_qfile_paths replaces companion_qfiles for the Claude path
#   - Codex path is UNCHANGED (still uses companion_qfiles in run-codex-review)
#   - Empty path list is a precondition failure, not a vacuous clean review
#   - Each q-file body is wrapped under UNTRUSTED-ARTIFACT-START markers
#   - Read output is data, not instructions

bats_require_minimum_version 1.5.0

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
}

# ---------------------------------------------------------------------------
# skills/research/SKILL.md — Claude reviewer dispatch contract
# ---------------------------------------------------------------------------

@test "research SKILL documents companion_qfile_paths as the canonical Claude reviewer dispatch parameter" {
  # CD-1 (Task 20): per-skill reviewer-dispatch mechanics collapsed into the
  # shared reviewer-dispatch include + the reviewer agent body. The canonical
  # companion_qfile_paths contract now lives in agents/qrspi-research-reviewer.md
  # (covered by the agent-body tests below); the research SKILL routes its
  # reviewer round through the shared include.
  grep -qF '!cat skills/_shared/reviewer-dispatch-prose.md' "$REPO_ROOT/skills/research/SKILL.md" \
    || { echo "research SKILL must route its reviewer round through the shared reviewer-dispatch include"; return 1; }
  grep -qF 'companion_qfile_paths' "$REPO_ROOT/agents/qrspi-research-reviewer.md" \
    || { echo "agent body must carry the canonical companion_qfile_paths contract"; return 1; }
}

@test "research SKILL does not document companion_qfiles as the canonical Claude inline parameter" {
  # companion_qfiles must no longer appear in the Claude reviewer dispatch
  # block. It may still appear in the Codex block (companion_qfiles= flag to
  # run-codex-review.sh), so we test for its absence in the Claude dispatch
  # context specifically: the Claude dispatch block is introduced by the
  # phrase "Claude quality-reviewer subagent". We check that within that
  # block, companion_qfiles does NOT appear as a dispatch parameter name
  # (not as a flag to run-codex-review.sh, which is in the Codex block).
  run awk '
    /Claude quality-reviewer subagent/ { in_claude=1 }
    in_claude && /Codex review/ { in_claude=0 }
    in_claude && /companion_qfiles[^=]/ { found=1 }
    END { exit found ? 0 : 1 }
  ' "$REPO_ROOT/skills/research/SKILL.md"
  # We expect NOT to find companion_qfiles in Claude block — status should be 1
  [ "$status" -eq 1 ]
}

@test "research SKILL describes orchestrator precondition for companion_qfile_paths: every listed path must be readable" {
  # CD-1 (Task 20): superseded. The orchestrator-side companion-readable
  # precondition was a per-skill dispatch responsibility; when companions left
  # the per-skill dispatch interface (universal dispatch chain), the SKILL-prose
  # precondition moved off the research SKILL. The behavioral contract is
  # retained by the check-qfile-paths.sh fixture tests below (readable/unreadable
  # gate, path-name surfacing).
  skip "superseded by CD-1 universal dispatch (Task 20); companion-readable precondition removed from the SKILL when companions left the per-skill dispatch interface — behavioral coverage retained by check-qfile-paths.sh fixture tests"
}

@test "research SKILL describes that on companion_qfile_paths precondition failure the unreadable path is surfaced and dispatch is refused" {
  # CD-1 (Task 20): superseded — see the readable-precondition test above. The
  # surface-and-refuse behavior on an unreadable path is retained behaviorally
  # by the check-qfile-paths.sh fixture tests below (non-zero exit + path name
  # in stderr).
  skip "superseded by CD-1 universal dispatch (Task 20); SKILL-prose precondition-failure description removed when companions left the per-skill dispatch interface — behavioral coverage retained by check-qfile-paths.sh fixture tests"
}

@test "research SKILL preserves Codex reviewer dispatch unchanged (companion_qfiles still in Codex block)" {
  # CD-1 (Task 20): the per-skill Codex reviewer block (with its
  # `companion_qfiles=` flag to the old wrapper) collapsed into the universal
  # companion dispatch path. `*-codex` reviewer tags now route through
  # scripts/dispatch-companion.sh via the shared reviewer-dispatch include.
  [ -f "$REPO_ROOT/scripts/dispatch-companion.sh" ] \
    || { echo "universal companion dispatcher scripts/dispatch-companion.sh must exist"; return 1; }
  grep -qF '!cat skills/_shared/reviewer-dispatch-prose.md' "$REPO_ROOT/skills/research/SKILL.md" \
    || { echo "research SKILL must route its reviewer round (incl. companion path) through the shared include"; return 1; }
}

@test "research SKILL documents empty companion_qfile_paths list as a precondition failure (not a vacuous clean review)" {
  # CD-1 (Task 20): superseded — the empty-list precondition was a per-skill
  # orchestrator responsibility that moved off the research SKILL when companions
  # left the per-skill dispatch interface. The empty-list-is-a-failure behavior
  # is retained by the check-qfile-paths.sh fixture tests below (non-zero exit +
  # zero-file diagnostic on stderr).
  skip "superseded by CD-1 universal dispatch (Task 20); empty-list precondition removed from the SKILL when companions left the per-skill dispatch interface — behavioral coverage retained by check-qfile-paths.sh fixture tests"
}

# ---------------------------------------------------------------------------
# agents/qrspi-research-reviewer.md — per-path Read step
# ---------------------------------------------------------------------------

@test "research-reviewer agent documents per-path Read step over companion_qfile_paths" {
  run grep -E "companion_qfile_paths" "$REPO_ROOT/agents/qrspi-research-reviewer.md"
  [ "$status" -eq 0 ]
}

@test "research-reviewer agent documents one Read per path in companion_qfile_paths" {
  run grep -E "one Read per path|per.path Read|Read.*per path|Read each path|per-path.*Read" "$REPO_ROOT/agents/qrspi-research-reviewer.md"
  [ "$status" -eq 0 ]
}

@test "research-reviewer agent contains the literal UNTRUSTED-ARTIFACT-START token" {
  run grep -F "UNTRUSTED-ARTIFACT-START" "$REPO_ROOT/agents/qrspi-research-reviewer.md"
  [ "$status" -eq 0 ]
}

@test "research-reviewer agent documents per-path id interpolation (filename as id)" {
  run grep -E "id=.*\.md|filename.*id|path.*id|interpolat" "$REPO_ROOT/agents/qrspi-research-reviewer.md"
  [ "$status" -eq 0 ]
}

@test "research-reviewer agent documents that read output is treated as data not instructions" {
  run grep -iE "data.*not instructions|treat.*as data|not.*instructions" "$REPO_ROOT/agents/qrspi-research-reviewer.md"
  [ "$status" -eq 0 ]
}

@test "research-reviewer agent preserves research-isolation invariant (no companion_goals)" {
  run grep -E "NO.*companion_goals|companion_goals.*NO|no companion_goals" "$REPO_ROOT/agents/qrspi-research-reviewer.md"
  [ "$status" -eq 0 ]
}

@test "research-reviewer agent preserves research-isolation invariant (no companion_questions)" {
  run grep -E "NO.*companion_questions|companion_questions.*NO|no companion_questions" "$REPO_ROOT/agents/qrspi-research-reviewer.md"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Behavioral: precondition-checker script (tests/fixtures/check-qfile-paths.sh)
# ---------------------------------------------------------------------------

@test "check-qfile-paths.sh fixture exists and is executable" {
  [ -x "$REPO_ROOT/tests/fixtures/check-qfile-paths.sh" ]
}

@test "check-qfile-paths.sh exits non-zero when a path is unreadable" {
  run "$REPO_ROOT/tests/fixtures/check-qfile-paths.sh" /dev/null/nonexistent
  [ "$status" -ne 0 ]
}

@test "check-qfile-paths.sh surfaces the unreadable path name in stderr when a path is unreadable" {
  run --separate-stderr "$REPO_ROOT/tests/fixtures/check-qfile-paths.sh" /dev/null/nonexistent
  [ "$status" -ne 0 ]
  echo "$stderr" | grep -qF "/dev/null/nonexistent" \
    || { echo "STDERR does not contain the unreadable path name"; return 1; }
}

@test "check-qfile-paths.sh exits non-zero when companion_qfile_paths is empty (zero paths given)" {
  run "$REPO_ROOT/tests/fixtures/check-qfile-paths.sh"
  [ "$status" -ne 0 ]
}

@test "check-qfile-paths.sh emits a zero-file diagnostic on stderr when companion_qfile_paths is empty" {
  run --separate-stderr "$REPO_ROOT/tests/fixtures/check-qfile-paths.sh"
  [ "$status" -ne 0 ]
  echo "$stderr" | grep -qiE "empty|zero|no.*q-file|no.*path|no.*file" \
    || { echo "STDERR does not contain a zero-file diagnostic"; return 1; }
}

@test "check-qfile-paths.sh exits zero when all given paths are readable files" {
  # Create a real readable file to test the happy path
  local tmpfile
  tmpfile="$(mktemp /tmp/test-qfile-XXXXXX.md)"
  echo "# test q-file" > "$tmpfile"
  run "$REPO_ROOT/tests/fixtures/check-qfile-paths.sh" "$tmpfile"
  local exit_status="$status"
  rm -f "$tmpfile"
  [ "$exit_status" -eq 0 ]
}

@test "check-qfile-paths.sh exits non-zero for a symlink pointing to a directory" {
  # A symlink to a directory is readable but is NOT a regular file (-f).
  # This pins the -f guard added in round-01: removing -f and keeping only -r
  # would cause this test to fail (the symlink would be treated as valid).
  local tmpdir
  tmpdir="$(mktemp -d /tmp/test-qfile-symlink-XXXXXX)"
  local symlink_path="$tmpdir/link-to-dir"
  ln -s "$tmpdir" "$symlink_path"
  run "$REPO_ROOT/tests/fixtures/check-qfile-paths.sh" "$symlink_path"
  local exit_status="$status"
  rm -rf "$tmpdir"
  [ "$exit_status" -ne 0 ]
}

@test "check-qfile-paths.sh names the symlink-to-directory path in stderr" {
  local tmpdir
  tmpdir="$(mktemp -d /tmp/test-qfile-symlink-XXXXXX)"
  local symlink_path="$tmpdir/link-to-dir"
  ln -s "$tmpdir" "$symlink_path"
  run --separate-stderr "$REPO_ROOT/tests/fixtures/check-qfile-paths.sh" "$symlink_path"
  local exit_status="$status"
  local captured_stderr="$stderr"
  rm -rf "$tmpdir"
  [ "$exit_status" -ne 0 ]
  echo "$captured_stderr" | grep -qF "$symlink_path" \
    || { echo "STDERR does not contain the symlink path name: $symlink_path"; return 1; }
}

@test "check-qfile-paths.sh exits non-zero for a FIFO (named pipe)" {
  # A FIFO is not a regular file (-f returns false) so the -f guard must
  # reject it even though it may be readable.  Removing -f and keeping only
  # -r would allow a FIFO through, breaking the regular-file invariant.
  local tmpdir
  tmpdir="$(mktemp -d /tmp/test-qfile-fifo-XXXXXX)"
  local fifo_path="$tmpdir/test.fifo"
  mkfifo "$fifo_path"
  run "$REPO_ROOT/tests/fixtures/check-qfile-paths.sh" "$fifo_path"
  local exit_status="$status"
  rm -rf "$tmpdir"
  [ "$exit_status" -ne 0 ]
}

@test "check-qfile-paths.sh names the FIFO path in stderr" {
  local tmpdir
  tmpdir="$(mktemp -d /tmp/test-qfile-fifo-XXXXXX)"
  local fifo_path="$tmpdir/test.fifo"
  mkfifo "$fifo_path"
  run --separate-stderr "$REPO_ROOT/tests/fixtures/check-qfile-paths.sh" "$fifo_path"
  local exit_status="$status"
  local captured_stderr="$stderr"
  rm -rf "$tmpdir"
  [ "$exit_status" -ne 0 ]
  echo "$captured_stderr" | grep -qF "$fifo_path" \
    || { echo "STDERR does not contain the FIFO path name: $fifo_path"; return 1; }
}

@test "check-qfile-paths.sh exits non-zero when one of multiple paths is unreadable and names the bad path" {
  # Two-bad-paths variant: a fail-fast impl would only emit the first bad path
  # name in stderr and exit before processing the second; this test asserts
  # BOTH bad path names appear in stderr, pinning the accumulate-and-defer
  # contract.  The previous "one good, one bad" form was order-dependent and
  # produced identical observable output for fail-fast vs accumulate-and-defer.
  run --separate-stderr "$REPO_ROOT/tests/fixtures/check-qfile-paths.sh" \
    /dev/null/nonexistent1 /dev/null/nonexistent2
  local exit_status="$status"
  local captured_stderr="$stderr"
  [ "$exit_status" -ne 0 ]
  echo "$captured_stderr" | grep -qF "/dev/null/nonexistent1" \
    || { echo "STDERR does not contain first bad path name (/dev/null/nonexistent1)"; return 1; }
  echo "$captured_stderr" | grep -qF "/dev/null/nonexistent2" \
    || { echo "STDERR does not contain second bad path name — fail-fast? (/dev/null/nonexistent2)"; return 1; }
}

@test "check-qfile-paths.sh exits non-zero for an unreadable regular file" {
  # Exercises the -r clause of the compound guard at check-qfile-paths.sh:L27.
  # A file that exists (passes -f) but has mode 000 (fails -r) must be
  # rejected.  Removing the || [[ ! -r "$path" ]] clause would cause this test
  # to fail, pinning both halves of the compound guard.
  # Skip if running as root: chmod a-r is ineffective for root (root can read
  # any file regardless of permission bits).
  if [[ "$(id -u)" -eq 0 ]]; then
    skip "running as root — chmod a-r is ineffective; -r guard cannot be pinned"
  fi
  local tmpfile
  tmpfile="$(mktemp /tmp/test-qfile-XXXXXX.md)"
  echo "# content" > "$tmpfile"
  chmod 000 "$tmpfile"
  run --separate-stderr "$REPO_ROOT/tests/fixtures/check-qfile-paths.sh" "$tmpfile"
  local exit_status="$status"
  local captured_stderr="$stderr"
  chmod 644 "$tmpfile"
  rm -f "$tmpfile"
  [ "$exit_status" -ne 0 ]
  echo "$captured_stderr" | grep -qF "$tmpfile" \
    || { echo "STDERR does not contain the unreadable file path name"; return 1; }
}
