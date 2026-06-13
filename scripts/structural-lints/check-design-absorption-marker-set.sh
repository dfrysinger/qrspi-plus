#!/usr/bin/env bash
#
# check-design-absorption-marker-set.sh
#
# Structural lint for design.md absorption-marker drift (Task 18 / Goal G3).
#
# Contract: every absorption-shaped marker in a design.md MUST be expressed
# in one of the 4 enumerated patterns recognised by the sibling redirect-map
# extractor at scripts/design-absorption-markers.sh:
#
#   P1 — Heading-suffix:    ^## G\d+ — .+: (moot|absorbed by CD-\d+|already fixed)
#   P2 — Block-internal:    **Explicit non-goal.**
#   P3 — Acceptance:        no separate v\d+\.\d+(\.\d+)? task ships under (the )?G\d+ ID
#   P4 — Free-prose:        deferred to v\d+\.\d+
#
# Drift surfaces as a lint failure on the design.md PR. The lint is closed-set
# by construction: new absorption marker forms cannot land without a paired
# design-decision update to the enumerated set AND a paired extension of the
# drift-synonym set below.
#
# Drift detection: a closed allow-listed set of synonym phrases that convey
# the same "no separate task ships / scope absorbed by another goal" semantics
# but are NOT in the enumerated set above. Any candidate hit is reported as
# a violation with `file:line: <marker-text>` on stderr (named-diagnostic
# discipline — file, line, and offending marker text are all named).
#
# Usage:
#   check-design-absorption-marker-set.sh [<design-path>...]
#
# With no arguments: scans every design.md under <repo>/docs/qrspi/**/.
# With arguments:    scans each named path.
#
# Exit 0 silently when every absorption-shaped marker matches one of the 4
# enumerated patterns (or no absorption-shaped markers are present).
# Exit 1 on violation; diagnostics emitted to stderr.

set -uo pipefail

# Closed synonym set for absorption-shape drift. Each phrase here is
# unambiguously an absorption claim that is NOT in the enumerated pattern
# set. Adding a sanctioned synonym requires a paired design-decision update
# to the enumerated set plus removal here.
#
# ERE alternation. Word-boundary-ish anchoring is provided by surrounding
# spaces/punctuation in real design.md prose; we keep the regex source-code
# tight rather than padding with [[:space:]] noise.
DRIFT_REGEX='(subsumed (under|by|into)|folded into|rolled (up )?into|merged into|obviated by|superseded by|absorbed (into|under))'

scan_file() {
  local file="$1"
  if [[ ! -r "$file" ]]; then
    printf 'design-path-unreadable: cannot read %s\n' "$file" >&2
    return 2
  fi

  local lineno=0
  local hits=0
  local line marker
  while IFS= read -r line || [[ -n "$line" ]]; do
    lineno=$((lineno + 1))
    if [[ "$line" =~ $DRIFT_REGEX ]]; then
      marker="${BASH_REMATCH[0]}"
      printf '%s:%d: non-enumerated absorption-shaped marker: %s\n' \
        "$file" "$lineno" "$marker" >&2
      hits=$((hits + 1))
    fi
  done < "$file"

  return $(( hits > 0 ? 1 : 0 ))
}

main() {
  local -a files=()
  if (( $# == 0 )); then
    local repo
    if ! repo="$(git rev-parse --show-toplevel 2>/dev/null)"; then
      repo="$PWD"
    fi
    if [[ -d "$repo/docs/qrspi" ]]; then
      while IFS= read -r f; do
        [[ -n "$f" ]] && files+=("$f")
      done < <(find "$repo/docs/qrspi" -type f -name design.md 2>/dev/null | LC_ALL=C sort)
    fi
  else
    files=("$@")
  fi

  local exit_code=0
  local f rc
  for f in "${files[@]:-}"; do
    [[ -z "$f" ]] && continue
    scan_file "$f"
    rc=$?
    if (( rc != 0 )); then
      exit_code=1
    fi
  done
  exit "$exit_code"
}

main "$@"
