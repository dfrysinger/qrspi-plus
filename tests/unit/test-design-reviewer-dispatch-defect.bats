#!/usr/bin/env bats
#
# Task 17c: Design reviewer dispatch-defect contract pin.
#
# Asserts the T16-installed dispatch-defect contract clause in
# agents/qrspi-design-reviewer.md fires on real findings:
#
#   - A Design-step dispatch with `absorption_map_path:` absent halts the
#     design reviewer with a `dispatch-defect:` named diagnostic and a
#     non-zero exit (silent-claude F01 dispatch-defect fail-loud direction).
#   - A goals/research/phasing/structure/parallelize-step dispatch with
#     `absorption_map_path:` absent proceeds normally (no false positive
#     for steps where the parameter has no applicable role).
#
# The "synthetic-dispatch" fixture is the agent body itself: the reviewer is
# an LLM agent whose halt-on-defect contract is encoded as prose under the
# § Design-specific quality checks H3 (R3 anchor location — see T16 R3
# relocation, commit c77ef69). The pin verifies the verbatim clauses T16
# installed; T16 carries cross_task_consumers pass-through disposition for
# this fixture.

load '../helpers/skill-markdown'

setup() {
  require_repo_root
  AGENT="$REPO_ROOT/agents/qrspi-design-reviewer.md"
  export AGENT
}

# Test expectation: A Design-step dispatch with `absorption_map_path:` absent
# halts the design reviewer with a `dispatch-defect:` named diagnostic and
# non-zero exit (silent-claude F01 dispatch-defect fail-loud direction).

@test "design reviewer agent file exists and is readable" {
  [ -r "$AGENT" ]
}

@test "dispatch-defect contract clause lives in § Design-specific quality checks (R3 anchor)" {
  run assert_section_contains "$AGENT" H3 \
    "Design-specific quality checks" \
    "[Dd]ispatch-defect contract"
  [ "$status" -eq 0 ]
}

@test "design-step clause names absent absorption_map_path: as the dispatch defect" {
  run assert_section_contains "$AGENT" H3 \
    "Design-specific quality checks" \
    "absorption_map_path:.*absent|absent.*absorption_map_path"
  [ "$status" -eq 0 ]
}

@test "design-step clause names the Design step as the mandatory site" {
  run assert_section_contains "$AGENT" H3 \
    "Design-specific quality checks" \
    "[Dd]esign step.*mandatory|mandatory.*[Dd]esign step|At the Design step.*mandatory"
  [ "$status" -eq 0 ]
}

@test "design-step clause names the dispatch-defect: diagnostic verbatim" {
  run assert_section_contains "$AGENT" H3 \
    "Design-specific quality checks" \
    "dispatch-defect: absorption_map_path absent at design step"
  [ "$status" -eq 0 ]
}

@test "design-step clause names the halt + non-zero-exit fail-loud direction" {
  run assert_section_contains "$AGENT" H3 \
    "Design-specific quality checks" \
    "halt.*non-zero|non-zero.*halt|exit non-zero|exits non-zero"
  [ "$status" -eq 0 ]
}

@test "design-step clause forbids silent no-op (silent-claude F01 fail-loud direction)" {
  run assert_section_contains "$AGENT" H3 \
    "Design-specific quality checks" \
    "silently no-op|silent.*no-op|Do NOT proceed without the map"
  [ "$status" -eq 0 ]
}

# Test expectation: A goals/research/phasing/structure/parallelize-step
# dispatch with `absorption_map_path:` absent proceeds normally (no false
# positive for steps where the parameter has no applicable role).

@test "clause restricts mandate to exactly Plan and Design (no false positive elsewhere)" {
  run assert_section_contains "$AGENT" H3 \
    "Design-specific quality checks" \
    "mandatory at exactly two steps.*Plan and Design|Plan and Design.*mandatory at exactly two"
  [ "$status" -eq 0 ]
}

@test "clause names goals/research/phasing/structure/parallelize as the optional-parameter steps" {
  run assert_section_contains "$AGENT" H3 \
    "Design-specific quality checks" \
    "goals.*research.*phasing.*structure.*parallelize"
  [ "$status" -eq 0 ]
}

@test "clause justifies optionality (no applicable role at non-Plan/Design steps)" {
  run assert_section_contains "$AGENT" H3 \
    "Design-specific quality checks" \
    "no applicable role|has no applicable role"
  [ "$status" -eq 0 ]
}
