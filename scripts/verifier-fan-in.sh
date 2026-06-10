#!/usr/bin/env bash
# scripts/verifier-fan-in.sh — CD-4 canonical verifier fan-in filter.
#
# Usage: scripts/verifier-fan-in.sh <round-dir>
#
# Reads `<round-dir>/*.finding-F*.md` reviewer findings + paired
# `<reviewer-tag>.finding-F<NN>.score.md` verifier sidecars, applies the
# script-owned threshold rule keyed on `change_type:`, and emits two
# load-bearing artifacts:
#
#   <round-dir>/kept-findings.txt          (one absolute path per kept finding,
#                                           one per line, no header, no comments)
#   <round-dir>/.verifier-fan-in-audit.json
#       {
#         "scored":  <int>, "kept": <int>, "dropped": <int>,
#         "halts":   [{"finding_id": "...", "cause": "..."}, ...],
#         "thresholds": {"style": 80, "clarity": 80, "correctness": 70}
#       }
#
# Exit 0: well-formed round, kept-findings.txt + audit JSON written.
# Exit 1: contract violation; audit JSON written with populated halts[];
#         stderr names the first halt cause on a single line.
#
# This script is the SINGLE SOURCE OF TRUTH (per design.md CD-4) for:
#   - the canonical `change_type` enum (CHANGE_TYPE_ENUM below)
#   - the per-`change_type` threshold floor constants
# No other consumer (skill prose, agent body, fixture) may duplicate these
# values; consumers point at this script's header instead.
#
# Halt cause taxonomy (matches design.md CD-4 §I.1):
#   missing_change_type        — finding frontmatter omits `change_type:`
#   change_type_out_of_enum    — value present but not in CHANGE_TYPE_ENUM
#   missing_sidecar            — no <stem>.score.* file found
#   sidecar_wrong_extension    — sidecar exists at wrong extension (e.g. .score.yml)
#   sidecar_unreadable         — sidecar file exists but cannot be read (permission/I/O error)
#   score_unparseable          — sidecar present but `score:` absent or not 1–3 decimal digits
#   finding_unreadable         — finding file exists but cannot be read (permission/I/O error)

set -euo pipefail

# ---- Dependency check -------------------------------------------------------
# jq is required for record_halt and write_audit.  Fail loudly at startup
# rather than silently crashing mid-loop if jq is absent.
command -v jq >/dev/null 2>&1 || {
  echo "verifier-fan-in: jq is required but not found in PATH" >&2
  exit 2
}
# awk is required for extract_frontmatter_field.  Guard here mirrors the jq
# guard above: without it, awk failures would be swallowed by "|| true" and
# misattributed to missing_change_type or score_unparseable.
command -v awk >/dev/null 2>&1 || {
  echo "verifier-fan-in: awk is required but not found in PATH" >&2
  exit 2
}

# ---- Canonical enum + threshold constants (single source of truth) -------

CHANGE_TYPE_ENUM=(style clarity correctness scope intent)

# Per-`change_type` floor; findings with score below the floor are dropped.
# `scope` and `intent` carry no floor — kept regardless of score (reviewer's
# scope/intent calls flow to the orchestrator's pause gate, not the score
# filter).
THRESHOLD_STYLE=80
THRESHOLD_CLARITY=80
THRESHOLD_CORRECTNESS=70

# ---- Argument handling ----------------------------------------------------

usage() {
  echo "Usage: scripts/verifier-fan-in.sh <round-dir>" >&2
}

if [[ $# -lt 1 ]]; then
  usage
  exit 2
fi

# Reject any positional that starts with '-' — these are always a misuse
# (typo'd flag silently consumed as <round-dir>). Closes the class-of-bug
# v0.7.2.4 hotfix fixes elsewhere; see tests/unit/test-verifier-fan-in-script.bats
# § "argument hardening".
case "$1" in
  -*)
    echo "verifier-fan-in: positional <round-dir> must not begin with '-' (got: $1)" >&2
    usage
    exit 2
    ;;
esac

ROUND_DIR="$1"

if [[ ! -d "$ROUND_DIR" ]]; then
  echo "verifier-fan-in: round-dir does not exist: $ROUND_DIR" >&2
  exit 2
fi

# Resolve to absolute path (kept-findings.txt is required to carry absolute
# finding-file paths per CD-4 §D).
ROUND_DIR_ABS="$(cd "$ROUND_DIR" && pwd -P)"

AUDIT_JSON="$ROUND_DIR_ABS/.verifier-fan-in-audit.json"
KEPT_TXT="$ROUND_DIR_ABS/kept-findings.txt"

# ---- Halt accumulator -----------------------------------------------------

HALTS_JSON=""           # comma-joined "{finding_id, cause}" objects
FIRST_HALT_CAUSE=""

record_halt() {
  # record_halt <finding_id> <cause>
  local fid="$1" cause="$2"
  if [[ -z "$FIRST_HALT_CAUSE" ]]; then
    FIRST_HALT_CAUSE="$cause"
  fi
  local entry
  entry=$(jq -nc --arg id "$fid" --arg c "$cause" '{finding_id:$id, cause:$c}')
  if [[ -z "$HALTS_JSON" ]]; then
    HALTS_JSON="$entry"
  else
    HALTS_JSON="$HALTS_JSON,$entry"
  fi
}

write_audit() {
  # write_audit <scored> <kept> <dropped>
  local scored="$1" kept="$2" dropped="$3"
  jq -n \
    --argjson scored "$scored" \
    --argjson kept "$kept" \
    --argjson dropped "$dropped" \
    --argjson halts "[${HALTS_JSON}]" \
    --argjson tstyle "$THRESHOLD_STYLE" \
    --argjson tclarity "$THRESHOLD_CLARITY" \
    --argjson tcorr "$THRESHOLD_CORRECTNESS" \
    '{
       scored: $scored,
       kept: $kept,
       dropped: $dropped,
       halts: $halts,
       thresholds: {style: $tstyle, clarity: $tclarity, correctness: $tcorr}
     }' >"$AUDIT_JSON"
}

# ---- Frontmatter helpers --------------------------------------------------

# Extract a single top-level scalar value from a YAML frontmatter block.
# Reads the leading `---`-delimited block only; ignores body.
extract_frontmatter_field() {
  # extract_frontmatter_field <file> <field>
  local file="$1" field="$2"
  awk -v field="$field" '
    BEGIN { in_fm = 0; n = 0 }
    /^---[[:space:]]*$/ {
      n++
      if (n == 1) { in_fm = 1; next }
      if (n == 2) { exit }
    }
    in_fm {
      if (match($0, "^[[:space:]]*" field "[[:space:]]*:[[:space:]]*")) {
        val = substr($0, RSTART + RLENGTH)
        sub(/[[:space:]]+$/, "", val)
        # strip simple surrounding double or single quotes if present
        if (val ~ /^".*"$/) { val = substr(val, 2, length(val) - 2) }
        else if (val ~ /^'\''.*'\''$/) { val = substr(val, 2, length(val) - 2) }
        print val
        exit
      }
    }
  ' "$file"
}

in_enum() {
  local needle="$1" v
  for v in "${CHANGE_TYPE_ENUM[@]}"; do
    [[ "$v" == "$needle" ]] && return 0
  done
  return 1
}

# Derive a stable finding identifier from the file path (used in halt
# records). Prefers `finding_id:` from frontmatter; falls back to the
# `<reviewer-tag>.finding-F<NN>` filename stem.
finding_id_for() {
  local file="$1" fid
  fid=$(extract_frontmatter_field "$file" finding_id || true)
  if [[ -n "${fid:-}" ]]; then
    printf '%s\n' "$fid"
    return 0
  fi
  local base="${file##*/}"
  printf '%s\n' "${base%.md}"
}

# ---- Enumerate findings ---------------------------------------------------

shopt -s nullglob
FINDINGS=()
for f in "$ROUND_DIR_ABS"/*.finding-F*.md; do
  # Exclude verifier sidecars (they also match `*.finding-F*.md` because
  # their suffix is `.score.md`).
  [[ "$f" == *.score.md ]] && continue
  FINDINGS+=("$f")
done
shopt -u nullglob

SCORED=0
KEPT=0
DROPPED=0
KEPT_PATHS=()

# ---- Per-finding processing ----------------------------------------------

for finding in "${FINDINGS[@]}"; do
  SCORED=$((SCORED + 1))

  # Readability check: a permission or I/O error on the finding file must be
  # reported as a diagnostic — not silently collapsed into missing_change_type.
  if [[ ! -r "$finding" ]]; then
    echo "verifier-fan-in: cannot read finding file: $finding" >&2
    fid="${finding##*/}"; fid="${fid%.md}"
    record_halt "$fid" finding_unreadable
    continue
  fi

  fid=$(finding_id_for "$finding")

  # 1. change_type required
  ct=$(extract_frontmatter_field "$finding" change_type || true)
  if [[ -z "${ct:-}" ]]; then
    record_halt "$fid" missing_change_type
    continue
  fi
  if ! in_enum "$ct"; then
    record_halt "$fid" change_type_out_of_enum
    continue
  fi

  # 2. paired sidecar at <stem>.score.md
  stem="${finding%.md}"
  sidecar="${stem}.score.md"
  if [[ ! -f "$sidecar" ]]; then
    # Distinguish wrong-extension from missing-altogether: if any sibling
    # at <stem>.score.* exists, the sidecar is on the wrong extension.
    shopt -s nullglob
    siblings=("$stem".score.*)
    shopt -u nullglob
    if [[ ${#siblings[@]} -gt 0 ]]; then
      record_halt "$fid" sidecar_wrong_extension
    else
      record_halt "$fid" missing_sidecar
    fi
    continue
  fi

  # Readability check: a permission or I/O error on the sidecar must be
  # reported with a distinct cause — not collapsed into score_unparseable.
  if [[ ! -r "$sidecar" ]]; then
    echo "verifier-fan-in: cannot read sidecar file: $sidecar" >&2
    record_halt "$fid" sidecar_unreadable
    continue
  fi

  # 3. score must be a parseable decimal integer 0..100
  # Use 10# prefix to force decimal interpretation: a bare $((070)) would be
  # treated as octal 56 by bash; $((089)) crashes under set -e.  The regex
  # caps at 3 digits to prevent integer-overflow bypass: an attacker could
  # craft a 19-digit string that wraps modulo 2^64 back into the valid range.
  raw_score=$(extract_frontmatter_field "$sidecar" score || true)
  if [[ -z "${raw_score:-}" ]] || ! [[ "$raw_score" =~ ^[0-9]{1,3}$ ]]; then
    record_halt "$fid" score_unparseable
    continue
  fi
  score=$((10#$raw_score))
  if (( score > 100 )); then
    record_halt "$fid" score_unparseable
    continue
  fi

  # 4. threshold rule keyed on change_type
  #
  # Universal HALLUCINATED gate: a score:0 finding is always dropped,
  # regardless of change_type.  This must precede the case statement so
  # that scope|intent findings produced by Cite Check failures (which emit
  # score:0 + reason "HALLUCINATED: ...") are not unconditionally kept by
  # the always-keep scope|intent arm below.
  if (( score == 0 )); then
    DROPPED=$((DROPPED + 1))
    continue
  fi

  case "$ct" in
    scope|intent)
      # Always-keep: scope/intent flow to the orchestrator pause gate
      # rather than the score filter.  Score:0 is already handled above.
      KEPT=$((KEPT + 1))
      KEPT_PATHS+=("$finding")
      ;;
    style)
      if (( score >= THRESHOLD_STYLE )); then
        KEPT=$((KEPT + 1)); KEPT_PATHS+=("$finding")
      else
        DROPPED=$((DROPPED + 1))
      fi
      ;;
    clarity)
      if (( score >= THRESHOLD_CLARITY )); then
        KEPT=$((KEPT + 1)); KEPT_PATHS+=("$finding")
      else
        DROPPED=$((DROPPED + 1))
      fi
      ;;
    correctness)
      if (( score >= THRESHOLD_CORRECTNESS )); then
        KEPT=$((KEPT + 1)); KEPT_PATHS+=("$finding")
      else
        DROPPED=$((DROPPED + 1))
      fi
      ;;
  esac
done

# ---- Emit outputs + exit --------------------------------------------------

if [[ -n "$FIRST_HALT_CAUSE" ]]; then
  # Halt path: emit the halt-cause diagnostic to stderr FIRST (before any disk
  # write), so the message is visible even if write_audit fails.  Remove any
  # stale kept-findings.txt from a prior successful run so downstream consumers
  # cannot act on data that is now invalid.
  echo "verifier-fan-in: halt: $FIRST_HALT_CAUSE" >&2
  rm -f "$KEPT_TXT"
  write_audit "$SCORED" "$KEPT" "$DROPPED" || true
  exit 1
fi

# Clean path: write audit FIRST so that if the write fails under set -e,
# kept-findings.txt is never created (no partial state on disk).
write_audit "$SCORED" "$KEPT" "$DROPPED"
: >"$KEPT_TXT"
for p in "${KEPT_PATHS[@]+"${KEPT_PATHS[@]}"}"; do
  printf '%s\n' "$p" >>"$KEPT_TXT"
done
exit 0
