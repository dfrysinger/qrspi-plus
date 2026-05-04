#!/usr/bin/env bats

# Structural CI test: quality reviewers must not contain scope language.
# Also asserts the design-reviewer Read carve-out is correctly bounded.
# Added in commit 5/22 of issue-110 migration.

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
}

@test "quality reviewers carry no OWNS/DEFERS or scope language" {
  for name in goals questions research design structure phasing plan parallelize replan; do
    local body
    body=$(awk '/^---$/{n++; next} n>=2{print}' "agents/qrspi-${name}-reviewer.md")
    echo "$body" | grep -qE 'owns-defers\.md|scope finding|scope review|boundary drift|OWNS / DEFERS' \
      && { echo "qrspi-${name}-reviewer.md contains forbidden scope language"; return 1; }
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
