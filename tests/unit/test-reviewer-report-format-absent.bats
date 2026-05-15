#!/usr/bin/env bats

# Repository-wide lint: asserts zero surviving "## Report Format" headings
# across the union of every agents/qrspi-*-reviewer.md file and the three
# additional reviewer-adjacent agents whose filenames do not match that glob.
#
# Background: Task 07 (v06-release, Subagent Contract Hardening slice) removed
# the ## Report Format block from every reviewer agent body so the
# reviewer-protocol five-line brief at skills/reviewer-protocol/SKILL.md is the
# sole contracted return surface. The new qrspi-visual-fidelity-reviewer.md
# (created by Task 06) was authored without a Report Format block. This lint
# test locks that invariant so any future agent edit that accidentally
# re-introduces the block fails loudly.
#
# Scan set:
#   - Glob:    agents/qrspi-*-reviewer.md
#   - Extras:  agents/qrspi-silent-failure-hunter.md
#              agents/qrspi-type-design-analyzer.md
#              agents/qrspi-code-simplifier.md
#
# All paths are relative to the repository root. setup() resolves root by
# stepping two directories up from tests/unit/ (the standard BATS convention
# used by sibling tests in this directory).

bats_require_minimum_version 1.5.0

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
  EXTRA_AGENTS=(
    "agents/qrspi-silent-failure-hunter.md"
    "agents/qrspi-type-design-analyzer.md"
    "agents/qrspi-code-simplifier.md"
  )
}

# ---------------------------------------------------------------------------
# Precondition: each of the three explicit extras must exist on disk.
# The test fails fast with a clear message naming the missing file so the
# operator does not need to re-grep to locate the problem.
# ---------------------------------------------------------------------------

@test "agents/qrspi-silent-failure-hunter.md exists on disk" {
  [ -f "agents/qrspi-silent-failure-hunter.md" ] \
    || { echo "MISSING FILE: agents/qrspi-silent-failure-hunter.md — required in scan set"; return 1; }
}

@test "agents/qrspi-type-design-analyzer.md exists on disk" {
  [ -f "agents/qrspi-type-design-analyzer.md" ] \
    || { echo "MISSING FILE: agents/qrspi-type-design-analyzer.md — required in scan set"; return 1; }
}

@test "agents/qrspi-code-simplifier.md exists on disk" {
  [ -f "agents/qrspi-code-simplifier.md" ] \
    || { echo "MISSING FILE: agents/qrspi-code-simplifier.md — required in scan set"; return 1; }
}

# ---------------------------------------------------------------------------
# Main lint: zero ## Report Format headings across the full scan set.
#
# A single @test block enumerates every file in the union, counts
# "## Report Format" heading lines, and fails on the first non-zero count.
# The failure message names the offending file path and the matching heading
# line so the operator can locate the surviving block without re-grepping.
# ---------------------------------------------------------------------------

@test "no surviving ## Report Format headings across all reviewer agents (glob + extras)" {
  local offenders=()

  # Collect glob matches first, then append the three explicit extras.
  local all_files=()
  while IFS= read -r f; do
    all_files+=("$f")
  done < <(find agents -name "qrspi-*-reviewer.md" -type f | sort)

  for extra in "${EXTRA_AGENTS[@]}"; do
    all_files+=("$extra")
  done

  for f in "${all_files[@]}"; do
    if [ ! -f "$f" ]; then
      # Already caught by the precondition tests above, but be safe.
      continue
    fi
    local count
    count=$(grep -c "^## Report Format" "$f" || true)
    if [ "$count" -gt 0 ]; then
      local line
      line=$(grep -n "^## Report Format" "$f" | head -1)
      offenders+=("$f:$line")
    fi
  done

  if [ "${#offenders[@]}" -gt 0 ]; then
    printf 'FAIL: surviving "## Report Format" heading found:\n' >&2
    printf '  %s\n' "${offenders[@]}" >&2
    return 1
  fi
}
