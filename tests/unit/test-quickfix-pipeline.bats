#!/usr/bin/env bats
#
# Structural lint for the quick-fix pipeline reshape contracts.
#
# This file pins the contract-bearing prose surfaces produced by the wave of
# work that delivered:
#   - the `question_budget` config-schema field (Field Definitions bullet and
#     the "Fields that affect pipeline behavior" validation-table row in
#     `skills/using-qrspi/SKILL.md`)
#   - the quick-fix auto-approve branches in `skills/questions/SKILL.md`,
#     `skills/research/SKILL.md`, and `skills/plan/SKILL.md` (skip the
#     human-approval gate and write `status: approved` automatically when
#     `pipeline: quick` and the review round produces zero kept findings)
#   - the binary Test gate (ship vs fix) in `skills/test/SKILL.md` that
#     activates when `config.md` carries `pipeline: quick`
#   - the N=1 dynamic-skip branch in `skills/implement/SKILL.md` that bypasses
#     Parallelize and Integrate dispatch when the approved task count is
#     exactly one, plus the literal audit-trail path
#     `reviews/implement-entry-decisions.md` that records the skip decision.
#
# Each test greps a single skill file for a contract-bearing phrase and exits
# zero on match. The file produces no behavioral coverage — its job is to fail
# loudly if a future edit removes or weakens any of the contract surfaces
# above. Match patterns are deliberately broad enough to survive cosmetic
# rewrites and narrow enough to catch deletion of the contract itself.
#
# Repo-root anchoring follows the pattern used by other structural-lint files
# in this directory (e.g. `test-cross-skill-contracts.bats`): resolve the repo
# root once via `BATS_TEST_FILENAME` so the file runs identically from the
# repo root or from `tests/unit/`.

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
}

setup() {
  USING_QRSPI="$REPO_ROOT/skills/using-qrspi/SKILL.md"
  QUESTIONS="$REPO_ROOT/skills/questions/SKILL.md"
  RESEARCH="$REPO_ROOT/skills/research/SKILL.md"
  PLAN="$REPO_ROOT/skills/plan/SKILL.md"
  TEST_SKILL="$REPO_ROOT/skills/test/SKILL.md"
  IMPLEMENT="$REPO_ROOT/skills/implement/SKILL.md"
}

# ---------------------------------------------------------------------------
# question_budget Field Definitions surface
# ---------------------------------------------------------------------------
@test "using-qrspi/SKILL.md lists question_budget in its Field Definitions bullet list" {
  # Extract the Field Definitions section (bounded by the leading bold marker
  # and the next bold-or-heading marker) and grep for a bullet that references
  # `question_budget`. Section-scoping avoids a false pass on the writer-fence
  # or validation-table occurrences elsewhere in the file.
  awk '
    /^\*\*Field definitions:\*\*/ { in_section=1; next }
    /^\*\*/ && in_section { in_section=0 }
    /^## / && in_section { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" \
    | grep -qE '^[[:space:]]*[-*][[:space:]]+`question_budget`' \
    || { echo "no Field Definitions bullet references \`question_budget\` in $USING_QRSPI"; return 1; }
}

# ---------------------------------------------------------------------------
# question_budget validation-table row surface
# ---------------------------------------------------------------------------
@test "using-qrspi/SKILL.md has a question_budget row in the Fields-that-affect-pipeline-behavior table" {
  # Section-scope the "Fields that affect pipeline behavior" validation table
  # and grep for a markdown table row (leading pipe + cell containing
  # `question_budget`). The row must live inside the table, not in surrounding
  # prose.
  awk '
    /^### Fields that affect pipeline behavior/ { in_section=1; next }
    /^### / && in_section { in_section=0 }
    /^## / && in_section { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" \
    | grep -qE '^\|[^|]*`question_budget`[^|]*\|' \
    || { echo "no validation-table row references \`question_budget\` in the Fields-that-affect-pipeline-behavior table in $USING_QRSPI"; return 1; }
}

# ---------------------------------------------------------------------------
# Quick-fix auto-approve branch — Questions
# ---------------------------------------------------------------------------
@test "questions/SKILL.md carries the quick-fix auto-approve branch language" {
  # Co-occurrence check: the pipeline-mode key (`pipeline: quick` or
  # equivalent) and either the auto-approve writer phrase (`status: approved`
  # written automatically) or the skip-gate phrase (human-approval gate is
  # skipped) must both appear in the file. They need not be on the same line.
  grep -qE 'pipeline:[[:space:]]*quick|pipeline[[:space:]]*==[[:space:]]*quick' "$QUESTIONS" \
    || { echo "no pipeline-mode key (\`pipeline: quick\`) in $QUESTIONS"; return 1; }

  grep -qiE 'human-approval gate is skipped|skips? the human-approval gate|status: approved.*automatically|automatically.*status: approved|auto-approve|written automatically without' "$QUESTIONS" \
    || { echo "no auto-approve / skip-gate phrase in $QUESTIONS"; return 1; }
}

# ---------------------------------------------------------------------------
# Quick-fix auto-approve branch — Research
# ---------------------------------------------------------------------------
@test "research/SKILL.md carries the quick-fix auto-approve branch language" {
  grep -qE 'pipeline:[[:space:]]*quick|pipeline[[:space:]]*==[[:space:]]*quick' "$RESEARCH" \
    || { echo "no pipeline-mode key (\`pipeline: quick\`) in $RESEARCH"; return 1; }

  grep -qiE 'human-approval gate is skipped|skips? the human-approval gate|status: approved.*automatically|automatically.*status: approved|auto-approve|written automatically without' "$RESEARCH" \
    || { echo "no auto-approve / skip-gate phrase in $RESEARCH"; return 1; }
}

# ---------------------------------------------------------------------------
# Quick-fix auto-approve branch — Plan
# ---------------------------------------------------------------------------
@test "plan/SKILL.md carries the quick-fix auto-approve branch language" {
  grep -qE 'pipeline:[[:space:]]*quick|pipeline[[:space:]]*==[[:space:]]*quick' "$PLAN" \
    || { echo "no pipeline-mode key (\`pipeline: quick\`) in $PLAN"; return 1; }

  grep -qiE 'human-approval gate is skipped|skips? the human-approval gate|status: approved.*automatically|automatically.*status: approved|auto-approve|proceed automatically without' "$PLAN" \
    || { echo "no auto-approve / skip-gate phrase in $PLAN"; return 1; }
}

# ---------------------------------------------------------------------------
# Binary Test gate (ship/fix) — Test
# ---------------------------------------------------------------------------
@test "test/SKILL.md documents the binary ship/fix gate for quick-fix mode" {
  # Two surfaces must co-occur: the pipeline-mode key and a phrase that names
  # the two-option ship/fix choice (or constrains the gate to those two
  # options). The phrase need not be on the same line as the pipeline-mode
  # key — both must appear somewhere in the file.
  grep -qE 'pipeline:[[:space:]]*quick|pipeline[[:space:]]*==[[:space:]]*quick' "$TEST_SKILL" \
    || { echo "no pipeline-mode key (\`pipeline: quick\`) in $TEST_SKILL"; return 1; }

  grep -qiE 'binary.*(ship|fix).*(ship|fix)|ship[[:space:]]*(/|or|vs|,)[[:space:]]*fix|exactly two choices|two choices.*ship.*fix|only the two choices' "$TEST_SKILL" \
    || { echo "no binary ship/fix gate phrasing in $TEST_SKILL"; return 1; }
}

# ---------------------------------------------------------------------------
# N=1 dynamic-skip branch — Implement
# ---------------------------------------------------------------------------
@test "implement/SKILL.md documents the N=1 dynamic-skip of Parallelize and Integrate" {
  # Co-occurrence check: the single-task condition phrase (`N=1`, `N == 1`, or
  # equivalent natural-language wording such as "exactly one") and the skip
  # target (Parallelize and Integrate) must both appear in the file.
  grep -qE 'N[[:space:]]*=[[:space:]]*1|N[[:space:]]*==[[:space:]]*1|N is exactly one|exactly one approved task|single-task' "$IMPLEMENT" \
    || { echo "no N=1 single-task condition phrase in $IMPLEMENT"; return 1; }

  grep -qiE 'skip(s|ped|ping)?[[:space:]]+(both[[:space:]]+)?Parallelize[[:space:]]+and[[:space:]]+Integrate|bypass(es|ing)?[[:space:]]+Parallelize[[:space:]]+and[[:space:]]+Integrate|skip[- ]parallelize[- ]integrate' "$IMPLEMENT" \
    || { echo "no 'skip Parallelize and Integrate' target phrase in $IMPLEMENT"; return 1; }
}

# ---------------------------------------------------------------------------
# N=1 audit-trail literal path — Implement
# ---------------------------------------------------------------------------
@test "implement/SKILL.md cites the literal audit-trail path reviews/implement-entry-decisions.md" {
  # Literal-path assertion: the audit-record contract requires the exact
  # relative path string. A weakening rename (e.g., to
  # `reviews/implement-decisions.md`) must fail this check.
  grep -qF 'reviews/implement-entry-decisions.md' "$IMPLEMENT" \
    || { echo "literal audit-trail path 'reviews/implement-entry-decisions.md' not found in $IMPLEMENT"; return 1; }
}

# ---------------------------------------------------------------------------
# Independent-assertion / non-zero-on-missing contract (suite-shape property)
# ---------------------------------------------------------------------------
@test "every target skill file referenced by an assertion exists and is readable" {
  # The contract that "any single missing surface fails the corresponding @test
  # and the suite returns non-zero" presupposes that each target skill file is
  # actually present on disk. A missing file would cause every grep above to
  # fail with a confusing 'No such file' error rather than the named diagnostic
  # the assertion was written to surface. Pin the file-existence precondition
  # so a future skill-rename surfaces here first, not in cascading grep
  # failures elsewhere in the file.
  for target in "$USING_QRSPI" "$QUESTIONS" "$RESEARCH" "$PLAN" "$TEST_SKILL" "$IMPLEMENT"; do
    [ -r "$target" ] \
      || { echo "target skill file missing or unreadable: $target"; return 1; }
  done
}

# ---------------------------------------------------------------------------
# Repo-root anchoring (suite-shape property)
# ---------------------------------------------------------------------------
@test "repo-root anchoring resolves to the actual qrspi-plus repo root" {
  # The file resolves $REPO_ROOT via BATS_TEST_FILENAME (two levels up from
  # tests/unit/). The anchoring contract says the file runs identically from
  # the repo root or from tests/unit/. Verify the resolution lands on a
  # directory that actually contains the skills tree this file asserts
  # against — a regression in the anchoring would silently break every test
  # above. Use a sentinel that is unlikely to move (the skills/ directory
  # itself) rather than a specific file inside it.
  [ -d "$REPO_ROOT/skills" ] \
    || { echo "REPO_ROOT does not resolve to a directory containing skills/: $REPO_ROOT"; return 1; }
  [ -d "$REPO_ROOT/tests/unit" ] \
    || { echo "REPO_ROOT does not resolve to a directory containing tests/unit/: $REPO_ROOT"; return 1; }
}
