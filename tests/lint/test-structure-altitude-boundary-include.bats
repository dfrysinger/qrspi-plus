#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# Task 37 — G35: regression guard for the structure-altitude-boundary `!cat`
# inclusions. Asserts that the literal directive
#
#     !cat skills/_shared/structure-altitude-boundary.md
#
# is present in BOTH consumer source files AT THEIR CANONICAL INSERTION
# POINTS:
#
# 1. `agents/qrspi-structure-scope-reviewer.md` — the directive must sit on
#    the line IMMEDIATELY AFTER the Step 1 Read citation introducer prose
#    ("The contract you just read carries the following allowances and
#    deferrals; restated here so they are present in your immediate
#    reasoning context:"). Drift that moves the directive away from the
#    introducer (or removes it entirely) fails this test.
#
# 2. `skills/structure/owns-defers.md` — the directive must REPLACE the
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

@test "skills/structure/owns-defers.md includes !cat skills/_shared/structure-altitude-boundary.md" {
  local file="${REPO_ROOT}/skills/structure/owns-defers.md"
  local directive='!cat skills/_shared/structure-altitude-boundary.md'
  if ! grep -qF -- "${directive}" "${file}"; then
    echo "structure-altitude-boundary include missing in ${file}: expected literal directive '${directive}'" >&2
    return 1
  fi
}

@test "agents/qrspi-structure-scope-reviewer.md includes !cat skills/_shared/structure-altitude-boundary.md" {
  local file="${REPO_ROOT}/agents/qrspi-structure-scope-reviewer.md"
  local directive='!cat skills/_shared/structure-altitude-boundary.md'
  if ! grep -qF -- "${directive}" "${file}"; then
    echo "structure-altitude-boundary include missing in ${file}: expected literal directive '${directive}'" >&2
    return 1
  fi
}

@test "agents/qrspi-structure-scope-reviewer.md places !cat directive on the line immediately after the introducer prose" {
  local file="${REPO_ROOT}/agents/qrspi-structure-scope-reviewer.md"
  local introducer='The contract you just read carries the following allowances and deferrals; restated here so they are present in your immediate reasoning context:'
  local directive='!cat skills/_shared/structure-altitude-boundary.md'
  local introducer_line directive_line
  introducer_line=$(grep -nF -- "${introducer}" "${file}" | head -n1 | cut -d: -f1)
  directive_line=$(grep -nF -- "${directive}" "${file}" | head -n1 | cut -d: -f1)
  if [[ -z "${introducer_line}" ]]; then
    echo "introducer prose missing in ${file}: expected literal line '${introducer}' (Step 1 Read citation introducer; canonical insertion point for the structure-altitude-boundary include)" >&2
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

@test "skills/_shared/structure-altitude-boundary.md exists and is non-empty" {
  local file="${REPO_ROOT}/skills/_shared/structure-altitude-boundary.md"
  if [[ ! -s "${file}" ]]; then
    echo "single source of truth missing or empty in ${file}: the shared structure-altitude-boundary snippet must exist and be non-empty so the '!cat skills/_shared/structure-altitude-boundary.md' include in both consumers expands to a real OWNS/DEFERS contract — deletion or emptying silently collapses the boundary" >&2
    return 1
  fi
}

@test "skills/_shared/structure-altitude-boundary.md body contains 'Structure OWNS:' preceding 'Structure DEFERS:'" {
  local file="${REPO_ROOT}/skills/_shared/structure-altitude-boundary.md"
  local owns='Structure OWNS:'
  local defers='Structure DEFERS:'
  local owns_line defers_line
  owns_line=$(grep -nF -- "${owns}" "${file}" | head -n1 | cut -d: -f1)
  defers_line=$(grep -nF -- "${defers}" "${file}" | head -n1 | cut -d: -f1)
  if [[ -z "${owns_line}" ]]; then
    echo "OWNS anchor missing in ${file}: expected literal line containing '${owns}' (single-source-of-truth snippet must carry the Structure OWNS block)" >&2
    return 1
  fi
  if [[ -z "${defers_line}" ]]; then
    echo "DEFERS anchor missing in ${file}: expected literal line containing '${defers}' (single-source-of-truth snippet must carry the Structure DEFERS block)" >&2
    return 1
  fi
  if (( owns_line >= defers_line )); then
    echo "OWNS/DEFERS order inverted in ${file}: '${owns}' (line ${owns_line}) must precede '${defers}' (line ${defers_line}); polarity inversion silently flips the boundary contract" >&2
    return 1
  fi
}

@test "skills/_shared/structure-altitude-boundary.md contains canonical OWNS allowance and DEFERS exclusion anchors" {
  local file="${REPO_ROOT}/skills/_shared/structure-altitude-boundary.md"
  local -a anchors=(
    'Unified system architecture diagram'
    'Module-boundary contracts'
    'Unified test architecture'
    'Per-type stitching of per-solution acceptance criteria'
    'Per-solution choice rationale'
    'Per-task assertions'
  )
  local anchor
  for anchor in "${anchors[@]}"; do
    if ! grep -qF -- "${anchor}" "${file}"; then
      echo "canonical boundary anchor missing in ${file}: expected literal substring '${anchor}' — paraphrasing or removing named OWNS allowances/DEFERS exclusions silently weakens the single-source-of-truth contract" >&2
      return 1
    fi
  done
}

@test "skills/structure/owns-defers.md replaces inline OWNS/DEFERS body with the !cat include (no residual inline body)" {
  local file="${REPO_ROOT}/skills/structure/owns-defers.md"
  # Patterns that would only appear if the previous inline OWNS/DEFERS
  # body were reintroduced alongside the !cat include. The canonical
  # OWNS/DEFERS body now lives in skills/_shared/structure-altitude-boundary.md
  # and must not be duplicated in this consumer. We grep the consumer
  # source itself (not the expanded include), so headings inside the
  # shared snippet do not trigger these checks.
  local -a inline_patterns=(
    '^### Structure OWNS'
    '^### Structure DEFERS'
    '^Structure OWNS:'
    '^Structure DEFERS:'
    '\*\*Structure OWNS:\*\*'
    '\*\*Structure DEFERS:\*\*'
  )
  local pat
  for pat in "${inline_patterns[@]}"; do
    if grep -qE -- "${pat}" "${file}"; then
      echo "inline OWNS/DEFERS body reintroduced in ${file}: pattern '${pat}' must not appear alongside the '!cat skills/_shared/structure-altitude-boundary.md' include — the shared snippet is the single source of truth and the previous inline body must remain replaced, not augmented" >&2
      return 1
    fi
  done
}
