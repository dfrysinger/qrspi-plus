#!/usr/bin/env bash
#
# design-absorption-markers.sh — print absorbed-goal redirect map for design.md.
#
# Usage: design-absorption-markers.sh <design-path>
#
# Reads the design.md at <design-path> and emits a tab-separated redirect map
# to stdout, one line per marker hit, in document order:
#
#   <absorbed-id>\t<absorbing-id|"no-task">
#
# Exactly four marker forms are recognised (the canonical set; non-enumerated
# absorption-shaped markers are intentionally ignored — the structural lint at
# the design.md authoring boundary owns marker-set discipline):
#
#   1. Heading-suffix:       ^## G\d+ — .+: (moot|absorbed by CD-\d+|already fixed)
#   2. Block-internal:       \*\*Explicit non-goal\.\*\*   (inside a ## G\d+ block)
#   3. Acceptance-criterion: no separate v\d+\.\d+(\.\d+)? task ships under (the )?G\d+ ID
#   4. Free-prose:           deferred to v\d+\.\d+         (inside a ## G\d+ block)
#
# A marker-free design.md exits 0 with empty stdout. A missing or unreadable
# design path exits non-zero with the named diagnostic 'design-path-unreadable:'
# on stderr.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  printf 'design-path-unreadable: usage: %s <design-path>\n' "${0##*/}" >&2
  exit 2
fi

design_path="$1"

if [[ ! -e "$design_path" ]] || [[ ! -r "$design_path" ]] || [[ -d "$design_path" ]]; then
  printf 'design-path-unreadable: cannot read design path: %s\n' "$design_path" >&2
  exit 2
fi

awk '
function emit(absorbed, absorbing) {
  printf "%s\t%s\n", absorbed, absorbing
}

# Heading lines: track enclosing goal block and check heading-suffix marker.
/^## / {
  current_goal = ""
  if (match($0, /^## G[0-9]+ —/)) {
    # Extract the goal-id literal. RLENGTH counts bytes (not characters),
    # and the em-dash (—, U+2014) is 3 bytes in UTF-8, so we strip prefix
    # and suffix textually rather than slicing by RLENGTH arithmetic.
    gid = $0
    sub(/^## /, "", gid)
    sub(/ —.*$/, "", gid)
    current_goal = gid
    # Heading-suffix marker check: the post-colon disjunction.
    if (match($0, /: (absorbed by CD-[0-9]+|moot|already fixed)/)) {
      seg = substr($0, RSTART + 2, RLENGTH - 2)
      if (seg ~ /^absorbed by CD-[0-9]+/) {
        sub(/^absorbed by /, "", seg)
        emit(gid, seg)
      } else {
        emit(gid, "no-task")
      }
    }
  }
  next
}

{
  line = $0

  # Acceptance-criterion marker: extract the goal-id named inside the matched
  # phrase (one or more occurrences per line). The goal-id here is taken from
  # the matched phrase itself, not from the enclosing heading, because the
  # phrase explicitly names the absorbed-id.
  s = line
  while (match(s, /no separate v[0-9]+\.[0-9]+(\.[0-9]+)? task ships under (the )?G[0-9]+ ID/)) {
    seg_start = RSTART; seg_len = RLENGTH
    seg = substr(s, seg_start, seg_len)
    if (match(seg, /G[0-9]+ ID$/)) {
      gid_in = substr(seg, RSTART, RLENGTH - 3)
      emit(gid_in, "no-task")
    }
    s = substr(s, seg_start + seg_len)
  }

  # Block-internal explicit-non-goal marker: requires enclosing goal block.
  if (current_goal != "" && match(line, /\*\*Explicit non-goal\.\*\*/)) {
    emit(current_goal, "no-task")
  }

  # Free-prose deferred-to marker: requires enclosing goal block.
  if (current_goal != "" && match(line, /deferred to v[0-9]+\.[0-9]+/)) {
    emit(current_goal, "no-task")
  }
}
' "$design_path"
