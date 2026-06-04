#!/usr/bin/env bash
# llm-prompt-utils.sh — sourced library of vendor-agnostic prompt-composition
# helpers reused by every third-party-LLM dispatch site in qrspi-plus.
#
# SOURCED ONLY — do not execute directly.
#
# Usage:
#   source scripts/lib/llm-prompt-utils.sh
#
# Exports three functions:
#   strip_frontmatter <file>
#   guard_marker_injection <label> <file>
#   emit_dispatch_parameters   (reads caller's parallel-array environment)
#
# The caller is responsible for populating the environment variables that
# emit_dispatch_parameters reads (see function docs below).
#
# Bash 3.2 portability contract (macOS system /bin/bash):
#   - No `mapfile` / `readarray`
#   - No `declare -A` (associative arrays)
#   - No `${var,,}` or `${var^^}` (case conversion)
#   - No `coproc`
#   - No `wait -n`
#   - Compatible with `set -u` in the sourcing script
#
# Exit codes from exported functions:
#   strip_frontmatter:        0 always (stdout is the result)
#   guard_marker_injection:   0 clean; 1 collision detected (stderr diagnostic)
#   emit_dispatch_parameters: 0 always (stdout is the result)
#
# Source-guard: prevents double-sourcing in the same process.
if [[ "${_QRSPI_LLM_PROMPT_UTILS_LOADED:-}" == "true" ]]; then
  return 0
fi

# Self-invocation guard: refuse to run as a script (must be sourced).
# BASH_SOURCE[0] is the library file path; $0 is the invoking command.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "error: llm-prompt-utils.sh must be sourced, not executed directly" >&2
  exit 1
fi

_QRSPI_LLM_PROMPT_UTILS_LOADED="true"

# ---------------------------------------------------------------------------
# strip_frontmatter <file>
#
# Strips ONLY the leading YAML frontmatter block (between the file's first
# two `^---$` lines), then prints the body verbatim to stdout.
#
# Handles:
#   - Files with a leading frontmatter block (emits body after closing ---)
#   - Files with no frontmatter (emits entire file unchanged)
#   - Files where the body itself contains `---` horizontal-rule lines
#     (those are preserved, not eaten, by gating `next` on n<2)
#
# Does NOT modify the file. Errors if <file> does not exist (awk exits
# non-zero; caller sees non-zero exit from the function).
#
# Parameters:
#   $1 — path to the file to strip
# ---------------------------------------------------------------------------
strip_frontmatter() {
  local file="$1"
  if [[ -z "$file" ]]; then
    echo "error: strip_frontmatter: file argument required" >&2
    return 1
  fi
  if [[ ! -f "$file" ]]; then
    echo "error: strip_frontmatter: file not found: $file" >&2
    return 1
  fi
  awk '/^---$/ && n<2 {n++; next} n>=2 {print}' "$file"
}

# ---------------------------------------------------------------------------
# guard_marker_injection <label> <file>
#
# Guards against untrusted artifact bodies containing the wrapper-private
# structural boundary marker `<<<AGENT-BODY-END>>>`. An artifact body that
# carries the marker literal would emit a second occurrence inside an
# UNTRUSTED-ARTIFACT block, which could defeat positional carve-outs in
# agent self-reference exception clauses (e.g., research-isolation Pre-Flight).
#
# Exits 0 when the file is clean (no marker found).
# Exits 1 with a named diagnostic to stderr when a collision is detected.
#
# Parameters:
#   $1 — human-readable label for the diagnostic (e.g. "subject_code", "diff-file")
#   $2 — path to the file to scan
# ---------------------------------------------------------------------------
guard_marker_injection() {
  local label="$1"
  local file="$2"
  local marker="<<<AGENT-BODY-END>>>"

  if [[ -z "$label" || -z "$file" ]]; then
    echo "error: guard_marker_injection: label and file arguments required" >&2
    return 1
  fi
  if [[ ! -f "$file" ]]; then
    echo "error: guard_marker_injection: file not found: $file" >&2
    return 1
  fi

  if grep -F -q -- "$marker" "$file" 2>/dev/null; then
    echo "error: ${label} contains the wrapper-private marker '${marker}' (path: ${file}). This would defeat the agent-body carve-out; reject the input." >&2
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# emit_dispatch_parameters
#
# Builds and emits the `## Dispatch parameters` block to stdout. Reads the
# following caller-populated variables (all arrays use Bash 3-compatible
# parallel-arrays; no associative arrays):
#
#   PRIMARY_FIELD        — string: "subject_code" or "artifact_body"
#   PRIMARY_PATHS        — array:  caller-relative paths (for display)
#   PRIMARY_ABS          — array:  resolved absolute paths (for cat/emit)
#   TASK_DEF             — string: relative path (empty if absent)
#   TASK_DEF_ABS         — string: absolute path  (empty if absent)
#   COMPANION_NAMES      — array:  parallel companion field names
#   COMPANION_PATHS      — array:  parallel companion caller-relative paths
#   COMPANION_ABS        — array:  parallel companion absolute paths
#   SCALAR_NAMES         — array:  plain scalar field names
#   SCALAR_VALUES        — array:  plain scalar field values
#   OUTPUT_DIR           — string: absolute output directory path
#   ROUND                — string: round number
#   REVIEWER_TAG         — string: reviewer tag string
#   DIFF_FILE            — string: absolute diff file path (empty if absent)
#   SCOPE_HINT           — string: scope-hint value (empty if absent)
#   SCOPE_HINT_SET       — string: "true" if --scope-hint was passed; else "false"
#
# All arrays must be declared and populated before sourcing this function —
# under `set -u`, referencing an undeclared array is a fatal unbound-variable
# error. Callers that do not use a feature (e.g. no companions) must still
# declare the arrays as empty: `COMPANION_NAMES=()`.
#
# Output format:
#   ## Dispatch parameters
#
#   <PRIMARY_FIELD>:
#   <<<UNTRUSTED-ARTIFACT-START id=<path>>>
#   ... file body ...
#   <<<UNTRUSTED-ARTIFACT-END id=<path>>>
#
#   [task_definition: ... (when TASK_DEF_ABS non-empty)]
#   [<companion_name>: ... (for each companion)]
#   [<scalar_name>: <value> (for each scalar)]
#   round_subdir: <OUTPUT_DIR>
#   round: <ROUND>
#   reviewer_tag: <REVIEWER_TAG>
#   [diff_file_path: <DIFF_FILE> (when non-empty)]
#   [scope_hint: ... (when SCOPE_HINT_SET == "true")]
#
# Entries are emitted in a stable, deterministic order across runs:
# primary field first, then task_definition, then companions (caller order),
# then scalars (caller order), then the fixed routing fields.
# ---------------------------------------------------------------------------
emit_dispatch_parameters() {
  # Internal helper: emit a single UNTRUSTED-ARTIFACT block.
  _emit_untrusted_artifact() {
    local path="$1"
    local id="${2:-$1}"
    printf '<<<UNTRUSTED-ARTIFACT-START id=%s>>>\n' "$id"
    cat "$path"
    printf '\n<<<UNTRUSTED-ARTIFACT-END id=%s>>>\n' "$id"
  }

  printf '\n\n## Dispatch parameters\n\n'

  # Required: primary artifact field — one wrapped block per path,
  # concatenated under a single field header.
  printf '%s:\n' "$PRIMARY_FIELD"
  local i
  for i in "${!PRIMARY_ABS[@]}"; do
    _emit_untrusted_artifact "${PRIMARY_ABS[$i]}" "${PRIMARY_PATHS[$i]}"
    printf '\n'
  done

  # Optional: task_definition. Absence is load-bearing in test-step reuse
  # mode (test/SKILL.md § Test-phase reuse contract).
  if [[ -n "$TASK_DEF_ABS" ]]; then
    printf 'task_definition:\n'
    _emit_untrusted_artifact "$TASK_DEF_ABS" "$TASK_DEF"
    printf '\n'
  fi

  # Companions: walk parallel arrays, emit each unique field name once
  # (header), then concatenate every wrapped block whose name matches.
  # Preserves caller-given order. Bash 3-compatible (no associative array).
  local emitted_names=" "
  local name j
  for i in "${!COMPANION_NAMES[@]}"; do
    name="${COMPANION_NAMES[$i]}"
    if [[ "$emitted_names" != *" $name "* ]]; then
      printf '%s:\n' "$name"
      emitted_names="${emitted_names}${name} "
      for j in "${!COMPANION_NAMES[@]}"; do
        if [[ "${COMPANION_NAMES[$j]}" == "$name" ]]; then
          _emit_untrusted_artifact "${COMPANION_ABS[$j]}" "${COMPANION_PATHS[$j]}"
          printf '\n'
        fi
      done
    fi
  done

  # Plain scalar fields (no wrapping) — emitted in caller-given order.
  for i in "${!SCALAR_NAMES[@]}"; do
    printf '%s: %s\n' "${SCALAR_NAMES[$i]}" "${SCALAR_VALUES[$i]}"
  done

  # Fixed routing fields — stable order per dispatcher contract.
  printf 'round_subdir: %s\n' "$OUTPUT_DIR"
  printf 'round: %s\n' "$ROUND"
  printf 'reviewer_tag: %s\n' "$REVIEWER_TAG"

  if [[ -n "$DIFF_FILE" ]]; then
    printf 'diff_file_path: %s\n' "$DIFF_FILE"
  fi

  if [[ "$SCOPE_HINT_SET" == "true" ]]; then
    printf 'scope_hint: <<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>%s<<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>\n' "$SCOPE_HINT"
  fi
}
