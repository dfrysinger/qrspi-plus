#!/usr/bin/env bats

# Structural CI test: quality reviewers must not contain scope language.
# Also asserts the design-reviewer Read carve-out is correctly bounded.
# Added in commit 5/22 of issue-110 migration.

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
}

@test "quality reviewers do not Read OWNS/DEFERS rules" {
  # Quality reviewers must NOT load the per-artifact OWNS/DEFERS file —
  # that is the scope-reviewer's job. The narrow check is "no reference
  # to the rule file"; emitting language is checked separately below.
  for name in goals questions research design structure phasing plan parallelize replan; do
    local body
    body=$(awk '/^---$/{n++; next} n>=2{print}' "agents/qrspi-${name}-reviewer.md")
    echo "$body" | grep -qE 'owns-defers\.md' \
      && { echo "qrspi-${name}-reviewer.md references owns-defers.md (scope-reviewer territory)"; return 1; }
  done
  return 0
}

@test "quality reviewers do not author or emit scope-shaped findings" {
  # Quality reviewers must not produce the kinds of findings that belong
  # to the scope-reviewer. We catch that as an emit-shape: a positive
  # instruction to emit scope/boundary/OWNS-DEFERS findings.
  #
  # The regex covers both spaced (`OWNS / DEFERS`) and unspaced
  # (`OWNS/DEFERS`) forms — the unspaced form is what every quality
  # reviewer body actually contains in NEGATION prose ("do not emit
  # OWNS/DEFERS violations as findings"). We exclude negation lines
  # (do not / MUST not / cannot / never) so the test only fires on
  # affirmative instructions to author scope findings.
  local emit_shaped='emit (a |an |any )?(scope|boundary[- ]drift|OWNS/DEFERS|OWNS / DEFERS) (finding|violation)|scope-compliance finding'
  local negation='do not|do NOT|MUST not|cannot|never'
  for name in goals questions research design structure phasing plan parallelize replan; do
    local body affirmative
    body=$(awk '/^---$/{n++; next} n>=2{print}' "agents/qrspi-${name}-reviewer.md")
    affirmative=$(echo "$body" | grep -iE "$emit_shaped" | grep -ivE "$negation" || true)
    [ -z "$affirmative" ] \
      || { echo "qrspi-${name}-reviewer.md contains affirmative emit-shaped scope language: $affirmative"; return 1; }
  done
  return 0
}

@test "quality reviewers grant Read in tools frontmatter (#112 PR-1 diff-file pattern)" {
  # Post-#112 PR-1 (Mechanism A): every reviewer now Reads the orchestrator-
  # emitted reviews/{step}/round-NN.diff file via the Read tool — the diff
  # content is intentionally kept out of the dispatch prompt to preserve
  # main-chat cache hits. Granting Read is therefore part of the contract.
  #
  # The earlier "8 of 9 must not grant Read" invariant was anchored to the
  # then-current "no Read tool needed" property; #112 PR-1 changed that
  # premise. The semantic invariant the older test was protecting (quality
  # reviewers must not load OWNS/DEFERS) is preserved by the
  # `quality reviewers do not Read OWNS/DEFERS rules` @test above (which
  # checks the file-name reference, not the tool grant — and is unaffected
  # by the Read-tool grant).
  for name in goals questions research structure phasing plan parallelize replan; do
    local fm
    fm=$(awk '/^---$/{n++; next} n==1{print}' "agents/qrspi-${name}-reviewer.md")
    echo "$fm" | grep -qE '^tools:.*Read' \
      || { echo "qrspi-${name}-reviewer.md must grant Read for the #112 diff-file pattern"; return 1; }
  done
  return 0
}

@test "qrspi-design-reviewer preserves Citation-verification Read carve-out alongside #112 diff-file Read" {
  # The design-reviewer's research/q*.md citation-verification carve-out
  # predates #112 PR-1; the diff-file Read pattern is an additional,
  # orthogonal use of the Read tool. Both must remain documented in the
  # agent body.
  local fm body
  fm=$(awk '/^---$/{n++; next} n==1{print}' agents/qrspi-design-reviewer.md)
  body=$(awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-design-reviewer.md)
  echo "$fm" | grep -qE '^tools:.*Read' || { echo "design-reviewer must grant Read"; return 1; }
  # Pre-existing carve-out: research/q*.md citation verification.
  echo "$body" | grep -B1 -A1 -F 'Citation-verification Read exception' \
    | grep -qE 'research/q\*\.md' \
    || { echo "design-reviewer body must place 'Citation-verification Read exception' adjacent to research/q*.md scope"; return 1; }
  # #112 PR-1 carve-out: round-NN.diff Read pattern.
  echo "$body" | grep -qF 'Diff-File Read Pattern (#112 PR-1 Mechanism A)' \
    || { echo "design-reviewer body must document the #112 PR-1 diff-file Read pattern"; return 1; }
}
