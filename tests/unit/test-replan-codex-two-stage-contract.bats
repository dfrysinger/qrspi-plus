#!/usr/bin/env bats

# Regression test for the 2-stage Replan Codex contract introduced in commit
# 0a33fd3 (codex code review round 2 fix #110-r2):
#
# Stage 1: launch qrspi-replan-analyzer (worker), AWAIT completion, capture
#          the analyzer's proposed-changes payload. The analyzer pipeline
#          MUST NOT preload reviewer-protocol and MUST NOT pass reviewer-only
#          fields (output, round, reviewer_tag) — the analyzer is a worker
#          that returns its payload inline per agents/qrspi-replan-analyzer.md.
#
# Stage 2: launch quality + scope reviewers in parallel from the captured
#          analyzer payload. Both reviewer pipelines DO preload reviewer-protocol
#          and DO pass reviewer-only fields.
#
# A regression to the round-1 broken state (analyzer + reviewers dispatched
# in parallel with reviewer-protocol baked into the analyzer) should fail
# this test before reaching production.

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
}

@test "replan SKILL.md documents Codex flow as 2 stages" {
  grep -qE 'two stages|Stage 1|Stage 2' skills/replan/SKILL.md \
    || { echo "skills/replan/SKILL.md no longer documents the 2-stage Codex contract"; return 1; }
}

@test "replan analyzer Codex pipeline does NOT preload reviewer-protocol" {
  # Find the analyzer Codex pipeline block; it MUST NOT contain a
  # `skills/reviewer-protocol/SKILL.md` awk preamble.
  local analyzer_block
  analyzer_block=$(awk '/Replan analyzer \(Codex\)/,/codex-companion-bg.sh launch/' \
    skills/replan/SKILL.md)
  ! echo "$analyzer_block" | grep -qE 'skills/reviewer-protocol/SKILL\.md' \
    || { echo "analyzer Codex pipeline still preloads reviewer-protocol — analyzer is a worker, not a reviewer"; return 1; }
}

@test "replan analyzer Codex pipeline does NOT pass reviewer-only dispatch fields" {
  local analyzer_block
  analyzer_block=$(awk '/Replan analyzer \(Codex\)/,/codex-companion-bg.sh launch/' \
    skills/replan/SKILL.md)
  ! echo "$analyzer_block" | grep -qE 'reviewer_tag:|^output:|round:.*-analyzer-codex\.md' \
    || { echo "analyzer Codex pipeline still passes reviewer-only fields (output/round/reviewer_tag)"; return 1; }
}

@test "replan quality reviewer Codex pipeline DOES preload reviewer-protocol" {
  local quality_block
  quality_block=$(awk '/Replan quality reviewer \(Codex\)/,/codex-companion-bg.sh launch/' \
    skills/replan/SKILL.md)
  echo "$quality_block" | grep -qE 'skills/reviewer-protocol/SKILL\.md' \
    || { echo "quality reviewer Codex pipeline must preload reviewer-protocol"; return 1; }
}

@test "replan scope reviewer Codex pipeline DOES preload reviewer-protocol" {
  local scope_block
  scope_block=$(awk '/Replan scope-reviewer \(Codex\)/,/codex-companion-bg.sh launch/' \
    skills/replan/SKILL.md)
  echo "$scope_block" | grep -qE 'skills/reviewer-protocol/SKILL\.md' \
    || { echo "scope reviewer Codex pipeline must preload reviewer-protocol"; return 1; }
}

@test "replan SKILL documents await-and-capture before reviewer dispatch" {
  # Stage 1 must say "await" and capture the analyzer payload. Stage 2's
  # reviewers reference the captured payload (analyzer-response payload).
  grep -qE 'await.*[Aa]nalyzer|capture.*analyzer|ANALYZER_PAYLOAD' skills/replan/SKILL.md \
    || { echo "Stage 1 must document awaiting the analyzer and capturing its payload before Stage 2"; return 1; }
}

@test "replan analyzer agent has no skills: preload (worker, not reviewer)" {
  # qrspi-replan-analyzer.md is a worker — its frontmatter must NOT include
  # `skills: [reviewer-protocol]` (reviewer-only).
  local frontmatter
  frontmatter=$(awk '/^---$/{n++; if(n==2) exit; next} n==1{print}' \
    agents/qrspi-replan-analyzer.md)
  ! echo "$frontmatter" | grep -qE '^skills:' \
    || { echo "qrspi-replan-analyzer.md must NOT declare a skills: preload — it is a worker, not a reviewer"; return 1; }
}
