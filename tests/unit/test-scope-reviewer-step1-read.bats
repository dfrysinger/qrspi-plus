#!/usr/bin/env bats

# Structural CI test: each scope-reviewer body must reference its concrete owns-defers.md path.
# Added in commit 5/22 of issue-110 migration. If the Step-1 Read is unreliable,
# commit 6 replaces this test with test-scope-reviewer-inline-owns-defers.bats.

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
}

@test "each scope-reviewer body Reads its concrete owns-defers.md path" {
  for name in goals design structure phasing plan parallelize replan; do
    local body
    body=$(awk '/^---$/{n++; next} n>=2{print}' "agents/qrspi-${name}-scope-reviewer.md")
    echo "$body" | grep -qF "skills/${name}/owns-defers.md" \
      || { echo "qrspi-${name}-scope-reviewer.md does not Read skills/${name}/owns-defers.md"; return 1; }
  done
}
