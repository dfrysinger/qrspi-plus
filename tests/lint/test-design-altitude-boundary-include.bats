#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# Task 29 — G34: regression guard for the design-altitude-boundary `!cat`
# inclusions. Asserts that the literal directive
#
#     !cat skills/_shared/design-altitude-boundary.md
#
# is present in BOTH consumer source files. Drift-via-subtraction (a future
# edit removes the include from one consumer) fails this test with a
# diagnostic naming the violating file and the missing directive. Single
# source of truth means content drift is structurally impossible — this
# test only guards the include-presence invariant.

setup() {
  REPO_ROOT="$(git -C "${BATS_TEST_DIRNAME}" rev-parse --show-toplevel)"
  export REPO_ROOT
}

@test "skills/design/owns-defers.md includes !cat skills/_shared/design-altitude-boundary.md" {
  local file="${REPO_ROOT}/skills/design/owns-defers.md"
  local directive='!cat skills/_shared/design-altitude-boundary.md'
  if ! grep -qF -- "${directive}" "${file}"; then
    echo "design-altitude-boundary include missing in ${file}: expected literal directive '${directive}'" >&2
    return 1
  fi
}

@test "agents/qrspi-design-scope-reviewer.md includes !cat skills/_shared/design-altitude-boundary.md" {
  local file="${REPO_ROOT}/agents/qrspi-design-scope-reviewer.md"
  local directive='!cat skills/_shared/design-altitude-boundary.md'
  if ! grep -qF -- "${directive}" "${file}"; then
    echo "design-altitude-boundary include missing in ${file}: expected literal directive '${directive}'" >&2
    return 1
  fi
}
