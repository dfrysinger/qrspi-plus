#!/usr/bin/env bats

setup() {
  TEST_DIR="$(mktemp -d)"
  export TEST_DIR
  cd "$TEST_DIR"
}

teardown() {
  cd /
  rm -rf "$TEST_DIR"
}

# Helper function to create a markdown file with frontmatter status
create_artifact() {
  local file="$1"
  local status="$2"
  local dir="$(dirname "$file")"

  mkdir -p "$dir"
  cat > "$file" <<EOF
---
status: $status
---
EOF
}

# Test: validate_state_schema with no state.json creates from artifacts
@test "validate_state_schema: no state.json -> creates from artifacts, returns 0" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  create_artifact "$artifact_dir/goals.md" "approved"

  cd "$TEST_DIR"
  mkdir -p ".qrspi"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh"
  run validate_state_schema "$artifact_dir"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Created state.json from artifacts"* ]]
  [ -f "$TEST_DIR/.qrspi/state.json" ]
}

# Test: validate_state_schema with valid v1 returns 0, no output
@test "validate_state_schema: valid v1 -> returns 0, no output" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  create_artifact "$artifact_dir/goals.md" "approved"

  cd "$TEST_DIR"
  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir" > /dev/null

  source "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh"
  run validate_state_schema "$artifact_dir"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# Test: validate_state_schema with missing version migrates to v1
@test "validate_state_schema: missing version -> migrates to v1" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  create_artifact "$artifact_dir/goals.md" "approved"

  cd "$TEST_DIR"
  mkdir -p ".qrspi"
  # Create v0 state without version field
  echo '{"current_step":"goals"}' > ".qrspi/state.json"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh"
  run validate_state_schema "$artifact_dir"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Migrated state.json from v0 to v1"* ]]

  # Verify migrated state has version=1
  local json
  json=$(cat "$TEST_DIR/.qrspi/state.json")
  [[ "$json" == *'"version":1'* ]]
}

# Test: validate_state_schema with missing wireframe_requested repairs
@test "validate_state_schema: missing wireframe_requested -> repairs" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  create_artifact "$artifact_dir/goals.md" "approved"

  cd "$TEST_DIR"
  mkdir -p ".qrspi"
  # Create v1 state missing wireframe_requested
  echo '{"version":1,"current_step":"goals","artifact_dir":"'$artifact_dir'","active_task":null,"artifacts":{"goals":"approved","questions":"draft","research":"draft","design":"draft","structure":"draft","plan":"draft","implement":"draft","test":"draft"},"phase_start_commit":null}' > ".qrspi/state.json"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh"
  run validate_state_schema "$artifact_dir"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Repaired: added wireframe_requested"* ]]

  # Verify field was added
  local json
  json=$(cat "$TEST_DIR/.qrspi/state.json")
  [[ "$json" == *'"wireframe_requested":false'* ]]
}

# Test: validate_state_schema with missing active_task repairs
@test "validate_state_schema: missing active_task -> repairs" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  create_artifact "$artifact_dir/goals.md" "approved"

  cd "$TEST_DIR"
  mkdir -p ".qrspi"
  # Create v1 state missing active_task
  echo '{"version":1,"current_step":"goals","artifact_dir":"'$artifact_dir'","wireframe_requested":false,"artifacts":{"goals":"approved","questions":"draft","research":"draft","design":"draft","structure":"draft","plan":"draft","implement":"draft","test":"draft"},"phase_start_commit":null}' > ".qrspi/state.json"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh"
  run validate_state_schema "$artifact_dir"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Repaired: added active_task"* ]]

  # Verify field was added
  local json
  json=$(cat "$TEST_DIR/.qrspi/state.json")
  [[ "$json" == *'"active_task":null'* ]]
}

# Test: validate_state_schema with missing artifacts rebuilds
@test "validate_state_schema: missing artifacts -> rebuilds" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  create_artifact "$artifact_dir/goals.md" "approved"

  cd "$TEST_DIR"
  mkdir -p ".qrspi"
  # Create v1 state missing artifacts map
  echo '{"version":1,"current_step":"goals","artifact_dir":"'$artifact_dir'","wireframe_requested":false,"active_task":null,"phase_start_commit":null}' > ".qrspi/state.json"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh"
  run validate_state_schema "$artifact_dir"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Repaired: rebuilt artifacts from frontmatter"* ]]

  # Verify artifacts map was added
  local json
  json=$(cat "$TEST_DIR/.qrspi/state.json")
  [[ "$json" == *'"artifacts"'* ]]
  [[ "$json" == *'"goals":"approved"'* ]]
}

# Test: validate_state_schema outputs migration log
@test "validate_state_schema: outputs migration log" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  create_artifact "$artifact_dir/goals.md" "approved"

  cd "$TEST_DIR"
  mkdir -p ".qrspi"
  echo '{"current_step":"goals"}' > ".qrspi/state.json"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh"
  run validate_state_schema "$artifact_dir"

  [ "$status" -eq 0 ]
  [ -n "$output" ]
}

# Test: validate_state_schema uses atomic write
@test "validate_state_schema: uses atomic write" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  create_artifact "$artifact_dir/goals.md" "approved"

  cd "$TEST_DIR"
  mkdir -p ".qrspi"
  echo '{"current_step":"goals"}' > ".qrspi/state.json"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh"
  run validate_state_schema "$artifact_dir"

  [ "$status" -eq 0 ]
  # Verify the final file is valid JSON
  jq . "$TEST_DIR/.qrspi/state.json" > /dev/null
}

# Test: validate_config with all fields returns 0
@test "validate_config: all fields present -> returns 0, no output" {
  local config_path="$TEST_DIR/config.md"
  cat > "$config_path" <<'EOF'
---
status: draft
phase: 4
enforcement_default: strict
---
# Config
EOF

  source "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh"
  run validate_config "$config_path"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# Test: validate_config missing Phase 4 fields adds defaults
@test "validate_config: missing Phase 4 fields -> adds defaults, returns 0" {
  local config_path="$TEST_DIR/config.md"
  cat > "$config_path" <<'EOF'
---
status: draft
---
# Config
EOF

  source "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh"
  run validate_config "$config_path"

  [ "$status" -eq 0 ]
  [[ "$output" == *"enforcement_default"* ]]

  # Verify field was added to file
  [[ $(cat "$config_path") == *"enforcement_default"* ]]
}

# Test: validate_config no file returns 1
@test "validate_config: no file -> returns 1" {
  source "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh"
  run validate_config "$TEST_DIR/nonexistent.md"

  [ "$status" -eq 1 ]
}

# Test: validate_config preserves existing content
@test "validate_config: preserves existing content when adding defaults" {
  local config_path="$TEST_DIR/config.md"
  cat > "$config_path" <<'EOF'
---
status: draft
---
# My Config

Some existing content here.
EOF

  source "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh"
  run validate_config "$config_path"

  [ "$status" -eq 0 ]
  [[ $(cat "$config_path") == *"My Config"* ]]
  [[ $(cat "$config_path") == *"Some existing content here"* ]]
}

# Test: validate_config repairs missing frontmatter
@test "validate_config: no frontmatter -> adds frontmatter with enforcement_default, returns 0" {
  source "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh"
  local config_path="$TEST_DIR/config-no-fm.md"
  printf 'codex_reviews: false\nsome other content\n' > "$config_path"

  run validate_config "$config_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"added missing frontmatter"* ]]

  # File should now have frontmatter with enforcement_default
  head -1 "$config_path" | grep -q "^---$"
  grep -q "enforcement_default: strict" "$config_path"
  # Original content preserved after frontmatter
  grep -q "codex_reviews: false" "$config_path"
}

# Test: validate_config repairs empty file
@test "validate_config: empty file -> adds frontmatter with enforcement_default, returns 0" {
  source "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh"
  local config_path="$TEST_DIR/config-empty.md"
  touch "$config_path"

  run validate_config "$config_path"
  [ "$status" -eq 0 ]

  grep -q "enforcement_default: strict" "$config_path"
}

# Test: validate_task_specs with full specs returns 0, no output
@test "validate_task_specs: full specs -> returns 0, no output" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir/tasks"

  cat > "$artifact_dir/tasks/task-01.md" <<'EOF'
---
status: draft
task: 1
phase: 4
enforcement: strict
allowed_files:
  - action: create
    path: some/file.sh
constraints:
  - Some constraint
---
Task content
EOF

  source "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh"
  run validate_task_specs "$artifact_dir"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# Test: validate_task_specs missing enforcement outputs warning
@test "validate_task_specs: missing enforcement -> warning" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir/tasks"

  cat > "$artifact_dir/tasks/task-01.md" <<'EOF'
---
status: draft
task: 1
phase: 4
allowed_files:
  - action: create
    path: some/file.sh
constraints:
  - Some constraint
---
Task content
EOF

  source "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh"
  run validate_task_specs "$artifact_dir"

  [ "$status" -eq 0 ]
  [[ "$output" == *"enforcement"* ]]
}

# Test: validate_task_specs missing allowed_files outputs warning
@test "validate_task_specs: missing allowed_files -> warning" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir/tasks"

  cat > "$artifact_dir/tasks/task-01.md" <<'EOF'
---
status: draft
task: 1
phase: 4
enforcement: strict
constraints:
  - Some constraint
---
Task content
EOF

  source "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh"
  run validate_task_specs "$artifact_dir"

  [ "$status" -eq 0 ]
  [[ "$output" == *"allowed_files"* ]]
}

# Test: validate_task_specs missing constraints outputs warning
@test "validate_task_specs: missing constraints -> warning" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir/tasks"

  cat > "$artifact_dir/tasks/task-01.md" <<'EOF'
---
status: draft
task: 1
phase: 4
enforcement: strict
allowed_files:
  - action: create
    path: some/file.sh
---
Task content
EOF

  source "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh"
  run validate_task_specs "$artifact_dir"

  [ "$status" -eq 0 ]
  [[ "$output" == *"constraints"* ]]
}

# Test: validate_task_specs with no task files returns 0
@test "validate_task_specs: no task files -> returns 0, no output" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh"
  run validate_task_specs "$artifact_dir"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# Test: validate_task_specs never modifies files
@test "validate_task_specs: never modifies files" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir/tasks"

  cat > "$artifact_dir/tasks/task-01.md" <<'EOF'
---
status: draft
task: 1
phase: 4
---
Original content
EOF

  local original_content
  original_content=$(cat "$artifact_dir/tasks/task-01.md")

  source "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh"
  run validate_task_specs "$artifact_dir"

  local after_content
  after_content=$(cat "$artifact_dir/tasks/task-01.md")

  [[ "$original_content" == "$after_content" ]]
}

# Test: validate_task_specs always returns 0
@test "validate_task_specs: always returns 0" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir/tasks"

  cat > "$artifact_dir/tasks/task-01.md" <<'EOF'
---
status: draft
task: 1
phase: 4
---
EOF

  source "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh"
  run validate_task_specs "$artifact_dir"

  [ "$status" -eq 0 ]
}

# Test: Library uses set -euo pipefail
@test "validate.sh: starts with #!/usr/bin/env bash" {
  head -1 "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh" | grep -q '^#!/usr/bin/env bash'
}

@test "validate.sh: has 'set -euo pipefail' as early line" {
  head -2 "$BATS_TEST_DIRNAME/../../hooks/lib/validate.sh" | tail -1 | grep -q '^set -euo pipefail'
}
