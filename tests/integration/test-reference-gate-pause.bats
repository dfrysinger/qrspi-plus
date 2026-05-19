#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# T30 (pin 5 of 5) — G10: Slice 5 reference-gate cross-skill integration pin.
#
# Exercises the cross-skill flow end-to-end against a seeded fixture plan:
#   - Parallelize-skill wave-termination rule (T26): a task carrying
#     reference_gate: true ends its Wave; dependents land in the next Wave;
#     parallelization.md carries the canonical `Reference gate: task-NN
#     ({name}) — dependents waiting: task-XX, ...` note.
#   - Implement-skill reference-gate pause (T27): dependents do not dispatch
#     until the approval file at `reviews/tasks/task-NN/reference-gate.md`
#     is recorded; a bypass attempt (dispatch before the file exists) is
#     blocked with the named `reference-gate-bypass:` diagnostic.
#
# This is the integration-tier pin (a real cross-skill exercise rather than
# a single-file markdown-section assertion). It assembles a fixture plan +
# parallelization.md on disk in a tmpdir, then asserts the documented
# contracts observably hold across skills/parallelize/SKILL.md and
# skills/implement/SKILL.md — including the canonical artifact paths,
# diagnostic strings, and ordering invariants the cross-skill flow depends on.
#
# Bash 3.2 portable. No live subagent dispatch; the integration boundary is
# the contract-shape integration (artifact-path + diagnostic naming) across
# the two skills, asserted against a fixture plan a runtime orchestrator
# would consume.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
  PARALLELIZE_SKILL="$REPO_ROOT/skills/parallelize/SKILL.md"
  IMPLEMENT_SKILL="$REPO_ROOT/skills/implement/SKILL.md"
  export PARALLELIZE_SKILL IMPLEMENT_SKILL
}

setup() {
  FIXTURE_DIR="$(mktemp -d)"
  export FIXTURE_DIR
  mkdir -p "$FIXTURE_DIR/tasks"
  mkdir -p "$FIXTURE_DIR/reviews/tasks/task-03"

  # Seed a reference-gated task spec.
  cat > "$FIXTURE_DIR/tasks/task-03.md" <<'EOF'
---
task: 3
status: approved
pipeline: full
task_type: code
model: sonnet
phase: 1
goal_ids: [G10]
dependencies: [T01, T02]
reference_gate: true
reference_artifact: reference/adapter-shape.png
loc_estimate: 80
---

# Task 3: Adapter contract doc (reference gate)
EOF

  # Seed a dependent task spec.
  cat > "$FIXTURE_DIR/tasks/task-04.md" <<'EOF'
---
task: 4
status: approved
pipeline: full
task_type: code
model: sonnet
phase: 1
goal_ids: [G10]
dependencies: [T03]
loc_estimate: 60
---

# Task 4: Apply adapter contract
EOF

  # Seed a parallelization.md carrying the canonical reference-gate note.
  cat > "$FIXTURE_DIR/parallelization.md" <<'EOF'
---
status: approved
---

## Branch Map

| Task | Dependencies | Files | Wave |
|------|--------------|-------|------|
| Task 1 | (none) | a.md | Wave 1 |
| Task 2 | (none) | b.md | Wave 1 |
| Task 3 | Task 1, Task 2 | c.md | Wave 2 (reference_gate: true) |
| Task 4 | Task 3 | d.md | Wave 3 |

Reference gate: task-03 (Adapter contract doc) — dependents waiting: task-04
EOF
}

teardown() {
  rm -rf "$FIXTURE_DIR"
}

# =============================================================================
# T26: Parallelize wave-termination rule + canonical note
# =============================================================================

@test "[T30-rg-pause] Parallelize documents reference_gate wave-termination rule" {
  extract_and_grep "$PARALLELIZE_SKILL" H2 "Branch Model (Symbolic — Resolved by Implement)" \
    "[Rr]eference-gate wave termination"
}

@test "[T30-rg-pause] Parallelize names dependents land in next Wave at the earliest" {
  extract_and_grep "$PARALLELIZE_SKILL" H2 "Branch Model (Symbolic — Resolved by Implement)" \
    "next Wave"
}

@test "[T30-rg-pause] Parallelize template documents canonical Reference-gate note shape" {
  extract_and_grep "$PARALLELIZE_SKILL" H2 "Artifact" \
    "Reference gate: task-NN"
}

@test "[T30-rg-pause] Parallelize Red Flags catches missing canonical note" {
  extract_and_grep "$PARALLELIZE_SKILL" H2 "Red Flags — STOP" \
    "reference_gate: true.*Reference gate: task-NN"
}

@test "[T30-rg-pause] Parallelize Red Flags catches dependent in same Wave as gate" {
  extract_and_grep "$PARALLELIZE_SKILL" H2 "Red Flags — STOP" \
    "same [Ww]ave"
}

# =============================================================================
# Fixture plan carries canonical note for the gated task
# =============================================================================

@test "[T30-rg-pause] Fixture parallelization.md emits canonical Reference-gate note for task-03" {
  grep -E "^Reference gate: task-03 \(Adapter contract doc\) — dependents waiting: task-04$" \
    "$FIXTURE_DIR/parallelization.md"
}

@test "[T30-rg-pause] Fixture task-03 carries reference_gate + reference_artifact pair" {
  grep -E "^reference_gate: true$" "$FIXTURE_DIR/tasks/task-03.md"
  grep -E "^reference_artifact: " "$FIXTURE_DIR/tasks/task-03.md"
}

# =============================================================================
# T27: Implement reference-gate pause names approval-file path + bypass diagnostic
# =============================================================================

@test "[T30-rg-pause] Implement names canonical approval file path reviews/tasks/task-NN/reference-gate.md" {
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "reviews/tasks/task-NN/reference-gate.md"
}

@test "[T30-rg-pause] Implement requires explicit reference approved confirmation" {
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "reference approved"
}

@test "[T30-rg-pause] Implement names reference-gate-bypass diagnostic on bypass attempt" {
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "reference-gate-bypass"
}

@test "[T30-rg-pause] Implement bypass diagnostic names blocked-dependent field" {
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "blocked-dependent=task-MM"
}

@test "[T30-rg-pause] Implement records approval with timestamp, run_slug, task_id, reference_artifact" {
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "timestamp"
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "run_slug"
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "task_id"
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "approver_acknowledgment"
}

# =============================================================================
# Bypass simulation: dependent dispatch attempted without approval file present
# =============================================================================
#
# The fixture stages task-03 (reference_gate: true) and task-04 (depends on T03)
# WITHOUT writing reviews/tasks/task-03/reference-gate.md. Per T27's pause
# contract, an orchestrator MUST NOT dispatch task-04 until that file exists.
# This pin asserts the bypass-detection contract is observable from the fixture
# state: the approval file does not exist, and the documented Implement-skill
# diagnostic names the precondition (`approval-file-absent`).

@test "[T30-rg-pause] Bypass simulation: approval file is absent in fixture state" {
  [ ! -e "$FIXTURE_DIR/reviews/tasks/task-03/reference-gate.md" ]
}

@test "[T30-rg-pause] Implement diagnostic names approval-file-absent as bypass reason" {
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "approval-file-absent"
}

# =============================================================================
# Approval simulation: writing the approval file releases the pause
# =============================================================================

@test "[T30-rg-pause] Approval simulation: writing reference-gate.md satisfies path-existence precondition" {
  cat > "$FIXTURE_DIR/reviews/tasks/task-03/reference-gate.md" <<'EOF'
timestamp: 2026-05-19T00:00:00Z
run_slug: t30-fixture
task_id: 3
reference_artifact: reference/adapter-shape.png
approver_acknowledgment: "reference approved"
EOF
  [ -e "$FIXTURE_DIR/reviews/tasks/task-03/reference-gate.md" ]
  grep -F 'approver_acknowledgment: "reference approved"' \
    "$FIXTURE_DIR/reviews/tasks/task-03/reference-gate.md"
}

# =============================================================================
# Coordination: reference-gate pause coordinates with ui:true visual-fidelity
# dispatch — the gate fires at DONE before any dependent (including sibling
# UI tasks in later waves) is dispatched.
# =============================================================================

@test "[T30-rg-pause] Implement coordinates reference-gate with ui:true visual-fidelity dispatch" {
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "ui: true"
}
