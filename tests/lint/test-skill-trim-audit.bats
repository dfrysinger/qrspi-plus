#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# tests/lint/test-skill-trim-audit.bats
#
# Task 38 (G9 Acceptance bullet 8) — skill-trim audit lint asserting zero
# grep matches across all active SKILL.md files for the eight documented
# narrative-restatement patterns retired by tasks T32–T36.
#
# Contract under test
# -------------------
# The helper
#
#     qrspi_skill_trim_audit [--skill-base <DIR>]
#
# (to be defined inline in this same file by the paired implementer commit)
# scans every active SKILL.md file under <DIR> for any of these eight
# narrative-restatement patterns:
#
#     jobId
#     tmpfile
#     HEAD~1
#     narrow.broaden
#     sidecar.*schema
#     change_type:.*enum
#     verifier.*threshold
#     third-party.*splitter
#
# Default <DIR> is "$REPO_ROOT/skills". The corpus is every SKILL.md file
# directly under <DIR>/*/SKILL.md (one level deep) — these are the active
# skill bodies. Non-SKILL.md companion files under the same tree are out of
# scope (their narrative is reference material, not the skill body itself).
#
# On clean input the helper exits 0 silently. On any hit it exits non-zero
# and emits, for every hit, one diagnostic of shape
#
#     <file>:<line>: skill-trim-audit: <pattern>: <matching line text>
#
# to stderr. The diagnostic names (a) the offending file path, (b) the
# 1-based line number, (c) the offending pattern verbatim, and (d) the
# matching line content. No silent non-zero exit — every non-zero return
# is paired with at least one named diagnostic line on stderr.
#
# Scope discipline
# ----------------
# The lint targets narrative restatements only. Concrete script names that
# appear in process-step Bash calls (e.g., `scripts/round-prepare.sh`,
# `scripts/verifier-fan-in.sh`) are an allowed exception: they are
# load-bearing call-site identifiers, not the retired script-mechanic
# narrative. The third @test below pins this no-false-positive guard by
# planting a `scripts/round-prepare.sh` invocation in a fixture skill body
# and asserting the lint still exits 0.
#
# RED→GREEN history
# -----------------
# The test-writer commit (this file's introduction) ships the @tests
# WITHOUT the `qrspi_skill_trim_audit` helper body. Every @test calls
# `_t38_assert_helper_defined`, which uses `declare -F` to assert the
# helper exists; on the bare RED branch that assertion fails with a named
# `helper-missing:` diagnostic (assertion-path failure, not exit-code 127
# command-not-found infrastructure breakage). The paired implementer
# commit then adds the helper inline below in this same file, at which
# point the tests transition to GREEN. The sibling pattern matches T06's
# `test-no-diff-redirect-prose.bats`: helper co-located with its tests.
#
# Bash 3.2 compatible (macOS /bin/bash 3.2): no associative arrays, no
# mapfile, no ${var,,}, no coproc, no wait -n. mktemp + printf only.

load '../helpers/skill-markdown'

# ---------------------------------------------------------------------------
# _t38_assert_helper_defined
# Defense-in-depth guard: assert `qrspi_skill_trim_audit` is defined in
# this file. On the RED test-writer commit the helper is absent and this
# guard surfaces a named `helper-missing:` assertion-path failure rather
# than letting a downstream `run qrspi_skill_trim_audit` call exit 127
# (command not found) and present as infrastructure breakage. The
# implementer commit makes this pass by adding the helper body below.
# ---------------------------------------------------------------------------
_t38_assert_helper_defined() {
  if ! declare -F qrspi_skill_trim_audit >/dev/null 2>&1; then
    printf 'helper-missing: qrspi_skill_trim_audit not defined in %s\n' \
      "${BATS_TEST_FILENAME:-this lint file}" >&2
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# _t38_make_clean_fixture_base <dir>
# Populate <dir>/<skill>/SKILL.md for a small representative set of skill
# directories with prose that contains NONE of the eight restatement
# patterns. The bodies are non-empty so the audit has something to scan.
# ---------------------------------------------------------------------------
_t38_make_clean_fixture_base() {
  local base="$1"
  local s
  for s in goals questions research design phasing structure parallelize replan implement test integrate; do
    mkdir -p "$base/$s"
    printf '# %s SKILL (fixture)\n\nDispatch the round through the documented entry point.\n' \
      "$s" > "$base/$s/SKILL.md"
  done
}

# ---------------------------------------------------------------------------
# _t38_inject_jobid_narrative_into <file>
# Append a narrative-restatement line containing the `jobId` token (one of
# the eight retired patterns) into <file>. Print the 1-based line number
# of the injected line on stdout so tests can assert it appears in the
# diagnostic.
# ---------------------------------------------------------------------------
_t38_inject_jobid_narrative_into() {
  local file="$1"
  printf '\nThe wrapper prints the captured jobId to stdout and the orchestrator pastes it into the await call.\n' \
    >> "$file"
  awk 'END { print NR }' "$file"
}

# ===========================================================================
# @test 1 — corpus invariant (G9 Acceptance bullet 8, verbatim):
#
# "A grep-based audit confirms zero matches across all active SKILL.md files
#  for the following patterns: `jobId`, `tmpfile`, `HEAD~1`, `narrow.broaden`,
#  `sidecar.*schema`, `change_type:.*enum`, `verifier.*threshold`,
#  `third-party.*splitter`"
#
# The real `skills/` corpus, after T32–T36 trim the residual narrative,
# contains zero matches for any of the eight patterns. The lint exits 0
# silently on the real corpus.
# ===========================================================================
@test "qrspi_skill_trim_audit: real active SKILL.md corpus contains zero matches for the eight retired narrative-restatement patterns" {
  require_repo_root
  _t38_assert_helper_defined

  run qrspi_skill_trim_audit
  if [ "$status" -ne 0 ]; then
    printf 'expected clean corpus (exit 0); got exit %d with output:\n%s\n' \
      "$status" "$output" >&2
    return 1
  fi
}

# ===========================================================================
# @test 2 — fail-direction guard:
#
# A fixture skill body that re-introduces a `jobId` narrative restatement
# causes the lint to fail non-zero, and the failure diagnostic names the
# offending file path, the 1-based line number, and the offending pattern
# (`jobId`) verbatim so the operator can locate and remove the regression.
# ===========================================================================
@test "qrspi_skill_trim_audit: fixture skill body re-introducing a jobId narrative restatement fails the lint with a named diagnostic (file, line, pattern)" {
  require_repo_root
  _t38_assert_helper_defined

  local fixture_base
  fixture_base="$(mktemp -d "${TMPDIR:-/tmp}/t38-trim-fail-XXXXXXXX")"
  _t38_make_clean_fixture_base "$fixture_base"
  local offender="$fixture_base/design/SKILL.md"
  local lineno
  lineno="$(_t38_inject_jobid_narrative_into "$offender")"

  run qrspi_skill_trim_audit --skill-base "$fixture_base"
  local rc=$status
  local out="$output"
  rm -rf "$fixture_base"

  if [ "$rc" -eq 0 ]; then
    printf 'fail-direction breach: lint exited 0 on a fixture that re-introduced the jobId narrative. Output:\n%s\n' \
      "$out" >&2
    return 1
  fi

  # Diagnostic must name the offending file path.
  case "$out" in
    *"$offender"*) : ;;
    *)
      printf 'diagnostic did not name offending file %s. Output was:\n%s\n' \
        "$offender" "$out" >&2
      return 1
      ;;
  esac

  # Diagnostic must name the offending 1-based line number in the canonical
  # file:line:diagnostic colon-bracketed shape.
  case "$out" in
    *":${lineno}:"*) : ;;
    *)
      printf 'diagnostic did not name offending line number %s in colon-bracketed shape. Output was:\n%s\n' \
        "$lineno" "$out" >&2
      return 1
      ;;
  esac

  # Diagnostic must name the offending pattern verbatim.
  case "$out" in
    *jobId*) : ;;
    *)
      printf 'diagnostic did not name offending pattern "jobId" verbatim. Output was:\n%s\n' \
        "$out" >&2
      return 1
      ;;
  esac
}

# ===========================================================================
# @test 3 — no-false-positive guard:
#
# A fixture skill body that legitimately references concrete script names
# in process-step Bash calls (e.g., `scripts/round-prepare.sh`,
# `scripts/verifier-fan-in.sh`) does NOT trigger the lint. The scope is
# narrative restatement only; call-site script references are load-bearing
# and allowed.
# ===========================================================================
@test "qrspi_skill_trim_audit: fixture skill body referencing concrete script names (scripts/round-prepare.sh, scripts/verifier-fan-in.sh) does not trigger the lint" {
  require_repo_root
  _t38_assert_helper_defined

  local fixture_base
  fixture_base="$(mktemp -d "${TMPDIR:-/tmp}/t38-trim-allow-XXXXXXXX")"
  _t38_make_clean_fixture_base "$fixture_base"

  # Plant concrete script-name call-site references in a skill body. These
  # are the allowed-exception case: they are not narrative restatement of
  # the retired script mechanic, they are the script being called.
  cat >> "$fixture_base/phasing/SKILL.md" <<'EOF'

Run the round preparation step:

    scripts/round-prepare.sh "$ROUND" "$STEP"

After all reviewers complete, fan in the verifier sidecars:

    scripts/verifier-fan-in.sh "$ROUND" "$STEP"
EOF

  run qrspi_skill_trim_audit --skill-base "$fixture_base"
  local rc=$status
  local out="$output"
  rm -rf "$fixture_base"

  if [ "$rc" -ne 0 ]; then
    printf 'false-positive: lint flagged a fixture containing only allowed concrete script-name call-site references (exit %d). Output:\n%s\n' \
      "$rc" "$out" >&2
    return 1
  fi
}
