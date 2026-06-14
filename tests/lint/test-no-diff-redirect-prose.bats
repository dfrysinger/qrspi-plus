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
# The helper
#
#     qrspi_diff_redirect_audit [--skill-base <DIR>]
#
# (defined inline below in this same file — see the `qrspi_diff_redirect_audit`
# function definition further down) scans the eight artifact-step SKILL.md files
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
# RED→GREEN history
# -----------------
# The paired RED commit (test-writer) introduced this file WITHOUT the helper
# body — every @test below first calls `_t06_assert_helper_defined`, which
# uses `declare -F` to assert the helper exists; on the bare RED branch that
# assertion failed loudly with a `helper-missing:` diagnostic (assertion-path
# failure, not exit-code 127 command-not-found infrastructure breakage). The
# paired implementer commit then added `qrspi_diff_redirect_audit` inline
# below in this same file (see the function definition further down), at
# which point the tests transitioned to GREEN. In the current GREEN state
# the helper is co-located with its tests by design (sibling pattern: the
# T12 skill-body lint follows the same single-file layout); the
# `_t06_assert_helper_defined` guard remains as defense-in-depth so a future
# accidental deletion of the helper would still surface as a named
# assertion-path failure rather than a silent 127.
#
# Bash 3.2 compatible (macOS /bin/bash 3.2): no associative arrays, no
# `mapfile`, no `${var,,}`, no `coproc`, no `wait -n`. mktemp + printf only.

load '../helpers/skill-markdown'

# ---------------------------------------------------------------------------
# qrspi_diff_redirect_audit [--skill-base <DIR>]
#
# Implementation of the T06 / CD-2 / G9 skill-body audit helper. Scans the
# eight artifact-step SKILL.md files
#
#     <DIR>/{goals,questions,research,design,phasing,structure,parallelize,replan}/SKILL.md
#
# for any Bash diff-redirect block — any line containing both a `git ... diff`
# invocation and a `> ... round-<N>.diff` stdout redirect into a round
# artifact file. Default <DIR> is "$REPO_ROOT/skills".
#
# On clean input: exit 0, no output. On any hit: exit non-zero and emit, for
# every hit, one diagnostic of shape
#
#     <file>:<line>: diff-redirect-prose: <matching line text>
#
# to stderr. Scope is strictly the eight named files — no other path under
# <DIR> is opened, so a benign occurrence of the literal string elsewhere
# never triggers a false positive.
#
# Bash 3.2 compatible (macOS /bin/bash 3.2): no associative arrays, no
# mapfile, no ${var,,}, no coproc, no wait -n.
# ---------------------------------------------------------------------------
qrspi_diff_redirect_audit() {
  local skill_base=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --skill-base)
        if [ "$#" -lt 2 ]; then
          printf 'qrspi_diff_redirect_audit: --skill-base requires an argument\n' >&2
          return 2
        fi
        skill_base="$2"
        shift 2
        ;;
      *)
        printf 'qrspi_diff_redirect_audit: unknown argument: %s\n' "$1" >&2
        return 2
        ;;
    esac
  done

  if [ -z "$skill_base" ]; then
    if [ -z "${REPO_ROOT:-}" ]; then
      printf 'qrspi_diff_redirect_audit: REPO_ROOT unset and no --skill-base given\n' >&2
      return 2
    fi
    skill_base="$REPO_ROOT/skills"
  fi

  local rc=0
  local s file
  for s in goals questions research design phasing structure parallelize replan; do
    file="$skill_base/$s/SKILL.md"
    [ -r "$file" ] || continue
    # A diff-redirect prose line: contains a `git ... diff` invocation whose
    # stdout is redirected via a Bash redirect operator into a `round-<token>.diff`
    # artifact target. The fingerprint of a real Bash redirect (vs. an incidental
    # `>` character inside a path placeholder like `<ABS_ARTIFACT_DIR>/...`) is
    # whitespace on both sides of `>`, optionally followed by a quote, then a
    # path that ends in `round-<token>.diff`. The token may be a literal NN
    # (round-01.diff) or a shell expansion (round-${ROUND}.diff).
    local hits
    hits="$(awk -v f="$file" '
      /git/ && /diff/ && /[[:space:]]>[[:space:]]*"?[^[:space:]"\x27]*round-[^[:space:]"\x27]*\.diff/ {
        printf "%s:%d: diff-redirect-prose: %s\n", f, NR, $0
      }
    ' "$file")"
    if [ -n "$hits" ]; then
      printf '%s\n' "$hits" >&2
      rc=1
    fi
  done
  return $rc
}

# ---------------------------------------------------------------------------
# _t06_assert_helper_defined
# Defense-in-depth guard: assert `qrspi_diff_redirect_audit` is defined in
# this file. In the current GREEN state the helper is defined inline above,
# so this assertion passes; it remains as a guard so a future accidental
# deletion of the helper would surface as a named `helper-missing:`
# assertion-path failure on stderr rather than a silent exit-code 127
# command-not-found breakage. (It also documented the original RED gate:
# on the test-writer commit before the helper was added, this assertion
# was the failure path that drove the implementer commit.)
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
