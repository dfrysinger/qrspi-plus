#!/usr/bin/env bash
# scripts/validate-stage-commit-parents.sh — G6.
#
# Wraps the wave-dispatch stage-merge step with two modes that pin the
# stage-commit parent invariants the integrate/test phases later attest:
#
#   --capture (called pre-merge): resolves the integration-base SHA
#       (`git rev-parse HEAD`) and the per-task-tip SHAs
#       (`git rev-parse refs/heads/<branch>`) and writes them as separable
#       fields to a runtime sidecar under
#       <repo-root>/reviews/implement/wave-state/<wave-id>.sidecar.
#
#   --validate (called post-merge): reads the sidecar, reads the actual
#       stage-commit parents via `git log --format='%P' -n 1 HEAD`, and
#       asserts:
#         (a) actual_parents[0] == captured integration-base SHA
#             (first-parent ordering invariant), and
#         (b) set(actual_parents[1:]) == set(captured task-tip SHAs)
#             (task-tip set equality).
#
# Usage:
#   validate-stage-commit-parents.sh --capture  --wave-id <id> \
#       --task-branch <name> [--task-branch <name> ...] \
#       [--wave-state-dir <abs-dir>]
#
#   validate-stage-commit-parents.sh --validate --wave-id <id> \
#       [--wave-state-dir <abs-dir>]
#
# Default --wave-state-dir is <repo-root>/reviews/implement/wave-state where
# <repo-root> is `git rev-parse --show-toplevel` from the current working
# directory.
#
# Named diagnostics (each emitted to stderr; each exits non-zero):
#   stage-commit-parent-mismatch:   parent invariant violated
#   sha-format-invalid:             a SHA read from the sidecar does not match
#                                   the well-formed git object-name shape
#                                   (lowercase hex, 7-64 chars). No git
#                                   command runs against the malformed value.
#   sidecar-missing:                --validate found no sidecar at the
#                                   expected wave-state path. Distinct from
#                                   sidecar-schema-mismatch. No
#                                   `git log --format='%P'` runs in this path.
#   sidecar-schema-mismatch:        sidecar present but on-disk shape does
#                                   not match the expected schema (missing
#                                   integration_base, missing task_tip_shas,
#                                   malformed key/value structure, or extra
#                                   unknown top-level field). Halts before
#                                   any SHA value is read or compared.
#   capture-git-error:              an underlying `git rev-parse` invocation
#                                   issued by --capture failed
#                                   (integration-base SHA resolution or
#                                   per-task-tip resolution). Lets the
#                                   caller's wrap abort BEFORE
#                                   `git merge --no-ff` runs.
#   capture-sidecar-write-error:    --capture cannot write the runtime
#                                   sidecar (unwritable directory, disk
#                                   full, permission denied). --capture
#                                   never silently exits 0 on a write
#                                   failure, so a downstream --validate
#                                   cannot encounter a missing sidecar
#                                   produced by a silent --capture failure.
#
# Symbolic-only branch-map invariant: this script writes resolved SHAs to
# the runtime sidecar only. parallelization.md is never touched.
#
# Bash 3.2 compatible (macOS system /bin/bash).

set -euo pipefail

# ── Argument parse ─────────────────────────────────────────────────────────

mode=""
wave_id=""
wave_state_dir=""
task_branches=()

usage() {
  sed -n '2,40p' "$0" >&2
  exit 2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --capture)         mode=capture ;;
    --validate)        mode=validate ;;
    --wave-id)         shift; wave_id=${1:-} ;;
    --wave-state-dir)  shift; wave_state_dir=${1:-} ;;
    --task-branch)     shift; task_branches+=("${1:-}") ;;
    -h|--help)         usage ;;
    *)                 echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

if [ -z "$mode" ]; then
  echo "one of --capture or --validate is required" >&2
  exit 2
fi
if [ -z "$wave_id" ]; then
  echo "--wave-id is required" >&2
  exit 2
fi

if [ -z "$wave_state_dir" ]; then
  if ! repo_root=$(git rev-parse --show-toplevel 2>/dev/null); then
    echo "not in a git repository (cannot resolve --wave-state-dir default)" >&2
    exit 2
  fi
  wave_state_dir="$repo_root/reviews/implement/wave-state"
fi
sidecar="$wave_state_dir/$wave_id.sidecar"

# ── SHA-shape validator ────────────────────────────────────────────────────
# Well-formed git object-name shape: lowercase hex, 7-64 characters. Every
# SHA read from the runtime sidecar passes through validate_sha BEFORE any
# `git` invocation or comparison consumes it.

validate_sha() {
  local sha=$1 ctx=$2
  if [ -z "$sha" ] || ! [[ $sha =~ ^[0-9a-f]{7,64}$ ]]; then
    echo "sha-format-invalid: $ctx: '$sha' does not match well-formed git object-name shape (lowercase hex, 7-64 chars)" >&2
    exit 1
  fi
}

# ── --capture mode ─────────────────────────────────────────────────────────

if [ "$mode" = capture ]; then
  # Resolve integration-base SHA. Failure here surfaces as capture-git-error
  # so the caller's wrap aborts BEFORE the wave's `git merge --no-ff` runs.
  if ! base=$(git rev-parse HEAD 2>&1); then
    echo "capture-git-error: 'git rev-parse HEAD' (integration-base resolution) failed: $base" >&2
    exit 1
  fi

  tips=()
  if [ ${#task_branches[@]} -gt 0 ]; then
    for b in "${task_branches[@]}"; do
      if ! sha=$(git rev-parse "refs/heads/$b" 2>&1); then
        echo "capture-git-error: 'git rev-parse refs/heads/$b' (task-tip resolution for branch $b) failed: $sha" >&2
        exit 1
      fi
      tips+=("$sha")
    done
  fi

  # Write sidecar atomically via temp + mv. A write failure at any step
  # surfaces as capture-sidecar-write-error so --capture never silently
  # exits 0 on a failed write.
  if ! mkdir -p "$wave_state_dir" 2>/dev/null; then
    echo "capture-sidecar-write-error: cannot create wave-state directory: $wave_state_dir" >&2
    exit 1
  fi
  if ! tmp=$(mktemp "$wave_state_dir/.sidecar.XXXXXX" 2>/dev/null); then
    echo "capture-sidecar-write-error: cannot create temp file under wave-state directory: $wave_state_dir" >&2
    exit 1
  fi
  tips_value=""
  if [ ${#tips[@]} -gt 0 ]; then
    tips_value="${tips[*]}"
  fi
  if ! {
        printf 'integration_base=%s\n' "$base"
        printf 'task_tip_shas=%s\n' "$tips_value"
      } > "$tmp" 2>/dev/null; then
    rm -f "$tmp"
    echo "capture-sidecar-write-error: cannot write sidecar contents to: $tmp" >&2
    exit 1
  fi
  if ! mv "$tmp" "$sidecar" 2>/dev/null; then
    rm -f "$tmp"
    echo "capture-sidecar-write-error: cannot rename sidecar to: $sidecar" >&2
    exit 1
  fi
  exit 0
fi

# ── --validate mode ────────────────────────────────────────────────────────
# Order is significant: sidecar-missing is checked BEFORE any schema parse,
# and schema validation is checked BEFORE any SHA value is read or compared,
# and SHA-shape validation is checked BEFORE any `git log`/comparison runs.

if [ ! -f "$sidecar" ]; then
  echo "sidecar-missing: expected sidecar at $sidecar (no --capture invocation has produced it in this wave)" >&2
  exit 1
fi

# Schema parse — collect known fields, reject unknown / malformed lines.
integration_base=""
task_tip_shas_raw=""
have_base=0
have_tips=0

while IFS= read -r line || [ -n "$line" ]; do
  # Skip blank lines and full-line comments.
  case "$line" in
    "") continue ;;
    \#*) continue ;;
  esac
  if [[ "$line" != *=* ]]; then
    echo "sidecar-schema-mismatch: malformed key/value structure (no '=' separator): '$line' in $sidecar" >&2
    exit 1
  fi
  key=${line%%=*}
  value=${line#*=}
  case "$key" in
    integration_base)
      integration_base=$value
      have_base=1
      ;;
    task_tip_shas)
      task_tip_shas_raw=$value
      have_tips=1
      ;;
    *)
      echo "sidecar-schema-mismatch: extra unknown top-level field '$key' in $sidecar" >&2
      exit 1
      ;;
  esac
done < "$sidecar"

if [ "$have_base" -ne 1 ]; then
  echo "sidecar-schema-mismatch: missing required field 'integration_base' in $sidecar" >&2
  exit 1
fi
if [ "$have_tips" -ne 1 ]; then
  echo "sidecar-schema-mismatch: missing required field 'task_tip_shas' in $sidecar" >&2
  exit 1
fi

# Now (and only now) validate every SHA value read from disk. Any malformed
# value halts before any git command runs against it.
validate_sha "$integration_base" "sidecar field integration_base"

captured_tips=()
if [ -n "$task_tip_shas_raw" ]; then
  # shellcheck disable=SC2206
  read -r -a captured_tips <<<"$task_tip_shas_raw"
  for s in ${captured_tips[@]+"${captured_tips[@]}"}; do
    validate_sha "$s" "sidecar field task_tip_shas entry"
  done
fi

# Read the actual stage-commit parents. Quiet failure here surfaces as a
# generic git error (the caller's wrap will see non-zero and abort).
parents_line=$(git log --format='%P' -n 1 HEAD)
actual_parents=()
if [ -n "$parents_line" ]; then
  # shellcheck disable=SC2206
  read -r -a actual_parents <<<"$parents_line"
fi

# (a) First-parent ordering invariant.
first_parent=${actual_parents[0]:-}
if [ "$first_parent" != "$integration_base" ]; then
  echo "stage-commit-parent-mismatch: first-parent ordering invariant violated: expected integration_base=$integration_base as parent[0], got '${first_parent:-<none>}' (HEAD=$(git rev-parse HEAD))" >&2
  exit 1
fi

# (b) Task-tip set equality of remaining parents vs captured tips.
remaining=()
if [ ${#actual_parents[@]} -gt 1 ]; then
  remaining=("${actual_parents[@]:1}")
fi

# Sort + uniq both sides for set comparison. Use newline-separated streams
# to avoid quoting hazards.
sort_one() {
  if [ "$#" -eq 0 ]; then
    :
  else
    printf '%s\n' "$@" | LC_ALL=C sort -u
  fi
}

sorted_actual=$(sort_one ${remaining[@]+"${remaining[@]}"})
sorted_captured=$(sort_one ${captured_tips[@]+"${captured_tips[@]}"})

if [ "$sorted_actual" != "$sorted_captured" ]; then
  missing=$(comm -23 <(printf '%s\n' "$sorted_captured") <(printf '%s\n' "$sorted_actual") | grep -v '^$' || true)
  extra=$(comm -13 <(printf '%s\n' "$sorted_captured") <(printf '%s\n' "$sorted_actual") | grep -v '^$' || true)
  msg="stage-commit-parent-mismatch: task-tip set invariant violated"
  if [ -n "$missing" ]; then
    msg+=$'\n'"  missing task-tip SHAs (captured but not in stage-commit parents): $(echo $missing)"
  fi
  if [ -n "$extra" ]; then
    msg+=$'\n'"  extra parent SHAs (in stage-commit parents but not captured): $(echo $extra)"
  fi
  echo "$msg" >&2
  exit 1
fi

exit 0
