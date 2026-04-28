#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Contract tests for hooks/session-start.
#
# Per integration-round-01 fix task-30 (R2 I-N2): the SessionStart hook's
# actual behavior must match its documented contract. The hook does NOT
# initialize state or validate artifacts — that is skill-driven via
# state_init_or_reconcile (Goals on first invocation, other skills via
# PostToolUse). These tests lock that contract by verifying the hook's
# header is canonical and that the hook neither sources state.sh nor calls
# state_init_or_reconcile.
#
# task-33 (using-qrspi/SKILL.md docs) consumes this contract; do not change
# the assertions here without coordinating that downstream change.

setup() {
  export PLUGIN_ROOT
  PLUGIN_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  export HOOK="$PLUGIN_ROOT/hooks/session-start"
}

# ──────────────────────────────────────────────────────────────
# Canonical contract: header explicitly states the hook is the
# canonical SessionStart contract and does NOT initialize state.
# ──────────────────────────────────────────────────────────────
@test "session-start header marks itself the canonical SessionStart contract" {
  [ -f "$HOOK" ]
  run grep -F 'Canonical SessionStart contract' "$HOOK"
  [ "$status" -eq 0 ]
}

@test "session-start header explicitly disclaims state initialization" {
  run grep -F 'does NOT initialize state or validate artifacts' "$HOOK"
  [ "$status" -eq 0 ]
}

@test "session-start header attributes state bootstrap to skills" {
  run grep -F 'state_init_or_reconcile' "$HOOK"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────
# Behavior parity: the hook MUST NOT source state.sh or invoke
# state_init_or_reconcile. Reality must match the docs we are
# locking in.
# ──────────────────────────────────────────────────────────────
@test "session-start does not source state.sh" {
  run grep -E '(source|\.)[[:space:]]+.*state\.sh' "$HOOK"
  [ "$status" -ne 0 ]
}

@test "session-start does not invoke state_init_or_reconcile" {
  # Mention in the header comment is fine; an actual invocation is not.
  # Strip comment lines, then check that no executable line invokes it.
  local code_only
  code_only=$(grep -v '^[[:space:]]*#' "$HOOK" || true)
  run grep -E 'state_init_or_reconcile' <<< "$code_only"
  [ "$status" -ne 0 ]
}

# ──────────────────────────────────────────────────────────────
# No regression: the hook still injects using-qrspi/SKILL.md as
# additionalContext (Claude Code) / additional_context (Cursor).
# ──────────────────────────────────────────────────────────────
@test "session-start reads using-qrspi/SKILL.md" {
  run grep -F 'skills/using-qrspi/SKILL.md' "$HOOK"
  [ "$status" -eq 0 ]
}

@test "session-start emits hookSpecificOutput.additionalContext for Claude Code" {
  run grep -F 'additionalContext' "$HOOK"
  [ "$status" -eq 0 ]
}

@test "session-start emits additional_context for Cursor" {
  run grep -F 'additional_context' "$HOOK"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────
# Smoke: hook executes successfully with CLAUDE_PLUGIN_ROOT and
# emits valid JSON containing the using-qrspi marker.
# ──────────────────────────────────────────────────────────────
@test "session-start runs and emits valid JSON with using-qrspi content" {
  run env CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" CURSOR_PLUGIN_ROOT= "$HOOK"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null
  [ "$?" -eq 0 ]
  echo "$output" | jq -r '.hookSpecificOutput.additionalContext' | grep -qF 'qrspi:using-qrspi'
}
