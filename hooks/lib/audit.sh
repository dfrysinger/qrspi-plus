#!/usr/bin/env bash
set -euo pipefail

# NOTE: Unlike other hooks/lib/ files (which are self-contained per the
# structural rule enforced in test-worktree.bats), audit.sh sources worktree.sh
# and bash-detect.sh because it needs slug extraction and Bash write detection
# for target-based artifact_dir resolution. Hooks that source audit.sh
# transitively get these libraries — this is intentional.

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

# _audit_find_repo_root [start_dir]
#
# Walks up from start_dir (default: $PWD) looking for a directory that
# contains `.qrspi/state.json`. Echoes the directory's absolute path on
# success, returns 1 if no ancestor matches before reaching `/`.
#
# Symlink hardening (L-sec-2 / CWE-59): the [[ -f ]] test alone follows
# symlinks. An attacker plant of `<some-ancestor>/.qrspi -> <victim>/.qrspi`
# (or a symlinked `state.json`) would otherwise let this walker return the
# wrong repo root, crossing a confidentiality/integrity boundary between
# concurrent QRSPI workspaces on the same host. We require BOTH `.qrspi`
# AND `.qrspi/state.json` to be non-symlinks (lstat semantics via `[[ ! -L ]]`)
# at every ancestor we accept.
_audit_find_repo_root() {
  local dir="${1:-$PWD}"
  # Resolve to an absolute path without requiring readlink -f (BSD/macOS lacks it).
  if [[ "$dir" != /* ]]; then
    dir="$(cd "$dir" 2>/dev/null && pwd)" || return 1
  fi
  while [[ -n "$dir" && "$dir" != "/" ]]; do
    if [[ -f "$dir/.qrspi/state.json" \
          && ! -L "$dir/.qrspi" \
          && ! -L "$dir/.qrspi/state.json" ]]; then
      echo "$dir"
      return 0
    fi
    dir="${dir%/*}"
    [[ -z "$dir" ]] && dir="/"
  done
  return 1
}

# _audit_resolve_artifact_dir_from_state [start_dir]
#
# State.json fallback: walks up from start_dir to find <repo>/.qrspi/state.json,
# reads `artifact_dir` from it, and echoes the absolute path on success.
# Returns 1 if state.json is not found, unreadable, or has no artifact_dir.
_audit_resolve_artifact_dir_from_state() {
  local start="${1:-$PWD}"
  local repo_root
  repo_root=$(_audit_find_repo_root "$start") || return 1

  local artifact_dir
  artifact_dir=$(jq -r '.artifact_dir // empty' "$repo_root/.qrspi/state.json" 2>/dev/null) || return 1
  [[ -z "$artifact_dir" ]] && return 1
  echo "$artifact_dir"
}

# _audit_resolve_target_to_artifact_dir <target_path>
#
# Internal helper. Given an absolute target file path, returns the artifact_dir
# path on stdout if the target is in QRSPI scope (worktree or artifact-dir),
# else returns 1.
#
# Resolution order:
#   1. If target is inside a worktree: try local-glob via slug, then fall back
#      to state.json (walking up from PWD) when the glob fails (the worktree-
#      CWD case where docs/qrspi/ is not visible relative to PWD).
#   2. If target is inside the local artifact-dir tree (PWD/docs/qrspi/...):
#      use the directory directly.
#   3. Otherwise return 1.
_audit_resolve_target_to_artifact_dir() {
  local target="$1"
  [[ -z "$target" ]] && return 1

  # Case 1: target inside a worktree
  local slug
  if slug=$(worktree_extract_slug "$target" 2>/dev/null); then
    local resolved
    if resolved=$(audit_resolve_artifact_dir "$slug" 2>/dev/null); then
      echo "$resolved"
      return 0
    fi
    # Fallback: read artifact_dir from state.json (walk up from PWD).
    if resolved=$(_audit_resolve_artifact_dir_from_state "$PWD" 2>/dev/null); then
      echo "$resolved"
      return 0
    fi
    return 1
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

# _audit_target_is_qrspi_scope <target_path>
#
# Returns 0 if target appears in-scope for QRSPI auditing (a worktree path),
# 1 otherwise. Used by audit_log_event to decide whether a resolution failure
# should orphan-log (in scope) or silently skip (out of scope).
_audit_target_is_qrspi_scope() {
  local target="$1"
  [[ -z "$target" ]] && return 1
  worktree_extract_slug "$target" >/dev/null 2>&1
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

  # Resolve target → artifact_dir.
  # If resolution fails AND the target is in QRSPI scope (a worktree path),
  # write an orphan row to <repo_root>/.qrspi/audit-orphan.jsonl and return
  # non-zero so the caller knows the canonical path failed (S-N3 fix:
  # never silently drop subagent enforcement events).
  # If the target is out of QRSPI scope, silently skip with return 0 (no
  # audit pollution from non-QRSPI work).
  local resolution_failed=0
  if ! artifact_dir=$(_audit_resolve_target_to_artifact_dir "$target" 2>/dev/null); then
    if _audit_target_is_qrspi_scope "$target"; then
      resolution_failed=1
    else
      return 0
    fi
  fi

  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

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

  if (( resolution_failed )); then
    # Orphan path: best-effort find a parent repo to anchor the orphan log.
    # If no repo root can be found (no .qrspi/state.json upstream), fall back
    # to anchoring at the worktree's nearest plausible repo root (the segment
    # before `/.worktrees/`).
    local orphan_root
    if ! orphan_root=$(_audit_find_repo_root "$PWD" 2>/dev/null); then
      # Derive from target: strip from /.worktrees/ onward.
      if [[ "$target" == *"/.worktrees/"* ]]; then
        orphan_root="${target%%/.worktrees/*}"
      else
        # Last resort: PWD itself.
        orphan_root="$PWD"
      fi
    fi
    mkdir -p "$orphan_root/.qrspi" 2>/dev/null || return 1
    printf '%s\n' "$line" >> "$orphan_root/.qrspi/audit-orphan.jsonl" || return 1
    return 1
  fi

  # Symlink hardening (S-3 / task-29 audit-path lockdown). Mirror the contract
  # in scripts/codex-companion-bg.sh:
  #   1. Canonicalize artifact_dir via realpath so any symlink in the ancestor
  #      chain is resolved before we construct the audit path.
  #   2. Refuse if <artifact_dir>/.qrspi is itself a symlink (an attacker
  #      could redirect every audit append into a sibling workspace).
  #   3. Refuse if <artifact_dir>/.qrspi/audit.jsonl is a symlink before the
  #      `>>` append (a naive append would dereference and corrupt the target).
  # Each check fails closed (return 1, stderr diagnostic) — never silently
  # follow.
  local canon_artifact_dir
  if ! canon_artifact_dir=$(realpath "$artifact_dir" 2>/dev/null) \
       || [[ -z "$canon_artifact_dir" ]]; then
    printf 'audit.sh: realpath failed for artifact_dir %s; refusing to write audit row\n' \
      "$artifact_dir" >&2
    return 1
  fi

  local qrspi_dir="$canon_artifact_dir/.qrspi"
  if [[ -L "$qrspi_dir" ]]; then
    printf 'audit.sh: %s is a symlink; refusing to follow (path-injection guard)\n' \
      "$qrspi_dir" >&2
    return 1
  fi

  mkdir -p "$qrspi_dir"
  local audit_file="$qrspi_dir/audit.jsonl"

  if [[ -L "$audit_file" ]]; then
    printf 'audit.sh: %s is a symlink; refusing to follow (path-injection guard)\n' \
      "$audit_file" >&2
    return 1
  fi

  printf '%s\n' "$line" >> "$audit_file"
}
