#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: codex-finding-splitter.sh <stdout-path> <round-subdir> <reviewer_tag>" >&2
  exit 2
fi

stdout_path=$1
round_subdir=$2
tag=$3

if [[ ! -d "$round_subdir" ]]; then
  echo "splitter: round subdir does not exist: $round_subdir" >&2
  exit 2
fi

# Round-subdir basename must match the canonical round-NN convention so the
# NO_FINDINGS branch's `basename | sed 's/round-//'` extraction yields a real
# integer. Test fixtures bypass this with a different mktemp basename — those
# tests never inspect the extracted round value, so the assertion is gated on
# basename starting with `round-`.
round_basename=$(basename "$round_subdir")
case "$round_basename" in
  round-[0-9]*) round_field=${round_basename#round-} ;;
  *)            round_field=$round_basename ;;   # tolerated for fixtures
esac

# Detect the NO_FINDINGS sentinel by exact-byte comparison: the file must
# contain either the literal string "NO_FINDINGS" or "NO_FINDINGS\n" — nothing
# else. Using $(<"$stdout_path") would strip ALL trailing newlines via command
# substitution semantics, accepting "NO_FINDINGS\n\n…" as a sentinel match,
# which is too permissive. Use cmp/wc instead.
size=$(wc -c < "$stdout_path" | tr -d ' ')
# NO_FINDINGS sentinel: byte-exact match against either the bare literal
# (11 bytes) or the literal-with-trailing-newline (12 bytes). cmp -s does
# byte-for-byte comparison and is immune to the command-substitution
# trailing-newline stripping that broke earlier `[[ "$(head -c …)" == … ]]`
# attempts.
if cmp -s "$stdout_path" <(printf 'NO_FINDINGS') \
   || cmp -s "$stdout_path" <(printf 'NO_FINDINGS\n'); then
  cat > "$round_subdir/${tag}.clean.md" <<EOF
---
reviewer: ${tag}
round: ${round_field}
findings: 0
---
EOF
  exit 0
fi

# Empty input → malformed.
if [[ "$size" -eq 0 ]] || { [[ "$size" -eq 1 ]] && [[ "$(head -c 1 "$stdout_path")" == $'\n' ]]; }; then
  echo "splitter: malformed input — empty stdout" >&2
  exit 1
fi

# Count boundaries. If zero, malformed (and not NO_FINDINGS).
if ! grep -qxF '<<<FINDING-BOUNDARY>>>' "$stdout_path"; then
  echo "splitter: malformed input — no <<<FINDING-BOUNDARY>>> and no NO_FINDINGS sentinel" >&2
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
    # encounter order even at high finding counts (>99). Spec §1 does not cap
    # the per-round finding count, so 99 would have been a silent truncation.
    f = sprintf("%s/seg-%04d", out, n)
    started = 1
    next
  }
  started { print > f }
  END { if (started) close(f) }
' "$stdout_path"

i=0
for seg in "$tmpdir"/seg-*; do
  [[ -e "$seg" ]] || continue
  # Skip empty segment files — Codex stdout ending with a stray trailing
  # `<<<FINDING-BOUNDARY>>>` (no content after) would create a zero-byte seg
  # file via the awk loop's `started=1` flag firing on the boundary alone;
  # writing that to disk would violate spec §1's "exactly one `\n`" contract.
  [[ -s "$seg" ]] || continue
  i=$((i + 1))
  printf -v num '%02d' "$i"
  out="$round_subdir/${tag}.finding-F${num}.md"
  # Strip leading blank lines via awk; awk's `print` emits a trailing newline
  # for every output line, so a non-empty awk output is guaranteed to end in
  # exactly one `\n` already.
  awk 'BEGIN{started=0} {if (!started && NF==0) next; started=1; print}' "$seg" > "$out"
  # Defense-in-depth: if the awk output is empty (segment was all blank
  # lines), drop the file rather than ship a zero-byte finding.
  [[ -s "$out" ]] || rm -f "$out"
done
