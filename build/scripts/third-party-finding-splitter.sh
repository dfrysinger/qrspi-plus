#!/usr/bin/env bash
set -euo pipefail

# third-party-finding-splitter.sh — split a captured third-party reviewer's raw
# output into stable per-finding files (or a clean sentinel).
#
# Renamed from codex-finding-splitter.sh (CD-1 vendor-neutral dispatch rename).
# The interface is flag-based and round-dir-anchored:
#
#   third-party-finding-splitter.sh --round-dir <abs-round-dir> --tag <reviewer-tag>
#
# Input  : <round-dir>/.dispatch/<tag>.raw   (written by dispatch-companion await)
# Output : <round-dir>/<tag>.finding-F01.md, <tag>.finding-F02.md, ...  (one per
#          <<<FINDING-BOUNDARY>>> block, stable zero-padded encounter order)
#   OR   : <round-dir>/<tag>.clean.md         (when the raw output is the
#          NO_FINDINGS sentinel)
#
# Fails loudly (non-zero + stderr diagnostic, no output files) for:
#   - a missing --round-dir or --tag flag
#   - a missing raw input file
#   - raw content with no boundaries and no NO_FINDINGS sentinel (malformed)
#   - an empty raw file
#   - a write error
#
# Output-bound contract (CD-1 #4): stdout is empty on success — the raw reviewer
# payload is materialized to disk and never echoed into the orchestrator context.
#
# Bash 3.2 portable: no mapfile, no declare -A, no ${var,,}, no coproc.

ROUND_DIR=""
TAG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --round-dir)
      if [[ $# -lt 2 ]]; then echo "splitter: --round-dir requires a value" >&2; exit 1; fi
      ROUND_DIR="$2"; shift 2 ;;
    --tag)
      if [[ $# -lt 2 ]]; then echo "splitter: --tag requires a value" >&2; exit 1; fi
      TAG="$2"; shift 2 ;;
    *)
      echo "splitter: unrecognized argument: $1 (usage: --round-dir <dir> --tag <tag>)" >&2
      exit 1 ;;
  esac
done

if [[ -z "$ROUND_DIR" ]]; then
  echo "splitter: required flag missing: --round-dir <abs-round-dir>" >&2
  exit 1
fi
if [[ -z "$TAG" ]]; then
  echo "splitter: required flag missing: --tag <reviewer-tag>" >&2
  exit 1
fi

if [[ ! -d "$ROUND_DIR" ]]; then
  echo "splitter: round-dir does not exist: $ROUND_DIR" >&2
  exit 1
fi

raw_path="$ROUND_DIR/.dispatch/${TAG}.raw"
if [[ ! -f "$raw_path" ]]; then
  echo "splitter: raw input not found: $raw_path (expected <round-dir>/.dispatch/<tag>.raw)" >&2
  exit 1
fi

# Detect the NO_FINDINGS sentinel by exact-byte comparison: the file must
# contain either the literal string "NO_FINDINGS" or "NO_FINDINGS\n" — nothing
# else. Using $(<"$raw_path") would strip ALL trailing newlines via command
# substitution semantics, accepting "NO_FINDINGS\n\n…" as a sentinel match,
# which is too permissive. Use cmp instead.
size=$(wc -c < "$raw_path" | tr -d ' ')
if cmp -s "$raw_path" <(printf 'NO_FINDINGS') \
   || cmp -s "$raw_path" <(printf 'NO_FINDINGS\n'); then
  cat > "$ROUND_DIR/${TAG}.clean.md" <<EOF
---
reviewer: ${TAG}
findings: 0
---
EOF
  exit 0
fi

# Empty input → malformed.
if [[ "$size" -eq 0 ]] || { [[ "$size" -eq 1 ]] && [[ "$(head -c 1 "$raw_path")" == $'\n' ]]; }; then
  echo "splitter: malformed input — empty raw output ($raw_path)" >&2
  exit 1
fi

# Count boundaries. If zero, malformed (and not NO_FINDINGS).
if ! grep -qxF '<<<FINDING-BOUNDARY>>>' "$raw_path"; then
  echo "splitter: malformed input — no <<<FINDING-BOUNDARY>>> and no NO_FINDINGS sentinel ($raw_path)" >&2
  exit 1
fi

# Split. awk pulls each between-boundary segment, prints to a per-segment temp,
# then the loop renames into the final per-finding files in encounter order.
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

awk -v out="$tmpdir" '
  BEGIN { n=0 }
  /^<<<FINDING-BOUNDARY>>>$/ {
    if (started) close(f)
    n++
    # Zero-pad to 4 digits so the lexicographic glob-and-sort below preserves
    # encounter order even at high finding counts (>99). The per-round finding
    # count is uncapped, so 99 would otherwise be a silent truncation.
    f = sprintf("%s/seg-%04d", out, n)
    started = 1
    next
  }
  started { print > f }
  END { if (started) close(f) }
' "$raw_path"

i=0
for seg in "$tmpdir"/seg-*; do
  [[ -e "$seg" ]] || continue
  # Skip empty segment files — a raw output ending with a stray trailing
  # <<<FINDING-BOUNDARY>>> (no content after) would create a zero-byte seg
  # file via the awk loop's started=1 flag firing on the boundary alone.
  [[ -s "$seg" ]] || continue
  i=$((i + 1))
  printf -v num '%02d' "$i"
  out="$ROUND_DIR/${TAG}.finding-F${num}.md"
  # Strip leading blank lines; awk's print emits a trailing newline for every
  # output line, so a non-empty awk output ends in exactly one \n.
  awk 'BEGIN{started=0} {if (!started && NF==0) next; started=1; print}' "$seg" > "$out"
  # Defense-in-depth: if the awk output is empty (segment was all blank lines),
  # drop the file rather than ship a zero-byte finding.
  [[ -s "$out" ]] || rm -f "$out"
done
