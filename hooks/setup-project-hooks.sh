#!/usr/bin/env bash
set -euo pipefail

# setup-project-hooks.sh
# TEMPORARY WORKAROUND for Claude Code bug #17688: plugin-level hooks
# (registered in hooks.json) may not fire for subagent tool calls. This
# script copies hook registrations into a project's .claude/settings.json
# where they fire for all tool calls including subagents.
#
# WHY THIS EXISTS:
#   Plugin hooks should fire for all agents in the session (main + subagents).
#   Bug #17688 causes them to only fire for the main session. This script
#   works around the bug by duplicating the registrations at project level.
#
# WHEN TO REMOVE:
#   Once bug #17688 is confirmed fixed, this script is no longer needed.
#   To verify: run a QRSPI pipeline with enforcement hooks registered ONLY
#   at plugin level (hooks.json), dispatch a worktree subagent, and confirm
#   PreToolUse blocks fire for the subagent's tool calls. If they do, the
#   bug is fixed and this script can be deleted.
#
# CLEANUP AFTER REMOVAL:
#   Projects that ran this script have QRSPI hooks hardcoded in their
#   .claude/settings.json. To clean up: run this script's remove_qrspi
#   jq function on the project's settings, or manually delete the
#   PreToolUse/PostToolUse entries whose commands contain the QRSPI
#   plugin path. The idempotent merge logic means leftover entries
#   won't conflict — they'll just be orphaned command paths.
#
# KNOWN LIMITATION:
#   The project settings get hardcoded absolute paths to the plugin
#   install location (e.g., ~/.claude/plugins/cache/qrspi-local/...).
#   If the plugin version changes or the cache path moves, re-run this
#   script to update the paths. Plugin-level hooks use ${CLAUDE_PLUGIN_ROOT}
#   which is expanded by Claude Code at runtime — project-level hooks
#   don't support this variable, hence the hardcoded paths.
#
# Usage: setup-project-hooks.sh [PROJECT_DIR]
#   PROJECT_DIR  target project directory (default: $PWD)

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_JSON="$PLUGIN_ROOT/hooks/hooks.json"

# Exit 1 if hooks.json is missing
if [[ ! -f "$HOOKS_JSON" ]]; then
  echo "ERROR: hooks.json not found at $HOOKS_JSON" >&2
  exit 1
fi

TARGET_DIR="${1:-$PWD}"
SETTINGS_DIR="$TARGET_DIR/.claude"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

# Ensure .claude directory exists
mkdir -p "$SETTINGS_DIR"

# Read PreToolUse and PostToolUse from hooks.json, replacing ${CLAUDE_PLUGIN_ROOT}
# with the actual absolute PLUGIN_ROOT path
QRSPI_PRE=$(jq --arg root "$PLUGIN_ROOT" \
  '[.hooks.PreToolUse[] | .hooks[].command |= gsub("\\$\\{CLAUDE_PLUGIN_ROOT\\}"; $root) | .]' \
  "$HOOKS_JSON")

QRSPI_POST=$(jq --arg root "$PLUGIN_ROOT" \
  '[.hooks.PostToolUse[] | .hooks[].command |= gsub("\\$\\{CLAUDE_PLUGIN_ROOT\\}"; $root) | .]' \
  "$HOOKS_JSON")

# Build or load the current settings JSON
if [[ -f "$SETTINGS_FILE" ]]; then
  CURRENT=$(jq '.' "$SETTINGS_FILE")
else
  CURRENT='{}'
fi

# Merge QRSPI hooks idempotently:
#   For each event type (PreToolUse, PostToolUse):
#     - Remove any existing entries whose command contains the PLUGIN_ROOT path
#       (so re-running replaces rather than duplicates)
#     - Append the QRSPI entries
MERGED=$(jq \
  --arg root "$PLUGIN_ROOT" \
  --argjson qrspi_pre "$QRSPI_PRE" \
  --argjson qrspi_post "$QRSPI_POST" \
  '
  # Helper: remove existing QRSPI entries from an array based on plugin root
  def remove_qrspi(root):
    if . == null then [] else
      map(select(
        (.hooks // []) | map(.command // "") | map(test(root; "g")) | any | not
      ))
    end;

  # Merge PreToolUse
  .hooks.PreToolUse = ((.hooks.PreToolUse // []) | remove_qrspi($root)) + $qrspi_pre |

  # Merge PostToolUse
  .hooks.PostToolUse = ((.hooks.PostToolUse // []) | remove_qrspi($root)) + $qrspi_post
  ' \
  <<< "$CURRENT")

# Write result atomically: write to temp file first, then rename.
# mv is atomic on POSIX — prevents a crash mid-write from leaving
# a half-written settings.json that would break Claude Code.
TMP_FILE=$(mktemp "$SETTINGS_DIR/.settings.json.XXXXXX")
printf '%s\n' "$MERGED" | jq '.' > "$TMP_FILE"
mv "$TMP_FILE" "$SETTINGS_FILE"

echo "QRSPI hooks written to $SETTINGS_FILE (PreToolUse: $(jq '.hooks.PreToolUse | length' "$SETTINGS_FILE"), PostToolUse: $(jq '.hooks.PostToolUse | length' "$SETTINGS_FILE"))"
