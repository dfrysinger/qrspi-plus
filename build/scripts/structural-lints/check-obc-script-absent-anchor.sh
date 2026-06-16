#!/usr/bin/env bash
#
# check-obc-script-absent-anchor.sh
#
# Structural lint for the consumer-side OBC-script-absent dispatch-defect
# anchor across the three phase SKILLs (Task 24b / Goal G5).
#
# Contract: each of
#   skills/implement/SKILL.md
#   skills/integrate/SKILL.md
#   skills/test/SKILL.md
# MUST carry the verbatim pre-invocation OBC-script-existence check that
# names `obc-script-absent:` as the named diagnostic entry written under a
# `## Dispatch defects` section and halts before invocation when the OBC
# script is absent or non-executable. This lint locks that prose against
# silent drift that would break the design.md G5 Step-N caller-side
# existence-check contract.
#
# The halt is consumer-side SKILL prose (not script behavior), so the
# observable here is anchor-phrase presence in each SKILL body rather than
# a runtime fixture.
#
# Usage:
#   check-obc-script-absent-anchor.sh [--skill-base <DIR>]
#
# With no flag: scans the three real SKILL files at
#   <repo>/skills/{implement,integrate,test}/SKILL.md
# With --skill-base <DIR>: scans
#   <DIR>/{implement,integrate,test}/SKILL.md
# (Fixture override used by the bats tests to swap in mutated SKILL bodies
# without touching the real repo SKILLs.)
#
# Exit 0 silently when each of the three skill files contains all required
# anchor tokens. Exit non-zero on violation, with stderr emitting at least
# one named diagnostic that identifies which of the three skill files is
# missing the anchor (named-diagnostic discipline — the relative
# `<phase>/SKILL.md` path is emitted, not just an opaque FAIL).

set -uo pipefail

PROG="$(basename "$0")"

usage() {
  echo "usage: ${PROG} [--skill-base <DIR>]" >&2
}

SKILL_BASE=""
while (( $# > 0 )); do
  case "$1" in
    --skill-base)
      if (( $# < 2 )); then
        echo "${PROG}: --skill-base requires a directory argument" >&2
        usage
        exit 2
      fi
      SKILL_BASE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "${PROG}: unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "${SKILL_BASE}" ]]; then
  # Default: scan real SKILLs in the repo containing this script.
  script_dir="$(cd "$(dirname "$0")" && pwd)"
  repo_root="$(git -C "${script_dir}" rev-parse --show-toplevel 2>/dev/null)" || {
    echo "${PROG}: unable to locate repo root from ${script_dir}" >&2
    exit 2
  }
  SKILL_BASE="${repo_root}/skills"
fi

# The three required anchor tokens. Each SKILL must contain all three:
#   1. the `obc-script-absent:` named diagnostic entry,
#   2. the `## Dispatch defects` section heading under which it is written,
#   3. the halt-before-invocation direction.
ANCHOR_DIAGNOSTIC='obc-script-absent:'
ANCHOR_SECTION='## Dispatch defects'
# Halt-before-invocation direction: the SKILL prose directs the orchestrator
# to halt (stop / abort the dispatch attempt) before invoking the agent. The
# load-bearing observable is that the SAME sentence carrying the
# `obc-script-absent:` anchor also pairs `halt` with `invoc`/`invok` (covers
# "halts before invocation", "halts ... without attempting invocation",
# "halts before invoking", etc.). Binding the halt-token check to the
# anchor's own line prevents an unrelated `halt`/`invoke` co-occurrence
# elsewhere in the SKILL from masking drift in the OBC anchor sentence.
ANCHOR_HALT_RE='obc-script-absent:.*halt.*invo|halt.*invo.*obc-script-absent:'

violations=0
for phase in implement integrate test; do
  rel="${phase}/SKILL.md"
  abs="${SKILL_BASE}/${rel}"

  if [[ ! -f "${abs}" ]]; then
    echo "obc-script-absent-anchor: '${rel}' not found at ${abs}" >&2
    violations=$((violations + 1))
    continue
  fi

  missing=()
  grep -qF -- "${ANCHOR_DIAGNOSTIC}" "${abs}" \
    || missing+=("named-diagnostic '${ANCHOR_DIAGNOSTIC}'")
  grep -qF -- "${ANCHOR_SECTION}" "${abs}" \
    || missing+=("section heading '${ANCHOR_SECTION}'")
  grep -qEi -- "${ANCHOR_HALT_RE}" "${abs}" \
    || missing+=("halt-before-invocation direction")

  if (( ${#missing[@]} > 0 )); then
    for token in "${missing[@]}"; do
      echo "obc-script-absent-anchor: '${rel}' is missing ${token}" >&2
    done
    violations=$((violations + 1))
  fi
done

if (( violations > 0 )); then
  exit 1
fi
exit 0
