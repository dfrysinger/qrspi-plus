#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# Task 29 — G34: regression guard for the design-altitude-boundary `!cat`
# inclusions. Asserts that the literal directive
#
#     !cat skills/_shared/design-altitude-boundary.md
#
# is present in BOTH consumer source files AT THEIR CANONICAL INSERTION
# POINTS:
#
# 1. `agents/qrspi-design-scope-reviewer.md` — the directive must sit on
#    the line IMMEDIATELY AFTER the Step 1 Read citation introducer prose
#    ("The contract you just read carries the following allowances and
#    deferrals; restated here so they are present in your immediate
#    reasoning context:"). Drift that moves the directive away from the
#    introducer (or removes it entirely) fails this test.
#
# 2. `skills/design/owns-defers.md` — the directive must REPLACE the
#    previous inline OWNS/DEFERS body. Drift that re-inlines OWNS/DEFERS
#    bullets or headings alongside the `!cat` include fails this test.
#
# Drift-via-subtraction (a future edit removes the include from one
# consumer) and drift-via-augmentation (a future edit reintroduces the
# inline body alongside the include) both fail this test with a
# diagnostic naming the violating file and the missing/misplaced
# directive. Single source of truth means content drift is structurally
# impossible only when these positional invariants hold.

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

@test "agents/qrspi-design-scope-reviewer.md places !cat directive on the line immediately after the introducer prose" {
  local file="${REPO_ROOT}/agents/qrspi-design-scope-reviewer.md"
  local introducer='The contract you just read carries the following allowances and deferrals; restated here so they are present in your immediate reasoning context:'
  local directive='!cat skills/_shared/design-altitude-boundary.md'
  local introducer_line directive_line
  introducer_line=$(grep -nF -- "${introducer}" "${file}" | head -n1 | cut -d: -f1)
  directive_line=$(grep -nF -- "${directive}" "${file}" | head -n1 | cut -d: -f1)
  if [[ -z "${introducer_line}" ]]; then
    echo "introducer prose missing in ${file}: expected literal line '${introducer}' (Step 1 Read citation introducer; canonical insertion point for the design-altitude-boundary include)" >&2
    return 1
  fi
  if [[ -z "${directive_line}" ]]; then
    echo "directive missing in ${file}: expected literal line '${directive}' (canonical insertion point: line immediately after the introducer prose)" >&2
    return 1
  fi
  if (( directive_line != introducer_line + 1 )); then
    echo "directive misplaced in ${file}: expected '${directive}' on the line immediately after the introducer prose (introducer at line ${introducer_line}, directive at line ${directive_line}; required: directive_line == introducer_line + 1)" >&2
    return 1
  fi
}

@test "skills/design/owns-defers.md replaces inline OWNS/DEFERS body with the !cat include (no residual inline body)" {
  local file="${REPO_ROOT}/skills/design/owns-defers.md"
  # Patterns that would only appear if the previous inline OWNS/DEFERS
  # body were reintroduced alongside the !cat include. The canonical
  # OWNS/DEFERS body now lives in skills/_shared/design-altitude-boundary.md
  # and must not be duplicated in this consumer. We grep the consumer
  # source itself (not the expanded include), so headings inside the
  # shared snippet do not trigger these checks.
  local -a inline_patterns=(
    '^### Design OWNS'
    '^### Design DEFERS'
    '^Design OWNS:'
    '^Design DEFERS:'
    '\*\*Design OWNS:\*\*'
    '\*\*Design DEFERS:\*\*'
  )
  local pat
  for pat in "${inline_patterns[@]}"; do
    if grep -qE -- "${pat}" "${file}"; then
      echo "inline OWNS/DEFERS body reintroduced in ${file}: pattern '${pat}' must not appear alongside the '!cat skills/_shared/design-altitude-boundary.md' include — the shared snippet is the single source of truth and the previous inline body must remain replaced, not augmented" >&2
      return 1
    fi
  done
}
