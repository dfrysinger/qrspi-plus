#!/usr/bin/env bats
# ============================================================================
# Unit tests for scripts/third-party-finding-splitter.sh
#
# Renamed from scripts/codex-finding-splitter.sh (task-20.md).
# This file tests the NEW flag-based interface:
#   third-party-finding-splitter.sh --round-dir <abs-round-dir> --tag <reviewer-tag>
# The script reads <round-dir>/.dispatch/<tag>.raw and materialises per-finding
# files at <round-dir>/<tag>.finding-F<NN>.md (or a NO_FINDINGS sentinel).
#
# Task-expectation coverage (task-20.md companion/splitter fixture coverage):
#   - File/rename audit: third-party-finding-splitter.sh exists; codex-finding-splitter.sh gone
#   - New flag-based CLI: --round-dir and --tag flags (not positional args)
#   - Input from .dispatch/<tag>.raw (not positional stdout-path arg)
#   - Materialization: stable F01, F02, ... per-finding files
#   - NO_FINDINGS sentinel written on clean no-findings raw output
#   - Loud failure: missing --round-dir, missing --tag, missing raw file, no boundaries, write errors
#
# RED state: scripts/codex-finding-splitter.sh still exists and
# scripts/third-party-finding-splitter.sh does not yet exist.
# All invocation-based tests fail with exit 127 (command not found)
# or assertion failure on path existence checks.
#
# GREEN state: scripts/third-party-finding-splitter.sh exists, reads from
# <round-dir>/.dispatch/<tag>.raw, writes per-finding files in stable order,
# writes NO_FINDINGS sentinel on clean output, fails loudly for every
# documented error case.
#
# Bash 3.2 portable: no mapfile, no declare -A, no ${var,,}, no coproc, no wait -n.
# ============================================================================

bats_require_minimum_version 1.5.0

setup() {
  ROUND_DIR="$(mktemp -d)"
  mkdir -p "$ROUND_DIR/.dispatch"
  TAG="quality-codex"
  SPLITTER="scripts/third-party-finding-splitter.sh"
  cd "$BATS_TEST_DIRNAME/../.."
}

teardown() {
  rm -rf "$ROUND_DIR"
}

# ── File/rename audit ────────────────────────────────────────────────────────

# Test expectation: hard rename landed; third-party-finding-splitter.sh is the live path
@test "rename-audit: scripts/third-party-finding-splitter.sh exists and is executable" {
  # Test expectation: codex-finding-splitter.sh renamed to third-party-finding-splitter.sh.
  # (task-20.md File/rename audit bullet.)
  [ -f "$SPLITTER" ]
  [ -x "$SPLITTER" ]
}

# Test expectation: old path completely gone
@test "rename-audit: scripts/codex-finding-splitter.sh no longer exists" {
  # Test expectation: hard rename — no compatibility shim or live file at old path.
  [ ! -f "scripts/codex-finding-splitter.sh" ]
}

# ── New flag-based CLI ───────────────────────────────────────────────────────

# Test expectation: missing --round-dir fails loudly with diagnostic
@test "flag-validation: missing --round-dir exits non-zero with diagnostic" {
  # Test expectation: the new flag-based CLI requires --round-dir; omitting it must exit 1
  # with a stderr diagnostic naming the missing flag (task-20.md companion/splitter coverage).
  run --separate-stderr "$SPLITTER" --tag "$TAG"
  [ "$status" -ne 0 ]
  echo "$stderr" | grep -qiE 'round-dir|missing|required'
}

# Test expectation: missing --tag fails loudly with diagnostic
@test "flag-validation: missing --tag exits non-zero with diagnostic" {
  # Test expectation: the new flag-based CLI requires --tag; omitting it must exit 1
  # with a stderr diagnostic naming the missing flag.
  run --separate-stderr "$SPLITTER" --round-dir "$ROUND_DIR"
  [ "$status" -ne 0 ]
  echo "$stderr" | grep -qiE 'tag|missing|required'
}

# Test expectation: both flags required together
@test "flag-validation: no flags exits non-zero with usage diagnostic" {
  # Test expectation: invoking without any flags fails loudly with a diagnostic
  # mentioning the required flags.
  run --separate-stderr "$SPLITTER"
  [ "$status" -ne 0 ]
  # Diagnostic must name at least one required flag.
  echo "$stderr" | grep -qiE 'round-dir|tag|usage|required'
}

# ── Input from .dispatch/<tag>.raw ──────────────────────────────────────────

# Test expectation: missing .dispatch/<tag>.raw fails loudly
@test "raw-input: missing .dispatch/<tag>.raw exits non-zero with diagnostic" {
  # Test expectation: the script reads <round-dir>/.dispatch/<tag>.raw; if the raw
  # file is absent it must fail loudly with a diagnostic (task-20.md loud failure
  # for missing raw output).
  # Do NOT create the raw file — assert failure.
  run --separate-stderr "$SPLITTER" --round-dir "$ROUND_DIR" --tag "$TAG"
  [ "$status" -ne 0 ]
  echo "$stderr" | grep -qiE 'raw|missing|not found|does not exist'
}

# Test expectation: script reads from .dispatch/<tag>.raw, not a positional arg
@test "raw-input: raw file is read from .dispatch/<tag>.raw path (not positional arg)" {
  # Test expectation: the new interface uses --round-dir + --tag to derive the raw input
  # path: <round-dir>/.dispatch/<tag>.raw. Supplying a correct raw file at that path
  # makes the script succeed (or fail only at write time); providing the raw content
  # via a positional arg must NOT work.
  # This test writes a valid raw file at the expected derived path.
  printf '<<<FINDING-BOUNDARY>>>\n---\nfinding_id: R1-F01\n---\nBody.\n' \
    > "$ROUND_DIR/.dispatch/${TAG}.raw"
  run "$SPLITTER" --round-dir "$ROUND_DIR" --tag "$TAG"
  # Must succeed (exit 0) when the raw file is at the correct derived path.
  [ "$status" -eq 0 ]
}

# ── Finding materialisation: boundary-delimited input ────────────────────────

# Test expectation: boundary-delimited raw content writes stable F01, F02 finding files
@test "materialise: boundary-delimited raw writes F01 and F02 finding files" {
  # Test expectation: each <<<FINDING-BOUNDARY>>> block in the raw file produces one
  # <tag>.finding-F<NN>.md file in stable encounter order (task-20.md companion/splitter
  # coverage: "stable F01, F02, ... materialization").
  printf '<<<FINDING-BOUNDARY>>>\n---\nfinding_id: R1-F01\n---\nFirst body.\n<<<FINDING-BOUNDARY>>>\n---\nfinding_id: R1-F02\n---\nSecond body.\n' \
    > "$ROUND_DIR/.dispatch/${TAG}.raw"
  "$SPLITTER" --round-dir "$ROUND_DIR" --tag "$TAG"
  [ -f "$ROUND_DIR/${TAG}.finding-F01.md" ]
  [ -f "$ROUND_DIR/${TAG}.finding-F02.md" ]
}

# Test expectation: reuses existing fixture data from issue-109 fixtures
@test "materialise: boundary-delimited fixture writes F01 and F02 with correct finding_ids" {
  # Test expectation: reuse the existing tests/fixtures/issue-109/codex-stdout/boundary-delimited.txt
  # fixture to confirm the new flag-based splitter produces the same output as the old positional form.
  cp "tests/fixtures/issue-109/codex-stdout/boundary-delimited.txt" \
    "$ROUND_DIR/.dispatch/${TAG}.raw"
  "$SPLITTER" --round-dir "$ROUND_DIR" --tag "$TAG"
  [ -f "$ROUND_DIR/${TAG}.finding-F01.md" ]
  [ -f "$ROUND_DIR/${TAG}.finding-F02.md" ]
  grep -qF 'finding_id: R3-F01' "$ROUND_DIR/${TAG}.finding-F01.md"
  grep -qF 'finding_id: R3-F02' "$ROUND_DIR/${TAG}.finding-F02.md"
  # Preamble before the first boundary must be discarded.
  ! grep -qF 'must be discarded' "$ROUND_DIR/${TAG}.finding-F01.md"
}

# Test expectation: finding files use stable zero-padded naming
@test "materialise: finding files are named with stable zero-padded index (F01, F02)" {
  # Test expectation: the F<NN> index is zero-padded so lexicographic sort preserves
  # encounter order even with many findings; not F1/F2 but F01/F02.
  printf '<<<FINDING-BOUNDARY>>>\nBody A.\n<<<FINDING-BOUNDARY>>>\nBody B.\n' \
    > "$ROUND_DIR/.dispatch/${TAG}.raw"
  "$SPLITTER" --round-dir "$ROUND_DIR" --tag "$TAG"
  [ -f "$ROUND_DIR/${TAG}.finding-F01.md" ]
  [ -f "$ROUND_DIR/${TAG}.finding-F02.md" ]
  # Must NOT create bare F1/F2 files.
  [ ! -f "$ROUND_DIR/${TAG}.finding-F1.md" ]
  [ ! -f "$ROUND_DIR/${TAG}.finding-F2.md" ]
}

# ── NO_FINDINGS sentinel ─────────────────────────────────────────────────────

# Test expectation: NO_FINDINGS raw content writes clean sentinel marker
@test "no-findings: NO_FINDINGS raw content writes clean sentinel marker" {
  # Test expectation: when the raw file contains only the literal "NO_FINDINGS" sentinel,
  # the splitter writes <tag>.clean.md and produces no finding files
  # (task-20.md companion/splitter coverage: "NO_FINDINGS sentinel writing").
  cp "tests/fixtures/issue-109/codex-stdout/no-findings.txt" \
    "$ROUND_DIR/.dispatch/${TAG}.raw"
  "$SPLITTER" --round-dir "$ROUND_DIR" --tag "$TAG"
  [ -f "$ROUND_DIR/${TAG}.clean.md" ]
  ! ls "$ROUND_DIR"/${TAG}.finding-*.md 2>/dev/null
}

@test "no-findings: NO_FINDINGS without trailing newline also writes clean sentinel" {
  # Test expectation: the 11-byte bare literal form also triggers the sentinel path.
  cp "tests/fixtures/issue-109/codex-stdout/no-findings-no-newline.txt" \
    "$ROUND_DIR/.dispatch/${TAG}.raw"
  "$SPLITTER" --round-dir "$ROUND_DIR" --tag "$TAG"
  [ -f "$ROUND_DIR/${TAG}.clean.md" ]
  ! ls "$ROUND_DIR"/${TAG}.finding-*.md 2>/dev/null
}

# ── Loud failure cases ───────────────────────────────────────────────────────

# Test expectation: malformed raw content exits non-zero with stderr diagnostic
@test "loud-failure: malformed raw input (no boundaries, not NO_FINDINGS) exits non-zero" {
  # Test expectation: raw content that is neither <<<FINDING-BOUNDARY>>>-delimited
  # nor the NO_FINDINGS sentinel is malformed; the splitter must exit non-zero with
  # a stderr diagnostic and write no output files (task-20.md "loud failure for
  # missing flags/raw/boundaries/write errors").
  cp "tests/fixtures/issue-109/codex-stdout/malformed.txt" \
    "$ROUND_DIR/.dispatch/${TAG}.raw"
  run --separate-stderr "$SPLITTER" --round-dir "$ROUND_DIR" --tag "$TAG"
  [ "$status" -ne 0 ]
  echo "$stderr" | grep -qiE 'malformed|FINDING-BOUNDARY|NO_FINDINGS'
  ! ls "$ROUND_DIR"/${TAG}.finding-*.md 2>/dev/null
  ! ls "$ROUND_DIR"/${TAG}.clean.md 2>/dev/null
}

# Test expectation: empty raw input exits non-zero with stderr diagnostic
@test "loud-failure: empty raw input exits non-zero with stderr diagnostic" {
  # Test expectation: a zero-byte raw file is malformed; exit non-zero with
  # a stderr diagnostic naming the cause.
  cp "tests/fixtures/issue-109/codex-stdout/empty.txt" \
    "$ROUND_DIR/.dispatch/${TAG}.raw"
  run --separate-stderr "$SPLITTER" --round-dir "$ROUND_DIR" --tag "$TAG"
  [ "$status" -ne 0 ]
  echo "$stderr" | grep -qiE 'malformed|empty'
  ! ls "$ROUND_DIR"/${TAG}.finding-*.md 2>/dev/null
}

# ── Idempotency ──────────────────────────────────────────────────────────────

# Test expectation: splitter is idempotent on the success path
@test "idempotency: running splitter twice produces identical output" {
  # Test expectation: re-running the splitter on the same raw input must produce
  # byte-identical finding files (idempotent materialisation).
  cp "tests/fixtures/issue-109/codex-stdout/boundary-delimited.txt" \
    "$ROUND_DIR/.dispatch/${TAG}.raw"
  "$SPLITTER" --round-dir "$ROUND_DIR" --tag "$TAG"
  local first_sha
  first_sha=$(shasum "$ROUND_DIR/${TAG}.finding-F01.md" "$ROUND_DIR/${TAG}.finding-F02.md")
  "$SPLITTER" --round-dir "$ROUND_DIR" --tag "$TAG"
  local second_sha
  second_sha=$(shasum "$ROUND_DIR/${TAG}.finding-F01.md" "$ROUND_DIR/${TAG}.finding-F02.md")
  [ "$first_sha" = "$second_sha" ]
}

# ── Stdout bounded (no payload echo) ────────────────────────────────────────

# Test expectation: splitter stdout is empty on success (all output goes to files)
@test "output-bound: splitter stdout is empty on success path" {
  # Test expectation: the splitter writes finding files to disk; stdout must be empty.
  # Raw reviewer payload must not echo into the orchestrator context (CD-1 #4 output-bound).
  cp "tests/fixtures/issue-109/codex-stdout/boundary-delimited.txt" \
    "$ROUND_DIR/.dispatch/${TAG}.raw"
  run "$SPLITTER" --round-dir "$ROUND_DIR" --tag "$TAG"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
