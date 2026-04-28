#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Acceptance tests for Phase 4 Hardening — Meta and regression goals.
#
# Covers:
#   SC5 — Test suite regression gate: existing pipeline functionality continues
#         to work after Phase 4 changes. Verified by confirming unit test suite
#         baseline is intact (complements AC8 tests which track exact counts).
#   SC6 — Friction log: manually verified (observations now captured in
#         future-goals.md Ideas section; artifact dir is in a separate repo).
#
# SC5 is primarily covered by AC8 (test-meta.bats), which tracks the exact
# unit test baseline (287 tests, 12 files). These SC5 tests verify that
# Phase 4 hook changes do not break end-to-end pipeline smoke paths.

setup() {
  export WORK_DIR
  WORK_DIR=$(mktemp -d)
  cd "$WORK_DIR"
  # Post-F-1: state.json lives at <artifact_dir>/.qrspi/state.json. Hook
  # resolves artifact_dir target-based via docs/qrspi/*-{slug}/ glob.
  export ARTIFACT_DIR="$WORK_DIR/docs/qrspi/2026-04-26-test"
  mkdir -p "$ARTIFACT_DIR/tasks"
  mkdir -p "$ARTIFACT_DIR/.qrspi"

  export PRE_HOOK
  PRE_HOOK="$(dirname "$BATS_TEST_FILENAME")/../../hooks/pre-tool-use"
  export POST_HOOK
  POST_HOOK="$(dirname "$BATS_TEST_FILENAME")/../../hooks/post-tool-use"
}

teardown() {
  cd /
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
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}\n' "$file_path"
}

# ── SC5: Pipeline regression smoke tests ─────────────────────────────────────
# Criterion: All existing pipeline functionality continues to work after Phase 4
# changes, verified by the existing test suite passing with zero new failures.
# These tests verify end-to-end smoke paths that represent the core pipeline invariants.

# SC5 — Goals write (first step) always allowed — no prerequisites broken
@test "[SC5] Goals write always allowed after Phase 4 changes (no prerequisites regression)" {
  # AC: Phase 4 must not introduce regressions that block goals writes
  create_artifact "$ARTIFACT_DIR/goals.md"            "draft"
  create_artifact "$ARTIFACT_DIR/questions.md"        "draft"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "draft"
  create_artifact "$ARTIFACT_DIR/design.md"           "draft"
  create_artifact "$ARTIFACT_DIR/structure.md"        "draft"
  create_artifact "$ARTIFACT_DIR/plan.md"             "draft"
  init_state "$ARTIFACT_DIR"

  run "$PRE_HOOK" <<< "$(write_json "$ARTIFACT_DIR/goals.md")"
  [ "$status" -eq 0 ]
}

# SC5 — Full-pipeline approved state allows plan write (end-to-end ordering smoke test)
@test "[SC5] All-approved pipeline allows plan.md write after Phase 4 changes" {
  # AC: the ordering check still works correctly in the happy path after Phase 4
  create_artifact "$ARTIFACT_DIR/goals.md"            "approved"
  create_artifact "$ARTIFACT_DIR/questions.md"        "approved"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "approved"
  create_artifact "$ARTIFACT_DIR/design.md"           "approved"
  create_artifact "$ARTIFACT_DIR/structure.md"        "approved"
  create_artifact "$ARTIFACT_DIR/plan.md"             "draft"
  init_state "$ARTIFACT_DIR"

  run "$PRE_HOOK" <<< "$(write_json "$ARTIFACT_DIR/plan.md")"
  [ "$status" -eq 0 ]
}

# SC5 — Ordering block still works: design write blocked when goals draft
@test "[SC5] Pipeline ordering block still works after Phase 4 changes (goals draft blocks design write)" {
  # AC: the ordering enforcement must not have been accidentally bypassed by Phase 4 changes
  create_artifact "$ARTIFACT_DIR/goals.md"            "draft"
  create_artifact "$ARTIFACT_DIR/questions.md"        "draft"
  create_artifact "$ARTIFACT_DIR/research/summary.md" "draft"
  create_artifact "$ARTIFACT_DIR/design.md"           "draft"
  create_artifact "$ARTIFACT_DIR/structure.md"        "draft"
  create_artifact "$ARTIFACT_DIR/plan.md"             "draft"
  init_state "$ARTIFACT_DIR"

  run "$PRE_HOOK" <<< "$(write_json "$ARTIFACT_DIR/design.md")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"goals"* ]]
}

# SC5 — Non-artifact writes still allowed (no regression on pass-through)
@test "[SC5] Non-artifact writes are still always allowed after Phase 4 changes" {
  # AC: Phase 4 changes must not accidentally block writes to non-artifact files
  run "$PRE_HOOK" <<< '{"tool_name":"Write","tool_input":{"file_path":"/tmp/sc5-smoke-test.sh","content":"x"}}'
  [ "$status" -eq 0 ]
}

# SC5 — post-tool-use still exits 0 (non-blocking post hook not broken)
@test "[SC5] post-tool-use exits 0 after Phase 4 changes (non-blocking invariant)" {
  # AC: post-tool-use must never block pipeline; Phase 4 must not break this
  run "$POST_HOOK" <<< '{"tool_name":"Write","tool_input":{"file_path":"/tmp/file.sh","content":"x"}}'
  [ "$status" -eq 0 ]
}

# SC5 — Asymmetric subagent target wall blocks writes outside .worktrees/
@test "[SC5] Asymmetric subagent target wall blocks writes outside .worktrees/" {
  # AC: pre-tool-use hook (post 2026-04-26 implement-runtime-fix) enforces target-based
  # subagent containment. Subagents may only write inside .worktrees/{slug}/(task-NN|baseline)/.
  # Replaces the dropped strict-mode allowlist enforcement.
  local target="$WORK_DIR/src/foo.ts"
  mkdir -p "$WORK_DIR/src"
  local envelope
  envelope=$(jq -cn --arg p "$target" '{agent_id:"sub-1",tool_name:"Edit",tool_input:{file_path:$p}}')

  run "$PRE_HOOK" <<< "$envelope"
  [ "$status" -eq 2 ]
  [ "$(echo "${lines[-1]}" | jq -r '.decision')" = "block" ]
}

# SC5 — Unit test file count has not regressed (Phase 4 must not delete unit tests)
@test "[SC5] Unit test suite has expected .bats files after 2026-04-26 implement-runtime-fix" {
  # AC: Phase 4 changes must not silently delete unit test files.
  # Net delta: +test-agent.bats (added Task 2), -test-enforcement.bats (deleted Task 11
  # along with the dead enforcement.sh library). Original 12 → 12 unchanged net.
  local unit_dir
  unit_dir="$(dirname "$BATS_TEST_DIRNAME")/unit"
  local count
  count=$(find "$unit_dir" -maxdepth 1 -name "*.bats" -type f | wc -l | tr -d ' ')
  [ "$count" -eq 12 ]
}

# SC5 — Unit test count has not regressed unexpectedly
@test "[SC5] Unit test suite has at least 280 @test definitions (no major regression)" {
  # AC: Phase 4 must not accidentally drop large numbers of unit tests.
  # Baseline lowered from 287 → 280 after 2026-04-26 implement-runtime-fix removed
  # test-enforcement.bats (the entire allowlist mechanism it tested no longer exists).
  local unit_dir
  unit_dir="$(dirname "$BATS_TEST_DIRNAME")/unit"
  local count
  count=$(grep -r "^@test" "$unit_dir" --include="*.bats" | wc -l | tr -d ' ')
  [ "$count" -ge 280 ]
}

# SC5 — All hook library files still present (no accidental deletion)
@test "[SC5] All expected hooks/lib/ files still exist after Phase 4 changes" {
  # AC: Phase 4 may rename or add files but must not delete required library files
  local hooks_lib
  hooks_lib="$(dirname "$BATS_TEST_FILENAME")/../../hooks/lib"

  local expected_files=(
    "agent.sh"
    "artifact-map.sh"
    "artifact.sh"
    "audit.sh"
    "bash-detect.sh"
    "frontmatter.sh"
    "pipeline.sh"
    "protected.sh"
    "state.sh"
    "task.sh"
    "worktree.sh"
  )

  for f in "${expected_files[@]}"; do
    [ -f "$hooks_lib/$f" ]
  done
}

# SC5 — All skill SKILL.md files still present after Phase 4 changes
@test "[SC5] All expected skill SKILL.md files still exist after Phase 4 changes" {
  # AC: Phase 4 prompt improvements must not accidentally delete skill files
  local skills_dir
  skills_dir="$(dirname "$BATS_TEST_FILENAME")/../../skills"

  local expected_skills=(
    "goals"
    "questions"
    "research"
    "design"
    "structure"
    "plan"
    "parallelize"
    "implement"
    "integrate"
    "test"
    "replan"
    "using-qrspi"
  )

  for skill in "${expected_skills[@]}"; do
    [ -f "$skills_dir/$skill/SKILL.md" ]
  done
}

# ── SC6: Friction log ─────────────────────────────────────────────────────────
# SC6 is verified manually. The friction log mechanism has been superseded by
# the Ideas section in future-goals.md (observations are captured there now).
# No automated tests — the artifact directory is in a separate repo with a
# machine-specific absolute path.
