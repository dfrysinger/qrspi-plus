#!/usr/bin/env bash
#
# review-prep.sh — per-step pre-dispatch input generation for reviewer dispatches.
#
# Usage:
#   review-prep.sh --step <step> --round <NN> --artifact-dir <abs-path> [--base-ref <ref>]
#
# Behaviour (task-03, design.md § CD-2, G3, G7):
#   * For every supported step, writes the per-round narrowed diff to
#     <artifact-dir>/reviews/<step>/round-NN.diff (atomic temp+rename).
#   * For the design / plan steps, additionally writes the absorbed-goal
#     redirect map produced by scripts/design-absorption-markers.sh to
#     <artifact-dir>/reviews/<step>/round-NN.absorption-map.tsv.
#   * Diff narrowing: on round >= 2, reads
#     reviews/<step>/round-<NN-1>-commit.txt for the narrowing SHA (NOT
#     HEAD~1, traces G7). On round 01, falls back to --base-ref.
#   * Every SHA read from the anchor file is validated against the lowercase-
#     hex 7..64-char shape BEFORE being passed to any git invocation; failure
#     halts non-zero with the `sha-format-invalid:` named diagnostic.
#   * Missing round-anchor file on round >= 2 halts with `anchor-file-missing:`.
#   * Corrupt --artifact-dir (path exists but is not a directory) halts with
#     `review-prep-corrupt-artifact-dir:`.
#   * Mid-write atomicity: each artifact is written to <final>.tmp first then
#     renamed; failure mid-write halts with `review-prep-write-failed:` and
#     leaves no partial file at the final path.
#   * Silent-on-no-input shape (design.md § CD-2 Dependencies + edge cases):
#       - artifact-dir not in a git working tree -> exit 0, no files written
#       - step's diff has no hunks -> exit 0, no files written
#       - unknown --step value (outside the closed step enumeration) -> exit
#         0, no files written, empty stderr
#
# Bash 3.2 compatible (macOS system /bin/bash).

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"

# ---------------------------------------------------------------------------
# Argument parsing.
# ---------------------------------------------------------------------------

STEP=""
ROUND=""
ARTIFACT_DIR=""
BASE_REF=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --step)         STEP="${2:-}"; shift 2 ;;
    --round)        ROUND="${2:-}"; shift 2 ;;
    --artifact-dir) ARTIFACT_DIR="${2:-}"; shift 2 ;;
    --base-ref)     BASE_REF="${2:-}"; shift 2 ;;
    *) echo "review-prep: unknown flag: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$STEP" ] || [ -z "$ROUND" ] || [ -z "$ARTIFACT_DIR" ]; then
  echo "review-prep: usage: $0 --step <step> --round <NN> --artifact-dir <path> [--base-ref <ref>]" >&2
  exit 1
fi

# Trust-boundary input validation (option-injection hardening): BASE_REF
# flows into `git rev-parse` / `git diff`. Reject option-shaped values.
case "$BASE_REF" in
  -*) echo "review-prep: --base-ref must not begin with '-' (got: $BASE_REF)." >&2; exit 1 ;;
esac

# Normalise round number to NN-string.
case "$ROUND" in
  ''|*[!0-9]*)
    echo "review-prep: --round must be a positive integer, got: $ROUND" >&2
    exit 1 ;;
esac
ROUND_NUM=$((10#$ROUND))
if [ "$ROUND_NUM" -lt 1 ]; then
  echo "review-prep: --round must be >= 1, got: $ROUND" >&2
  exit 1
fi
ROUND_NN=$(printf '%02d' "$ROUND_NUM")
PREV_NN=$(printf '%02d' $((ROUND_NUM - 1)))

# ---------------------------------------------------------------------------
# Step enumeration.
#
# The closed step enumeration is the eight artifact-step pipeline steps plus
# `implement` for per-task implement-review dispatches. Each entry maps to
# the artifact filename under <artifact-dir>.
# ---------------------------------------------------------------------------

artifact_for_step() {
  case "$1" in
    goals)       echo "goals.md" ;;
    questions)   echo "questions.md" ;;
    research)    echo "research/summary.md" ;;
    design)      echo "design.md" ;;
    phasing)     echo "phasing.md" ;;
    plan)        echo "plan.md" ;;
    structure)   echo "structure.md" ;;
    parallelize) echo "parallelization.md" ;;
    replan)      echo "plan.md" ;;
    implement)   echo "" ;;   # per-task diff handled separately; v0.7.3 stub
    *)           echo "" ;;
  esac
}

ARTIFACT_FILE="$(artifact_for_step "$STEP")"

# Unknown --step value -> silent-on-no-input shape per design.md § CD-2 +
# CD-1 edge case. Exit 0, no files written, no stderr. This must precede
# any directory creation so reviews/<unknown>/ never materialises.
if [ -z "$ARTIFACT_FILE" ] && [ "$STEP" != "implement" ]; then
  exit 0
fi
if [ "$STEP" = "implement" ]; then
  # Per-task implement-review diff path is dispatched per-task with its own
  # working-tree context; this script's v0.7.3 contribution for `implement`
  # is silent (no-op) — the per-task diff is owned by round-prepare.sh on
  # the per-task path. Exit 0, no files written.
  exit 0
fi

# ---------------------------------------------------------------------------
# Artifact-dir shape validation.
# ---------------------------------------------------------------------------

if [ -e "$ARTIFACT_DIR" ] && [ ! -d "$ARTIFACT_DIR" ]; then
  echo "review-prep-corrupt-artifact-dir: --artifact-dir is not a directory: $ARTIFACT_DIR" >&2
  exit 1
fi
if [ ! -d "$ARTIFACT_DIR" ]; then
  echo "review-prep-corrupt-artifact-dir: --artifact-dir does not exist: $ARTIFACT_DIR" >&2
  exit 1
fi

# Silent-on-no-input: artifact-dir is not inside a git working tree.
if ! git -C "$ARTIFACT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  exit 0
fi

# ---------------------------------------------------------------------------
# Resolve narrowing base ref.
#
# On round >= 2: read reviews/<step>/round-<NN-1>-commit.txt (G7 anchor
# file). Missing file -> anchor-file-missing:. Malformed SHA shape ->
# sha-format-invalid: (no git invocation against the malformed value).
#
# On round 01: fall back to --base-ref (per structure.md § File-by-file map
# "For round 01 the diff is against <base-branch>"). The absence of a
# round-00 anchor file is NOT an anchor-file-missing condition.
# ---------------------------------------------------------------------------

NARROW_REF=""

if [ "$ROUND_NUM" -ge 2 ]; then
  ANCHOR_FILE="$ARTIFACT_DIR/reviews/$STEP/round-$PREV_NN-commit.txt"
  if [ ! -f "$ANCHOR_FILE" ]; then
    echo "anchor-file-missing: expected per-round anchor file at $ANCHOR_FILE for round $ROUND_NN narrowing" >&2
    exit 1
  fi
  CANDIDATE_SHA="$(tr -d '[:space:]' < "$ANCHOR_FILE")"
  # Well-formed git object-name shape: lowercase hex, 7..64 chars.
  case "$CANDIDATE_SHA" in
    *[!0-9a-f]*)
      echo "sha-format-invalid: anchor SHA in $ANCHOR_FILE failed lowercase-hex shape check (got: $CANDIDATE_SHA)" >&2
      exit 1 ;;
  esac
  SHA_LEN=${#CANDIDATE_SHA}
  if [ "$SHA_LEN" -lt 7 ] || [ "$SHA_LEN" -gt 64 ]; then
    echo "sha-format-invalid: anchor SHA in $ANCHOR_FILE failed length 7..64 shape check (got length $SHA_LEN: $CANDIDATE_SHA)" >&2
    exit 1
  fi
  NARROW_REF="$CANDIDATE_SHA"
else
  if [ -z "$BASE_REF" ]; then
    echo "review-prep: --base-ref is required for round 01 narrowing fallback" >&2
    exit 1
  fi
  NARROW_REF="$BASE_REF"
fi

# ---------------------------------------------------------------------------
# Compute the per-step diff payload.
# ---------------------------------------------------------------------------

# Use --end-of-options where supported to defend against ref-shaped values
# that begin with '-' slipping past the flag-parse layer; SHAs and `main`
# are safe but defense in depth is cheap.
DIFF_OUT="$(git -C "$ARTIFACT_DIR" diff "$NARROW_REF" -- "$ARTIFACT_FILE" 2>/dev/null || true)"

# Empty-diff handling (G7 divergence sanity check).
#
# On round 01 the narrowing base is --base-ref (e.g., `main`); an empty diff
# legitimately means "step's artifact has no edits against the base branch"
# and is the design § CD-2 Dependencies + edge-cases silent-on-no-input
# shape — exit 0 with no files written.
#
# On round >= 2 the narrowing base is the prior per-round commit anchor.
# A narrow round whose diff is structurally empty is the divergence
# sanity-check failure case named in skills/using-qrspi/SKILL.md step 12:
# "the round HAD findings, hence the scope-set, hence the narrow decision —
# but the artifact shows zero delta against the prior per-round commit,
# which means the prior commit did not capture the round's edits or the
# anchor file points at the wrong commit". Halt non-zero with the named
# `narrow-round-empty-diff:` diagnostic — no silent fallback to base-branch
# (masking this divergence would let a broken anchor stay broken across
# many rounds).
if ! printf '%s' "$DIFF_OUT" | grep -q '^@@'; then
  if [ "$ROUND_NUM" -ge 2 ]; then
    echo "narrow-round-empty-diff: anchor-narrowed diff for step '$STEP' round $ROUND_NN against $NARROW_REF produced no hunks — anchor file may point at the wrong commit or the prior per-round commit did not capture the round's edits" >&2
    exit 1
  fi
  exit 0
fi

# ---------------------------------------------------------------------------
# Write outputs atomically (temp+rename).
# ---------------------------------------------------------------------------

OUT_DIR="$ARTIFACT_DIR/reviews/$STEP"
DIFF_PATH="$OUT_DIR/round-$ROUND_NN.diff"
MAP_PATH="$OUT_DIR/round-$ROUND_NN.absorption-map.tsv"

# Create the per-step output dir. mkdir failure (e.g., parent not writable)
# is a write failure per the atomicity contract.
if ! mkdir -p "$OUT_DIR" 2>/dev/null; then
  echo "review-prep-write-failed: cannot create output dir $OUT_DIR" >&2
  exit 1
fi

write_atomic() {
  # write_atomic <final-path> <content-source-cmd...>
  # Writes content to <final-path>.tmp by sourcing stdout from the command,
  # then renames to <final-path>. Removes the .tmp on any failure so no
  # partial file is left at the final path.
  _final="$1"; shift
  _tmp="$_final.tmp"
  if ! "$@" > "$_tmp" 2>/dev/null; then
    rm -f "$_tmp" 2>/dev/null || true
    echo "review-prep-write-failed: write to $_tmp failed" >&2
    return 1
  fi
  if ! mv "$_tmp" "$_final" 2>/dev/null; then
    rm -f "$_tmp" 2>/dev/null || true
    echo "review-prep-write-failed: rename of $_tmp to $_final failed" >&2
    return 1
  fi
  return 0
}

emit_diff() {
  printf '%s\n' "$DIFF_OUT"
}

emit_absorption_map() {
  bash "$SCRIPT_DIR/design-absorption-markers.sh" "$ARTIFACT_DIR/design.md"
}

# Diff file: every supported step that reaches this point.
if ! write_atomic "$DIFF_PATH" emit_diff; then
  exit 1
fi

# Absorption-map file: design and plan steps only.
case "$STEP" in
  design|plan)
    if ! write_atomic "$MAP_PATH" emit_absorption_map; then
      # Diff already on disk — back it out so the "no partial-state artifact
      # leaks to downstream dispatch" contract holds for the absorption-map
      # write failure path as well.
      rm -f "$DIFF_PATH" 2>/dev/null || true
      exit 1
    fi
    ;;
esac

exit 0
