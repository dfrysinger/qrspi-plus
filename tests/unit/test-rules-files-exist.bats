#!/usr/bin/env bats

# Cross-cutting CI test: verifies the new architecture's load-bearing files
# (reviewer-protocol skill + per-skill owns-defers files) are present where
# the spec requires, and absent where it requires absence.
# Added in commit 22/22 of issue-110 migration.

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
}

@test "skills/reviewer-protocol/SKILL.md is present" {
  [[ -f skills/reviewer-protocol/SKILL.md ]]
}

@test "each scope-reviewed skill has a non-empty owns-defers.md" {
  local names=(goals design structure phasing plan parallelize replan)
  for name in "${names[@]}"; do
    [[ -s "skills/${name}/owns-defers.md" ]] \
      || { echo "missing or empty skills/${name}/owns-defers.md"; return 1; }
  done
}

@test "questions and research have NO owns-defers.md (no scope review for these phases)" {
  ! [[ -e skills/questions/owns-defers.md ]]
  ! [[ -e skills/research/owns-defers.md ]]
}
