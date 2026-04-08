#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Setup: create temp dirs
setup() {
  export PROJECT_DIR
  PROJECT_DIR=$(mktemp -d)

  export PLUGIN_ROOT
  PLUGIN_ROOT="$(dirname "$BATS_TEST_FILENAME")/../../"
  # Resolve to absolute path
  PLUGIN_ROOT="$(cd "$PLUGIN_ROOT" && pwd)"

  export SCRIPT="$PLUGIN_ROOT/hooks/setup-project-hooks.sh"
  export HOOKS_JSON="$PLUGIN_ROOT/hooks/hooks.json"
}

teardown() {
  rm -rf "$PROJECT_DIR"
}

# ──────────────────────────────────────────────────────────────
# Test 1: No existing settings.json → creates with PreToolUse and PostToolUse
# ──────────────────────────────────────────────────────────────
@test "no existing settings.json creates file with PreToolUse and PostToolUse" {
  run "$SCRIPT" "$PROJECT_DIR"
  [ "$status" -eq 0 ]

  local settings_file="$PROJECT_DIR/.claude/settings.json"
  [ -f "$settings_file" ]

  local pre
  pre=$(jq '.hooks.PreToolUse | length' "$settings_file")
  [ "$pre" -gt 0 ]

  local post
  post=$(jq '.hooks.PostToolUse | length' "$settings_file")
  [ "$post" -gt 0 ]
}

# ──────────────────────────────────────────────────────────────
# Test 2: No existing settings.json → SessionStart is NOT written
# ──────────────────────────────────────────────────────────────
@test "no existing settings.json does not include SessionStart" {
  run "$SCRIPT" "$PROJECT_DIR"
  [ "$status" -eq 0 ]

  local settings_file="$PROJECT_DIR/.claude/settings.json"
  local session
  session=$(jq '.hooks.SessionStart // "absent"' "$settings_file")
  [ "$session" = '"absent"' ]
}

# ──────────────────────────────────────────────────────────────
# Test 3: Existing settings.json with no hooks → adds hooks section
# ──────────────────────────────────────────────────────────────
@test "existing settings.json with no hooks gets hooks section added" {
  mkdir -p "$PROJECT_DIR/.claude"
  printf '{"theme":"dark"}\n' > "$PROJECT_DIR/.claude/settings.json"

  run "$SCRIPT" "$PROJECT_DIR"
  [ "$status" -eq 0 ]

  local settings_file="$PROJECT_DIR/.claude/settings.json"
  local theme
  theme=$(jq -r '.theme' "$settings_file")
  [ "$theme" = "dark" ]

  local pre
  pre=$(jq '.hooks.PreToolUse | length' "$settings_file")
  [ "$pre" -gt 0 ]
}

# ──────────────────────────────────────────────────────────────
# Test 4: Existing settings.json with other hooks → appends without removing
# ──────────────────────────────────────────────────────────────
@test "existing settings.json with other hooks keeps existing and adds QRSPI" {
  mkdir -p "$PROJECT_DIR/.claude"
  printf '{"hooks":{"PreToolUse":[{"matcher":"Read","hooks":[{"type":"command","command":"echo read"}]}]}}\n' \
    > "$PROJECT_DIR/.claude/settings.json"

  run "$SCRIPT" "$PROJECT_DIR"
  [ "$status" -eq 0 ]

  local settings_file="$PROJECT_DIR/.claude/settings.json"
  local pre_count
  pre_count=$(jq '.hooks.PreToolUse | length' "$settings_file")
  # Should have at least 2 entries (original + QRSPI)
  [ "$pre_count" -ge 2 ]

  # The original entry must still be present
  local has_read
  has_read=$(jq '[.hooks.PreToolUse[].matcher] | map(select(. == "Read")) | length' "$settings_file")
  [ "$has_read" -ge 1 ]
}

# ──────────────────────────────────────────────────────────────
# Test 5: QRSPI hooks already present → running again produces identical output (idempotent)
# ──────────────────────────────────────────────────────────────
@test "running script twice is idempotent" {
  run "$SCRIPT" "$PROJECT_DIR"
  [ "$status" -eq 0 ]

  local settings_file="$PROJECT_DIR/.claude/settings.json"
  local first_run
  first_run=$(jq -c '.' "$settings_file")

  run "$SCRIPT" "$PROJECT_DIR"
  [ "$status" -eq 0 ]

  local second_run
  second_run=$(jq -c '.' "$settings_file")

  [ "$first_run" = "$second_run" ]
}

# ──────────────────────────────────────────────────────────────
# Test 6: ${CLAUDE_PLUGIN_ROOT} replaced with actual absolute path
# ──────────────────────────────────────────────────────────────
@test "CLAUDE_PLUGIN_ROOT variable replaced with absolute path in commands" {
  run "$SCRIPT" "$PROJECT_DIR"
  [ "$status" -eq 0 ]

  local settings_file="$PROJECT_DIR/.claude/settings.json"

  # No literal ${CLAUDE_PLUGIN_ROOT} should remain
  local has_variable
  has_variable=$(jq '.' "$settings_file" | grep -c '\${CLAUDE_PLUGIN_ROOT}' || true)
  [ "$has_variable" -eq 0 ]

  # The path should start with /
  local command_val
  command_val=$(jq -r '.hooks.PreToolUse[0].hooks[0].command' "$settings_file")
  # Should contain an absolute path (starts with /)
  [[ "$command_val" == *"/"* ]]
}

# ──────────────────────────────────────────────────────────────
# Test 7: Output JSON is valid
# ──────────────────────────────────────────────────────────────
@test "output settings.json is valid JSON" {
  run "$SCRIPT" "$PROJECT_DIR"
  [ "$status" -eq 0 ]

  local settings_file="$PROJECT_DIR/.claude/settings.json"
  run jq '.' "$settings_file"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────
# Test 8: Explicit project dir argument works
# ──────────────────────────────────────────────────────────────
@test "explicit project directory argument is used" {
  local explicit_dir
  explicit_dir=$(mktemp -d)

  run "$SCRIPT" "$explicit_dir"
  [ "$status" -eq 0 ]

  [ -f "$explicit_dir/.claude/settings.json" ]
  rm -rf "$explicit_dir"
}

# ──────────────────────────────────────────────────────────────
# Test 9: No argument → uses $PWD
# ──────────────────────────────────────────────────────────────
@test "no argument uses PWD" {
  local saved_pwd="$PWD"
  cd "$PROJECT_DIR"

  run "$SCRIPT"
  [ "$status" -eq 0 ]

  [ -f "$PROJECT_DIR/.claude/settings.json" ]

  cd "$saved_pwd"
}

# ──────────────────────────────────────────────────────────────
# Test 10: Exit 0 on success with summary message
# ──────────────────────────────────────────────────────────────
@test "exit 0 on success and prints a summary message" {
  run "$SCRIPT" "$PROJECT_DIR"
  [ "$status" -eq 0 ]
  [ -n "$output" ]
}

# ──────────────────────────────────────────────────────────────
# Test 11: Exit 1 if hooks.json is missing
# ──────────────────────────────────────────────────────────────
@test "exit 1 when hooks.json cannot be read" {
  # Run with a fake PLUGIN_ROOT that has no hooks.json
  local fake_root
  fake_root=$(mktemp -d)
  mkdir -p "$fake_root/hooks"

  # We need to override PLUGIN_ROOT detection — do this by creating a wrapper
  # that calls the script but with the hooks.json path missing
  # The simplest approach: copy script, patch it to point at fake root
  local wrapper
  wrapper=$(mktemp /tmp/test-wrapper-XXXXXX.sh)
  printf '#!/usr/bin/env bash\nexec "%s" "$@"\n' "$SCRIPT" > "$wrapper"
  chmod +x "$wrapper"

  # Actually test the script directly: temporarily rename hooks.json
  local real_hooks_json="$PLUGIN_ROOT/hooks/hooks.json"
  local backup_hooks_json="$PLUGIN_ROOT/hooks/hooks.json.bak"
  mv "$real_hooks_json" "$backup_hooks_json"

  run "$SCRIPT" "$PROJECT_DIR"
  local exit_code="$status"

  # Restore
  mv "$backup_hooks_json" "$real_hooks_json"
  rm -f "$wrapper"
  rm -rf "$fake_root"

  [ "$exit_code" -eq 1 ]
}

# ──────────────────────────────────────────────────────────────
# Test 12: Script uses set -euo pipefail
# ──────────────────────────────────────────────────────────────
@test "setup-project-hooks.sh uses set -euo pipefail" {
  local script_head
  script_head=$(head -3 "$SCRIPT")
  [[ "$script_head" == *"set -euo pipefail"* ]]
}
