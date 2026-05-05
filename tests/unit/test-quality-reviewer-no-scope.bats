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

@test "8 of 9 quality reviewers do not grant Read in tools frontmatter" {
  for name in goals questions research structure phasing plan parallelize replan; do
    local fm
    fm=$(awk '/^---$/{n++; next} n==1{print}' "agents/qrspi-${name}-reviewer.md")
    echo "$fm" | grep -qE '^tools:.*Read' \
      && { echo "qrspi-${name}-reviewer.md grants Read but should not"; return 1; }
  done
  return 0
}

@test "qrspi-design-reviewer is the single Read carve-out (adjacency + bounded scope)" {
  local fm body
  fm=$(awk '/^---$/{n++; next} n==1{print}' agents/qrspi-design-reviewer.md)
  body=$(awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-design-reviewer.md)
  echo "$fm" | grep -qE '^tools:.*Read' || { echo "design-reviewer must grant Read"; return 1; }
  echo "$body" | grep -B1 -A1 -F 'Citation-verification Read exception' \
    | grep -qE 'research/q\*\.md' \
    || { echo "design-reviewer body must place 'Citation-verification Read exception' adjacent to research/q*.md scope"; return 1; }
  local non_carveout
  non_carveout=$(echo "$body" | grep -v -B2 -A2 -F 'Citation-verification Read exception' || true)
  if echo "$non_carveout" | grep -qE '\bRead\s+(file|tool|the)|\bRead\(.*\)|\bread\s+research/'; then
    echo "design-reviewer body must contain no Read directive outside the carve-out block"
    return 1
  fi
}
