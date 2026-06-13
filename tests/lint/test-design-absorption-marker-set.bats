#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# tests/lint/test-design-absorption-marker-set.bats
#
# Task 18 (G3): structural lint for design.md absorption-marker drift.
#
# Spec: docs/qrspi/2026-06-04-v073-release/plan.md task T18 — "Create
# tests/lint/test-design-absorption-marker-set.bats structural lint". The lint
# scans every design.md under docs/qrspi/**/ and asserts that any
# absorption-shaped marker text matches one of the 4 enumerated patterns:
#
#   1. Heading-suffix:       ^## G\d+ — .+: (moot|absorbed by CD-\d+|already fixed)
#   2. Block-internal:       **Explicit non-goal.**   (inside a ## G\d+ block)
#   3. Acceptance-criterion: no separate v\d+\.\d+(\.\d+)? task ships under (the )?G\d+ ID
#   4. Free-prose:           deferred to v\d+\.\d+    (inside a ## G\d+ block)
#
# Drift surfaces as a lint failure on the design.md PR. The lint runs in CI on
# every PR; new absorption marker forms cannot land without a paired
# design-decision update to the enumerated set.
#
# These tests drive an external lint script created by the T18 implementer at
# scripts/structural-lints/check-design-absorption-marker-set.sh. Contract:
#
#   Usage:  check-design-absorption-marker-set.sh [<design-path>...]
#
#   With no arguments: scans every design.md under <repo>/docs/qrspi/**/.
#   With arguments: scans each named path.
#
#   Exit 0 silently when every absorption-shaped marker matches one of the 4
#   enumerated patterns (or none are present).
#
#   Exit non-zero on violation, with stderr emitting at least one diagnostic
#   line that names the offending file, the line number, and the offending
#   marker text (named-diagnostic discipline).
#
# Bullet coverage (Test Expectations from task-18 spec):
#   - bullet 2 first half (meta-acceptance: passes against the v0.7.3 design.md)
#       → @test "lint passes against the v0.7.3 design.md (meta-acceptance)"
#   - bullet 2 second half (fails against fixture with non-enumerated marker)
#       → @test "lint fails against a fixture design.md with a non-enumerated absorption-shaped marker"
#   - bullet 3 (failure output names file, line, and marker text)
#       → @test "lint failure output names the offending file, line, and marker text (named-diagnostic discipline)"
#   - bullet 4 (zero-marker design.md passes silently)
#       → @test "lint passes silently against a design.md with zero absorption markers"

setup() {
  REPO_ROOT="$(git -C "${BATS_TEST_DIRNAME}" rev-parse --show-toplevel)"
  export REPO_ROOT
  LINT_SCRIPT="${REPO_ROOT}/scripts/structural-lints/check-design-absorption-marker-set.sh"
  export LINT_SCRIPT
  FIXTURE_DIR="$(mktemp -d "${BATS_TMPDIR:-/tmp}/t18-abs-marker.XXXXXX")"
  export FIXTURE_DIR
}

teardown() {
  if [[ -n "${FIXTURE_DIR:-}" && -d "${FIXTURE_DIR}" ]]; then
    rm -rf "${FIXTURE_DIR}"
  fi
}

# Test expectation: "The lint 'passes against the v0.7.3 design.md (this very
# document — meta-acceptance)' (G3 Acceptance bullet 2, first half)."
@test "lint passes against the v0.7.3 design.md (meta-acceptance)" {
  local design="${REPO_ROOT}/docs/qrspi/2026-06-04-v073-release/design.md"
  [[ -r "${design}" ]] || {
    echo "fixture-setup: v0.7.3 design.md not readable at ${design}" >&2
    return 1
  }
  [[ -x "${LINT_SCRIPT}" ]] || {
    echo "lint-script-missing: expected executable lint at ${LINT_SCRIPT} (T18 implementer creates this)" >&2
    return 1
  }
  run --separate-stderr "${LINT_SCRIPT}" "${design}"
  if (( status != 0 )); then
    echo "expected lint to PASS against v0.7.3 design.md (meta-acceptance), but exited ${status}" >&2
    echo "stdout: ${output}" >&2
    echo "stderr: ${stderr}" >&2
    return 1
  fi
  # Silent-pass: stdout/stderr should be empty on a clean pass (no noise on
  # the green path; named diagnostics live only on the red path).
  if [[ -n "${output}" ]]; then
    echo "expected silent pass on v0.7.3 design.md but lint wrote to stdout: ${output}" >&2
    return 1
  fi
  if [[ -n "${stderr}" ]]; then
    echo "expected silent pass on v0.7.3 design.md but lint wrote to stderr: ${stderr}" >&2
    return 1
  fi
}

# Test expectation: "The lint 'fails against a fixture design.md containing a
# non-enumerated marker form' (G3 Acceptance bullet 2, second half)."
@test "lint fails against a fixture design.md with a non-enumerated absorption-shaped marker" {
  [[ -x "${LINT_SCRIPT}" ]] || {
    echo "lint-script-missing: expected executable lint at ${LINT_SCRIPT} (T18 implementer creates this)" >&2
    return 1
  }
  # Fixture: a goal block whose absorption framing uses a phrase NOT in the
  # enumerated set ("subsumed under" is absorption-shaped — it conveys
  # "no separate task ships" semantics — but is not one of the 4 sanctioned
  # forms). A lint that enforces the closed marker set must reject it.
  local fixture="${FIXTURE_DIR}/design.md"
  cat >"${fixture}" <<'EOF'
# Design — fixture

## G99 — Drifted absorption marker

This goal is **subsumed under** CD-7 and ships no separate task.

#### Acceptance

- nothing to assert; absorbed.
EOF
  run --separate-stderr "${LINT_SCRIPT}" "${fixture}"
  if (( status == 0 )); then
    echo "expected lint to FAIL against fixture with non-enumerated marker ('subsumed under'), but it exited 0" >&2
    echo "stdout: ${output}" >&2
    echo "stderr: ${stderr}" >&2
    return 1
  fi
}

# Test expectation: "The lint's failure output names the offending file, line,
# and the non-enumerated marker text (named-diagnostic discipline)."
@test "lint failure output names the offending file, line, and marker text (named-diagnostic discipline)" {
  [[ -x "${LINT_SCRIPT}" ]] || {
    echo "lint-script-missing: expected executable lint at ${LINT_SCRIPT} (T18 implementer creates this)" >&2
    return 1
  }
  local fixture="${FIXTURE_DIR}/design.md"
  # Build a multi-line fixture where the offending absorption-shaped marker
  # sits at a known line (line 5 below), so the test can assert the lint
  # surfaces that exact line number rather than line 1.
  cat >"${fixture}" <<'EOF'
# Design — fixture

## G42 — Some goal

This goal is **subsumed under** CD-3 and has no standalone task.

#### Acceptance

- nothing.
EOF
  run --separate-stderr "${LINT_SCRIPT}" "${fixture}"
  if (( status == 0 )); then
    echo "expected lint to FAIL on fixture with non-enumerated marker, but it exited 0" >&2
    echo "stdout: ${output}" >&2
    echo "stderr: ${stderr}" >&2
    return 1
  fi
  # Combine stdout+stderr for the diagnostic-shape assertions; the contract
  # only requires the names appear in the lint's output streams.
  local combined="${output}"$'\n'"${stderr}"
  if ! grep -qF -- "${fixture}" <<<"${combined}"; then
    echo "named-diagnostic missing offending file path: expected '${fixture}' in lint output" >&2
    echo "combined output: ${combined}" >&2
    return 1
  fi
  if ! grep -qE -- '(^|[^0-9])5([^0-9]|$)' <<<"${combined}"; then
    echo "named-diagnostic missing offending line number: expected line '5' in lint output" >&2
    echo "combined output: ${combined}" >&2
    return 1
  fi
  if ! grep -qF -- 'subsumed under' <<<"${combined}"; then
    echo "named-diagnostic missing offending marker text: expected 'subsumed under' in lint output" >&2
    echo "combined output: ${combined}" >&2
    return 1
  fi
}

# Test expectation: "A design.md with zero absorption markers passes the lint
# silently."
@test "lint passes silently against a design.md with zero absorption markers" {
  [[ -x "${LINT_SCRIPT}" ]] || {
    echo "lint-script-missing: expected executable lint at ${LINT_SCRIPT} (T18 implementer creates this)" >&2
    return 1
  }
  local fixture="${FIXTURE_DIR}/design.md"
  cat >"${fixture}" <<'EOF'
# Design — marker-free fixture

## G1 — Independent goal that ships its own task

#### Acceptance

- standalone task lands under G1.

## G2 — Another independent goal

#### Acceptance

- standalone task lands under G2.
EOF
  run --separate-stderr "${LINT_SCRIPT}" "${fixture}"
  if (( status != 0 )); then
    echo "expected lint to PASS silently on marker-free design.md, but exited ${status}" >&2
    echo "stdout: ${output}" >&2
    echo "stderr: ${stderr}" >&2
    return 1
  fi
  if [[ -n "${output}" ]]; then
    echo "expected silent pass on marker-free design.md but lint wrote to stdout: ${output}" >&2
    return 1
  fi
  if [[ -n "${stderr}" ]]; then
    echo "expected silent pass on marker-free design.md but lint wrote to stderr: ${stderr}" >&2
    return 1
  fi
}
