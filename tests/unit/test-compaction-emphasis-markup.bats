#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# Task 18 — M53 compaction-emphasis markup tests.
#
# Per design.md M53 and structure.md "Hook-Point Locations (M53)" matrix
# (transcribed below), each per-skill placement site uses an approved
# emphasis-marker pattern (IMPORTANT / Iron Rule / RED FLAG) at four
# pressure moments: pre-review-loop, pre-large-subagent-dispatch,
# terminal-state, cross-skill-transition. Per-skill judgment determines
# which moments fire (`✓` = anchor applies; `—` = does not).
#
# Source of truth for the matrix: structure.md § Hook-Point Locations (M53).
# Transcribed here (NOT parsed from markdown) for stability — if the matrix
# changes upstream, this test file is the place to update.
#
# Cross-cutting assertions:
#   - No file under skills/_shared/ matches *compaction-callout* pattern
#     (M53 deliberately uses inline duplication, not centralization — per
#     design.md "Trade-offs Considered: M53 — centralized callout template
#     vs. per-site high-emphasis markup").
#   - implement template (skills/implement/templates/per-task-orchestrator.md)
#     does NOT carry the implement-row M53 callouts itself — those callouts
#     live in skills/implement/SKILL.md (the per-task orchestrator subagent
#     delegates compaction-recommendation to its caller per its own prompt
#     line 236). The implement-row matrix coverage is therefore checked
#     against skills/implement/SKILL.md.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  export REPO_ROOT
}

# =============================================================================
# Helper: assert_anchor_present <file> <anchor-regex>
#
# Asserts that <file> contains a line matching the emphasis-marker prefix
# (IMPORTANT / Iron Rule / IRON RULE / RED FLAG / Red Flag) AND <anchor-regex>
# on the same line. Returns 0 on match, 1 on miss; prints the file + regex
# on miss for diagnostics.
# =============================================================================

assert_anchor_present() {
  local file="$1"
  local anchor_re="$2"
  if grep -E "(IMPORTANT|Iron Rule|IRON RULE|RED FLAG|Red Flag).*${anchor_re}|${anchor_re}.*(IMPORTANT|Iron Rule|IRON RULE|RED FLAG|Red Flag)" "$file" > /dev/null; then
    return 0
  fi
  printf 'M53 anchor missing in %s (regex: %s)\n' "$file" "$anchor_re" >&2
  return 1
}

# =============================================================================
# Per-row positive coverage (one @test per skill row, walking ticked anchors).
#
# Anchor regexes are kept loose to tolerate the two stylistic variants
# observed in the post-Wave-5 baseline: (a) the "[M53 — <anchor>]" form
# (e.g. goals/SKILL.md) and (b) the "Compaction recommended (M53; <anchor>)"
# form (e.g. questions/SKILL.md, parallelize/SKILL.md). Both are approved
# under the design.md guidance; the test asserts the anchor concept is
# carried by an emphasis marker, not the exact tagging convention.
# =============================================================================

# Matrix row: goals | ✓ | — | ✓ | ✓ |
@test "[M53-row:goals] ticked anchors carry emphasis-marker callouts" {
  local f="$REPO_ROOT/skills/goals/SKILL.md"
  [ -f "$f" ]
  # pre-review-loop ✓
  assert_anchor_present "$f" "[Pp]re-review-loop|review.loop|reviewer dispatch|before dispatching reviewers"
  # terminal-state ✓
  assert_anchor_present "$f" "[Tt]erminal[ -][Ss]tate|approved\\.|[Cc]ompaction recommended.*terminal"
  # cross-skill-transition ✓
  assert_anchor_present "$f" "[Cc]ross-skill[ -]transition|next skill|invoke.*next"
}

# Matrix row: questions | ✓ | — | ✓ | ✓ |
@test "[M53-row:questions] ticked anchors carry emphasis-marker callouts" {
  local f="$REPO_ROOT/skills/questions/SKILL.md"
  [ -f "$f" ]
  assert_anchor_present "$f" "[Pp]re-review-loop|review.loop|reviewer dispatch|before dispatching"
  assert_anchor_present "$f" "[Tt]erminal[ -][Ss]tate|approved\\.|[Cc]ompaction recommended.*terminal|good point to compact"
  assert_anchor_present "$f" "[Cc]ross-skill[ -]transition|next skill|invoke.*next"
}

# Matrix row: research | ✓ | ✓ | ✓ | ✓ |
@test "[M53-row:research] all four anchors carry emphasis-marker callouts" {
  local f="$REPO_ROOT/skills/research/SKILL.md"
  [ -f "$f" ]
  assert_anchor_present "$f" "[Pp]re-review-loop|review.loop|reviewer dispatch|before dispatching"
  assert_anchor_present "$f" "[Pp]re-large-subagent|synthesis subagent|large.*subagent|33|before dispatching this subagent"
  assert_anchor_present "$f" "[Tt]erminal[ -][Ss]tate|approved\\.|[Cc]ompaction recommended.*terminal|good point to compact"
  assert_anchor_present "$f" "[Cc]ross-skill[ -]transition|next skill|invoke.*next"
}

# Matrix row: design | ✓ | — | ✓ | ✓ |
@test "[M53-row:design] ticked anchors carry emphasis-marker callouts" {
  local f="$REPO_ROOT/skills/design/SKILL.md"
  [ -f "$f" ]
  assert_anchor_present "$f" "[Pp]re-review-loop|review.loop|reviewer dispatch|before dispatching"
  assert_anchor_present "$f" "[Tt]erminal[ -][Ss]tate|approved\\.|[Cc]ompaction recommended.*terminal|good point to compact"
  assert_anchor_present "$f" "[Cc]ross-skill[ -]transition|next skill|invoke.*next"
}

# Matrix row: phasing | ✓ | — | ✓ | ✓ |
@test "[M53-row:phasing] ticked anchors carry emphasis-marker callouts" {
  local f="$REPO_ROOT/skills/phasing/SKILL.md"
  [ -f "$f" ]
  assert_anchor_present "$f" "[Pp]re-review-loop|review.loop|reviewer dispatch|before dispatching|before this dispatch"
  assert_anchor_present "$f" "[Tt]erminal[ -][Ss]tate|approval|approved|good point to compact|before invoking Structure"
  assert_anchor_present "$f" "[Cc]ross-skill[ -]transition|next step|next skill|invoking Structure"
}

# Matrix row: structure | ✓ | — | ✓ | ✓ |
@test "[M53-row:structure] ticked anchors carry emphasis-marker callouts" {
  local f="$REPO_ROOT/skills/structure/SKILL.md"
  [ -f "$f" ]
  assert_anchor_present "$f" "[Pp]re-review-loop|review.loop|reviewer dispatch|before dispatching"
  assert_anchor_present "$f" "[Tt]erminal[ -][Ss]tate|approved\\.|[Cc]ompaction recommended.*terminal|good point to compact"
  assert_anchor_present "$f" "[Cc]ross-skill[ -]transition|next skill|invoke.*next|invoking the next"
}

# Matrix row: plan | ✓ | ✓ | ✓ | ✓ |
@test "[M53-row:plan] all four anchors carry emphasis-marker callouts" {
  local f="$REPO_ROOT/skills/plan/SKILL.md"
  [ -f "$f" ]
  assert_anchor_present "$f" "[Pp]re-review-loop|review.loop|review.round dispatch|reviewer dispatch|before reviewers dispatch"
  assert_anchor_present "$f" "[Pp]re-large-subagent|spec.generation|sub.subagent|fan.out|reviewer fan.out|parallel reviewer"
  assert_anchor_present "$f" "[Tt]erminal[ -][Ss]tate|approved\\.|[Cc]ompaction recommended.*terminal|good point to compact|split tasks"
  assert_anchor_present "$f" "[Cc]ross-skill[ -]transition|next skill|invoke.*next|invoking the next"
}

# Matrix row: parallelize | ✓ | ✓ | ✓ | ✓ |
@test "[M53-row:parallelize] all four anchors carry emphasis-marker callouts" {
  local f="$REPO_ROOT/skills/parallelize/SKILL.md"
  [ -f "$f" ]
  assert_anchor_present "$f" "[Pp]re-review-loop|review.loop|reviewer dispatch|before dispatching reviewers"
  assert_anchor_present "$f" "[Pp]re-large-subagent|dependency.graph synthesis|reviewer subagent|synthesis subagent"
  assert_anchor_present "$f" "[Tt]erminal[ -][Ss]tate|approved|good point to compact|plan approved"
  assert_anchor_present "$f" "[Cc]ross-skill[ -]transition|next skill|invoke.*next|invoking the next"
}

# Matrix row: implement | — | ✓ | ✓ | ✓ |
@test "[M53-row:implement] ticked anchors carry emphasis-marker callouts" {
  local f="$REPO_ROOT/skills/implement/SKILL.md"
  [ -f "$f" ]
  # pre-review-loop is — (no assertion)
  # pre-large-subagent-dispatch ✓ (per-task orchestrator dispatch — large)
  assert_anchor_present "$f" "[Pp]re-large-subagent|per.task orchestrator|wave.*dispatch|batch dispatch"
  # terminal-state ✓
  assert_anchor_present "$f" "[Tt]erminal[ -][Ss]tate|batch complete|good point to compact"
  # cross-skill-transition ✓
  assert_anchor_present "$f" "[Cc]ross-skill[ -]transition|next route step|next skill|invoke.*next"
}

# Matrix row: integrate | ✓ | — | ✓ | ✓ |
@test "[M53-row:integrate] ticked anchors carry emphasis-marker callouts" {
  local f="$REPO_ROOT/skills/integrate/SKILL.md"
  [ -f "$f" ]
  assert_anchor_present "$f" "[Pp]re-review-loop|review.loop|reviewer dispatch|before dispatching"
  assert_anchor_present "$f" "[Tt]erminal[ -][Ss]tate|approved\\.|[Cc]ompaction recommended.*terminal|good point to compact"
  assert_anchor_present "$f" "[Cc]ross-skill[ -]transition|next skill|invoke.*next|invoking the next"
}

# Matrix row: test | ✓ | — | ✓ | ✓ |
@test "[M53-row:test] ticked anchors carry emphasis-marker callouts" {
  local f="$REPO_ROOT/skills/test/SKILL.md"
  [ -f "$f" ]
  assert_anchor_present "$f" "[Pp]re-review-loop|review.loop|reviewer dispatch|before dispatching"
  assert_anchor_present "$f" "[Tt]erminal[ -][Ss]tate|approved\\.|[Cc]ompaction recommended.*terminal|good point to compact|before invoking"
  assert_anchor_present "$f" "[Cc]ross-skill[ -]transition|next skill|invoke.*next|qrspi:replan"
}

# Matrix row: replan | ✓ | — | ✓ | ✓ |
@test "[M53-row:replan] ticked anchors carry emphasis-marker callouts" {
  local f="$REPO_ROOT/skills/replan/SKILL.md"
  [ -f "$f" ]
  assert_anchor_present "$f" "[Pp]re-review-loop|review.loop|reviewer dispatch|before dispatching"
  assert_anchor_present "$f" "[Tt]erminal[ -][Ss]tate|analysis complete|good point to compact"
  assert_anchor_present "$f" "[Cc]ross-skill[ -]transition|next skill|next.phase|loop.back|Major path|Minor path"
}

# Matrix row: using-qrspi | — | — | ✓ | ✓ |
@test "[M53-row:using-qrspi] ticked anchors carry emphasis-marker callouts" {
  local f="$REPO_ROOT/skills/using-qrspi/SKILL.md"
  [ -f "$f" ]
  # pre-review-loop and pre-large-subagent-dispatch are — (no assertion)
  # terminal-state ✓
  assert_anchor_present "$f" "[Tt]erminal[ -][Ss]tate|terminal state|good point to compact"
  # cross-skill-transition ✓
  assert_anchor_present "$f" "[Cc]ross-skill[ -]transition|cross-skill transition|next-skill invocation|invoking.*qrspi:"
}

# =============================================================================
# Cross-cutting assertions
# =============================================================================

@test "[M53-shared-template] no centralized compaction-callout file under skills/_shared/" {
  # Per design.md "Trade-offs Considered: M53 — centralized callout template
  # vs. per-site high-emphasis markup", the design leans toward per-site
  # in-line markup with no shared template. This test enforces the leaning:
  # if a future change introduces skills/_shared/compaction-callout.md (or
  # similar), this test fires and forces an explicit decision review.
  local count
  count=$(find "$REPO_ROOT/skills/_shared" -type f -name "*compaction-callout*" 2>/dev/null | wc -l | tr -d ' ')
  [ "$count" -eq 0 ]
}

@test "[M53-shared-template] no skill SKILL.md cites a centralized compaction-callout asset" {
  # Negative-coverage: no SKILL.md should `@include` or link to a centralized
  # compaction-callout asset under skills/_shared/. Catches a citation-based
  # centralization (an alternative to a literal shared file).
  if grep -rE "skills/_shared/.*compaction.callout|@include.*compaction.callout" "$REPO_ROOT/skills" 2>/dev/null; then
    return 1
  fi
  return 0
}

@test "[M53-implement-template] per-task-orchestrator.md does NOT recommend compaction (delegated to Implement)" {
  # The per-task-orchestrator template explicitly delegates compaction
  # recommendation to its caller (Implement). The implement row's M53
  # callouts therefore live in skills/implement/SKILL.md, not in the
  # template. This test pins the contract.
  local f="$REPO_ROOT/skills/implement/templates/per-task-orchestrator.md"
  [ -f "$f" ]
  # The template should explicitly state the delegation.
  grep -qE "does NOT.*recommend compaction|owned by Implement" "$f"
}

@test "[M53-anchor-counts] approved emphasis-marker count per file meets matrix lower bounds" {
  # Lightweight global-mutation guard: counts the number of emphasis-marker
  # callouts (lines containing IMPORTANT/Iron Rule/IRON RULE/RED FLAG/Red
  # Flag) per file and asserts the count meets or exceeds the per-file
  # minimum implied by the matrix's ticked-anchor count. Not a tight bound
  # (files may contain emphasis markers for non-M53 reasons — e.g. goals
  # has IRON RULEs around the type field — so we use the matrix tick count
  # as a lower bound, not equality).
  local skill min count
  declare -A min_anchors=(
    [goals]=3
    [questions]=3
    [research]=4
    [design]=3
    [phasing]=3
    [structure]=3
    [plan]=4
    [parallelize]=4
    [implement]=3
    [integrate]=3
    [test]=3
    [replan]=3
    [using-qrspi]=2
  )
  for skill in "${!min_anchors[@]}"; do
    min="${min_anchors[$skill]}"
    count=$(grep -cE "IMPORTANT|Iron Rule|IRON RULE|RED FLAG|Red Flag" "$REPO_ROOT/skills/$skill/SKILL.md" 2>/dev/null || echo 0)
    if [ "$count" -lt "$min" ]; then
      printf 'M53 emphasis-marker count below matrix lower bound for %s: got %d, expected >= %d\n' "$skill" "$count" "$min" >&2
      return 1
    fi
  done
}
