#!/usr/bin/env bats
#
# T13 Slice-2 pin: assert agents/qrspi-test-writer.md exposes BOTH
# Implement-phase and Test-phase H2 mode sections against the same agent body,
# keys mode selection on task_definition presence, and documents the empty-
# task-definition loud-failure path per T08.

load '../helpers/skill-markdown'

setup() {
  require_repo_root
  AGENT_FILE="$REPO_ROOT/agents/qrspi-test-writer.md"
  export AGENT_FILE
}

@test "test-writer agent file exists" {
  [ -r "$AGENT_FILE" ]
}

@test "test-writer exposes ## Mode: implement-phase (per-task) H2 section" {
  # Direct call: extract_section non-zero return fails the @test block.
  out="$(extract_section "$AGENT_FILE" H2 "Mode: implement-phase (per-task)")"
  [ -n "$out" ]
}

@test "test-writer exposes ## Mode: test-phase (plan-level) H2 section" {
  out="$(extract_section "$AGENT_FILE" H2 "Mode: test-phase (plan-level)")"
  [ -n "$out" ]
}

@test "test-writer implement-phase mode body keys activation on task_definition presence" {
  run assert_section_contains "$AGENT_FILE" H2 "Mode: implement-phase (per-task)" "task_definition.*(present|non-empty)"
  [ "$status" -eq 0 ]
}

@test "test-writer test-phase mode body keys activation on task_definition absence" {
  run assert_section_contains "$AGENT_FILE" H2 "Mode: test-phase (plan-level)" "task_definition.*absent"
  [ "$status" -eq 0 ]
}

@test "test-writer documents the empty-task-definition loud-failure path" {
  # Anchored in the Dispatch Signal Resolution section per T08.
  run assert_section_contains "$AGENT_FILE" H2 "Dispatch Signal Resolution" "empty-task-definition"
  [ "$status" -eq 0 ]
}

@test "test-writer dispatch signal resolution names the present-but-empty invalid path" {
  run assert_section_contains "$AGENT_FILE" H2 "Dispatch Signal Resolution" "present.*but.*empty"
  [ "$status" -eq 0 ]
}

@test "test-writer Purpose section documents the YOU WRITE TESTS, NOT FIX CODE iron law (Implement-phase mode)" {
  # Either section may carry the iron law; scope to implement-phase mode body.
  run assert_section_contains "$AGENT_FILE" H2 "Mode: implement-phase (per-task)" "Do NOT run the tests"
  [ "$status" -eq 0 ]
}

@test "test-writer test-phase mode declares The Iron Law for plan-level test authoring" {
  run assert_section_contains "$AGENT_FILE" H2 "Mode: test-phase (plan-level)" "Iron Law"
  [ "$status" -eq 0 ]
}
