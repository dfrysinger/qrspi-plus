#!/usr/bin/env bash
#
# check-integrate-test-skill-phase-base-write.sh
#
# Structural lint for Task 24 (Goal G5): locks the phase-base.txt write step
# into skills/integrate/SKILL.md and skills/test/SKILL.md against silent
# SKILL-prose drift that would break the OBC script's integration/test read
# paths.
#
# Each of the two SKILLs MUST carry the literal anchor phrase that names
# `reviews/integration/phase-base.txt` (integrate) or `reviews/test/phase-base.txt`
# (test) as the write target at phase start. A "write step" is detected as a
# line that combines a write verb (Write / write / writes) with the literal
# phase-base.txt path.
#
# Usage:
#   check-integrate-test-skill-phase-base-write.sh \
#     [--integrate-skill <path>] [--test-skill <path>]
#
# With no flags: checks the real repo files
#   <repo>/skills/integrate/SKILL.md and <repo>/skills/test/SKILL.md.
#
# Exits 0 silently when both files carry the write step.
# Exits non-zero with a named diagnostic on stderr identifying which
# canonical SKILL path (skills/integrate/SKILL.md or skills/test/SKILL.md)
# is missing the write step.

set -euo pipefail

repo_root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
integrate_skill="${repo_root}/skills/integrate/SKILL.md"
test_skill="${repo_root}/skills/test/SKILL.md"

while (( $# > 0 )); do
  case "$1" in
    --integrate-skill)
      integrate_skill="$2"; shift 2 ;;
    --test-skill)
      test_skill="$2"; shift 2 ;;
    *)
      printf 'check-integrate-test-skill-phase-base-write.sh: unknown argument: %s\n' "$1" >&2
      exit 2 ;;
  esac
done

# A write step = a line combining a write verb with the path.
# Use grep -E with anchors that tolerate markdown surrounds (backticks, bold).
check_file() {
  local path="$1" target="$2"
  [[ -r "$path" ]] || return 1
  # Match any line that contains both a write verb (Write/write/writes/writing)
  # and the literal target path.
  grep -E -i -- '(^|[^[:alnum:]])writ(e|es|ing)([^[:alnum:]]|$)' "$path" \
    | grep -F -- "$target" >/dev/null
}

fail=0

if ! check_file "$integrate_skill" "reviews/integration/phase-base.txt"; then
  printf 'skills/integrate/SKILL.md: missing phase-base.txt write step (expected a line combining a write verb with `reviews/integration/phase-base.txt` at phase start)\n' >&2
  fail=1
fi

if ! check_file "$test_skill" "reviews/test/phase-base.txt"; then
  printf 'skills/test/SKILL.md: missing phase-base.txt write step (expected a line combining a write verb with `reviews/test/phase-base.txt` at phase start)\n' >&2
  fail=1
fi

exit "$fail"
