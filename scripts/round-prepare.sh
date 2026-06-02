#!/usr/bin/env bash
# scripts/round-prepare.sh — G4 canonical round-preparation primitive.
#
# Single deterministic owner of:
#   - per-task SHA-correctness checks (exits 10/11/12) + commit-anchor write
#   - prior-round bookkeeping validation (round-(NN-1)-commit.txt + scope-set)
#   - backward-loop flag consume-once
#   - convergence narrow/broaden decision (deterministic set comparison)
#   - HEAD~1 SHA safety check on narrow decisions
#   - cumulative diff emission to <output-dir>/round-NN.diff
#   - .round-prepare.json sidecar emission (atomic mv pattern)
#
# Usage:
#   round-prepare.sh <round-NN> <output-dir>
#       [--task-branch <branch> --implementer-commit <SHA>]
#       [--worktree <path>] [--base-ref <ref>]
#       [--artifact <path>]
#
# Exit codes:
#   0   round prepared; sidecar + diff (+ commit-anchor on per-task) written.
#   2   non-git workspace; no diff_file or scope_hint fabricated.
#   10  --task-branch / --implementer-commit partial use (orchestrator bug).
#   11  passed SHA != git rev-parse HEAD (worktree integrity break — HALT).
#   12  passed SHA == prior round's anchor / task base (re-dispatch implementer).
#   1   prior-round bookkeeping / generic failure (named diagnostic on stderr).
#
# Output-bound: stdout is the sidecar JSON or empty; stderr carries diagnostics.
#
# Authority: design.md §G4 (L1050-L1148) + structure.md §`scripts/round-prepare.sh`
# (Slice 1.4 creation block + Slice 1.3 Modify rows).
#
# Bash 3.2 compatible (macOS system /bin/bash). No `mapfile`, no `declare -A`,
# no `${var,,}`.

set -u

# ---------------------------------------------------------------------------
# Argument parsing.
# ---------------------------------------------------------------------------

if [ "$#" -lt 2 ]; then
  echo "round-prepare: usage: $0 <round-NN> <output-dir> [--task-branch <b> --implementer-commit <SHA>] [--worktree <path>] [--base-ref <ref>] [--artifact <path>]" >&2
  exit 1
fi

ROUND="$1"; shift
OUTPUT_DIR="$1"; shift

TASK_BRANCH=""
IMPLEMENTER_COMMIT=""
WORKTREE=""
BASE_REF=""
ARTIFACT=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --task-branch)        TASK_BRANCH="${2:-}"; shift 2 ;;
    --implementer-commit) IMPLEMENTER_COMMIT="${2:-}"; shift 2 ;;
    --worktree)           WORKTREE="${2:-}"; shift 2 ;;
    --base-ref)           BASE_REF="${2:-}"; shift 2 ;;
    --artifact)           ARTIFACT="${2:-}"; shift 2 ;;
    --verify)             shift ;;
    *) echo "round-prepare: unknown flag: $1" >&2; exit 1 ;;
  esac
done

# Normalize round number to integer-safe NN string + value.
case "$ROUND" in
  ''|*[!0-9]*)
    echo "round-prepare: round-NN must be a positive integer, got: $ROUND" >&2
    exit 1 ;;
esac
ROUND_NUM=$((10#$ROUND))
if [ "$ROUND_NUM" -lt 1 ]; then
  echo "round-prepare: round-NN must be >= 1, got: $ROUND" >&2
  exit 1
fi
ROUND_NN=$(printf '%02d' "$ROUND_NUM")

mkdir -p "$OUTPUT_DIR"

# Bookkeeping artifacts live in the parent of <output-dir> (which is the
# per-task or per-artifact directory). Per design.md §G9, the round commit
# anchor is written to <output-dir>/../round-NN-commit.txt.
TASK_DIR="$(cd "$OUTPUT_DIR/.." && pwd -P)"

# Per-task and artifact-level invocations are distinguished by --task-branch.
PER_TASK=0
if [ -n "$TASK_BRANCH" ] || [ -n "$IMPLEMENTER_COMMIT" ]; then
  PER_TASK=1
fi

# ---------------------------------------------------------------------------
# Step 1 — HEAD-correctness checks (per-task only).
# Per design.md §G4 step 1 (L1056-L1097) + structure.md L968-995.
# ---------------------------------------------------------------------------

if [ "$PER_TASK" -eq 1 ]; then
  # Check 1: required-flag pair (exit 10 — orchestrator bug).
  if [ -z "$TASK_BRANCH" ] || [ -z "$IMPLEMENTER_COMMIT" ]; then
    echo "round-prepare: --task-branch requires --implementer-commit (and vice-versa). Recovery: orchestrator bug — main chat must read commit_sha from the implementer Task return and pass both --task-branch and --implementer-commit. Halt and surface to user." >&2
    exit 10
  fi

  # Resolve task-base SHA for the round-1 across-rounds variant + the diff
  # base on per-task invocations.
  TASK_BASE_SHA=""
  if [ -n "$BASE_REF" ]; then
    TASK_BASE_SHA="$(git -C "${WORKTREE:-.}" rev-parse "$BASE_REF" 2>/dev/null || true)"
  fi

  # Check 2: across-rounds advance check (exit 12 — re-dispatch implementer).
  PRIOR=""
  PRIOR_LABEL=""
  if [ "$ROUND_NUM" -ge 2 ]; then
    PRIOR_FILE="$TASK_DIR/round-$(printf '%02d' $((ROUND_NUM - 1)))-commit.txt"
    if [ -f "$PRIOR_FILE" ]; then
      PRIOR="$(tr -d '[:space:]' < "$PRIOR_FILE")"
      PRIOR_LABEL="prior round anchor (round $((ROUND_NUM - 1)))"
    fi
  else
    PRIOR="$TASK_BASE_SHA"
    PRIOR_LABEL="task base commit"
  fi
  if [ -n "$PRIOR" ] && [ "$IMPLEMENTER_COMMIT" = "$PRIOR" ]; then
    echo "round-prepare: implementer did not advance HEAD — passed SHA $IMPLEMENTER_COMMIT equals $PRIOR_LABEL. Recovery: re-dispatch the implementer subagent via SendMessage or a fresh Task tool invocation; the implementer must produce a new commit before reviewers can run." >&2
    exit 12
  fi

  # Check 3: within-round equality check (exit 11 — HALT).
  ACTUAL_HEAD="$(git -C "${WORKTREE:-.}" rev-parse HEAD 2>/dev/null || true)"
  if [ -z "$ACTUAL_HEAD" ]; then
    echo "round-prepare: failed to git rev-parse HEAD in worktree '${WORKTREE:-.}'. Recovery: check worktree path; this is normally an orchestrator path-resolution bug." >&2
    exit 1
  fi
  if [ "$ACTUAL_HEAD" != "$IMPLEMENTER_COMMIT" ]; then
    echo "round-prepare: implementer-commit / HEAD mismatch — main chat passed $IMPLEMENTER_COMMIT, worktree HEAD is $ACTUAL_HEAD. Recovery: HALT — likely worktree corruption, wrong worktree path, concurrent commit by another process, or implementer self-report drift. Surface to user; do not auto-retry." >&2
    exit 11
  fi

  # All three checks passed — write the round commit anchor (40-char SHA + LF).
  ANCHOR_PATH="$TASK_DIR/round-${ROUND_NN}-commit.txt"
  ANCHOR_TMP="${ANCHOR_PATH}.tmp.$$"
  printf '%s\n' "$IMPLEMENTER_COMMIT" > "$ANCHOR_TMP"
  if ! mv "$ANCHOR_TMP" "$ANCHOR_PATH"; then
    rm -f "$ANCHOR_TMP"
    echo "round-prepare: failed to write round-${ROUND_NN}-commit.txt at $ANCHOR_PATH (disk full / parent missing / permissions)." >&2
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
# Step 10 — Pre-dispatch presence assertion (per design.md §G4 step 10,
# L1113-1123). On round NN >= 2: prior-round commit anchor must exist and be
# well-formed. On round NN >= 3 (and scope_tagger_enabled): prior scope-set
# must exist and be non-empty.
# ---------------------------------------------------------------------------

if [ "$ROUND_NUM" -ge 2 ]; then
  PRIOR_ANCHOR_PATH="$TASK_DIR/round-$(printf '%02d' $((ROUND_NUM - 1)))-commit.txt"
  if [ ! -f "$PRIOR_ANCHOR_PATH" ]; then
    echo "round-prepare: missing prior-round commit anchor at $PRIOR_ANCHOR_PATH — implementer commit-anchor capture failed or skipped in round $((ROUND_NUM - 1))" >&2
    exit 1
  fi
  ANCHOR_CONTENT="$(cat "$PRIOR_ANCHOR_PATH" 2>/dev/null || true)"
  # Required shape: ^[0-9a-f]{40}\n$ (40-char SHA + single trailing newline).
  if ! printf '%s' "$ANCHOR_CONTENT" | python3 -c '
import sys
data = sys.stdin.buffer.read()
import re
sys.exit(0 if re.match(rb"^[0-9a-f]{40}\n$", data) else 1)
' < "$PRIOR_ANCHOR_PATH"; then
    SAMPLE="$(head -c 80 "$PRIOR_ANCHOR_PATH" | python3 -c "import sys; print(repr(sys.stdin.read()))")"
    echo "round-prepare: malformed prior-round commit anchor at $PRIOR_ANCHOR_PATH — expected 40-char SHA + newline, got $SAMPLE" >&2
    exit 1
  fi
fi

# Scope-tagger gate: only check the scope-set on round NN >= 3 when scope
# tagger is enabled (per design.md §G4 step 10 narrowing-eligibility note).
SCOPE_TAGGER_ENABLED="${QRSPI_SCOPE_TAGGER_ENABLED:-false}"
if [ "$ROUND_NUM" -ge 3 ] && [ "$SCOPE_TAGGER_ENABLED" = "true" ]; then
  PRIOR_SCOPE_PATH="$TASK_DIR/round-$(printf '%02d' $((ROUND_NUM - 1)))-scope-set.txt"
  if [ ! -f "$PRIOR_SCOPE_PATH" ]; then
    echo "round-prepare: missing prior-round scope-set at $PRIOR_SCOPE_PATH — scope-tagger dispatch was skipped or failed in round $((ROUND_NUM - 1))" >&2
    exit 1
  fi
  if [ ! -s "$PRIOR_SCOPE_PATH" ]; then
    echo "round-prepare: empty prior-round scope-set at $PRIOR_SCOPE_PATH — scope-tagger emitted zero tags in round $((ROUND_NUM - 1)), broaden manually or re-run tagger" >&2
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
# Step 2 — Backward-loop flag (read-and-delete). A present flag for the round
# being prepared forces broaden and the flag is consumed once.
# ---------------------------------------------------------------------------

BACKWARD_FLAG_PATH="$TASK_DIR/round-${ROUND_NN}-backward-loop.flag"
BACKWARD_FORCED=0
if [ -e "$BACKWARD_FLAG_PATH" ]; then
  BACKWARD_FORCED=1
  if ! rm -f "$BACKWARD_FLAG_PATH" 2>/dev/null; then
    echo "round-prepare: failed to delete backward-loop flag at $BACKWARD_FLAG_PATH (deletion failed; manual cleanup required)" >&2
  fi
fi

# ---------------------------------------------------------------------------
# Steps 3 + 4 — Convergence decision (deterministic set comparison).
# Per design.md §G4 step 4 + step 12 narrow/broaden table.
#
# Eligibility for narrow: round NN >= 3 AND both round-(NN-1)-scope-set.txt
# and round-(NN-2)-scope-set.txt are present, non-empty, and equal-or-proper-
# subset (with safety margin via HEAD~1 anchor match).
# All other cases (missing, empty, full-artifact, superset, partial-overlap,
# disjoint, HEAD~1 mismatch) → broaden.
# ---------------------------------------------------------------------------

NARROWED="false"
REASON=""
SCOPE_HINT=""

decide_narrow() {
  if [ "$BACKWARD_FORCED" -eq 1 ]; then
    REASON="backward-loop flag forced base-branch preparation"
    return 1
  fi
  if [ "$ROUND_NUM" -lt 3 ]; then
    REASON="round $ROUND_NUM uses base-branch broaden (narrowing requires NN>=3)"
    return 1
  fi
  local prev1="$TASK_DIR/round-$(printf '%02d' $((ROUND_NUM - 1)))-scope-set.txt"
  local prev2="$TASK_DIR/round-$(printf '%02d' $((ROUND_NUM - 2)))-scope-set.txt"
  if [ ! -s "$prev1" ] || [ ! -s "$prev2" ]; then
    REASON="prior-round scope-set missing or empty — broaden"
    return 1
  fi
  # Compare sorted unique non-blank lines.
  local s1 s2
  s1="$(sort -u "$prev1" | sed '/^[[:space:]]*$/d')"
  s2="$(sort -u "$prev2" | sed '/^[[:space:]]*$/d')"
  if [ "$s1" = "$s2" ]; then
    : # equal — narrow-eligible (subject to SHA safety check)
  else
    # Proper-subset case: every element of s1 is in s2 AND s2 has extra
    # elements (i.e., scope shrank from NN-2 to NN-1).
    local s1_minus_s2
    s1_minus_s2="$(comm -23 <(printf '%s\n' "$s1") <(printf '%s\n' "$s2"))"
    if [ -z "$s1_minus_s2" ]; then
      : # proper-subset — narrow-eligible
    else
      REASON="scope-sets diverge (superset / partial-overlap / disjoint) — broaden"
      return 1
    fi
  fi
  # SHA safety: HEAD~1 must equal the prior commit anchor for narrow to be
  # safe.
  local prior_anchor="$TASK_DIR/round-$(printf '%02d' $((ROUND_NUM - 1)))-commit.txt"
  if [ -f "$prior_anchor" ]; then
    local prior_sha head1
    prior_sha="$(tr -d '[:space:]' < "$prior_anchor")"
    head1="$(git -C "${WORKTREE:-.}" rev-parse HEAD~1 2>/dev/null || true)"
    if [ -z "$head1" ] || [ "$head1" != "$prior_sha" ]; then
      REASON="HEAD~1 ($head1) does not match prior round anchor ($prior_sha) — fall back to broaden"
      return 1
    fi
  fi
  SCOPE_HINT="$(cat "$prev1")"
  REASON="scope-sets converged (equal or proper-subset) — narrow"
  return 0
}

if decide_narrow; then
  NARROWED="true"
fi

# ---------------------------------------------------------------------------
# Step 6 — Resolve base ref. On per-task invocations this is the task-base
# commit (passed via --base-ref); on artifact-level it is the configured base
# branch.
# ---------------------------------------------------------------------------

REF=""
if [ -n "$BASE_REF" ]; then
  REF="$BASE_REF"
else
  # Artifact-level fallback: try main, then trunk, then HEAD~1.
  for candidate in main trunk HEAD~1; do
    if git rev-parse --verify "$candidate" >/dev/null 2>&1; then
      REF="$candidate"
      break
    fi
  done
fi

# ---------------------------------------------------------------------------
# Step 9 — Non-git workspace check. Exit 2 with no fabricated diff/scope.
# ---------------------------------------------------------------------------

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Emit a minimal sidecar with no diff_file / scope_hint.
  SIDECAR="$OUTPUT_DIR/.round-prepare.json"
  SIDECAR_TMP="${SIDECAR}.tmp.$$"
  python3 - "$SIDECAR_TMP" <<'PYEOF'
import json, sys
sys.argv[1]
out = {
  "ref": None,
  "narrowed": False,
  "scope_hint": None,
  "diff_file": None,
  "reason": "non-git workspace — no diff or scope_hint fabricated"
}
open(sys.argv[1], "w").write(json.dumps(out, indent=2, sort_keys=True) + "\n")
PYEOF
  mv "$SIDECAR_TMP" "$SIDECAR"
  echo "round-prepare: non-git workspace; no diff produced." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Step 7 — Emit cumulative diff to <output-dir>/round-NN.diff.
# Atomic via temp file + mv.
# ---------------------------------------------------------------------------

DIFF_PATH="$OUTPUT_DIR/round-${ROUND_NN}.diff"
DIFF_TMP="${DIFF_PATH}.tmp.$$"
if [ -n "$ARTIFACT" ]; then
  git diff "$REF" -- "$ARTIFACT" > "$DIFF_TMP" 2>/dev/null || true
else
  git diff "$REF" > "$DIFF_TMP" 2>/dev/null || true
fi
if ! mv "$DIFF_TMP" "$DIFF_PATH"; then
  rm -f "$DIFF_TMP"
  echo "round-prepare: failed to write $DIFF_PATH" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Step 8 — Write .round-prepare.json sidecar (atomic mv pattern).
# Schema fields per design.md §G4 step 8: ref, narrowed, scope_hint,
# diff_file, reason.
# ---------------------------------------------------------------------------

SIDECAR="$OUTPUT_DIR/.round-prepare.json"
SIDECAR_TMP="${SIDECAR}.tmp.$$"

# Resolve diff_file to an absolute path so consumers don't depend on $PWD.
DIFF_ABS="$(cd "$OUTPUT_DIR" && pwd -P)/round-${ROUND_NN}.diff"

REF_FOR_JSON="$REF"
NARROWED_FOR_JSON="$NARROWED"
SCOPE_HINT_FOR_JSON="$SCOPE_HINT"
REASON_FOR_JSON="$REASON"

export REF_FOR_JSON NARROWED_FOR_JSON SCOPE_HINT_FOR_JSON REASON_FOR_JSON DIFF_ABS

python3 - "$SIDECAR_TMP" <<'PYEOF'
import json, os, sys
out = {
  "ref":        os.environ.get("REF_FOR_JSON") or None,
  "narrowed":   os.environ.get("NARROWED_FOR_JSON") == "true",
  "scope_hint": os.environ.get("SCOPE_HINT_FOR_JSON") or None,
  "diff_file":  os.environ.get("DIFF_ABS") or None,
  "reason":     os.environ.get("REASON_FOR_JSON") or None,
}
open(sys.argv[1], "w").write(json.dumps(out, indent=2, sort_keys=True) + "\n")
PYEOF

if ! mv "$SIDECAR_TMP" "$SIDECAR"; then
  rm -f "$SIDECAR_TMP"
  echo "round-prepare: failed to write $SIDECAR" >&2
  exit 1
fi

exit 0
