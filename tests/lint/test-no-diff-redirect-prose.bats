#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# tests/lint/test-no-diff-redirect-prose.bats
#
# Task 06 (CD-2 / G9) — skill-body audit lint asserting zero
# `git diff > round-NN.diff` Bash redirect blocks remain in the eight
# artifact-step SKILL.md files after the T05 prose-replacement pass.
#
# Contract under test
# -------------------
# The implementer-supplied helper
#
#     qrspi_diff_redirect_audit [--skill-base <DIR>]
#
# scans the eight artifact-step SKILL.md files
#
#     <DIR>/{goals,questions,research,design,phasing,structure,parallelize,replan}/SKILL.md
#
# (default <DIR> is "$REPO_ROOT/skills") for any Bash diff-redirect block —
# any line that contains a `git ... diff ...` invocation whose stdout is
# redirected (`>`) into a `round-NN.diff` (or `round-${ROUND}.diff`,
# `round-01.diff`, etc.) artifact file. Such a line is the load-bearing
# fingerprint of the per-step orchestrator-side diff-emission prose pattern
# that CD-2 / T05 retires in favour of dispatch-agent's high-level entry.
#
# On clean input the helper exits 0 silently. On any hit it exits non-zero
# and emits, for every hit, a named diagnostic of the shape
#
#     <file>:<line>: diff-redirect-prose: <matching line text>
#
# to stderr. The diagnostic names (a) the offending file path, (b) the
# 1-based line number within that file, and (c) the matching line content
# (which itself contains both `git diff` and `round-...diff` so the
# `git diff > round-NN.diff` redirect pattern is named verbatim in the
# operator's failure output). No silent non-zero exit — every non-zero
# return is paired with at least one named diagnostic line on stderr.
#
# Scope discipline
# ----------------
# The helper's corpus is fixed: exactly the eight artifact-step skills
# listed above. A benign occurrence of the literal `git diff > round-NN.diff`
# string in any OTHER file (a different skill body, a test fixture, this
# very lint file's prose) is NOT flagged — the helper only opens the eight
# named SKILL.md files. The `--skill-base <DIR>` flag exists so this test
# can swap in a fixture tree without touching the real skills/ directory.
#
# RED-gate verification
# ---------------------
# Every @test below first asserts that the implementer has defined
# `qrspi_diff_redirect_audit` in this file (via `declare -F`). On the bare
# branch the helper does not exist, so each test fails loudly with a
# `helper-missing:` diagnostic — assertion-failure path, not exit-code 127
# command-not-found infrastructure breakage. The paired implement-phase
# commit adds the helper inline and the tests transition to GREEN.
#
# Bash 3.2 compatible (macOS /bin/bash 3.2): no associative arrays, no
# `mapfile`, no `${var,,}`, no `coproc`, no `wait -n`. mktemp + printf only.

load '../helpers/skill-markdown'

# ---------------------------------------------------------------------------
# _t06_assert_helper_defined
# Fail loudly (RED) when the implementer-supplied helper is missing.
# ---------------------------------------------------------------------------
_t06_assert_helper_defined() {
  if ! declare -F qrspi_diff_redirect_audit >/dev/null 2>&1; then
    printf 'helper-missing: qrspi_diff_redirect_audit not defined in %s\n' \
      "${BATS_TEST_FILENAME:-this lint file}" >&2
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# _t06_make_clean_fixture_base <dir>
# Populate <dir>/{goals,...,replan}/SKILL.md with prose that does NOT
# contain the diff-redirect pattern. Each body carries a token so the
# fixture is non-empty and distinguishable from the real skills/ tree.
# ---------------------------------------------------------------------------
_t06_make_clean_fixture_base() {
  local base="$1"
  local s
  for s in goals questions research design phasing structure parallelize replan; do
    mkdir -p "$base/$s"
    printf '# %s SKILL (fixture)\n\nDispatch the round through dispatch-agent high-level entry.\n' \
      "$s" > "$base/$s/SKILL.md"
  done
}

# ---------------------------------------------------------------------------
# _t06_inject_redirect_into <file>
# Append a Bash diff-redirect prose line of the exact retired shape into
# <file>. Returns the 1-based line number on stdout for the test to assert
# against the helper's diagnostic.
# ---------------------------------------------------------------------------
_t06_inject_redirect_into() {
  local file="$1"
  printf '\nBefore dispatching, the orchestrator runs `git -C "<repo>" diff "<ref>" -- "<artifact>" > "<dir>/round-${ROUND}.diff"` as a Bash redirect.\n' \
    >> "$file"
  # The injected redirect line is the final non-empty line; report its 1-based
  # line number by counting all lines in the file.
  awk 'END { print NR }' "$file"
}

# ===========================================================================
# @test 1 — corpus invariant: real eight SKILL.md files are clean post-T05
# ===========================================================================
@test "qrspi_diff_redirect_audit: real artifact-step skill bodies contain zero diff-redirect blocks post-T05" {
  require_repo_root
  _t06_assert_helper_defined

  run qrspi_diff_redirect_audit
  [ -n "$output" ] && : # touch $output so set -u shells do not trip
  if [ "$status" -ne 0 ]; then
    printf 'expected clean corpus (exit 0); got exit %d with output:\n%s\n' \
      "$status" "$output" >&2
    return 1
  fi
}

# ===========================================================================
# @test 2 — fail-direction: a re-introduced redirect block in a fixture
#           skill body causes the lint to fail (non-zero exit).
# ===========================================================================
@test "qrspi_diff_redirect_audit: fails non-zero when a fixture skill body re-introduces a diff-redirect block" {
  require_repo_root
  _t06_assert_helper_defined

  local fixture_base
  fixture_base="$(mktemp -d "${TMPDIR:-/tmp}/t06-redirect-fixture-XXXXXXXX")"
  _t06_make_clean_fixture_base "$fixture_base"
  _t06_inject_redirect_into "$fixture_base/design/SKILL.md" >/dev/null

  run qrspi_diff_redirect_audit --skill-base "$fixture_base"
  local rc=$status
  local out="$output"
  rm -rf "$fixture_base"

  if [ "$rc" -eq 0 ]; then
    printf 'fail-direction breach: lint exited 0 on a fixture that re-introduced the redirect block. Output:\n%s\n' \
      "$out" >&2
    return 1
  fi
}

# ===========================================================================
# @test 3 — named diagnostic: failure output names the offending file path
# ===========================================================================
@test "qrspi_diff_redirect_audit: failure diagnostic names the offending file path" {
  require_repo_root
  _t06_assert_helper_defined

  local fixture_base
  fixture_base="$(mktemp -d "${TMPDIR:-/tmp}/t06-redirect-fixture-XXXXXXXX")"
  _t06_make_clean_fixture_base "$fixture_base"
  local offender="$fixture_base/phasing/SKILL.md"
  _t06_inject_redirect_into "$offender" >/dev/null

  run qrspi_diff_redirect_audit --skill-base "$fixture_base"
  local rc=$status
  local out="$output"
  rm -rf "$fixture_base"

  if [ "$rc" -eq 0 ]; then
    printf 'expected non-zero exit on injected redirect; got 0\n' >&2
    return 1
  fi
  case "$out" in
    *"$offender"*) : ;;
    *)
      printf 'diagnostic did not name offending file %s. Output was:\n%s\n' \
        "$offender" "$out" >&2
      return 1
      ;;
  esac
}

# ===========================================================================
# @test 4 — named diagnostic: failure output names the offending line number
# ===========================================================================
@test "qrspi_diff_redirect_audit: failure diagnostic names the offending line number" {
  require_repo_root
  _t06_assert_helper_defined

  local fixture_base
  fixture_base="$(mktemp -d "${TMPDIR:-/tmp}/t06-redirect-fixture-XXXXXXXX")"
  _t06_make_clean_fixture_base "$fixture_base"
  local offender="$fixture_base/parallelize/SKILL.md"
  local lineno
  lineno="$(_t06_inject_redirect_into "$offender")"

  run qrspi_diff_redirect_audit --skill-base "$fixture_base"
  local rc=$status
  local out="$output"
  rm -rf "$fixture_base"

  if [ "$rc" -eq 0 ]; then
    printf 'expected non-zero exit on injected redirect; got 0\n' >&2
    return 1
  fi
  # Diagnostic shape includes :<line>: — assert the exact line number we
  # injected appears bracketed by colons (file:line:diagnostic).
  case "$out" in
    *":${lineno}:"*) : ;;
    *)
      printf 'diagnostic did not name offending line number %s in colon-bracketed shape. Output was:\n%s\n' \
        "$lineno" "$out" >&2
      return 1
      ;;
  esac
}

# ===========================================================================
# @test 5 — named diagnostic: failure output names the diff-redirect pattern
#           (both `git diff` and `round-...diff` appear in the diagnostic so
#           the operator sees the retired pattern verbatim).
# ===========================================================================
@test "qrspi_diff_redirect_audit: failure diagnostic names the git-diff redirect pattern verbatim" {
  require_repo_root
  _t06_assert_helper_defined

  local fixture_base
  fixture_base="$(mktemp -d "${TMPDIR:-/tmp}/t06-redirect-fixture-XXXXXXXX")"
  _t06_make_clean_fixture_base "$fixture_base"
  _t06_inject_redirect_into "$fixture_base/replan/SKILL.md" >/dev/null

  run qrspi_diff_redirect_audit --skill-base "$fixture_base"
  local rc=$status
  local out="$output"
  rm -rf "$fixture_base"

  if [ "$rc" -eq 0 ]; then
    printf 'expected non-zero exit on injected redirect; got 0\n' >&2
    return 1
  fi
  case "$out" in
    *"git"*"diff"*"round-"*".diff"*) : ;;
    *)
      printf 'diagnostic did not surface the git-diff redirect pattern (expected "git" ... "diff" ... "round-...diff" in the output). Output was:\n%s\n' \
        "$out" >&2
      return 1
      ;;
  esac
}

# ===========================================================================
# @test 6 — scope discipline: an unrelated file under the fixture base
#           containing the literal `git diff > round-NN.diff` string does NOT
#           trigger a false positive. Only the eight named SKILL.md files
#           are scanned.
# ===========================================================================
@test "qrspi_diff_redirect_audit: ignores diff-redirect literals in files outside the eight artifact-step skills" {
  require_repo_root
  _t06_assert_helper_defined

  local fixture_base
  fixture_base="$(mktemp -d "${TMPDIR:-/tmp}/t06-redirect-scope-XXXXXXXX")"
  _t06_make_clean_fixture_base "$fixture_base"

  # Plant the redirect literal in an unrelated skill (`implement` is NOT in
  # the eight artifact-step skill set) and in a non-skill fixture path.
  mkdir -p "$fixture_base/implement"
  printf 'git -C "<r>" diff "<ref>" -- "<a>" > "<d>/round-${ROUND}.diff"\n' \
    > "$fixture_base/implement/SKILL.md"
  printf 'git diff > round-01.diff\n' > "$fixture_base/test-fixture-prose.md"

  run qrspi_diff_redirect_audit --skill-base "$fixture_base"
  local rc=$status
  local out="$output"
  rm -rf "$fixture_base"

  if [ "$rc" -ne 0 ]; then
    printf 'scope breach: lint flagged a redirect outside the eight artifact-step skills (exit %d). Output:\n%s\n' \
      "$rc" "$out" >&2
    return 1
  fi
}
