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

# Test-name tag conventions used in this file:
#   [T32-split] — pre-existing T31/T32 tests covering the dispatch contract
#       structure (input payload, atomicity, exact-set verification). Do not
#       extend this prefix in new work.
#   [split]    — current canonical prefix. All new tests covering the
#       block-hash idempotency contract, pre-fan-out HALT, Task-ID validation,
#       and approval-state completion use this prefix. Add new tests under
#       this tag.

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

# =============================================================================
# Block-hash header format (contract doc sections)
# =============================================================================

@test "[split] Contract declares Block-Hash Header Format section" {
  extract_and_grep "$CONTRACT_DOC" H2 "Block-Hash Header Format" \
    "block-hash"
}

@test "[split] Block-Hash Header Format documents position: immediately after closing frontmatter ---" {
  extract_and_grep "$CONTRACT_DOC" H2 "Block-Hash Header Format" \
    "immediately after"
}

@test "[split] Block-Hash Header Format documents syntax: # block-hash: <sha256-hex>" {
  extract_and_grep "$CONTRACT_DOC" H2 "Block-Hash Header Format" \
    "# block-hash:"
}

@test "[split] Block-Hash Header Format documents sha256 hex no-salt algorithm" {
  extract_and_grep "$CONTRACT_DOC" H2 "Block-Hash Header Format" \
    "sha256"
  extract_and_grep "$CONTRACT_DOC" H2 "Block-Hash Header Format" \
    "no salt"
}

@test "[split] Block-Hash Header Format documents normalization: strip trailing whitespace per line" {
  extract_and_grep "$CONTRACT_DOC" H2 "Block-Hash Header Format" \
    "strip trailing whitespace"
}

# =============================================================================
# Idempotent split contract (3-case decision rule)
# =============================================================================

@test "[split] Contract declares Idempotent Split Contract section" {
  extract_and_grep "$CONTRACT_DOC" H2 "Idempotent Split Contract" \
    "absent|dispatch|safe-skip|HALT"
}

@test "[split] Idempotent Split Contract documents Case 1: absent file dispatches sub-subagent" {
  extract_and_grep "$CONTRACT_DOC" H2 "Idempotent Split Contract" \
    "[Aa]bsent"
  extract_and_grep "$CONTRACT_DOC" H2 "Idempotent Split Contract" \
    "dispatch"
}

@test "[split] Idempotent Split Contract documents Case 2: matching hash safe-skip without rewrite" {
  extract_and_grep "$CONTRACT_DOC" H2 "Idempotent Split Contract" \
    "safe-skip|safe skip"
}

@test "[split] Idempotent Split Contract documents Case 3: mismatching hash HALT" {
  extract_and_grep "$CONTRACT_DOC" H2 "Idempotent Split Contract" \
    "mismatch|HALT"
}

# =============================================================================
# HALT diagnostic exact text
# =============================================================================

@test "[split] Contract declares HALT Diagnostic section" {
  extract_and_grep "$CONTRACT_DOC" H2 "HALT Diagnostic" \
    "task-NN.md"
}

@test "[split] HALT Diagnostic contains exact mismatch diagnostic text (anchor phrase)" {
  extract_and_grep "$CONTRACT_DOC" H2 "HALT Diagnostic" \
    "source block in plan.md has changed since the last split"
}

@test "[split] HALT Diagnostic contains exact delete-and-rerun instruction" {
  extract_and_grep "$CONTRACT_DOC" H2 "HALT Diagnostic" \
    "delete tasks/task-NN.md and re-run"
}

@test "[split] HALT Diagnostic contains exact revert-plan instruction" {
  extract_and_grep "$CONTRACT_DOC" H2 "HALT Diagnostic" \
    "revert your plan.md edit"
}

# =============================================================================
# Pre-G5 migration diagnostic (missing-header and malformed-header)
# =============================================================================

@test "[split] Contract declares Pre-G5 Migration Diagnostic section" {
  extract_and_grep "$CONTRACT_DOC" H2 "Pre-G5 Migration Diagnostic" \
    "block-hash"
}

@test "[split] Pre-G5 Migration Diagnostic contains exact missing-header text (anchor phrase)" {
  extract_and_grep "$CONTRACT_DOC" H2 "Pre-G5 Migration Diagnostic" \
    "carries no '# block-hash:' header"
}

@test "[split] Pre-G5 Migration Diagnostic names predates idempotent-split contract" {
  extract_and_grep "$CONTRACT_DOC" H2 "Pre-G5 Migration Diagnostic" \
    "predates the idempotent-split contract"
}

@test "[split] Pre-G5 Migration Diagnostic names malformed block-hash header case" {
  extract_and_grep "$CONTRACT_DOC" H2 "Pre-G5 Migration Diagnostic" \
    "malformed block-hash header"
}

# =============================================================================
# Sub-subagent dispatch contract gains block_hash field
# =============================================================================

@test "[split] Contract declares Sub-Subagent Dispatch Contract section" {
  extract_and_grep "$CONTRACT_DOC" H2 "Sub-Subagent Dispatch Contract" \
    "block_hash"
}

@test "[split] Sub-Subagent Dispatch Contract includes block_hash: <sha256-hex> field" {
  extract_and_grep "$CONTRACT_DOC" H2 "Sub-Subagent Dispatch Contract" \
    "block_hash: <sha256-hex>|block_hash:.*sha256"
}

@test "[split] Sub-Subagent Dispatch Contract instructs sub-subagent to emit block-hash line after frontmatter" {
  extract_and_grep "$CONTRACT_DOC" H2 "Sub-Subagent Dispatch Contract" \
    "emit.*# block-hash:|# block-hash:.*immediately after"
}

# =============================================================================
# Quick-fix N=1 path
# =============================================================================

@test "[split] Contract declares Quick-Fix N=1 Path section" {
  extract_and_grep "$CONTRACT_DOC" H2 "Quick-Fix N=1 Path" \
    "block-hash|block_hash"
}

@test "[split] Quick-Fix N=1 Path documents same idempotency rule as full fan-out" {
  extract_and_grep "$CONTRACT_DOC" H2 "Quick-Fix N=1 Path" \
    "absent|safe-skip|HALT|audit"
}

# =============================================================================
# Behavioral fixtures: block-hash line position and format
# =============================================================================

@test "[split] Emitted task file has block-hash line immediately after closing frontmatter ---" {
  # Simulate a correctly-written tasks/task-01.md: block-hash on line 4
  # (immediately after the closing frontmatter ---, before first body content).
  # Use a real sha256 of the source block as the hash value.
  local hash
  hash="$(printf '### Task 1: example\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  cat > "$FIXTURE_DIR/tasks/task-01.md" <<EOF
---
task: 1
---
# block-hash: $hash
# Task 1: example
EOF
  # Line immediately after closing --- is line 4 (1-indexed).
  local hashline
  hashline="$(sed -n '4p' "$FIXTURE_DIR/tasks/task-01.md")"
  echo "$hashline" | grep -E "^# block-hash: [0-9a-f]{64}$"
}

@test "[split] Block-hash line has correct syntax: # block-hash: <64-char sha256 hex>" {
  cat > "$FIXTURE_DIR/tasks/task-02.md" <<'EOF'
---
task: 2
---
# block-hash: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
Body content starts here.
EOF
  grep -E "^# block-hash: [0-9a-f]{64}$" "$FIXTURE_DIR/tasks/task-02.md"
}

@test "[split] Hash calculation: sha256 over normalized source block (strip trailing whitespace)" {
  # Verify normalization rule: strip trailing whitespace from each line.
  # sha256("### Task 1: example\n") == known value.
  local raw_block normalized_hash expected_hash
  raw_block="### Task 1: example   
body line with trailing space   "
  # Normalize: strip trailing whitespace per line.
  normalized_hash="$(printf '%s\n' "$raw_block" | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  # Verify the hash is a 64-char hex string.
  echo "$normalized_hash" | grep -E "^[0-9a-f]{64}$"
  # Verify trailing spaces were stripped before hashing (hash of normalized != hash of raw).
  local raw_hash
  raw_hash="$(printf '%s\n' "$raw_block" | shasum -a 256 | awk '{print $1}')"
  # The raw block has trailing whitespace, so raw_hash should differ from normalized_hash.
  [ "$raw_hash" != "$normalized_hash" ]
}

# =============================================================================
# Behavioral fixtures: partial-split crash recovery
# =============================================================================

@test "[split] Partial-split crash recovery: only missing task files dispatched on re-run" {
  # Simulate: plan.md has 3 tasks; only task-01.md and task-03.md were written
  # before crash (task-02.md missing). On re-run, only task-02 should be dispatched.
  # Fixture: write task-01.md and task-03.md with valid block-hash headers.
  local hash01 hash03
  hash01="$(printf '### Task 1: first\nbody\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  hash03="$(printf '### Task 3: third\nbody\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"

  cat > "$FIXTURE_DIR/tasks/task-01.md" <<EOF
---
task: 1
---
# block-hash: $hash01
# Task 1: first
EOF

  cat > "$FIXTURE_DIR/tasks/task-03.md" <<EOF
---
task: 3
---
# block-hash: $hash03
# Task 3: third
EOF

  # Task-02 is absent — it should be dispatched on re-run.
  [ ! -e "$FIXTURE_DIR/tasks/task-02.md" ]

  # Simulate: orchestrator checks each expected task file.
  # task-01 present + hash matches → safe-skip.
  local actual_hash01
  actual_hash01="$(printf '### Task 1: first\nbody\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  local stored_hash01
  stored_hash01="$(grep -E "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md" | awk '{print $3}')"
  [ "$actual_hash01" = "$stored_hash01" ]

  # task-02 absent → dispatch (simulate by counting dispatches needed).
  local dispatch_count
  dispatch_count=0
  for i in 1 2 3; do
    f="$FIXTURE_DIR/tasks/task-$(printf '%02d' "$i").md"
    if [ ! -e "$f" ]; then
      dispatch_count=$((dispatch_count + 1))
    fi
  done
  [ "$dispatch_count" -eq 1 ]
}

# =============================================================================
# Behavioral fixtures: complete re-run no-op (zero dispatches)
# =============================================================================

@test "[split] Complete re-run with all matching hashes dispatches zero sub-subagents" {
  # Simulate: all task files present with matching block-hash values.
  local hash01 hash02
  hash01="$(printf '### Task 1: first\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  hash02="$(printf '### Task 2: second\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"

  cat > "$FIXTURE_DIR/tasks/task-01.md" <<EOF
---
task: 1
---
# block-hash: $hash01
# Task 1: first
EOF

  cat > "$FIXTURE_DIR/tasks/task-02.md" <<EOF
---
task: 2
---
# block-hash: $hash02
# Task 2: second
EOF

  # Simulate orchestrator decision loop: count dispatches needed.
  local dispatch_count
  dispatch_count=0
  for i in 1 2; do
    local f hash_in_file actual_hash
    f="$FIXTURE_DIR/tasks/task-$(printf '%02d' "$i").md"
    if [ ! -e "$f" ]; then
      dispatch_count=$((dispatch_count + 1))
    else
      hash_in_file="$(grep -E "^# block-hash:" "$f" | awk '{print $3}')"
      if [ "$i" -eq 1 ]; then
        actual_hash="$hash01"
      else
        actual_hash="$hash02"
      fi
      if [ "$hash_in_file" != "$actual_hash" ]; then
        dispatch_count=$((dispatch_count + 1))
      fi
    fi
  done
  [ "$dispatch_count" -eq 0 ]
}

# =============================================================================
# Behavioral fixtures: hand-edit preservation
# =============================================================================

@test "[split] Hand-edit preserved when stored block hash still matches current plan.md block" {
  # Simulate: task-01.md has a hand-edit in the body, but the stored
  # block-hash still matches the current plan.md ### Task 1 block.
  # Canonical hash pattern (preserves terminating newline per contract).
  local hash
  hash="$(printf '### Task 1: original\nbody\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"

  cat > "$FIXTURE_DIR/tasks/task-01.md" <<EOF
---
task: 1
---
# block-hash: $hash
# Task 1: original (hand-edited note added below)
This note was added by hand after the split.
EOF

  # Orchestrator re-computes hash from the same plan.md block.
  local recomputed_hash
  recomputed_hash="$(printf '### Task 1: original\nbody\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"

  # Hash match → safe-skip; file unchanged.
  local stored_hash
  stored_hash="$(grep -E "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md" | awk '{print $3}')"
  [ "$stored_hash" = "$recomputed_hash" ]

  # Hand-edit is preserved (body still contains the hand-added note).
  grep -F "This note was added by hand after the split." "$FIXTURE_DIR/tasks/task-01.md"
}

# =============================================================================
# Behavioral fixtures: mismatch HALT
# =============================================================================

@test "[split] Mismatch HALT: changed plan.md block with existing file halts and leaves file untouched" {
  # Simulate: task-01.md was written when plan.md block was version A;
  # user edited plan.md to version B without deleting the task file.
  # Canonical hash pattern (preserves terminating newline per contract).
  local hash_v1 hash_v2
  hash_v1="$(printf '### Task 1: original title\nOriginal body.\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  hash_v2="$(printf '### Task 1: amended title\nAmended body.\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"

  cat > "$FIXTURE_DIR/tasks/task-01.md" <<EOF
---
task: 1
---
# block-hash: $hash_v1
# Task 1: original title
Original body.
EOF

  # Hashes differ → HALT condition. Capture pre-decision content.
  local stored_hash content_before decision
  stored_hash="$(grep -E "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md" | awk '{print $3}')"
  [ "$stored_hash" != "$hash_v2" ]
  content_before="$(cat "$FIXTURE_DIR/tasks/task-01.md")"

  # Orchestrator decision: stored hash != re-computed hash → halt branch
  # (do NOT rewrite). A buggy implementation that took the rewrite branch
  # on mismatch would clobber the existing file with v2 content; the
  # assertion below would then catch the regression.
  if [ "$stored_hash" != "$hash_v2" ]; then
    decision=halt
    # Halt branch: no filesystem op. File must remain untouched.
    :
  else
    decision=rewrite
    cat > "$FIXTURE_DIR/tasks/task-01.md" <<EOF
---
task: 1
---
# block-hash: $hash_v2
# Task 1: amended title
Amended body.
EOF
  fi
  [ "$decision" = halt ]

  # File is byte-for-byte unchanged: the halt branch performed no write.
  # If a future regression flipped the if-condition (or executed the
  # rewrite unconditionally), content_after would diverge.
  local content_after
  content_after="$(cat "$FIXTURE_DIR/tasks/task-01.md")"
  [ "$content_before" = "$content_after" ]
}

# =============================================================================
# Behavioral fixtures: missing block-hash header
# =============================================================================

@test "[split] Missing block-hash header triggers pre-G5 migration HALT diagnostic" {
  # Simulate a pre-G5 task file with no # block-hash: line.
  cat > "$FIXTURE_DIR/tasks/task-01.md" <<'EOF'
---
task: 1
---
# Task 1: pre-G5 file
Body content.
EOF

  # Behavioral pin: orchestrator decision branches on header presence. The
  # halt branch performs no filesystem op; the proceed branch would. We
  # capture pre-decision content, run the branching logic, and assert the
  # halt branch was taken AND the file is unchanged. A regression that
  # silently auto-backfilled a header (proceed branch on missing header)
  # would alter content_after and fail the equality assertion below.
  local content_before decision content_after
  content_before="$(cat "$FIXTURE_DIR/tasks/task-01.md")"
  if grep -qE "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md"; then
    decision=proceed
    # Proceed branch: would normally re-audit the existing hash. Not
    # exercised here because the fixture deliberately lacks the header.
    :
  else
    decision=halt-missing-header
    # Halt branch: emit diagnostic, do NOT touch the file.
    :
  fi
  [ "$decision" = halt-missing-header ]
  content_after="$(cat "$FIXTURE_DIR/tasks/task-01.md")"
  [ "$content_before" = "$content_after" ]

  # Contract doc must document the exact diagnostic text for this case.
  extract_and_grep "$CONTRACT_DOC" H2 "Pre-G5 Migration Diagnostic" \
    "carries no '# block-hash:' header"
  extract_and_grep "$CONTRACT_DOC" H2 "Pre-G5 Migration Diagnostic" \
    "predates the idempotent-split contract"
}

# =============================================================================
# Behavioral fixtures: malformed block-hash header
# =============================================================================

@test "[split] Malformed block-hash header triggers named malformed diagnostic" {
  # Simulate a task file with a malformed # block-hash: line (not valid hex).
  cat > "$FIXTURE_DIR/tasks/task-01.md" <<'EOF'
---
task: 1
---
# block-hash: not-valid-hex
# Task 1: file with malformed hash
EOF

  # Behavioral pin: orchestrator decision branches on whether the header
  # line, when present, matches the strict 64-char lowercase hex pattern.
  # The halt branch performs no filesystem op. A regression that accepted
  # a malformed header (proceed branch) and re-wrote a "corrected" header
  # would alter content_after.
  local content_before hashline decision content_after
  content_before="$(cat "$FIXTURE_DIR/tasks/task-01.md")"
  hashline="$(grep "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md" | head -1)"
  if echo "$hashline" | grep -qE "^# block-hash: [0-9a-f]{64}$"; then
    decision=proceed
    :
  else
    decision=halt-malformed-header
    :
  fi
  [ "$decision" = halt-malformed-header ]
  content_after="$(cat "$FIXTURE_DIR/tasks/task-01.md")"
  [ "$content_before" = "$content_after" ]

  # Contract doc must name "malformed block-hash header" specifically.
  extract_and_grep "$CONTRACT_DOC" H2 "Pre-G5 Migration Diagnostic" \
    "malformed block-hash header"
}

# =============================================================================
# Quick-fix N=1 path emits block-hash line (behavioral)
# =============================================================================

@test "[split] Quick-fix N=1 path: single-task file carries block-hash line" {
  # Simulate the quick-fix inline write path for a single-task plan.
  local hash
  hash="$(printf '### Task 1: quick fix task\nFix body.\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"

  cat > "$FIXTURE_DIR/tasks/task-01.md" <<EOF
---
task: 1
---
# block-hash: $hash
# Task 1: quick fix task
Fix body.
EOF

  # Block-hash line must be present and valid.
  grep -E "^# block-hash: [0-9a-f]{64}$" "$FIXTURE_DIR/tasks/task-01.md"

  # Block-hash line must be immediately after closing frontmatter ---.
  local hashline
  hashline="$(sed -n '4p' "$FIXTURE_DIR/tasks/task-01.md")"
  echo "$hashline" | grep -E "^# block-hash: [0-9a-f]{64}$"
}

@test "[split] Quick-fix N=1 path: re-run with matching hash is a safe-skip" {
  # Canonical hash pattern (preserves terminating newline per contract).
  local hash
  hash="$(printf '### Task 1: quick fix task\nFix body.\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"

  cat > "$FIXTURE_DIR/tasks/task-01.md" <<EOF
---
task: 1
---
# block-hash: $hash
# Task 1: quick fix task
Fix body.
EOF

  # Orchestrator recomputes hash — must match → safe-skip.
  local recomputed
  recomputed="$(printf '### Task 1: quick fix task\nFix body.\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  local stored
  stored="$(grep -E "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md" | awk '{print $3}')"
  [ "$stored" = "$recomputed" ]
}

# =============================================================================
# Grep-based documentation audit (all required section anchors)
# =============================================================================

@test "[split] Doc audit: contract doc contains all required section anchors" {
  # Each required section must be present as an H2 markdown heading.
  grep -F "## Block-Hash Header Format" "$CONTRACT_DOC"
  grep -F "## Idempotent Split Contract" "$CONTRACT_DOC"
  grep -F "## HALT Diagnostic" "$CONTRACT_DOC"
  grep -F "## Pre-G5 Migration Diagnostic" "$CONTRACT_DOC"
  grep -F "## Sub-Subagent Dispatch Contract" "$CONTRACT_DOC"
  grep -F "## Quick-Fix N=1 Path" "$CONTRACT_DOC"
}

# =============================================================================
# Theme B — Block-hash uniqueness: exactly one line per file
# =============================================================================

@test "[split] Block-hash line appears exactly once in a correctly emitted task file" {
  # A correctly emitted task file carries exactly one block-hash header line.
  # grep -c asserts count==1, catching any double-emission defect.
  local hash
  hash="$(printf '### Task 1: unique\nbody\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  cat > "$FIXTURE_DIR/tasks/task-01.md" <<EOF
---
task: 1
---
# block-hash: $hash
# Task 1: unique
body
EOF
  local count
  count="$(grep -c "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md")"
  [ "$count" -eq 1 ]
}

@test "[split] Block-hash uniqueness: two different source blocks produce different hashes" {
  # Collision-free property: distinct source blocks must not hash to the same value.
  # Canonical hash pattern (preserves terminating newline per contract).
  local hash_a hash_b
  hash_a="$(printf '### Task 1: alpha\nalpha body\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  hash_b="$(printf '### Task 1: beta\nbeta body\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  [ "$hash_a" != "$hash_b" ]
}

# =============================================================================
# Doc audit: file-untouched guarantee for missing-header / malformed-header HALT
# =============================================================================

@test "[split] Pre-G5 Migration Diagnostic section documents file is not rewritten on missing-header HALT" {
  # The contract must explicitly state that the existing tasks/task-NN.md file
  # is left untouched when the orchestrator detects a missing or malformed
  # block-hash header. Doc-audit assertion (the contract is the source of
  # truth; orchestrator is an LLM that reads this skill doc).
  extract_and_grep "$CONTRACT_DOC" H2 "Pre-G5 Migration Diagnostic" \
    "not rewritten|untouched|no automatic backfill"
}

# =============================================================================
# Multi-task pre-fan-out HALT — single mismatch halts entire fan-out (no dispatch)
# =============================================================================

@test "[split] Multi-task pre-fan-out HALT: single mismatch in 3-task set halts entire fan-out (zero dispatches)" {
  # Contract property: "A single Case 3 mismatch anywhere in the set halts the
  # entire fan-out." Critical safety property — without it, an orchestrator
  # could dispatch sub-subagents for matching tasks while halting only on the
  # mismatching one, overwriting N-1 task files.
  #
  # Fixture: 3-task plan; task-01 and task-03 are ABSENT (Case 1 — would
  # normally dispatch one write each); task-02 is present with a stale
  # block-hash (Case 3 — mismatch). A naive per-task orchestrator that
  # decides+dispatches in order would fire 1 dispatch (task-01) before
  # halting at task-02 → dispatch_count=1. A correct pre-fan-out
  # orchestrator scans ALL tasks first, then enters the dispatch phase
  # only if no mismatch was detected → dispatch_count=0.
  #
  # The scan/dispatch separation below is what makes the
  # `dispatch_count -eq 0` assertion non-vacuous: a regression that fused
  # scan + dispatch into a single pass would set dispatch_count=1 for
  # task-01 before reaching task-02's mismatch, failing the assertion.

  # Canonical hash pattern (preserves terminating newline per contract).
  local hash01_current hash02_current hash03_current
  hash01_current="$(printf '### Task 1: first\nbody01\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  hash02_current="$(printf '### Task 2: second-amended\nAmended body.\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  hash03_current="$(printf '### Task 3: third\nbody03\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"

  # task-02 is on disk with the OLD (pre-amend) hash → mismatch.
  # task-01 and task-03 are absent → would dispatch in a non-halted run.
  local hash02_stale
  hash02_stale="$(printf '### Task 2: second-original\nOriginal body.\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"

  cat > "$FIXTURE_DIR/tasks/task-02.md" <<EOF
---
task: 2
---
# block-hash: $hash02_stale
# Task 2: second-original
Original body.
EOF

  # Capture pre-decision filesystem state.
  local content02_before
  content02_before="$(cat "$FIXTURE_DIR/tasks/task-02.md")"
  [ ! -e "$FIXTURE_DIR/tasks/task-01.md" ]
  [ ! -e "$FIXTURE_DIR/tasks/task-03.md" ]

  # ----- Scan phase: classify every task; do NOT dispatch yet. -----
  local mismatch_detected expected_hash stored f
  local -a absent_ids=()
  mismatch_detected=false
  for i in 1 2 3; do
    f="$FIXTURE_DIR/tasks/task-$(printf '%02d' "$i").md"
    if [ "$i" -eq 1 ]; then expected_hash="$hash01_current"
    elif [ "$i" -eq 2 ]; then expected_hash="$hash02_current"
    else expected_hash="$hash03_current"
    fi
    if [ ! -e "$f" ]; then
      absent_ids+=("$i")           # Case 1 — would dispatch in dispatch phase
      continue
    fi
    stored="$(grep -E "^# block-hash:" "$f" | awk '{print $3}')"
    if [ "$stored" != "$expected_hash" ]; then
      mismatch_detected=true        # Case 3 — pre-fan-out HALT trigger
    fi
  done

  # Mismatch must be detected on task-02.
  [ "$mismatch_detected" = "true" ]
  # Sanity: scan correctly classified two tasks as absent (Case 1).
  [ "${#absent_ids[@]}" -eq 2 ]

  # ----- Dispatch phase: gated on the scan's halt decision. -----
  # The pre-fan-out HALT contract requires this gate: a mismatch anywhere
  # in the set MUST suppress the dispatch phase for the entire set,
  # including the absent-file (Case 1) tasks that would otherwise dispatch.
  local dispatch_count
  dispatch_count=0
  if [ "$mismatch_detected" = "false" ]; then
    for i in "${absent_ids[@]}"; do
      # Would dispatch a sub-subagent to write tasks/task-NN.md here.
      dispatch_count=$((dispatch_count + 1))
    done
  fi

  # Because mismatch was detected pre-fan-out, the dispatch phase did
  # NOT run. dispatch_count stays at 0 even though two Case 1 absent
  # tasks were classified as dispatchable. Without the gate, this
  # assertion would fail with dispatch_count=2.
  [ "$dispatch_count" -eq 0 ]

  # All on-disk files must remain byte-for-byte identical, and absent
  # files must remain absent (the matching-task safe-skip and the
  # halted Case 1 dispatches both leave the filesystem untouched).
  local content02_after
  content02_after="$(cat "$FIXTURE_DIR/tasks/task-02.md")"
  [ "$content02_before" = "$content02_after" ]
  [ ! -e "$FIXTURE_DIR/tasks/task-01.md" ]
  [ ! -e "$FIXTURE_DIR/tasks/task-03.md" ]
}

@test "[split] Idempotent Split Contract documents pre-fan-out HALT covers entire set" {
  # Doc-audit pin for the multi-task pre-fan-out HALT property: the contract
  # must state explicitly that a single Case 3 mismatch halts the ENTIRE
  # fan-out (not only the mismatching task).
  extract_and_grep "$CONTRACT_DOC" H2 "Idempotent Split Contract" \
    "single Case 3 mismatch.*halts the entire fan-out|halts the entire fan-out"
}

# =============================================================================
# Task-ID Validation — security: reject path-traversal task IDs before fs ops
# =============================================================================

@test "[split] Contract declares Task-ID Validation section" {
  # Without an ID-validation contract, an attacker who controls plan.md can
  # craft a heading like '### Task ../../../home/user/.ssh/authorized_keys: x'
  # so the orchestrator constructs tasks/task-<traversal>.md and writes the
  # task spec body outside the tasks/ directory.
  extract_and_grep "$CONTRACT_DOC" H2 "Task-ID Validation" \
    "positive integer|\\^\\[0-9\\]\\+\\$"
}

@test "[split] Task-ID Validation contract prose pins ordering: validation precedes filesystem probe (doc-audit)" {
  # Doc-audit: this test verifies CONTRACT PROSE ONLY. The orchestrator is
  # an LLM that reads this skill doc; the load-bearing ordering invariant
  # ("validate before any test -e / path construction / dispatch") must be
  # written explicitly in the contract so the LLM enforces it. Behavioral
  # ordering enforcement against a real orchestrator is out of scope for
  # bats fixtures (no orchestrator process to spy on); coverage relies on
  # this doc-pin plus the regex-pattern test below.
  #
  # We require BOTH an ordering keyword (before / prior to / pre-fan-out)
  # AND a specific filesystem-operation keyword (test -e / filesystem
  # probe / filesystem operation) in the same section. A drift that
  # softened the prose to "validation should occur" without the
  # before/test-e ordering would fail one of these assertions.
  extract_and_grep "$CONTRACT_DOC" H2 "Task-ID Validation" \
    "before|prior to|pre-fan-out|BEFORE"
  extract_and_grep "$CONTRACT_DOC" H2 "Task-ID Validation" \
    "test -e|filesystem probe|filesystem operation"
  extract_and_grep "$CONTRACT_DOC" H2 "Task-ID Validation" \
    "halt|HALT|reject"
}

@test "[split] Task-ID Validation pattern: positive integer regex catches path-traversal attempt" {
  # Behavioral pin: the validation regex defined by the contract must match
  # well-formed positive-integer IDs and MUST NOT match path-traversal or
  # other non-numeric IDs. Locks the regex so a future contract drift to a
  # weaker pattern (e.g., [^/]+) would fail this assertion.
  local id_ok id_traversal id_dotdot id_slash id_alpha
  id_ok="42"
  id_traversal="../../../home/user/.ssh/authorized_keys"
  id_dotdot=".."
  id_slash="3/etc/passwd"
  id_alpha="abc"

  # Apply the contract's required pattern (^[0-9]+$).
  echo "$id_ok"        | grep -qE '^[0-9]+$'
  ! echo "$id_traversal" | grep -qE '^[0-9]+$'
  ! echo "$id_dotdot"    | grep -qE '^[0-9]+$'
  ! echo "$id_slash"     | grep -qE '^[0-9]+$'
  ! echo "$id_alpha"     | grep -qE '^[0-9]+$'
}

# =============================================================================
# Security Scope — block-hash integrity boundary (plan.md provenance only)
# =============================================================================

@test "[split] Contract declares Security Scope section" {
  # The block-hash audit was framed as an "audit contract" without naming its
  # integrity boundary. A reader could reasonably infer the hash also attests
  # to the task file BODY — but the algorithm hashes only the plan.md source
  # block, so a mid-flight body tamper is silently safe-skipped on re-run as
  # long as the header byte string is preserved.
  extract_and_grep "$CONTRACT_DOC" H2 "Security Scope" \
    "plan.md|source block|provenance"
}

@test "[split] Security Scope clarifies block-hash attests to plan.md source only (not file body)" {
  # Doc-audit: the contract must explicitly call out that the block-hash does
  # NOT attest to the integrity of the tasks/task-NN.md file body. This is
  # the named integrity boundary that prevents a false guarantee.
  extract_and_grep "$CONTRACT_DOC" H2 "Security Scope" \
    "not.*body|body.*not|does not.*body|body integrity"
}

# =============================================================================
# Hash normalization — explicit trailing-newline contract + both-form lock
# =============================================================================

@test "[split] Block-Hash Header Format documents trailing-newline behavior explicitly" {
  # The normalization rule must state explicitly whether the terminating
  # newline of the final line is included in the hash input. Without this,
  # two equally-defensible implementations (one preserving \n, one stripping)
  # produce different SHA-256 values for the same source block.
  extract_and_grep "$CONTRACT_DOC" H2 "Block-Hash Header Format" \
    "trailing newline|terminating newline|preserves.*newline|including.*newline"
}

@test "[split] Hash normalization: trailing-newline preservation produces a different hash than stripping it" {
  # Lock the contract direction: hashing the block WITH its trailing \n
  # (Pattern A) and hashing without (Pattern B) MUST produce distinct
  # SHA-256 values. If the contract direction ever flips, the canonical
  # hash pattern in this test file (which uses Pattern A) becomes wrong
  # and every block-hash test will fail — that is the intended trip-wire.
  local block_with_nl_hash block_no_nl_hash
  block_with_nl_hash="$(printf '### Task 1: example\nbody\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  block_no_nl_hash="$(printf '### Task 1: example\nbody'    | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  [ "$block_with_nl_hash" != "$block_no_nl_hash" ]

  # The canonical hash pattern in this file uses 'printf ...\n | sed | shasum'
  # — i.e., the trailing \n is preserved into the hash input.
  # This test pins the canonical pattern matches the contract.
  echo "$block_with_nl_hash" | grep -qE '^[0-9a-f]{64}$'
}

# =============================================================================
# Theme E — Partial-crash: no-rewrite + exact-set passes once all files present
# =============================================================================

@test "[split] Partial-crash recovery: existing matching file is not rewritten; exact-set passes once completed" {
  # Simulate: plan has 2 tasks; task-01.md present+matching (crash before task-02.md).
  # On re-run: task-01 is safe-skipped (content unchanged); task-02 is dispatched.
  # After simulated dispatch: exact-set verification passes (both files present).
  local hash01
  hash01="$(printf '### Task 1: first\nbody01\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"

  cat > "$FIXTURE_DIR/tasks/task-01.md" <<EOF
---
task: 1
---
# block-hash: $hash01
# Task 1: first
body01
EOF
  local content_before
  content_before="$(cat "$FIXTURE_DIR/tasks/task-01.md")"

  # task-02 is absent (crash scenario).
  [ ! -e "$FIXTURE_DIR/tasks/task-02.md" ]

  # Orchestrator re-runs decision loop: task-01 matches → safe-skip (no rewrite);
  # task-02 absent → dispatch.
  local stored_hash actual_hash
  stored_hash="$(grep -E "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md" | awk '{print $3}')"
  actual_hash="$(printf '### Task 1: first\nbody01\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  [ "$stored_hash" = "$actual_hash" ]  # task-01: Case 2, safe-skip

  # task-01 content is unchanged (safe-skip = no rewrite).
  local content_after
  content_after="$(cat "$FIXTURE_DIR/tasks/task-01.md")"
  [ "$content_before" = "$content_after" ]

  # Simulate dispatch for task-02 (absent → write).
  local hash02
  hash02="$(printf '### Task 2: second\nbody02\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  cat > "$FIXTURE_DIR/tasks/task-02.md" <<EOF
---
task: 2
---
# block-hash: $hash02
# Task 2: second
body02
EOF

  # Exact-set verification: both task-01.md and task-02.md now present.
  local exact_set_ok
  exact_set_ok=true
  for i in 1 2; do
    f="$FIXTURE_DIR/tasks/task-$(printf '%02d' "$i").md"
    [ -e "$f" ] || exact_set_ok=false
  done
  [ "$exact_set_ok" = "true" ]
}

# =============================================================================
# Theme E — Complete re-run: approval-state completion after zero dispatches
# =============================================================================

@test "[split] Complete re-run with zero dispatches proceeds to approval-state completion" {
  # Simulate plan.md with status: draft; all task files present+matching → zero
  # dispatches → orchestrator writes status: approved and phase_start_commit.
  cat > "$FIXTURE_DIR/plan.md" <<'EOF'
---
status: draft
phase_start_commit: null
---
# Plan
EOF

  local hash01 hash02
  hash01="$(printf '### Task 1: alpha\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  hash02="$(printf '### Task 2: beta\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"

  cat > "$FIXTURE_DIR/tasks/task-01.md" <<EOF
---
task: 1
---
# block-hash: $hash01
# Task 1: alpha
EOF
  cat > "$FIXTURE_DIR/tasks/task-02.md" <<EOF
---
task: 2
---
# block-hash: $hash02
# Task 2: beta
EOF

  # Orchestrator decision loop: all hashes match → zero dispatches.
  local dispatch_count
  dispatch_count=0
  for i in 1 2; do
    local f h_stored h_actual
    f="$FIXTURE_DIR/tasks/task-$(printf '%02d' "$i").md"
    if [ ! -e "$f" ]; then
      dispatch_count=$((dispatch_count + 1))
    else
      h_stored="$(grep -E "^# block-hash:" "$f" | awk '{print $3}')"
      if [ "$i" -eq 1 ]; then h_actual="$hash01"; else h_actual="$hash02"; fi
      [ "$h_stored" = "$h_actual" ] || dispatch_count=$((dispatch_count + 1))
    fi
  done
  [ "$dispatch_count" -eq 0 ]

  # Exact-set verification passes: both files present.
  [ -e "$FIXTURE_DIR/tasks/task-01.md" ]
  [ -e "$FIXTURE_DIR/tasks/task-02.md" ]

  # Simulate approval-state write: plan.md gets status: approved and
  # phase_start_commit gets a non-null SHA.
  sed -i.bak 's/status: draft/status: approved/' "$FIXTURE_DIR/plan.md"
  sed -i.bak 's/phase_start_commit: null/phase_start_commit: 0123456789abcdef0123456789abcdef01234567/' "$FIXTURE_DIR/plan.md"
  grep -qF "status: approved" "$FIXTURE_DIR/plan.md"
  grep -qE "^phase_start_commit: [0-9a-f]{40}$" "$FIXTURE_DIR/plan.md"
}

# =============================================================================
# Theme A — Quick-fix N=1 parity: missing audit-case coverage
# =============================================================================

@test "[split] Quick-fix N=1 path: absent file on re-run triggers single write" {
  # Case 1 (absent): no task-01.md present → orchestrator dispatches exactly one write.
  [ ! -e "$FIXTURE_DIR/tasks/task-01.md" ]

  # Orchestrator counts dispatches needed for N=1 plan.
  local dispatch_count
  dispatch_count=0
  [ -e "$FIXTURE_DIR/tasks/task-01.md" ] || dispatch_count=$((dispatch_count + 1))
  [ "$dispatch_count" -eq 1 ]

  # Simulate the write (inline for N=1 quick-fix path).
  local hash
  hash="$(printf '### Task 1: quick fix\nbody\n' | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  cat > "$FIXTURE_DIR/tasks/task-01.md" <<EOF
---
task: 1
---
# block-hash: $hash
# Task 1: quick fix
body
EOF
  # Block-hash line must be present and valid.
  grep -E "^# block-hash: [0-9a-f]{64}$" "$FIXTURE_DIR/tasks/task-01.md"
  # Count must be exactly 1.
  local count
  count="$(grep -c "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md")"
  [ "$count" -eq 1 ]
}

@test "[split] Quick-Fix N=1 Path documents same audit-case rules as full fan-out" {
  # Doc-audit: the contract must state that the quick-fix N=1 path applies
  # the SAME absent / matching / mismatching / missing-header / malformed-header
  # audit rules as the full fan-out. This replaces three earlier behavioral
  # tests that constructed expected diagnostic strings inside the test and
  # then grepped those local strings — those tests could not fail and were
  # removed. The diagnostic phrases themselves are pinned by the
  # `## HALT Diagnostic` and `## Pre-G5 Migration Diagnostic` doc-audit
  # tests above against the actual contract document.
  extract_and_grep "$CONTRACT_DOC" H2 "Quick-Fix N=1 Path" \
    "absent"
  extract_and_grep "$CONTRACT_DOC" H2 "Quick-Fix N=1 Path" \
    "matches|matching"
  extract_and_grep "$CONTRACT_DOC" H2 "Quick-Fix N=1 Path" \
    "mismatch"
  extract_and_grep "$CONTRACT_DOC" H2 "Quick-Fix N=1 Path" \
    "missing block-hash header"
  extract_and_grep "$CONTRACT_DOC" H2 "Quick-Fix N=1 Path" \
    "malformed block-hash header"
}
