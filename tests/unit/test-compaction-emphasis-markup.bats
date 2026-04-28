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
#
# CodexF1 (fix-cycle 1, downgraded HIGH→LOW per Claude verifier):
#   The implement-row M53 emphasis markers MUST live in
#   `skills/implement/SKILL.md`, NOT in
#   `skills/implement/templates/per-task-orchestrator.md`. The template at
#   line 236 explicitly states it "does NOT invoke any route step, present
#   a batch gate, or recommend compaction — those are owned by Implement
#   (see implement/SKILL.md)". This is the load-bearing delegation contract
#   that resolves the spec ambiguity between (a) marking the row at the
#   template (because the template hosts the per-task subagent dispatch)
#   and (b) marking the row at Implement/SKILL.md (because Implement is
#   the orchestrator that owns the batch gate / compaction recommendation).
#   This test enforces (b): @tests below assert (i) emphasis markers in
#   `skills/implement/SKILL.md` (positive coverage at the implement row)
#   AND (ii) the delegation-contract pin in the template (the
#   per-task-orchestrator.md does NOT carry compaction-recommendation
#   language).
#
# CodexF2 (fix-cycle 1):
#   For each `—` (no-tick) cell in the M53 matrix, this file adds a
#   per-cell negative-coverage @test asserting that the corresponding file
#   does NOT carry an emphasis-marker callout for the anchor at that cell.
#   This implements the requirement in `tasks/task-18.md` line 23 ("for
#   each `—` cell in the matrix, no emphasis-marker callout exists at that
#   anchor location in the corresponding file (negative coverage)").
#
#   Three cells (goals × pre-large-subagent, design × pre-large-subagent,
#   structure × pre-large-subagent) currently DIVERGE from structure.md's
#   matrix — those skill files DO carry an `M53; pre-large-subagent-dispatch`
#   callout despite the matrix marking them `—`. The divergence is
#   documented inline at the affected @tests via `skip` with a reason
#   string; reconciliation (either updating the matrix in structure.md or
#   removing the SKILL.md callouts) is out of scope for T18.
#
# CodexF3 (fix-cycle 1):
#   The previous lower-bound `[M53-anchor-counts]` mutation guard was
#   removed: per-anchor positive-coverage assertions (assert_anchor_present)
#   now carry the load-bearing per-cell positive contract, and the negative
#   coverage added in CodexF2 catches absence-related mutations at `—` cells.
#   The lower-bound count guard had a known masking failure mode (a skill
#   could lose a required anchor and still satisfy the count if it had
#   other unrelated emphasis markers) and is no longer needed.

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

# =============================================================================
# Per-cell negative coverage (CodexF2 fix-cycle 1)
#
# For each `—` (no-tick) cell in the M53 Hook-Point Locations matrix, assert
# that the corresponding SKILL.md does NOT carry an emphasis-marker callout
# tagged with that anchor's distinguishing token. The "anchor distinguishing
# token" is the literal anchor name as used in the M53 callouts elsewhere
# in the codebase: `pre-review-loop`, `pre-large-subagent-dispatch` (or
# `pre-large-subagent`), `terminal-state` (or `terminal state`),
# `cross-skill-transition` (or `cross-skill transition`).
#
# Negative-coverage assertion: grep for emphasis-marker prefix
# (IMPORTANT|Iron Rule|IRON RULE|RED FLAG|Red Flag) AND anchor token on the
# same line. If any match exists, the test fails — meaning the file carries
# a callout at an anchor location where the matrix says `—`.
#
# Three cells DIVERGE from the matrix (goals/design/structure ×
# pre-large-subagent — those skill files carry such callouts despite the
# matrix marking them `—`). Those three @tests use `skip` with a reason
# string; reconciliation is out of scope for T18.
# =============================================================================

assert_anchor_absent() {
  local file="$1"
  local anchor_re="$2"
  if grep -E "(IMPORTANT|Iron Rule|IRON RULE|RED FLAG|Red Flag).*${anchor_re}|${anchor_re}.*(IMPORTANT|Iron Rule|IRON RULE|RED FLAG|Red Flag)" "$file" > /dev/null; then
    printf 'M53 anchor unexpectedly present in %s (matrix says `—`; regex: %s)\n' "$file" "$anchor_re" >&2
    grep -nE "(IMPORTANT|Iron Rule|IRON RULE|RED FLAG|Red Flag).*${anchor_re}|${anchor_re}.*(IMPORTANT|Iron Rule|IRON RULE|RED FLAG|Red Flag)" "$file" >&2
    return 1
  fi
  return 0
}

# --- goals row ---

@test "[M53-neg:goals] pre-large-subagent-dispatch anchor is no-tick (matrix cell empty; negative coverage)" {
  local f="$REPO_ROOT/skills/goals/SKILL.md"
  assert_anchor_absent "$f" "pre-large-subagent"
}

# --- questions row ---

@test "[M53-neg:questions] pre-large-subagent-dispatch anchor is no-tick (matrix cell empty; negative coverage)" {
  local f="$REPO_ROOT/skills/questions/SKILL.md"
  [ -f "$f" ]
  assert_anchor_absent "$f" "pre-large-subagent"
}

# --- design row ---

@test "[M53-neg:design] pre-large-subagent-dispatch anchor is no-tick (matrix cell empty; negative coverage)" {
  local f="$REPO_ROOT/skills/design/SKILL.md"
  assert_anchor_absent "$f" "pre-large-subagent"
}

# --- phasing row ---

@test "[M53-neg:phasing] pre-large-subagent-dispatch anchor is no-tick (matrix cell empty; negative coverage)" {
  local f="$REPO_ROOT/skills/phasing/SKILL.md"
  [ -f "$f" ]
  assert_anchor_absent "$f" "pre-large-subagent"
}

# --- structure row ---

@test "[M53-neg:structure] pre-large-subagent-dispatch anchor is no-tick (matrix cell empty; negative coverage)" {
  local f="$REPO_ROOT/skills/structure/SKILL.md"
  assert_anchor_absent "$f" "pre-large-subagent"
}

# --- implement row ---

@test "[M53-neg:implement] pre-review-loop anchor is no-tick (matrix cell empty; negative coverage)" {
  # Implement is special: per design intent, pre-review-loop does NOT
  # apply because Implement does not own the per-task review loop (that
  # loop lives inside the per-task orchestrator subagent, whose template
  # carries no M53 markers per the delegation contract pinned above).
  local f="$REPO_ROOT/skills/implement/SKILL.md"
  [ -f "$f" ]
  assert_anchor_absent "$f" "pre-review-loop"
}

# --- integrate row ---

@test "[M53-neg:integrate] pre-large-subagent-dispatch anchor is no-tick (matrix cell empty; negative coverage)" {
  local f="$REPO_ROOT/skills/integrate/SKILL.md"
  [ -f "$f" ]
  assert_anchor_absent "$f" "pre-large-subagent"
}

# --- test row ---

@test "[M53-neg:test] pre-large-subagent-dispatch anchor is no-tick (matrix cell empty; negative coverage)" {
  local f="$REPO_ROOT/skills/test/SKILL.md"
  [ -f "$f" ]
  assert_anchor_absent "$f" "pre-large-subagent"
}

# --- replan row ---

@test "[M53-neg:replan] pre-large-subagent-dispatch anchor is no-tick (matrix cell empty; negative coverage)" {
  local f="$REPO_ROOT/skills/replan/SKILL.md"
  [ -f "$f" ]
  assert_anchor_absent "$f" "pre-large-subagent"
}

# --- using-qrspi row (two `—` cells: pre-review-loop AND pre-large-subagent) ---

@test "[M53-neg:using-qrspi] pre-review-loop anchor is no-tick (matrix cell empty; negative coverage)" {
  local f="$REPO_ROOT/skills/using-qrspi/SKILL.md"
  [ -f "$f" ]
  assert_anchor_absent "$f" "pre-review-loop"
}

@test "[M53-neg:using-qrspi] pre-large-subagent-dispatch anchor is no-tick (matrix cell empty; negative coverage)" {
  local f="$REPO_ROOT/skills/using-qrspi/SKILL.md"
  [ -f "$f" ]
  assert_anchor_absent "$f" "pre-large-subagent"
}
