#!/usr/bin/env bash
set -euo pipefail

# Source worktree.sh for slug extraction
_audit_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$_audit_script_dir/worktree.sh"
source "$_audit_script_dir/bash-detect.sh"

# audit_resolve_artifact_dir <slug>
#
# Globs `docs/qrspi/*-{slug}/` relative to PWD. Echoes the absolute path of
# the single match on stdout and returns 0. If 0 or 2+ matches, returns 1
# without printing.
audit_resolve_artifact_dir() {
  local slug="$1"
  [[ -z "$slug" ]] && return 1

  local matches=()
  local d
  shopt -s nullglob
  for d in docs/qrspi/*-"$slug"/; do
    matches+=("${d%/}")
  done
  shopt -u nullglob

  if [[ ${#matches[@]} -ne 1 ]]; then
    return 1
  fi

  (cd "${matches[0]}" && pwd)
}

# _audit_resolve_target_to_artifact_dir <target_path>
#
# Internal helper. Given an absolute target file path, returns the artifact_dir
# path on stdout if the target is in QRSPI scope (worktree or artifact-dir),
# else returns 1.
_audit_resolve_target_to_artifact_dir() {
  local target="$1"
  [[ -z "$target" ]] && return 1

  # Case 1: target inside a worktree
  local slug
  if slug=$(worktree_extract_slug "$target" 2>/dev/null); then
    audit_resolve_artifact_dir "$slug"
    return $?
  fi

  # Case 2: target inside an artifact dir directly
  local artifact_root
  artifact_root="$(pwd)/docs/qrspi/"
  if [[ "$target" == "$artifact_root"* ]]; then
    # Strip everything after the date-slug segment to get the artifact_dir
    local rest="${target#"$artifact_root"}"
    local first_seg="${rest%%/*}"
    if [[ -n "$first_seg" && -d "$artifact_root$first_seg" ]]; then
      echo "$artifact_root$first_seg"
      return 0
    fi
  fi

  return 1
}

# audit_log_event <envelope_json> <outcome> <reason>
#
# Appends a JSON line to <artifact_dir>/.qrspi/audit.jsonl when the operation
# targets a path inside QRSPI scope (a worktree or an artifact dir). For
# operations targeting paths outside QRSPI scope, returns 0 silently — no
# audit log pollution from non-QRSPI work.
#
# Schema (one JSONL line per call):
#   {
#     "ts": "<ISO 8601 UTC>",
#     "agent_id": "<string>" | null,
#     "agent_type": "<string>" | null,
#     "tool": "Edit" | "Write" | "NotebookEdit" | "Bash",
#     "target": "<absolute path>" | null,
#     "command": "<full bash command>" | null,
#     "outcome": "allow" | "block",
#     "reason": "<string>" | null
#   }
#
# Arguments:
#   envelope_json - The full hook stdin JSON
#   outcome       - "allow" or "block"
#   reason        - Block reason string (use "" for allow)
audit_log_event() {
  local envelope_json="$1"
  local outcome="$2"
  local reason="$3"

  local agent_id agent_type tool file_path command target ts artifact_dir

  agent_id=$(printf '%s' "$envelope_json" | jq -r '.agent_id // empty' 2>/dev/null) || agent_id=""
  agent_type=$(printf '%s' "$envelope_json" | jq -r '.agent_type // empty' 2>/dev/null) || agent_type=""
  tool=$(printf '%s' "$envelope_json" | jq -r '.tool_name // empty' 2>/dev/null) || tool=""
  file_path=$(printf '%s' "$envelope_json" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || file_path=""
  command=$(printf '%s' "$envelope_json" | jq -r '.tool_input.command // empty' 2>/dev/null) || command=""

  # Determine target: file_path for Write/Edit/NotebookEdit; first detected write for Bash
  target=""
  case "$tool" in
    Write|Edit|NotebookEdit)
      target="$file_path"
      ;;
    Bash)
      if [[ -n "$command" ]]; then
        local detected
        detected=$(bash_detect_file_writes "$command" 2>/dev/null) || detected=""
        if [[ -n "$detected" ]]; then
          target=$(printf '%s' "$detected" | head -n1)
          # Resolve relative to PWD if not absolute
          if [[ -n "$target" && "$target" != /* ]]; then
            target="$PWD/$target"
          fi
        fi
      fi
      ;;
  esac

  [[ -z "$target" ]] && return 0

  # Resolve target → artifact_dir; silent skip if not in QRSPI scope
  artifact_dir=$(_audit_resolve_target_to_artifact_dir "$target" 2>/dev/null) || return 0

  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  mkdir -p "$artifact_dir/.qrspi"
  local audit_file="$artifact_dir/.qrspi/audit.jsonl"

  local line
  line=$(jq -cn \
    --arg ts "$ts" \
    --arg agent_id "$agent_id" \
    --arg agent_type "$agent_type" \
    --arg tool "$tool" \
    --arg target "$target" \
    --arg command "$command" \
    --arg outcome "$outcome" \
    --arg reason "$reason" \
    '{
      ts: $ts,
      agent_id: (if $agent_id == "" then null else $agent_id end),
      agent_type: (if $agent_type == "" then null else $agent_type end),
      tool: $tool,
      target: $target,
      command: (if $command == "" then null else $command end),
      outcome: $outcome,
      reason: (if $reason == "" then null else $reason end)
    }') || return 1

  printf '%s\n' "$line" >> "$audit_file"
}
