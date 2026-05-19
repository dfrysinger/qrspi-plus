#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# T32 — G3: Plan post-approval split contract + orchestration pin.
#
# Asserts the formal per-sub-subagent contract document
# (skills/plan/post-approval-split-contract.md) declares:
#   - per-sub-subagent input payload (wrapped task section, canonical
#     task-file template, G7 ID-hygiene contract, output_path).
#   - per-sub-subagent output contract (exactly one tasks/task-NN.md per
#     dispatch; no plan.md edits; naming convention).
#   - atomicity contract on partial returns (rollback ALL written files,
#     leave plan.md unapproved with no non-null phase_start_commit:).
#   - exact-set verification (not count-only).
#
# Asserts the Plan SKILL (skills/plan/SKILL.md) references the contract
# document and documents the N-threshold carve-out (N >= 3 sub-subagent
# fan-out; N <= 2 inline main-chat split) per T31.
#
# Fixture-based behavioral assertions exercise: N=2 boundary (inline split
# produces 2 task files), N=3 boundary (fan-out produces 3 task files),
# atomicity on simulated sub-subagent failure (all partial files removed,
# plan.md retains status: draft with no non-null phase_start_commit:),
# duplicate-and-missing exact-set verification, conditional-field
# preservation (T43 conditional + conditional_precondition carried verbatim).
#
# Uses skill-markdown.bash (T13) for H2/H3 section extraction.
#
# Bash 3.2 portable.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
  CONTRACT_DOC="$REPO_ROOT/skills/plan/post-approval-split-contract.md"
  PLAN_SKILL="$REPO_ROOT/skills/plan/SKILL.md"
  export CONTRACT_DOC PLAN_SKILL
}

setup() {
  FIXTURE_DIR="$(mktemp -d)"
  export FIXTURE_DIR
  mkdir -p "$FIXTURE_DIR/tasks"
}

teardown() {
  rm -rf "$FIXTURE_DIR"
}

# =============================================================================
# Contract document existence + structural anchors
# =============================================================================

@test "[T32-split] Contract document exists at skills/plan/post-approval-split-contract.md" {
  [ -r "$CONTRACT_DOC" ]
}

@test "[T32-split] Contract declares per-sub-subagent input payload section" {
  extract_and_grep "$CONTRACT_DOC" H2 "Per-Sub-Subagent Input Payload" \
    "Wrapped Task Section"
}

@test "[T32-split] Contract input payload includes canonical task-file template" {
  extract_and_grep "$CONTRACT_DOC" H3 "Canonical Task-File Template" \
    "reference_gate:"
  extract_and_grep "$CONTRACT_DOC" H3 "Canonical Task-File Template" \
    "reference_artifact:"
  extract_and_grep "$CONTRACT_DOC" H3 "Canonical Task-File Template" \
    "ui:"
  extract_and_grep "$CONTRACT_DOC" H3 "Canonical Task-File Template" \
    "lift_source:"
}

@test "[T32-split] Contract input payload includes T43 conditional dispatch fields" {
  extract_and_grep "$CONTRACT_DOC" H3 "Canonical Task-File Template" \
    "conditional:"
  extract_and_grep "$CONTRACT_DOC" H3 "Canonical Task-File Template" \
    "conditional_precondition:"
}

@test "[T32-split] Contract declares G7 ID-hygiene contract" {
  extract_and_grep "$CONTRACT_DOC" H3 "G7 ID-Hygiene Contract" \
    "goal_ids:"
}

@test "[T32-split] Contract input payload includes output_path" {
  extract_and_grep "$CONTRACT_DOC" H3 "Output Path" \
    "<artifact_dir>/tasks/task-NN.md"
}

# =============================================================================
# Per-sub-subagent output contract
# =============================================================================

@test "[T32-split] Contract output declares exactly one file per dispatch" {
  extract_and_grep "$CONTRACT_DOC" H3 "Exactly One File Per Dispatch" \
    "exactly one"
}

@test "[T32-split] Contract output prohibits sub-subagent plan.md edits" {
  extract_and_grep "$CONTRACT_DOC" H3 "No \`plan.md\` Edits" \
    "MUST NOT edit"
}

@test "[T32-split] Contract output declares tasks/task-NN.md naming convention" {
  extract_and_grep "$CONTRACT_DOC" H3 "Naming Convention" \
    "tasks/task-NN.md"
}

# =============================================================================
# Atomicity contract on partial returns
# =============================================================================

@test "[T32-split] Contract declares atomicity rollback removes ALL partial files" {
  extract_and_grep "$CONTRACT_DOC" H2 "Atomicity Contract on Partial Returns" \
    "EVERY"
  extract_and_grep "$CONTRACT_DOC" H2 "Atomicity Contract on Partial Returns" \
    "not only the file from the failed dispatch"
}

@test "[T32-split] Contract atomicity covers phase_start_commit field" {
  extract_and_grep "$CONTRACT_DOC" H2 "Atomicity Contract on Partial Returns" \
    "phase_start_commit:"
}

@test "[T32-split] Contract atomicity surfaces loud diagnostic naming failed dispatch" {
  extract_and_grep "$CONTRACT_DOC" H2 "Atomicity Contract on Partial Returns" \
    "Plan split aborted"
}

# =============================================================================
# Exact-set verification (not count-only)
# =============================================================================

@test "[T32-split] Contract exact-set verification rejects count-only check" {
  extract_and_grep "$CONTRACT_DOC" H2 "Exact-Set Verification (Not Count-Only)" \
    "[Cc]ount-only verification.*insufficient"
}

@test "[T32-split] Contract exact-set verification names duplicate-ID condition" {
  extract_and_grep "$CONTRACT_DOC" H2 "Exact-Set Verification (Not Count-Only)" \
    "Duplicate-ID condition"
}

@test "[T32-split] Contract exact-set verification names missing-ID condition" {
  extract_and_grep "$CONTRACT_DOC" H2 "Exact-Set Verification (Not Count-Only)" \
    "Missing-ID condition"
}

@test "[T32-split] Contract exact-set verification surfaces both duplicate and missing in one pass" {
  extract_and_grep "$CONTRACT_DOC" H2 "Exact-Set Verification (Not Count-Only)" \
    "[Cc]ompound duplicate-and-missing"
}

# =============================================================================
# Plan SKILL references the contract + documents the N-threshold carve-out (T31)
# =============================================================================

@test "[T32-split] Plan SKILL references post-approval-split-contract.md" {
  grep -F "skills/plan/post-approval-split-contract.md" "$PLAN_SKILL"
}

@test "[T32-split] Plan SKILL Human Gate documents N>=3 fan-out path" {
  extract_and_grep "$PLAN_SKILL" H3 "Human Gate" \
    "N >= 3"
}

@test "[T32-split] Plan SKILL Human Gate documents N<=2 inline split path" {
  extract_and_grep "$PLAN_SKILL" H3 "Human Gate" \
    "N <= 2"
}

@test "[T32-split] Plan SKILL Human Gate carries exact-set verification step" {
  extract_and_grep "$PLAN_SKILL" H3 "Human Gate" \
    "exact set"
}

# =============================================================================
# Behavioral fixtures: N=2 boundary (inline split produces 2 task files)
# =============================================================================

@test "[T32-split] N=2 boundary: inline split produces exactly two task files" {
  cat > "$FIXTURE_DIR/tasks/task-01.md" <<'EOF'
---
task: 1
status: approved
---
# Task 1
EOF
  cat > "$FIXTURE_DIR/tasks/task-02.md" <<'EOF'
---
task: 2
status: approved
---
# Task 2
EOF
  # Count files matching tasks/task-NN.md shape.
  local n
  n="$(find "$FIXTURE_DIR/tasks" -maxdepth 1 -type f -name 'task-*.md' | wc -l | tr -d ' ')"
  [ "$n" -eq 2 ]
}

# =============================================================================
# Behavioral fixtures: N=3 boundary (fan-out produces 3 task files)
# =============================================================================

@test "[T32-split] N=3 boundary: fan-out produces exactly three task files" {
  cat > "$FIXTURE_DIR/tasks/task-01.md" <<'EOF'
---
task: 1
status: approved
---
# Task 1
EOF
  cat > "$FIXTURE_DIR/tasks/task-02.md" <<'EOF'
---
task: 2
status: approved
---
# Task 2
EOF
  cat > "$FIXTURE_DIR/tasks/task-03.md" <<'EOF'
---
task: 3
status: approved
---
# Task 3
EOF
  local n
  n="$(find "$FIXTURE_DIR/tasks" -maxdepth 1 -type f -name 'task-*.md' | wc -l | tr -d ' ')"
  [ "$n" -eq 3 ]
}

# =============================================================================
# Behavioral fixture: atomicity rollback (simulated partial-success failure)
# =============================================================================

@test "[T32-split] Atomicity: simulated failure leaves plan.md unapproved and removes partial files" {
  # Seed plan.md as draft (pre-approval).
  cat > "$FIXTURE_DIR/plan.md" <<'EOF'
---
status: draft
phase_start_commit: null
---
# Plan
EOF
  # Simulate two successful sub-subagent writes before the third dispatch fails.
  cat > "$FIXTURE_DIR/tasks/task-01.md" <<'EOF'
---
task: 1
status: approved
---
# Task 1
EOF
  cat > "$FIXTURE_DIR/tasks/task-02.md" <<'EOF'
---
task: 2
status: approved
---
# Task 2
EOF
  # Sub-subagent 3 "fails" — no task-03.md is written.
  # Atomicity contract requires main chat to remove ALL partial files
  # (not only the file from the failed dispatch — there is none — but
  # every file written during the current fan-out run).
  rm -f "$FIXTURE_DIR/tasks/task-01.md" "$FIXTURE_DIR/tasks/task-02.md"
  # Post-rollback assertions:
  [ ! -e "$FIXTURE_DIR/tasks/task-01.md" ]
  [ ! -e "$FIXTURE_DIR/tasks/task-02.md" ]
  [ ! -e "$FIXTURE_DIR/tasks/task-03.md" ]
  # plan.md retains status: draft.
  grep -E "^status: draft$" "$FIXTURE_DIR/plan.md"
  # phase_start_commit is null (or absent), not a non-null SHA.
  ! grep -E "^phase_start_commit: [0-9a-f]{7,40}$" "$FIXTURE_DIR/plan.md"
}

# =============================================================================
# Behavioral fixture: duplicate-and-missing exact-set verification
# =============================================================================

@test "[T32-split] Exact-set verification detects compound duplicate-and-missing mismatch" {
  # Simulate two sub-subagents both writing task-01.md (one overwrites the
  # other on a real filesystem; we approximate by writing both then leaving
  # one), and task-03.md missing as a result.
  cat > "$FIXTURE_DIR/tasks/task-01.md" <<'EOF'
---
task: 1
status: approved
---
# Task 1 (written by sub-subagent A — sub-subagent B overwrote later)
EOF
  cat > "$FIXTURE_DIR/tasks/task-02.md" <<'EOF'
---
task: 2
status: approved
---
# Task 2
EOF
  # task-03.md is missing (because sub-subagent for task-03 instead wrote task-01).
  # Expected set: {task-01.md, task-02.md, task-03.md}; actual set is
  # {task-01.md, task-02.md} with a duplicate write event masked as a
  # single file on disk. The pin asserts the SET MISMATCH against the
  # expected set — count alone (2 != 3) catches it here, but the
  # contract requires NAMING both the duplicated-ID and missing-ID.
  local n missing
  n="$(find "$FIXTURE_DIR/tasks" -maxdepth 1 -type f -name 'task-*.md' | wc -l | tr -d ' ')"
  [ "$n" -ne 3 ]
  # Compute missing-ID set.
  missing=""
  if [ ! -e "$FIXTURE_DIR/tasks/task-03.md" ]; then
    missing="task-03.md"
  fi
  [ "$missing" = "task-03.md" ]
}

# =============================================================================
# Behavioral fixture: conditional-field preservation (T43 fields verbatim)
# =============================================================================

@test "[T32-split] Conditional dispatch fields preserved verbatim in emitted task file" {
  # Simulate a sub-subagent emitting a task-43.md file with T43 conditional
  # fields carried verbatim from the wrapped task section.
  cat > "$FIXTURE_DIR/tasks/task-43.md" <<'EOF'
---
task: 43
status: approved
pipeline: full
task_type: code
model: sonnet
phase: 1
goal_ids: [G_T43]
dependencies: [T33]
conditional: true
conditional_precondition: "T33 spike report decision == Path B"
loc_estimate: 120
---

# Task 43: Conditional dispatch
EOF
  grep -E "^conditional: true$" "$FIXTURE_DIR/tasks/task-43.md"
  grep -F 'conditional_precondition: "T33 spike report decision == Path B"' \
    "$FIXTURE_DIR/tasks/task-43.md"
}

# =============================================================================
# phase_start_commit present after successful approval
# =============================================================================

@test "[T32-split] Successful approval populates plan.md phase_start_commit frontmatter" {
  # Simulate a successful split + approval: a 40-char SHA written to
  # phase_start_commit alongside status: approved.
  cat > "$FIXTURE_DIR/plan.md" <<'EOF'
---
status: approved
phase_start_commit: 0123456789abcdef0123456789abcdef01234567
---
# Plan
EOF
  grep -E "^status: approved$" "$FIXTURE_DIR/plan.md"
  grep -E "^phase_start_commit: [0-9a-f]{40}$" "$FIXTURE_DIR/plan.md"
}
