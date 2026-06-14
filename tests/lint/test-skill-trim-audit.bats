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
# qrspi_skill_trim_audit [--skill-base <DIR>]
#
# Implementation of the T38 / G9 skill-trim audit helper. Scans every active
# SKILL.md file directly under <DIR>/*/SKILL.md (one level deep) for any of
# the eight narrative-restatement patterns retired by tasks T32-T36:
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
# Default <DIR> is "$REPO_ROOT/skills".
#
# Allowed-exception scope (line-level): the lint's scope is narrative
# restatement only, so the following load-bearing line shapes are exempt
# from flagging when they happen to contain one of the eight patterns:
#
#   (1) Concrete script-name call-site references of shape
#       `scripts/<name>.sh` (e.g., `scripts/round-prepare.sh`,
#       `scripts/verifier-fan-in.sh`, `scripts/codex-companion-bg.sh
#       await <jobId>`) — process-step Bash call sites, not retired
#       script-mechanic narrative.
#
#   (2) Bare `<name>.sh` path-shaped references without the `scripts/`
#       prefix (e.g., `round-prepare.sh` cited mid-sentence) — same
#       call-site rationale as (1), broader citation form.
#
#   (3) In-fence active commands: the matched pattern lies inside
#       backticks on that line (e.g., `git -C <worktree> diff HEAD~1
#       --unified=0`) — load-bearing command shown verbatim to the
#       implementer, not narrative restatement of the mechanic.
#
#   (4) Negative guards: the line carries a negation token (`No `,
#       `no `, `not `, `Not `, `Never`, `never`, `without`, `Without`,
#       `MUST NOT`, `does not`, `do not`) preceding the pattern match
#       (anywhere earlier on the line). These are load-bearing safety
#       assertions that the retired mechanic is NOT used — e.g.,
#       "No `HEAD~1` shorthand is used and no silent fallback fires".
#
#   (5) Delegation pointers: the line contains one of the canonical
#       delegation phrases (`'s contract`, `per the loud-failure rule`,
#       `per the canonical`, `delegates to`, `'s schema`,
#       `the verifier's`, `is a contract violation`). These route the
#       reader to the canonical owner of the mechanic rather than
#       restating it — e.g., "Full sidecar schema validation is the
#       verifier's contract (see `agents/qrspi-finding-verifier.md`)".
#
# On clean input: exit 0, no output. On any hit: exit non-zero and emit,
# for every hit, one diagnostic of shape
#
#     <file>:<line>: skill-trim-audit: <pattern>: <matching line text>
#
# to stderr. The diagnostic names (a) the offending file path,
# (b) the 1-based line number, (c) the offending pattern verbatim,
# and (d) the matching line content. No silent non-zero exit.
#
# Bash 3.2 compatible (macOS /bin/bash 3.2): no associative arrays, no
# mapfile, no ${var,,}, no coproc, no wait -n.
# ---------------------------------------------------------------------------
qrspi_skill_trim_audit() {
  local skill_base=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --skill-base)
        if [ "$#" -lt 2 ]; then
          printf 'qrspi_skill_trim_audit: --skill-base requires an argument\n' >&2
          return 2
        fi
        skill_base="$2"
        shift 2
        ;;
      *)
        printf 'qrspi_skill_trim_audit: unknown argument: %s\n' "$1" >&2
        return 2
        ;;
    esac
  done

  if [ -z "$skill_base" ]; then
    if [ -z "${REPO_ROOT:-}" ]; then
      printf 'qrspi_skill_trim_audit: REPO_ROOT unset and no --skill-base given\n' >&2
      return 2
    fi
    skill_base="$REPO_ROOT/skills"
  fi

  if [ ! -d "$skill_base" ]; then
    printf 'qrspi_skill_trim_audit: skill base directory not found: %s\n' "$skill_base" >&2
    return 2
  fi

  local rc=0
  local file pattern hits
  # The eight retired narrative-restatement patterns (positional list; do not
  # reorder — the verbatim pattern strings are part of the diagnostic shape
  # asserted by the test suite and the G9 acceptance contract).
  local patterns="jobId tmpfile HEAD~1 narrow.broaden sidecar.*schema change_type:.*enum verifier.*threshold third-party.*splitter"

  for file in "$skill_base"/*/SKILL.md; do
    [ -r "$file" ] || continue
    for pattern in $patterns; do
      # awk single-pass: for each line matching `pattern`, skip if any of the
      # five line-level exemptions from the header doc apply (script-call,
      # bare *.sh, in-fence command, negative-guard, delegation pointer);
      # otherwise emit one diagnostic line. The exemptions are line-level by
      # design — a narrative-restatement sentence that legitimately carries
      # one of these load-bearing shapes is treated as in-scope context, not
      # retired mechanic narrative.
      hits="$(awk -v f="$file" -v pat="$pattern" '
        function is_exempt(line, p, mlen,    pre, parts, btcount, mtxt) {
          # (1) scripts/<name>.sh call-site
          if (line ~ /scripts\/[A-Za-z0-9_.-]+\.sh/) return 1
          # (2) bare <name>.sh path-shaped citation
          if (line ~ /(^|[^A-Za-z0-9_\/-])[A-Za-z0-9_-]+\.sh([^A-Za-z0-9]|$)/) return 1
          # (5) delegation pointers (anywhere on line)
          if (line ~ /'\''s contract/) return 1
          if (line ~ /'\''s schema/) return 1
          if (line ~ /per the loud-failure rule/) return 1
          if (line ~ /per the canonical/) return 1
          if (line ~ /delegates to/) return 1
          if (line ~ /the verifier'\''s/) return 1
          if (line ~ /is a contract violation/) return 1
          # Compute pre = substring of line preceding first pattern match,
          # and mtxt = the matched span itself.
          pre = substr(line, 1, p - 1)
          mtxt = substr(line, p, mlen)
          # (3) in-fence: odd number of backticks before pattern AND the
          # matched span itself contains no backticks → entirely inside
          # one inline-code fence. A matched span that crosses backticks
          # spans prose, so the fence rule does NOT apply.
          btcount = split(pre, parts, "`") - 1
          if (btcount % 2 == 1 && mtxt !~ /`/) return 1
          # (4) negative-guard tokens preceding the pattern
          if (pre ~ /(^|[^A-Za-z])(No|no|Not|not|Never|never|Without|without)([^A-Za-z]|$)/) return 1
          if (pre ~ /(MUST NOT|does not|do not)/) return 1
          return 0
        }
        {
          p = match($0, pat)
          if (p == 0) next
          if (is_exempt($0, p, RLENGTH)) next
          printf "%s:%d: skill-trim-audit: %s: %s\n", f, NR, pat, $0
        }
      ' "$file")"
      if [ -n "$hits" ]; then
        printf '%s\n' "$hits" >&2
        rc=1
      fi
    done
  done
  return $rc
}

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
# A fixture skill body that legitimately uses the five allowed line-level
# exemption shapes — (1) `scripts/<name>.sh` call-site references,
# (2) bare `<name>.sh` path-shaped citations, (3) in-fence active commands
# containing one of the patterns, (4) negative-guard sentences asserting
# the retired mechanic is NOT used, and (5) delegation pointers routing
# to the canonical owner — does NOT trigger the lint. The scope is
# narrative restatement only; load-bearing call-sites, commands, guards,
# and delegations are allowed.
# ===========================================================================
@test "qrspi_skill_trim_audit: fixture skill body using all five allowed exemption shapes (script call-site, bare *.sh, in-fence command, negative guard, delegation pointer) does not trigger the lint" {
  require_repo_root
  _t38_assert_helper_defined

  local fixture_base
  fixture_base="$(mktemp -d "${TMPDIR:-/tmp}/t38-trim-allow-XXXXXXXX")"
  _t38_make_clean_fixture_base "$fixture_base"

  # (1) scripts/<name>.sh call-site references and (2) bare *.sh citations.
  cat >> "$fixture_base/phasing/SKILL.md" <<'EOF'

Run the round preparation step:

    scripts/round-prepare.sh "$ROUND" "$STEP"

After all reviewers complete, fan in the verifier sidecars:

    scripts/verifier-fan-in.sh "$ROUND" "$STEP"

The companion script (codex-companion-bg.sh) awaits a jobId before
proceeding; round-prepare.sh handles convergence per its own contract.
EOF

  # (3) In-fence active command containing HEAD~1 (load-bearing command,
  # not narrative restatement of the mechanic).
  cat >> "$fixture_base/implement/SKILL.md" <<'EOF'

Obtain the added lines for the trim audit:

    `git -C <worktree> diff HEAD~1 --unified=0 | grep '^+'`
EOF

  # (4) Negative-guard sentences (assert the retired mechanic is NOT used).
  cat >> "$fixture_base/integrate/SKILL.md" <<'EOF'

No HEAD~1 shorthand is used here — the anchor file is the source of truth.
Do not fall back silently to HEAD~1 or base-branch on a missing anchor.
The per-round commit is not a candidate to be cross-checked against HEAD~1.
EOF

  # (5) Delegation pointers (route to canonical owner; do not restate).
  cat >> "$fixture_base/questions/SKILL.md" <<'EOF'

Full sidecar schema validation is the verifier's contract; this skill
assumes well-formed sidecars. Out-of-enum change_type: values are a
contract violation per the loud-failure rule enforced by the fan-in script.
EOF

  run qrspi_skill_trim_audit --skill-base "$fixture_base"
  local rc=$status
  local out="$output"
  rm -rf "$fixture_base"

  if [ "$rc" -ne 0 ]; then
    printf 'false-positive: lint flagged a fixture containing only allowed line-level exemption shapes (exit %d). Output:\n%s\n' \
      "$rc" "$out" >&2
    return 1
  fi
}
