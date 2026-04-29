#!/usr/bin/env bash
set -euo pipefail

# Source pipeline.sh from the same directory (transitively sources artifact-map.sh)
_artifact_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$_artifact_script_dir/pipeline.sh"

# ARTIFACT_FILES — array of 6 known artifact paths (built from canonical map)
ARTIFACT_FILES=()
for _af_step in goals questions research design structure plan; do
  ARTIFACT_FILES+=("$(artifact_map_get "$_af_step")")
done
unset _af_step

# artifact_is_known <file_path> <artifact_dir>
# Checks if file_path matches a known artifact by comparing path suffix.
# Returns 0 with step name on stdout if matched (goals, questions, research, design, structure, plan).
# Returns 1 if not a known artifact.
artifact_is_known() {
  local file_path="$1"
  local artifact_dir="$2"

  # Resolve artifact_dir to absolute path
  artifact_dir=$(cd "$artifact_dir" 2>/dev/null && pwd) || return 1

  # Resolve file_path to absolute path if possible
  local abs_file_path
  if [[ "$file_path" =~ ^/ ]]; then
    abs_file_path="$file_path"
  else
    abs_file_path="$(cd "$(dirname "$file_path")" 2>/dev/null && pwd)/$(basename "$file_path")" || return 1
  fi

  # Check if file_path is under artifact_dir (require exact prefix + /)
  # Without the trailing slash check, /path/to/artifacts-evil/goals.md
  # would falsely match /path/to/artifacts as a prefix.
  if [[ "$abs_file_path" != "$artifact_dir/"* ]]; then
    return 1
  fi

  # Strip artifact_dir prefix to get relative path
  local rel_path="${abs_file_path#"$artifact_dir/"}"

  # Map known artifacts to step names via canonical lookup
  artifact_map_get_step "$rel_path" || return 1
}

# artifact_sync_state <file_path> <artifact_dir> [--skip-cascade]
# Called after a known artifact is written:
# - Reads frontmatter status via frontmatter_get
# - If status: approved → update state.json artifacts map to set that step = "approved"
# - If status: draft → call pipeline_cascade_reset to reset that step and all downstream
#   (with --skip-cascade: resets only that step, leaves downstream untouched)
# - For design.md specifically: also read wireframe_requested field and sync to state.json
# Rejects unknown flags with return 1.
artifact_sync_state() {
  local file_path="$1"
  local artifact_dir="$2"
  shift 2

  # Parse optional flags
  local cascade_flag=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skip-cascade) cascade_flag="--skip-cascade"; shift ;;
      *)
        echo "artifact_sync_state: unknown flag '$1'" >&2
        return 1
        ;;
    esac
  done

  # Get the step name for this artifact
  local step
  step=$(artifact_is_known "$file_path" "$artifact_dir") || return 1

  # Read frontmatter status
  local fm_status
  fm_status=$(frontmatter_get "$file_path" "status") || return 1
  # frontmatter_get returns exit 0 with empty string when field is absent;
  # treat that like the old frontmatter_get_status behavior (return 1)
  [[ -n "$fm_status" ]] || return 1

  # Apply state changes via state_update (locked R-M-W primitive — the
  # previous state_read + state_write_atomic pattern held the lock only
  # over the final write, leaving an open R-M-W window against concurrent
  # state_update writers (e.g., Plan's narrow direct write of
  # phase_start_commit). state_update serializes the full critical
  # section and binds untrusted values via --arg/--argjson so the jq
  # filter stays a static expression.
  case "$fm_status" in
    approved)
      # Set this step's artifact status to approved AND recompute
      # current_step in the same atomic write. The recompute reads
      # frontmatter from disk via state_compute_current_step; the
      # on-disk status was just promoted to approved (caller wrote it
      # before invoking artifact_sync_state), so the recompute sees the
      # post-promotion value. Combining both patches into one filter
      # ensures readers never observe (artifacts advanced, current_step
      # stale).
      local new_cs
      new_cs=$(state_compute_current_step "$artifact_dir") || return 1
      state_update '.artifacts[$step] = "approved" | .current_step = $cs' \
        --arg step "$step" --arg cs "$new_cs" \
        --artifact-dir "$artifact_dir" || return 1
      ;;
    draft)
      # Cascade reset from this step onwards (pass --skip-cascade if set).
      # pipeline_cascade_reset itself uses state_update internally, so the
      # cascade also runs under the same lock primitive.
      if [[ -n "$cascade_flag" ]]; then
        pipeline_cascade_reset "$step" "$artifact_dir" "$cascade_flag" || return 1
      else
        pipeline_cascade_reset "$step" "$artifact_dir" || return 1
      fi
      ;;
  esac

  # For design.md specifically: sync wireframe_requested field
  if [[ "$step" == "design" ]]; then
    local wireframe_str_value
    wireframe_str_value=$(frontmatter_get "$file_path" "wireframe_requested") || {
      local _ec=$?
      if [[ $_ec -eq 1 ]]; then
        echo "artifact_sync_state: WARNING: design.md not found at ${file_path} — treating wireframe_requested as false" >&2
      fi
      wireframe_str_value="false"
    }
    # Default to "false" when field is absent (frontmatter_get returns empty)
    wireframe_str_value="${wireframe_str_value:-false}"

    # Convert string to JSON boolean value
    local wireframe_json_value="false"
    if [[ "$wireframe_str_value" == "true" ]]; then
      wireframe_json_value="true"
    fi

    # Bind the boolean via --argjson (typed JSON) so the filter stays
    # static — caller-side jq-filter interpolation is forbidden.
    state_update '.wireframe_requested = $w' \
      --argjson w "$wireframe_json_value" \
      --artifact-dir "$artifact_dir" || return 1
  fi
}

# artifact_snapshot_phase <artifact_dir> <phase_number>
# Creates a read-only snapshot of the current phase's artifacts.
# Copies core artifacts (including Phasing-owned phasing.md, roadmap.md, and
# the four future-*.md artifacts) and task files; excludes reviews/,
# fixes/, feedback/, phases/, config.md, .qrspi/.
# Phasing-owned artifacts:
#   - phasing.md, roadmap.md (Phasing OWNS — see skills/phasing/SKILL.md)
#   - future-goals.md, future-questions.md, future-research-summary.md,
#     future-design.md (Phasing OWNS — pruning artifacts)
# Returns 0 on success, 1 if artifact_dir doesn't exist or copy fails.
artifact_snapshot_phase() {
  local artifact_dir="$1"
  local phase_number="$2"

  # Validate artifact_dir exists
  [[ -d "$artifact_dir" ]] || return 1

  # Build zero-padded phase directory name
  local phase_label
  phase_label="phase-$(printf '%02d' "$phase_number")"
  local snapshot_dir="$artifact_dir/phases/$phase_label"

  mkdir -p "$snapshot_dir" || return 1

  # Copy core artifact files if they exist.
  # Includes Phasing-owned artifacts (phasing.md, roadmap.md, future-*.md)
  # — see skills/phasing/SKILL.md "Phasing OWNS / Phasing DEFERS".
  local core_files=(
    "goals.md"
    "questions.md"
    "design.md"
    "phasing.md"
    "roadmap.md"
    "structure.md"
    "plan.md"
    "future-goals.md"
    "future-questions.md"
    "future-research-summary.md"
    "future-design.md"
  )
  local f
  for f in "${core_files[@]}"; do
    if [[ -f "$artifact_dir/$f" ]]; then
      cp "$artifact_dir/$f" "$snapshot_dir/$f" || return 1
    fi
  done

  # Copy research/summary.md if it exists
  if [[ -f "$artifact_dir/research/summary.md" ]]; then
    mkdir -p "$snapshot_dir/research" || return 1
    cp "$artifact_dir/research/summary.md" "$snapshot_dir/research/summary.md" || return 1
  fi

  # Copy tasks/ directory contents if present
  if [[ -d "$artifact_dir/tasks" ]]; then
    mkdir -p "$snapshot_dir/tasks" || return 1
    # Copy task-NN.md files and parallelization.md
    for f in "$artifact_dir/tasks/"*; do
      [[ -f "$f" ]] || continue
      cp "$f" "$snapshot_dir/tasks/" || return 1
    done
  fi

  return 0
}

# artifact_promote_next_phase <artifact_dir> <completed_phase_number>
# Cleans up phase-scoped files after snapshot, preparing for the next phase.
# Deletes:
#   - phase-scoped files: structure.md, plan.md, tasks/, reviews/, feedback/, .qrspi/
#   - roadmap.md (Phasing re-emits it on the next phase's Phasing run)
# Resets frontmatter status to "draft" on remaining synthesizing artifacts:
#   goals.md, questions.md, design.md, research/summary.md, phasing.md
# Leaves future-*.md files in place — Replan's populate sequence reads them
# to extract next-phase entries (see skills/replan/SKILL.md:135-142).
# Phasing-owned artifact handling (added 2026-04-28 per task-26 / R2 I-N1):
#   - phasing.md is reset to draft so the next-phase Phasing run re-validates
#     under Phase-2+ Behavior (skills/phasing/SKILL.md "Phase-2+ Behavior").
#   - roadmap.md is deleted; Phasing re-emits a refreshed roadmap.
#   - future-*.md files persist; Replan reads them in the populate sequence.
# Frontmatter reset uses portable awk (BSD/GNU compatible) per R2 I-N6 fix:
#   the previous `sed -i ''` form is BSD/macOS-only and silently misbehaves
#   on GNU sed (Linux/CI), leaving frontmatter unchanged with exit 0.
# Returns 0 on success, 1 on failure.
artifact_promote_next_phase() {
  local artifact_dir="$1"
  local completed_phase_number="$2"

  # Validate artifact_dir exists
  [[ -d "$artifact_dir" ]] || return 1

  # Delete phase-scoped files and directories
  rm -f "$artifact_dir/structure.md"
  rm -f "$artifact_dir/plan.md"
  rm -f "$artifact_dir/roadmap.md"
  rm -rf "$artifact_dir/tasks"
  rm -rf "$artifact_dir/reviews"
  rm -rf "$artifact_dir/feedback"
  rm -rf "$artifact_dir/.qrspi"

  # Reset frontmatter status to draft on remaining synthesizing artifacts.
  # phasing.md is included so Phase-2+ Behavior re-validates the roadmap.
  # future-*.md files are intentionally NOT in this list — Replan's populate
  # sequence reads them post-promote.
  local reset_files=(
    "goals.md"
    "questions.md"
    "design.md"
    "research/summary.md"
    "phasing.md"
  )
  local f tmp
  for f in "${reset_files[@]}"; do
    if [[ -f "$artifact_dir/$f" ]]; then
      # Portable in-place edit: awk → tempfile → mv. This avoids the
      # BSD-vs-GNU `sed -i` argument incompatibility — `sed -i ''` is
      # BSD/macOS only; GNU sed (Linux/CI) treats `''` as a filename and
      # silently leaves the file unchanged.
      tmp="$artifact_dir/$f.tmp.$$"
      awk '/^status: / { print "status: draft"; next } { print }' \
        "$artifact_dir/$f" > "$tmp" || { rm -f "$tmp"; return 1; }
      mv "$tmp" "$artifact_dir/$f" || { rm -f "$tmp"; return 1; }
    fi
  done

  return 0
}
