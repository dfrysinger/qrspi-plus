#!/usr/bin/env bats
#
# tests/unit/test-detect-interaction-mode.bats
# Task 24 — CD-4 detect-interaction-mode.sh helper
# Target: scripts/detect-interaction-mode.sh
#
# Covers every test-expectation bullet from tasks/task-24.md:
#
#   [T24] Copilot CLI branch (COPILOT_CLI=1): PLATFORM=copilot-cli
#   [T24] Copilot CLI branch (COPILOT_CLI=1): DETECTION_TYPE=llm-context
#   [T24] Copilot CLI branch (COPILOT_CLI=1): expected autopilot context-inspection INSTRUCTION
#   [T24] Claude Code branch (CLAUDE_PROJECT_DIR, no COPILOT_CLI): PLATFORM=claude-code
#   [T24] Claude Code branch (CLAUDE_PROJECT_DIR, no COPILOT_CLI): DETECTION_TYPE=llm-context
#   [T24] Claude Code branch (CLAUDE_PROJECT_DIR, no COPILOT_CLI): expected auto-mode INSTRUCTION
#   [T24] Unknown host, no override: PLATFORM=unknown
#   [T24] Unknown host, no override: DETECTION_TYPE=user-override-only
#   [T24] Unknown host, no override: VERDICT=interactive
#   [T24] Unknown host, no override: safe-default EVIDENCE present
#   [T24] QRSPI_INTERACTION_MODE=auto: override verdict wins
#   [T24] QRSPI_INTERACTION_MODE=interactive: override verdict wins
#   [T24] Invalid QRSPI_INTERACTION_MODE: non-zero exit with diagnostics
#   [T24] Positional arguments: non-zero exit with diagnostics
#   [T24] stdout/stderr-only: no .interaction-mode-audit.json or other files created
#   [T24] Header: locked platform directory table present
#   [T24] Header: override chain present
#   [T24] Header: encapsulation rule present
#   [T24] Header: implementation-start verification citation block present
#   [T24] Grep regression: autopilot_mode literal absent from skills/ and agents/
#   [T24] Grep regression: autopilot context sentence absent from skills/ and agents/
#   [T24] Output-shape: every stdout line is KEY=VALUE
#   [T24] Output-shape: DETECTION_TYPE in allowed enum when present
#
# Test strategy:
#   All tests invoke the script via `run bash -c` subshells with explicit
#   env overrides so that the host's own COPILOT_CLI=1 does not bleed into
#   tests for other branches.  The script has no source-guard mode (it is not
#   sourced as a library) — tests always invoke it as a subprocess.
#
# bash 3.2 portable: no mapfile, no declare -A, no ${var,,}, no coproc.

bats_require_minimum_version 1.5.0

# ---------------------------------------------------------------------------
# Suite setup
# ---------------------------------------------------------------------------

setup_file() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd -P)"
  export REPO_ROOT
  SCRIPT="$REPO_ROOT/scripts/detect-interaction-mode.sh"
  export SCRIPT
}

# ===========================================================================
# COPILOT_CLI=1 branch
# ===========================================================================

@test "[T24] COPILOT_CLI=1 branch emits PLATFORM=copilot-cli" {
  run bash -c "
    unset CLAUDE_PROJECT_DIR QRSPI_INTERACTION_MODE
    export COPILOT_CLI=1
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^PLATFORM=copilot-cli$'
}

@test "[T24] COPILOT_CLI=1 branch emits DETECTION_TYPE=llm-context" {
  run bash -c "
    unset CLAUDE_PROJECT_DIR QRSPI_INTERACTION_MODE
    export COPILOT_CLI=1
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^DETECTION_TYPE=llm-context$'
}

@test "[T24] COPILOT_CLI=1 branch emits autopilot context-inspection INSTRUCTION" {
  # The INSTRUCTION must tell the orchestrator to inspect for the
  # <autopilot_mode> block and the sentinel sentence.
  run bash -c "
    unset CLAUDE_PROJECT_DIR QRSPI_INTERACTION_MODE
    export COPILOT_CLI=1
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  # INSTRUCTION line must mention autopilot_mode tag
  echo "$output" | grep -q '^INSTRUCTION=.*autopilot_mode'
  # INSTRUCTION line must mention the durable sentinel sentence
  echo "$output" | grep -q 'Autopilot mode is currently active'
}

# ===========================================================================
# Claude Code branch
# ===========================================================================

@test "[T24] Claude Code branch emits PLATFORM=claude-code" {
  run bash -c "
    unset COPILOT_CLI QRSPI_INTERACTION_MODE
    export CLAUDE_PROJECT_DIR='/some/project'
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^PLATFORM=claude-code$'
}

@test "[T24] Claude Code branch emits DETECTION_TYPE=llm-context" {
  run bash -c "
    unset COPILOT_CLI QRSPI_INTERACTION_MODE
    export CLAUDE_PROJECT_DIR='/some/project'
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^DETECTION_TYPE=llm-context$'
}

@test "[T24] Claude Code branch emits auto-mode context-inspection INSTRUCTION" {
  # The INSTRUCTION must tell the orchestrator to inspect for ## Auto Mode Active.
  run bash -c "
    unset COPILOT_CLI QRSPI_INTERACTION_MODE
    export CLAUDE_PROJECT_DIR='/some/project'
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^INSTRUCTION=.*Auto Mode Active'
}

# ===========================================================================
# Unknown host / no override
# ===========================================================================

@test "[T24] Unknown host (no COPILOT_CLI, no CLAUDE_PROJECT_DIR) emits PLATFORM=unknown" {
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR QRSPI_INTERACTION_MODE
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^PLATFORM=unknown$'
}

@test "[T24] Unknown host emits DETECTION_TYPE=user-override-only" {
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR QRSPI_INTERACTION_MODE
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^DETECTION_TYPE=user-override-only$'
}

@test "[T24] Unknown host emits VERDICT=interactive (safe default)" {
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR QRSPI_INTERACTION_MODE
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^VERDICT=interactive$'
}

@test "[T24] Unknown host emits EVIDENCE naming the safe default" {
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR QRSPI_INTERACTION_MODE
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  # EVIDENCE line must be present and must not be empty / placeholder
  echo "$output" | grep -q '^EVIDENCE=.'
}

# ===========================================================================
# QRSPI_INTERACTION_MODE override
# ===========================================================================

@test "[T24] QRSPI_INTERACTION_MODE=auto override: VERDICT=auto emitted" {
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR
    export QRSPI_INTERACTION_MODE=auto
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^VERDICT=auto$'
}

@test "[T24] QRSPI_INTERACTION_MODE=auto override: EVIDENCE names the override value" {
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR
    export QRSPI_INTERACTION_MODE=auto
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^EVIDENCE=.*QRSPI_INTERACTION_MODE.*auto'
}

@test "[T24] QRSPI_INTERACTION_MODE=interactive override: VERDICT=interactive emitted" {
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR
    export QRSPI_INTERACTION_MODE=interactive
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^VERDICT=interactive$'
}

@test "[T24] QRSPI_INTERACTION_MODE=interactive override: EVIDENCE names the override value" {
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR
    export QRSPI_INTERACTION_MODE=interactive
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^EVIDENCE=.*QRSPI_INTERACTION_MODE.*interactive'
}

# override path must emit DETECTION_TYPE=user-override-only
@test "[T24] QRSPI_INTERACTION_MODE=auto override (unknown host): emits DETECTION_TYPE=user-override-only" {
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR
    export QRSPI_INTERACTION_MODE=auto
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^DETECTION_TYPE=user-override-only$'
}

@test "[T24] QRSPI_INTERACTION_MODE=interactive override (unknown host): emits DETECTION_TYPE=user-override-only" {
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR
    export QRSPI_INTERACTION_MODE=interactive
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^DETECTION_TYPE=user-override-only$'
}

# override path must emit PLATFORM line with expected host token
@test "[T24] QRSPI_INTERACTION_MODE=auto override (Copilot CLI host): emits PLATFORM=copilot-cli" {
  run bash -c "
    export COPILOT_CLI=1
    unset CLAUDE_PROJECT_DIR
    export QRSPI_INTERACTION_MODE=auto
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^PLATFORM=copilot-cli$'
}

@test "[T24] QRSPI_INTERACTION_MODE=auto override (unknown host): emits PLATFORM=unknown" {
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR
    export QRSPI_INTERACTION_MODE=auto
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^PLATFORM=unknown$'
}

@test "[T24] QRSPI_INTERACTION_MODE=auto override (Claude Code host): emits PLATFORM=claude-code" {
  run bash -c "
    unset COPILOT_CLI
    export CLAUDE_PROJECT_DIR='/some/project'
    export QRSPI_INTERACTION_MODE=auto
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^PLATFORM=claude-code$'
  echo "$output" | grep -q '^VERDICT=auto$'
  # Must NOT emit DETECTION_TYPE=llm-context when override wins
  ! echo "$output" | grep -q '^DETECTION_TYPE=llm-context$'
  echo "$output" | grep -q '^DETECTION_TYPE=user-override-only$'
}

# output-shape test covering the override branch
@test "[T24] Output-shape: every stdout line from override branch (unknown host) is KEY=VALUE" {
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR
    export QRSPI_INTERACTION_MODE=auto
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  while IFS= read -r line; do
    [[ "$line" =~ ^[A-Z_]+=.+$ ]] || { echo "Bad line: $line"; return 1; }
  done <<< "$output"
}

@test "[T24] Output-shape: DETECTION_TYPE from override branch is in allowed enum" {
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR
    export QRSPI_INTERACTION_MODE=auto
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  local dt
  dt="$(echo "$output" | grep '^DETECTION_TYPE=' | cut -d= -f2)"
  [[ "$dt" == "shell-verdict" || "$dt" == "llm-context" || "$dt" == "user-override-only" ]]
}

# Override must win even on a recognized host (COPILOT_CLI=1)
@test "[T24] QRSPI_INTERACTION_MODE=auto override wins even on COPILOT_CLI=1 host" {
  run bash -c "
    export COPILOT_CLI=1
    export QRSPI_INTERACTION_MODE=auto
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^VERDICT=auto$'
  # Must NOT emit DETECTION_TYPE=llm-context when override wins
  ! echo "$output" | grep -q '^DETECTION_TYPE=llm-context$'
  echo "$output" | grep -q '^DETECTION_TYPE=user-override-only$'
}

# Interactive override must also win on a recognized host (COPILOT_CLI=1)
@test "QRSPI_INTERACTION_MODE=interactive override wins even on COPILOT_CLI=1 host" {
  run bash -c "
    export COPILOT_CLI=1
    unset CLAUDE_PROJECT_DIR
    export QRSPI_INTERACTION_MODE=interactive
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^PLATFORM=copilot-cli$'
  echo "$output" | grep -q '^VERDICT=interactive$'
  # Must NOT emit DETECTION_TYPE=llm-context when override wins
  ! echo "$output" | grep -q '^DETECTION_TYPE=llm-context$'
  echo "$output" | grep -q '^DETECTION_TYPE=user-override-only$'
  echo "$output" | grep -q '^EVIDENCE=.*QRSPI_INTERACTION_MODE.*interactive'
}

# Interactive override must also win on Claude Code host
@test "QRSPI_INTERACTION_MODE=interactive override (Claude Code host): emits PLATFORM=claude-code" {
  run bash -c "
    unset COPILOT_CLI
    export CLAUDE_PROJECT_DIR='/some/project'
    export QRSPI_INTERACTION_MODE=interactive
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^PLATFORM=claude-code$'
  echo "$output" | grep -q '^VERDICT=interactive$'
  # Must NOT emit DETECTION_TYPE=llm-context when override wins
  ! echo "$output" | grep -q '^DETECTION_TYPE=llm-context$'
  echo "$output" | grep -q '^DETECTION_TYPE=user-override-only$'
  echo "$output" | grep -q '^EVIDENCE=.*QRSPI_INTERACTION_MODE.*interactive'
}

# ===========================================================================
# Failure paths
# ===========================================================================

@test "[T24] Invalid QRSPI_INTERACTION_MODE exits non-zero" {
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR
    export QRSPI_INTERACTION_MODE=yolo
    bash \"$SCRIPT\"
  "
  [ "$status" -ne 0 ]
}

@test "[T24] Invalid QRSPI_INTERACTION_MODE emits diagnostics naming allowed values" {
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR
    export QRSPI_INTERACTION_MODE=yolo
    bash \"$SCRIPT\" 2>&1
  "
  [ "$status" -ne 0 ]
  # Diagnostic must name at least the two allowed values
  echo "$output" | grep -qi 'auto'
  echo "$output" | grep -qi 'interactive'
}

@test "[T24] Positional argument supplied: exits non-zero" {
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR QRSPI_INTERACTION_MODE
    bash \"$SCRIPT\" somearg
  "
  [ "$status" -ne 0 ]
}

@test "[T24] Positional argument supplied: emits usage diagnostics" {
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR QRSPI_INTERACTION_MODE
    bash \"$SCRIPT\" somearg 2>&1
  "
  [ "$status" -ne 0 ]
  # Diagnostic must mention usage or the script name
  echo "$output" | grep -qiE 'usage|no argument|detect-interaction-mode'
}

# ===========================================================================
# stdout/stderr-only — no files created
# ===========================================================================

@test "[T24] Copilot CLI branch creates no .interaction-mode-audit.json" {
  local tmpdir="$BATS_TEST_TMPDIR"
  run bash -c "
    export COPILOT_CLI=1
    unset CLAUDE_PROJECT_DIR QRSPI_INTERACTION_MODE
    cd \"$tmpdir\"
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  [ ! -f "$tmpdir/.interaction-mode-audit.json" ]
  # Also assert no unexpected regular files were created
  local n_files
  n_files="$(find "$tmpdir" -maxdepth 1 -type f | wc -l | tr -d ' ')"
  [ "$n_files" -eq 0 ]
}

@test "[T24] Unknown host branch creates no files at all" {
  local tmpdir="$BATS_TEST_TMPDIR"
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR QRSPI_INTERACTION_MODE
    cd \"$tmpdir\"
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  local n_files
  n_files="$(find "$tmpdir" -maxdepth 1 -type f | wc -l | tr -d ' ')"
  [ "$n_files" -eq 0 ]
}

# ===========================================================================
# Script header content
# ===========================================================================

@test "[T24] Header: locked platform directory table present" {
  # The header must contain the platform discriminator table per design.md I.7
  run grep -c 'Platform discriminator' "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

@test "[T24] Header: override chain documented" {
  # The header must contain the OVERRIDE CHAIN section anchor — unique to the header
  run grep -c 'OVERRIDE CHAIN' "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

@test "[T24] Header: encapsulation rule present" {
  # The header must state the encapsulation rule per design.md I.7 L679
  run grep -c 'Encapsulation rule' "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

@test "[T24] Header: implementation-start verification citation block present" {
  # The header must contain the verification citation block per design.md I.7
  # citing: host CLI version, observation method, observation date
  run grep -c 'Implementation-start verification\|verification citation\|observation method' "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

@test "[T24] Header: COPILOT_CLI_BINARY_VERSION or host version documented in citation" {
  # The citation block must name the verified CLI version (Iron Law)
  run grep -cE 'v1\.0\.57|COPILOT_CLI_BINARY_VERSION|1\.0\.57-1' "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

# ===========================================================================
# Grep regression: host-specific literals only in allowed files
# ===========================================================================

@test "[T24] Grep regression: <autopilot_mode> literal absent from skills/ dir" {
  # autopilot_mode is a Copilot-CLI-specific signal injected by the CLI at runtime.
  # It must NOT appear in any skills/ file — only in scripts/detect-interaction-mode.sh
  # and its test fixture.
  [ -d "$REPO_ROOT/skills" ]
  run grep -rl 'autopilot_mode' "$REPO_ROOT/skills"
  # grep -rl exits 1 (no matches) when absent — that's the passing state; exit 2 is an error
  [ "$status" -eq 1 ]
}

@test "[T24] Grep regression: <autopilot_mode> literal absent from agents/ dir" {
  [ -d "$REPO_ROOT/agents" ]
  run grep -rl 'autopilot_mode' "$REPO_ROOT/agents"
  [ "$status" -eq 1 ]
}

@test "[T24] Grep regression: 'Autopilot mode is currently active' sentence absent from skills/" {
  [ -d "$REPO_ROOT/skills" ]
  run grep -rl 'Autopilot mode is currently active' "$REPO_ROOT/skills"
  [ "$status" -eq 1 ]
}

@test "[T24] Grep regression: 'Autopilot mode is currently active' sentence absent from agents/" {
  [ -d "$REPO_ROOT/agents" ]
  run grep -rl 'Autopilot mode is currently active' "$REPO_ROOT/agents"
  [ "$status" -eq 1 ]
}

# ===========================================================================
# Output-shape: every stdout line is KEY=VALUE; DETECTION_TYPE in enum
# ===========================================================================

@test "[T24] Output-shape: every stdout line from COPILOT_CLI=1 branch is KEY=VALUE" {
  run bash -c "
    unset CLAUDE_PROJECT_DIR QRSPI_INTERACTION_MODE
    export COPILOT_CLI=1
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  # Every line must match ^[A-Z_]+=.+$  (KEY=value, non-empty value)
  while IFS= read -r line; do
    [[ "$line" =~ ^[A-Z_]+=.+$ ]] || { echo "Bad line: $line"; return 1; }
  done <<< "$output"
}

@test "[T24] Output-shape: every stdout line from unknown branch is KEY=VALUE" {
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR QRSPI_INTERACTION_MODE
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  while IFS= read -r line; do
    [[ "$line" =~ ^[A-Z_]+=.+$ ]] || { echo "Bad line: $line"; return 1; }
  done <<< "$output"
}

@test "[T24] Output-shape: DETECTION_TYPE value is in allowed enum (llm-context or user-override-only)" {
  # Test both recognized branches; both must emit a valid DETECTION_TYPE
  # Copilot CLI → llm-context
  run bash -c "
    unset CLAUDE_PROJECT_DIR QRSPI_INTERACTION_MODE
    export COPILOT_CLI=1
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  local dt
  dt="$(echo "$output" | grep '^DETECTION_TYPE=' | cut -d= -f2)"
  [[ "$dt" == "shell-verdict" || "$dt" == "llm-context" || "$dt" == "user-override-only" ]]

  # Unknown host → user-override-only
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR QRSPI_INTERACTION_MODE
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  dt="$(echo "$output" | grep '^DETECTION_TYPE=' | cut -d= -f2)"
  [[ "$dt" == "shell-verdict" || "$dt" == "llm-context" || "$dt" == "user-override-only" ]]
}

@test "[T24] Output-shape: no placeholder values in stdout (no bare <name> sentinel or TODO tokens)" {
  run bash -c "
    unset CLAUDE_PROJECT_DIR QRSPI_INTERACTION_MODE
    export COPILOT_CLI=1
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  # No line should have its ENTIRE value be a placeholder token like <name> or <signal>.
  # Pattern: KEY=<word>  where the value IS the placeholder (not contains it).
  # This avoids false-positives from legitimate tag literals in INSTRUCTION prose.
  ! echo "$output" | grep -qE '^[A-Z_]+=<[a-z][a-z_-]*>$'
  # Also no TODO or PLACEHOLDER tokens
  ! echo "$output" | grep -qE 'TODO|PLACEHOLDER'
}

# ===========================================================================
# Grep regression: '## Auto Mode Active' absent from agents/ dir
# ===========================================================================

@test "Grep regression: '## Auto Mode Active' Claude Code signal absent from agents/ dir" {
  # ## Auto Mode Active is the Claude Code in-context auto-mode signal.
  # It must NOT appear in any agents/ file — only in scripts/detect-interaction-mode.sh
  # and its test fixture (tests/unit/test-detect-interaction-mode.bats).
  # Note: skills/ is intentionally excluded here because the string already
  # legitimately appears in skills/goals/SKILL.md and skills/design/SKILL.md as
  # documented precedent; a skills/ check would produce a false failure.
  [ -d "$REPO_ROOT/agents" ]
  run grep -rl '## Auto Mode Active' "$REPO_ROOT/agents"
  # grep -rl exits 1 (no matches) when absent — that is the passing state.
  # Do NOT use -ne 0; exit 2 (grep error) would also pass that check.
  [ "$status" -eq 1 ]
}

# ===========================================================================
# Output-shape: Claude Code branch stdout is KEY=VALUE
# ===========================================================================

@test "Output-shape: every stdout line from Claude Code branch is KEY=VALUE" {
  run bash -c "
    unset COPILOT_CLI QRSPI_INTERACTION_MODE
    export CLAUDE_PROJECT_DIR='/some/project'
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  # Every line must match ^[A-Z_]+=.+$  (KEY=value, non-empty value)
  while IFS= read -r line; do
    [[ "$line" =~ ^[A-Z_]+=.+$ ]] || { echo "Bad line: $line"; return 1; }
  done <<< "$output"
}

# ===========================================================================
# Native-detection precedence: COPILOT_CLI wins over CLAUDE_PROJECT_DIR
# ===========================================================================

@test "Native-detection precedence: COPILOT_CLI=1 wins over CLAUDE_PROJECT_DIR when no override" {
  # With both host signals present and no QRSPI_INTERACTION_MODE override,
  # the if-elif chain must resolve to COPILOT_CLI first (top of chain).
  run bash -c "
    unset QRSPI_INTERACTION_MODE
    export COPILOT_CLI=1
    export CLAUDE_PROJECT_DIR='/some/project'
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  # Must be the Copilot CLI platform
  echo "$output" | grep -q '^PLATFORM=copilot-cli$'
  # Must be llm-context (Copilot CLI shape)
  echo "$output" | grep -q '^DETECTION_TYPE=llm-context$'
  # Must NOT emit claude-code platform
  ! echo "$output" | grep -q '^PLATFORM=claude-code$'
}

# ===========================================================================
# Semantic EVIDENCE assertion for the unknown-host safe-default
# ===========================================================================

@test "Unknown host safe-default EVIDENCE contains semantic safe-default content" {
  # The script emits:
  #   EVIDENCE=no host signal; QRSPI_INTERACTION_MODE absent; safe default applied
  # Verify the semantic content rather than just non-empty presence.
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR QRSPI_INTERACTION_MODE
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  # Must name the safe-default outcome
  echo "$output" | grep -q '^EVIDENCE=.*safe default'
  # Must also name the absence of the override variable
  echo "$output" | grep -q '^EVIDENCE=.*QRSPI_INTERACTION_MODE'
}

# ===========================================================================
# No-file-write assertion for the Claude Code branch
# ===========================================================================

@test "Claude Code branch creates no files at all" {
  local tmpdir="$BATS_TEST_TMPDIR"
  run bash -c "
    unset COPILOT_CLI QRSPI_INTERACTION_MODE
    export CLAUDE_PROJECT_DIR='/some/project'
    cd \"$tmpdir\"
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  # No regular files should have been created in the working directory
  local n_files
  n_files="$(find "$tmpdir" -maxdepth 1 -type f | wc -l | tr -d ' ')"
  [ "$n_files" -eq 0 ]
}

# ===========================================================================
# No-file-write assertion for the override branch
# ===========================================================================

@test "Override branch creates no files at all" {
  local tmpdir="$BATS_TEST_TMPDIR"
  run bash -c "
    unset COPILOT_CLI CLAUDE_PROJECT_DIR
    export QRSPI_INTERACTION_MODE=auto
    cd \"$tmpdir\"
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  # No regular files should have been created in the working directory
  local n_files
  n_files="$(find "$tmpdir" -maxdepth 1 -type f | wc -l | tr -d ' ')"
  [ "$n_files" -eq 0 ]
}
