#!/usr/bin/env bats
#
# T13 Slice-2 pin: TDD dispatch-order contract per T12.
#
# Asserts skills/plan/SKILL.md § Per-Task Classification documents:
#   - task_type: code → test-writer-then-implementer order (TDD path),
#     with the RED-verification gate between them.
#   - Absent task_type → defaults to the same TDD path (test-writer first).
#   - task_type: lightweight → lightweight-only dispatch (no test-writer, no
#     RED gate).
#
# Also asserts skills/implement/SKILL.md § Per-Implementer Test-Writer Dispatch
# encodes the same dispatch order on the orchestrator side.

load '../helpers/skill-markdown'

setup() {
  require_repo_root
  PLAN_SKILL="$REPO_ROOT/skills/plan/SKILL.md"
  IMPL_SKILL="$REPO_ROOT/skills/implement/SKILL.md"
  export PLAN_SKILL IMPL_SKILL
}

@test "plan skill exposes ## Per-Task Classification H3 section" {
  out="$(extract_section "$PLAN_SKILL" H3 "Per-Task Classification (\`task_type\` and \`model\`)")"
  [ -n "$out" ]
}

@test "plan: task_type: code produces test-writer-then-implementer order" {
  run assert_section_contains "$PLAN_SKILL" H3 \
    "Per-Task Classification (\`task_type\` and \`model\`)" \
    "task_type: code.*test-writer dispatches first|test-writer.*then.*implementer"
  [ "$status" -eq 0 ]
}

@test "plan: explicit Dispatch order line documents test-writer → RED gate → implementer" {
  run assert_section_contains "$PLAN_SKILL" H3 \
    "Per-Task Classification (\`task_type\` and \`model\`)" \
    "Dispatch order: test-writer.*RED.*implementer"
  [ "$status" -eq 0 ]
}

@test "plan: absent task_type defaults to the TDD path" {
  run assert_section_contains "$PLAN_SKILL" H3 \
    "Per-Task Classification (\`task_type\` and \`model\`)" \
    "Absent.*task_type.*defaults to the TDD path"
  [ "$status" -eq 0 ]
}

@test "plan: task_type: lightweight produces lightweight-only dispatch (no test-writer, no RED gate)" {
  run assert_section_contains "$PLAN_SKILL" H3 \
    "Per-Task Classification (\`task_type\` and \`model\`)" \
    "task_type: lightweight.*lightweight-only dispatch.*no test-writer.*no RED gate"
  [ "$status" -eq 0 ]
}

@test "plan: lightweight dispatch order is implementer only" {
  run assert_section_contains "$PLAN_SKILL" H3 \
    "Per-Task Classification (\`task_type\` and \`model\`)" \
    "Dispatch order: implementer only"
  [ "$status" -eq 0 ]
}

@test "plan: per-task TDD specs MUST carry an explicit dispatch-ordering note" {
  run assert_section_contains "$PLAN_SKILL" H3 \
    "Per-Task Classification (\`task_type\` and \`model\`)" \
    "must carry an explicit dispatch-ordering note"
  [ "$status" -eq 0 ]
}

@test "implement skill: pre-implementer test-writer dispatch fires for task_type: code OR absent task_type" {
  run assert_section_contains "$IMPL_SKILL" H3 \
    "Pre-Implementer Test-Writer Dispatch + RED-Verification Gate" \
    "task_type: code.*absent.*task_type|TDD tasks"
  [ "$status" -eq 0 ]
}

@test "implement skill: lightweight bypasses both the test-writer dispatch and the RED-verification gate" {
  run assert_section_contains "$IMPL_SKILL" H3 \
    "Pre-Implementer Test-Writer Dispatch + RED-Verification Gate" \
    "task_type: lightweight.*skips both the test-writer dispatch and the RED-verification gate"
  [ "$status" -eq 0 ]
}

@test "implement skill: behavioral observability — test-writer entry before implementer entry on proceed path" {
  run assert_section_contains "$IMPL_SKILL" H3 \
    "Pre-Implementer Test-Writer Dispatch + RED-Verification Gate" \
    "test-writer entry before implementer entry"
  [ "$status" -eq 0 ]
}
