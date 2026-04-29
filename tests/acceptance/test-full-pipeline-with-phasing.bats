#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Acceptance: a single QRSPI run reaches the Phasing step after Design and
# produces phasing.md before Structure runs.
#
# This is a lightweight ordering acceptance test — it exercises the
# pre-tool-use hook end-to-end (mirroring test-pipeline-ordering.bats) to
# confirm the post-M54 pipeline shape:
#
#   Goals → Questions → Research → Design → Phasing → Structure → Plan → ...
#
# Spec (task-05 line 25): "a single QRSPI run reaches the Phasing step after
# Design and produces phasing.md before Structure runs."

setup() {
  export WORK_DIR
  WORK_DIR=$(mktemp -d)
  cd "$WORK_DIR"

  export ARTIFACT_DIR
  ARTIFACT_DIR="$WORK_DIR/docs/qrspi/2026-04-26-fakeproj"
  mkdir -p "$ARTIFACT_DIR/research"

  export HOOK
  HOOK="$(dirname "$BATS_TEST_FILENAME")/../../hooks/pre-tool-use"
}

teardown() {
  rm -rf "$WORK_DIR"
}

# ── Helpers ──────────────────────────────────────────────────────────────────

create_artifact() {
  local path="$1"
  local status="$2"
  mkdir -p "$(dirname "$path")"
  printf -- '---\nstatus: %s\n---\nContent\n' "$status" > "$path"
}

init_state() {
  local artifact_dir="$1"
  local pipeline_lib
  pipeline_lib="$(dirname "$BATS_TEST_FILENAME")/../../hooks/lib/pipeline.sh"
  bash -c "source '$pipeline_lib'; cd '$WORK_DIR'; state_init_or_reconcile '$artifact_dir'"
}

write_json() {
  local file_path="$1"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"new"}}\n' "$file_path"
}

# ── Acceptance: phasing slot is present and ordered between design and structure ──

@test "[AC-phasing] Pipeline reaches Phasing step after Design (write phasing.md allowed when goals+questions+research+design approved)" {
  create_artifact "$ARTIFACT_DIR/goals.md"            "approved"
  create_artifact "$ARTIFACT_DIR/questions.md"        "approved"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact "$ARTIFACT_DIR/design.md"           "approved"
  create_artifact "$ARTIFACT_DIR/phasing.md"          "draft"
  create_artifact "$ARTIFACT_DIR/structure.md"        "draft"
  create_artifact "$ARTIFACT_DIR/plan.md"             "draft"
  init_state "$ARTIFACT_DIR"

  run "$HOOK" <<< "$(write_json "$ARTIFACT_DIR/phasing.md")"
  [ "$status" -eq 0 ]
}

@test "[AC-phasing] Phasing must complete before Structure (write structure.md blocked when phasing draft)" {
  create_artifact "$ARTIFACT_DIR/goals.md"            "approved"
  create_artifact "$ARTIFACT_DIR/questions.md"        "approved"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact "$ARTIFACT_DIR/design.md"           "approved"
  create_artifact "$ARTIFACT_DIR/phasing.md"          "draft"
  create_artifact "$ARTIFACT_DIR/structure.md"        "draft"
  create_artifact "$ARTIFACT_DIR/plan.md"             "draft"
  init_state "$ARTIFACT_DIR"

  run "$HOOK" <<< "$(write_json "$ARTIFACT_DIR/structure.md")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"phasing"* ]]
}

@test "[AC-phasing] Phasing cannot run before Design (write phasing.md blocked when design draft)" {
  create_artifact "$ARTIFACT_DIR/goals.md"            "approved"
  create_artifact "$ARTIFACT_DIR/questions.md"        "approved"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact "$ARTIFACT_DIR/design.md"           "draft"
  create_artifact "$ARTIFACT_DIR/phasing.md"          "draft"
  create_artifact "$ARTIFACT_DIR/structure.md"        "draft"
  create_artifact "$ARTIFACT_DIR/plan.md"             "draft"
  init_state "$ARTIFACT_DIR"

  run "$HOOK" <<< "$(write_json "$ARTIFACT_DIR/phasing.md")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"design"* ]]
}

@test "[AC-phasing] Full approved sequence reaches Structure only after Phasing approved" {
  create_artifact "$ARTIFACT_DIR/goals.md"            "approved"
  create_artifact "$ARTIFACT_DIR/questions.md"        "approved"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact "$ARTIFACT_DIR/design.md"           "approved"
  create_artifact "$ARTIFACT_DIR/phasing.md"          "approved"
  create_artifact "$ARTIFACT_DIR/structure.md"        "draft"
  create_artifact "$ARTIFACT_DIR/plan.md"             "draft"
  init_state "$ARTIFACT_DIR"

  run "$HOOK" <<< "$(write_json "$ARTIFACT_DIR/structure.md")"
  [ "$status" -eq 0 ]
}

@test "[AC-phasing] phasing/SKILL.md exists at canonical path (skill registered)" {
  local skill_file
  skill_file="$(dirname "$BATS_TEST_FILENAME")/../../skills/phasing/SKILL.md"
  [ -f "$skill_file" ]
}
