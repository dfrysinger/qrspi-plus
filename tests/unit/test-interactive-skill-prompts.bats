#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# #118 / #115 Interactive-skill UX bundle — defends the prose anchors in the
# collaborative-skill preambles (auto-mode detection in goals + design) and
# the per-researcher dispatch contract pins (direct-write + summary-last
# authoring order in research). Cheap grep guards; catch accidental deletion
# during future SKILL.md edits.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  export REPO_ROOT
}

@test "goals/SKILL.md carries the auto-mode detection paragraph" {
  grep -F "Auto Mode Active" "$REPO_ROOT/skills/goals/SKILL.md"
}

@test "design/SKILL.md carries the auto-mode detection paragraph" {
  grep -F "Auto Mode Active" "$REPO_ROOT/skills/design/SKILL.md"
}

@test "research/SKILL.md carries the direct-write and summary-last contract pins" {
  grep -F "Direct-write contract" "$REPO_ROOT/skills/research/SKILL.md"
  grep -F "Summary-last authoring order" "$REPO_ROOT/skills/research/SKILL.md"
}
