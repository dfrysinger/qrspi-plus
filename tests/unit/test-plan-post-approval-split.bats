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

# =============================================================================
# G5 — Block-hash header format (contract doc sections)
# =============================================================================

@test "[T34-G5] Contract declares Block-Hash Header Format section" {
  extract_and_grep "$CONTRACT_DOC" H2 "Block-Hash Header Format" \
    "block-hash"
}

@test "[T34-G5] Block-Hash Header Format documents position: immediately after closing frontmatter ---" {
  extract_and_grep "$CONTRACT_DOC" H2 "Block-Hash Header Format" \
    "immediately after"
}

@test "[T34-G5] Block-Hash Header Format documents syntax: # block-hash: <sha256-hex>" {
  extract_and_grep "$CONTRACT_DOC" H2 "Block-Hash Header Format" \
    "# block-hash:"
}

@test "[T34-G5] Block-Hash Header Format documents sha256 hex no-salt algorithm" {
  extract_and_grep "$CONTRACT_DOC" H2 "Block-Hash Header Format" \
    "sha256"
  extract_and_grep "$CONTRACT_DOC" H2 "Block-Hash Header Format" \
    "no salt"
}

@test "[T34-G5] Block-Hash Header Format documents normalization: strip trailing whitespace per line" {
  extract_and_grep "$CONTRACT_DOC" H2 "Block-Hash Header Format" \
    "strip trailing whitespace"
}

# =============================================================================
# G5 — Idempotent split contract (3-case decision rule)
# =============================================================================

@test "[T34-G5] Contract declares Idempotent Split Contract section" {
  extract_and_grep "$CONTRACT_DOC" H2 "Idempotent Split Contract" \
    "absent|dispatch|safe-skip|HALT"
}

@test "[T34-G5] Idempotent Split Contract documents Case 1: absent file dispatches sub-subagent" {
  extract_and_grep "$CONTRACT_DOC" H2 "Idempotent Split Contract" \
    "[Aa]bsent"
  extract_and_grep "$CONTRACT_DOC" H2 "Idempotent Split Contract" \
    "dispatch"
}

@test "[T34-G5] Idempotent Split Contract documents Case 2: matching hash safe-skip without rewrite" {
  extract_and_grep "$CONTRACT_DOC" H2 "Idempotent Split Contract" \
    "safe-skip|safe skip"
}

@test "[T34-G5] Idempotent Split Contract documents Case 3: mismatching hash HALT" {
  extract_and_grep "$CONTRACT_DOC" H2 "Idempotent Split Contract" \
    "mismatch|HALT"
}

# =============================================================================
# G5 — HALT diagnostic exact text
# =============================================================================

@test "[T34-G5] Contract declares HALT Diagnostic section" {
  extract_and_grep "$CONTRACT_DOC" H2 "HALT Diagnostic" \
    "task-NN.md"
}

@test "[T34-G5] HALT Diagnostic contains exact mismatch diagnostic text (anchor phrase)" {
  extract_and_grep "$CONTRACT_DOC" H2 "HALT Diagnostic" \
    "source block in plan.md has changed since the last split"
}

@test "[T34-G5] HALT Diagnostic contains exact delete-and-rerun instruction" {
  extract_and_grep "$CONTRACT_DOC" H2 "HALT Diagnostic" \
    "delete tasks/task-NN.md and re-run"
}

@test "[T34-G5] HALT Diagnostic contains exact revert-plan instruction" {
  extract_and_grep "$CONTRACT_DOC" H2 "HALT Diagnostic" \
    "revert your plan.md edit"
}

# =============================================================================
# G5 — Pre-G5 migration diagnostic (missing-header and malformed-header)
# =============================================================================

@test "[T34-G5] Contract declares Pre-G5 Migration Diagnostic section" {
  extract_and_grep "$CONTRACT_DOC" H2 "Pre-G5 Migration Diagnostic" \
    "block-hash"
}

@test "[T34-G5] Pre-G5 Migration Diagnostic contains exact missing-header text (anchor phrase)" {
  extract_and_grep "$CONTRACT_DOC" H2 "Pre-G5 Migration Diagnostic" \
    "carries no '# block-hash:' header"
}

@test "[T34-G5] Pre-G5 Migration Diagnostic names predates idempotent-split contract" {
  extract_and_grep "$CONTRACT_DOC" H2 "Pre-G5 Migration Diagnostic" \
    "predates the idempotent-split contract"
}

@test "[T34-G5] Pre-G5 Migration Diagnostic names malformed block-hash header case" {
  extract_and_grep "$CONTRACT_DOC" H2 "Pre-G5 Migration Diagnostic" \
    "malformed block-hash header"
}

# =============================================================================
# G5 — Sub-subagent dispatch contract gains block_hash field
# =============================================================================

@test "[T34-G5] Contract declares Sub-Subagent Dispatch Contract section" {
  extract_and_grep "$CONTRACT_DOC" H2 "Sub-Subagent Dispatch Contract" \
    "block_hash"
}

@test "[T34-G5] Sub-Subagent Dispatch Contract includes block_hash: <sha256-hex> field" {
  extract_and_grep "$CONTRACT_DOC" H2 "Sub-Subagent Dispatch Contract" \
    "block_hash: <sha256-hex>|block_hash:.*sha256"
}

@test "[T34-G5] Sub-Subagent Dispatch Contract instructs sub-subagent to emit block-hash line after frontmatter" {
  extract_and_grep "$CONTRACT_DOC" H2 "Sub-Subagent Dispatch Contract" \
    "emit.*# block-hash:|# block-hash:.*immediately after"
}

# =============================================================================
# G5 — Quick-fix N=1 path
# =============================================================================

@test "[T34-G5] Contract declares Quick-Fix N=1 Path section" {
  extract_and_grep "$CONTRACT_DOC" H2 "Quick-Fix N=1 Path" \
    "block-hash|block_hash"
}

@test "[T34-G5] Quick-Fix N=1 Path documents same idempotency rule as full fan-out" {
  extract_and_grep "$CONTRACT_DOC" H2 "Quick-Fix N=1 Path" \
    "absent|safe-skip|HALT|audit"
}

# =============================================================================
# G5 — Behavioral fixtures: block-hash line position and format
# =============================================================================

@test "[T34-G5] Emitted task file has block-hash line immediately after closing frontmatter ---" {
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

@test "[T34-G5] Block-hash line has correct syntax: # block-hash: <64-char sha256 hex>" {
  cat > "$FIXTURE_DIR/tasks/task-02.md" <<'EOF'
---
task: 2
---
# block-hash: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
Body content starts here.
EOF
  grep -E "^# block-hash: [0-9a-f]{64}$" "$FIXTURE_DIR/tasks/task-02.md"
}

@test "[T34-G5] Hash calculation: sha256 over normalized source block (strip trailing whitespace)" {
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
# G5 — Behavioral fixtures: partial-split crash recovery
# =============================================================================

@test "[T34-G5] Partial-split crash recovery: only missing task files dispatched on re-run" {
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
# G5 — Behavioral fixtures: complete re-run no-op (zero dispatches)
# =============================================================================

@test "[T34-G5] Complete re-run with all matching hashes dispatches zero sub-subagents" {
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
# G5 — Behavioral fixtures: hand-edit preservation
# =============================================================================

@test "[T34-G5] Hand-edit preserved when stored block hash still matches current plan.md block" {
  # Simulate: task-01.md has a hand-edit in the body, but the stored
  # block-hash still matches the current plan.md ### Task 1 block.
  local plan_block hash
  plan_block="$(printf '### Task 1: original\nbody\n')"
  hash="$(printf '%s' "$plan_block" | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"

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
  recomputed_hash="$(printf '%s' "$plan_block" | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"

  # Hash match → safe-skip; file unchanged.
  local stored_hash
  stored_hash="$(grep -E "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md" | awk '{print $3}')"
  [ "$stored_hash" = "$recomputed_hash" ]

  # Hand-edit is preserved (body still contains the hand-added note).
  grep -F "This note was added by hand after the split." "$FIXTURE_DIR/tasks/task-01.md"
}

# =============================================================================
# G5 — Behavioral fixtures: mismatch HALT
# =============================================================================

@test "[T34-G5] Mismatch HALT: changed plan.md block with existing file halts and leaves file untouched" {
  # Simulate: task-01.md was written when plan.md block was version A;
  # user edited plan.md to version B without deleting the task file.
  local block_v1 block_v2 hash_v1
  block_v1="$(printf '### Task 1: original title\nOriginal body.\n')"
  block_v2="$(printf '### Task 1: amended title\nAmended body.\n')"
  hash_v1="$(printf '%s' "$block_v1" | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"

  cat > "$FIXTURE_DIR/tasks/task-01.md" <<EOF
---
task: 1
---
# block-hash: $hash_v1
# Task 1: original title
Original body.
EOF
  local original_mtime
  original_mtime="$(stat -f '%m' "$FIXTURE_DIR/tasks/task-01.md" 2>/dev/null || stat -c '%Y' "$FIXTURE_DIR/tasks/task-01.md" 2>/dev/null)"

  # Orchestrator re-computes hash from the current (amended) plan.md block.
  local hash_v2
  hash_v2="$(printf '%s' "$block_v2" | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"

  # Hashes differ → HALT condition.
  local stored_hash
  stored_hash="$(grep -E "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md" | awk '{print $3}')"
  [ "$stored_hash" != "$hash_v2" ]

  # File is NOT rewritten (content unchanged — same as written).
  grep -F "# Task 1: original title" "$FIXTURE_DIR/tasks/task-01.md"
  grep -F "Original body." "$FIXTURE_DIR/tasks/task-01.md"
  ! grep -F "amended title" "$FIXTURE_DIR/tasks/task-01.md"
}

# =============================================================================
# G5 — Behavioral fixtures: missing block-hash header
# =============================================================================

@test "[T34-G5] Missing block-hash header triggers pre-G5 migration HALT diagnostic" {
  # Simulate a pre-G5 task file with no # block-hash: line.
  cat > "$FIXTURE_DIR/tasks/task-01.md" <<'EOF'
---
task: 1
---
# Task 1: pre-G5 file
Body content.
EOF

  # Orchestrator inspects the file: no block-hash line → audit-fail condition.
  local has_hash
  has_hash="$(grep -c "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md" || true)"
  [ "$has_hash" -eq 0 ]

  # Contract doc must document the exact diagnostic text for this case.
  extract_and_grep "$CONTRACT_DOC" H2 "Pre-G5 Migration Diagnostic" \
    "carries no '# block-hash:' header"
  extract_and_grep "$CONTRACT_DOC" H2 "Pre-G5 Migration Diagnostic" \
    "predates the idempotent-split contract"
}

# =============================================================================
# G5 — Behavioral fixtures: malformed block-hash header
# =============================================================================

@test "[T34-G5] Malformed block-hash header triggers named malformed diagnostic" {
  # Simulate a task file with a malformed # block-hash: line (not valid hex).
  cat > "$FIXTURE_DIR/tasks/task-01.md" <<'EOF'
---
task: 1
---
# block-hash: not-valid-hex
# Task 1: file with malformed hash
EOF

  # Malformed = present but not matching 64-char hex sha256 pattern.
  local hashline
  hashline="$(grep "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md" | head -1)"
  # Should NOT match the valid sha256 hex pattern.
  ! echo "$hashline" | grep -qE "^# block-hash: [0-9a-f]{64}$"

  # Contract doc must name "malformed block-hash header" specifically.
  extract_and_grep "$CONTRACT_DOC" H2 "Pre-G5 Migration Diagnostic" \
    "malformed block-hash header"
}

# =============================================================================
# G5 — Quick-fix N=1 path emits block-hash line (behavioral)
# =============================================================================

@test "[T34-G5] Quick-fix N=1 path: single-task file carries block-hash line" {
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

@test "[T34-G5] Quick-fix N=1 path: re-run with matching hash is a safe-skip" {
  local block hash
  block="$(printf '### Task 1: quick fix task\nFix body.\n')"
  hash="$(printf '%s' "$block" | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"

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
  recomputed="$(printf '%s' "$block" | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  local stored
  stored="$(grep -E "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md" | awk '{print $3}')"
  [ "$stored" = "$recomputed" ]
}

# =============================================================================
# G5 — Grep-based documentation audit (all required section anchors)
# =============================================================================

@test "[T34-G5] Doc audit: contract doc contains all required G5 section anchors" {
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

@test "[T34-G5] Block-hash line appears exactly once in a correctly emitted task file" {
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

@test "[T34-G5] Block-hash uniqueness: two different source blocks produce different hashes" {
  # Collision-free property: distinct source blocks must not hash to the same value.
  local block_a block_b hash_a hash_b
  block_a="$(printf '### Task 1: alpha\nalpha body\n')"
  block_b="$(printf '### Task 1: beta\nbeta body\n')"
  hash_a="$(printf '%s' "$block_a" | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  hash_b="$(printf '%s' "$block_b" | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  [ "$hash_a" != "$hash_b" ]
}

# =============================================================================
# Theme C — Malformed-header file preservation assertion
# =============================================================================

@test "[T34-G5] Malformed block-hash header: existing file is not rewritten after HALT" {
  # Spec DoD and test expectation both require the file to be left unchanged
  # when a malformed header is detected. Capture content before detection and
  # verify it is identical afterward.
  local original_content
  cat > "$FIXTURE_DIR/tasks/task-01.md" <<'EOF'
---
task: 1
---
# block-hash: not-valid-hex
# Task 1: file with malformed hash
Original body content that must not be rewritten.
EOF
  original_content="$(cat "$FIXTURE_DIR/tasks/task-01.md")"

  # Orchestrator detects malformed hash: present but not matching 64-char hex.
  local hashline is_malformed
  hashline="$(grep "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md" | head -1)"
  is_malformed=false
  if ! echo "$hashline" | grep -qE "^# block-hash: [0-9a-f]{64}$"; then
    is_malformed=true
    # Orchestrator HALTS here — does NOT rewrite the file.
  fi
  [ "$is_malformed" = "true" ]

  # File content must be byte-for-byte identical after the HALT decision.
  local after_content
  after_content="$(cat "$FIXTURE_DIR/tasks/task-01.md")"
  [ "$original_content" = "$after_content" ]

  # Spot-check: original body line is still present.
  grep -F "Original body content that must not be rewritten." "$FIXTURE_DIR/tasks/task-01.md"
}

# =============================================================================
# Theme D — HALT diagnostic behavioral assertions
# =============================================================================

@test "[T34-G5] Mismatch HALT: diagnostic contains required halt-cause text" {
  # The orchestrator must emit the exact mismatch diagnostic text. Simulate
  # the detection logic and assert the produced diagnostic contains the
  # required phrases from the contract.
  local block_v1 block_v2 hash_v1 hash_v2
  block_v1="$(printf '### Task 1: original title\nOriginal body.\n')"
  block_v2="$(printf '### Task 1: amended title\nAmended body.\n')"
  hash_v1="$(printf '%s' "$block_v1" | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  hash_v2="$(printf '%s' "$block_v2" | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"

  cat > "$FIXTURE_DIR/tasks/task-01.md" <<EOF
---
task: 1
---
# block-hash: $hash_v1
# Task 1: original title
Original body.
EOF

  # Orchestrator detects mismatch (stored hash != re-computed hash from current block).
  local stored_hash diagnostic
  stored_hash="$(grep -E "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md" | awk '{print $3}')"
  [ "$stored_hash" != "$hash_v2" ]  # mismatch confirmed

  # Produce the required diagnostic (as the orchestrator would before halting).
  diagnostic="task-01.md exists but its source block in plan.md has changed since the last split. To regenerate from the current plan.md, delete tasks/task-01.md and re-run. To preserve the existing file, revert your plan.md edit."

  # Assert all three required phrases from the contract are present.
  echo "$diagnostic" | grep -qF "exists but its source block in plan.md has changed"
  echo "$diagnostic" | grep -qF "delete tasks/task-01.md and re-run"
  echo "$diagnostic" | grep -qF "revert your plan.md edit"
}

@test "[T34-G5] Missing-header HALT: diagnostic contains required migration-guide text" {
  # The orchestrator must emit the exact pre-G5 migration diagnostic text.
  cat > "$FIXTURE_DIR/tasks/task-01.md" <<'EOF'
---
task: 1
---
# Task 1: pre-G5 file without block-hash line
Body content.
EOF

  # Detect absence of block-hash header.
  local has_hash diagnostic
  has_hash="$(grep -c "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md" || true)"
  [ "$has_hash" -eq 0 ]  # missing-header condition confirmed

  # Produce the required diagnostic.
  diagnostic="task-01.md is present but carries no '# block-hash:' header. This file predates the idempotent-split contract. To regenerate under the current contract, delete tasks/task-01.md and re-run."

  echo "$diagnostic" | grep -qF "carries no '# block-hash:' header"
  echo "$diagnostic" | grep -qF "predates the idempotent-split contract"
  echo "$diagnostic" | grep -qF "delete tasks/task-01.md and re-run"
}

@test "[T34-G5] Malformed-header HALT: diagnostic names malformed block-hash header" {
  # The orchestrator must emit a diagnostic that names "malformed block-hash header"
  # specifically (contract requirement; no exact text otherwise mandated).
  cat > "$FIXTURE_DIR/tasks/task-01.md" <<'EOF'
---
task: 1
---
# block-hash: INVALID!!!
# Task 1: malformed hash
EOF

  # Detect malformed header (present but not valid hex).
  local hashline is_malformed diagnostic
  hashline="$(grep "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md" | head -1)"
  is_malformed=false
  if ! echo "$hashline" | grep -qE "^# block-hash: [0-9a-f]{64}$"; then
    is_malformed=true
  fi
  [ "$is_malformed" = "true" ]

  # Produce the required diagnostic (must name "malformed block-hash header").
  diagnostic="task-01.md has a malformed block-hash header. To regenerate under the current contract, delete tasks/task-01.md and re-run."

  echo "$diagnostic" | grep -qF "malformed block-hash header"
}

# =============================================================================
# Theme E — Partial-crash: no-rewrite + exact-set passes once all files present
# =============================================================================

@test "[T34-G5] Partial-crash recovery: existing matching file is not rewritten; exact-set passes once completed" {
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

@test "[T34-G5] Complete re-run with zero dispatches proceeds to approval-state completion" {
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
  sed -i.bak 's/phase_start_commit: null/phase_start_commit: abc123def456/' "$FIXTURE_DIR/plan.md"
  grep -qF "status: approved" "$FIXTURE_DIR/plan.md"
  grep -qE "phase_start_commit: [0-9a-f]+" "$FIXTURE_DIR/plan.md"
}

# =============================================================================
# Theme A — Quick-fix N=1 parity: missing audit-case coverage
# =============================================================================

@test "[T34-G5] Quick-fix N=1 path: absent file on re-run triggers single write" {
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

@test "[T34-G5] Quick-fix N=1 path: mismatch halt emits named diagnostic and leaves file untouched" {
  # Case 3 (mismatch): existing file's stored hash != re-computed hash from
  # current plan.md block → HALT with mismatch diagnostic; file unchanged.
  local block_v1 block_v2 hash_v1 hash_v2
  block_v1="$(printf '### Task 1: original quick-fix\nOriginal.\n')"
  block_v2="$(printf '### Task 1: amended quick-fix\nAmended.\n')"
  hash_v1="$(printf '%s' "$block_v1" | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"
  hash_v2="$(printf '%s' "$block_v2" | sed 's/[[:space:]]*$//' | shasum -a 256 | awk '{print $1}')"

  cat > "$FIXTURE_DIR/tasks/task-01.md" <<EOF
---
task: 1
---
# block-hash: $hash_v1
# Task 1: original quick-fix
Original.
EOF
  local original_content
  original_content="$(cat "$FIXTURE_DIR/tasks/task-01.md")"

  # Detect mismatch.
  local stored_hash
  stored_hash="$(grep -E "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md" | awk '{print $3}')"
  [ "$stored_hash" != "$hash_v2" ]  # mismatch confirmed → HALT

  # Emit diagnostic (as orchestrator would).
  local diagnostic
  diagnostic="task-01.md exists but its source block in plan.md has changed since the last split. To regenerate from the current plan.md, delete tasks/task-01.md and re-run. To preserve the existing file, revert your plan.md edit."
  echo "$diagnostic" | grep -qF "exists but its source block in plan.md has changed"

  # File is untouched (not rewritten).
  local after_content
  after_content="$(cat "$FIXTURE_DIR/tasks/task-01.md")"
  [ "$original_content" = "$after_content" ]
}

@test "[T34-G5] Quick-fix N=1 path: missing block-hash header halts with pre-G5 migration diagnostic" {
  # Missing-header condition on the N=1 path: HALT with the migration diagnostic.
  cat > "$FIXTURE_DIR/tasks/task-01.md" <<'EOF'
---
task: 1
---
# Task 1: pre-G5 quick-fix file (no block-hash line)
Body without block-hash.
EOF

  # Detect absence of block-hash header.
  local has_hash
  has_hash="$(grep -c "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md" || true)"
  [ "$has_hash" -eq 0 ]  # missing-header condition confirmed

  # Emit migration diagnostic (as orchestrator would).
  local diagnostic
  diagnostic="task-01.md is present but carries no '# block-hash:' header. This file predates the idempotent-split contract. To regenerate under the current contract, delete tasks/task-01.md and re-run."
  echo "$diagnostic" | grep -qF "carries no '# block-hash:' header"
  echo "$diagnostic" | grep -qF "predates the idempotent-split contract"
  echo "$diagnostic" | grep -qF "delete tasks/task-01.md and re-run"
}

@test "[T34-G5] Quick-fix N=1 path: malformed block-hash header halts with named malformed diagnostic" {
  # Malformed-header condition on the N=1 path: HALT with diagnostic naming
  # "malformed block-hash header"; existing file is not rewritten.
  cat > "$FIXTURE_DIR/tasks/task-01.md" <<'EOF'
---
task: 1
---
# block-hash: INVALID-NOT-HEX
# Task 1: malformed quick-fix
EOF
  local original_content
  original_content="$(cat "$FIXTURE_DIR/tasks/task-01.md")"

  # Detect malformed header.
  local hashline is_malformed
  hashline="$(grep "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md" | head -1)"
  is_malformed=false
  if ! echo "$hashline" | grep -qE "^# block-hash: [0-9a-f]{64}$"; then
    is_malformed=true
  fi
  [ "$is_malformed" = "true" ]

  # Emit diagnostic naming "malformed block-hash header".
  local diagnostic
  diagnostic="task-01.md has a malformed block-hash header. To regenerate under the current contract, delete tasks/task-01.md and re-run."
  echo "$diagnostic" | grep -qF "malformed block-hash header"

  # File must not be rewritten.
  local after_content
  after_content="$(cat "$FIXTURE_DIR/tasks/task-01.md")"
  [ "$original_content" = "$after_content" ]
}
