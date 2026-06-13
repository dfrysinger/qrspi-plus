#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# tests/lint/test-integrate-test-skill-phase-base-write.bats
#
# Task 24 (G5): structural lint locking the phase-base.txt write step into
# skills/integrate/SKILL.md and skills/test/SKILL.md against silent SKILL-prose
# drift that would break the OBC script's integration/test read paths.
#
# Spec: docs/qrspi/2026-06-04-v073-release/plan.md task T24 — "Create
# tests/lint/test-integrate-test-skill-phase-base-write.bats". The lint asserts
# that each of the two SKILLs carries the literal anchor phrase that names
# `reviews/integration/phase-base.txt` (integrate) or `reviews/test/phase-base.txt`
# (test) as the write target at phase start.
#
# Drives an external lint script created by the T24 implementer at
# scripts/structural-lints/check-integrate-test-skill-phase-base-write.sh.
#
# Contract:
#
#   Usage: check-integrate-test-skill-phase-base-write.sh \
#            [--integrate-skill <path>] [--test-skill <path>]
#
#   With no flags: checks the real repo files
#     <repo>/skills/integrate/SKILL.md and <repo>/skills/test/SKILL.md.
#
#   With flags: checks the named substitute paths (for fixture testing).
#
#   Exit 0 silently when both files contain the phase-base.txt write step
#   (i.e., prose that combines a write verb with the path
#   `reviews/integration/phase-base.txt` or `reviews/test/phase-base.txt`
#   respectively, at phase start).
#
#   Exit non-zero on violation, with stderr emitting a named diagnostic that
#   identifies WHICH skill file is missing the write step — naming literally
#   `skills/integrate/SKILL.md` or `skills/test/SKILL.md` (the canonical
#   repo-relative path the orchestrator/reader cares about), not just the
#   substituted fixture path. The diagnostic MUST NOT be an opaque "FAIL".
#
# Bullet coverage (Test Expectations from task-24 spec):
#   - bullet 2 (integrate SKILL contains the write step naming
#       reviews/integration/phase-base.txt)
#       → @test "lint passes against the real skills/integrate/SKILL.md and skills/test/SKILL.md (meta-acceptance)"
#   - bullet 3 (test SKILL contains the write step naming
#       reviews/test/phase-base.txt)
#       → same meta-acceptance test (covers both real files) plus the per-file
#         fixture failure tests below
#   - bullet 4 (fixture missing the write step fails with a named diagnostic
#       identifying which of the two skill files is missing the write step)
#       → @test "lint fails with named diagnostic when integrate SKILL fixture lacks the write step"
#       → @test "lint fails with named diagnostic when test SKILL fixture lacks the write step"

setup() {
  REPO_ROOT="$(git -C "${BATS_TEST_DIRNAME}" rev-parse --show-toplevel)"
  export REPO_ROOT
  LINT_SCRIPT="${REPO_ROOT}/scripts/structural-lints/check-integrate-test-skill-phase-base-write.sh"
  export LINT_SCRIPT
  FIXTURE_DIR="$(mktemp -d "${BATS_TMPDIR:-/tmp}/t24-phase-base-write.XXXXXX")"
  export FIXTURE_DIR
}

teardown() {
  if [[ -n "${FIXTURE_DIR:-}" && -d "${FIXTURE_DIR}" ]]; then
    rm -rf "${FIXTURE_DIR}"
  fi
}

# Write a fixture integrate SKILL.md that CONTAINS the phase-base.txt write
# step (so it passes lint). The content mirrors the structural shape of the
# real SKILL prose: a phase-start instruction that combines a write verb with
# the path reviews/integration/phase-base.txt.
write_valid_integrate_fixture() {
  local path="$1"
  cat >"${path}" <<'EOF'
# Integrate SKILL — fixture

## Phase Start

Write `reviews/integration/phase-base.txt` as the first orchestrator action of
the integrate phase, before any subagent dispatch. Capture the integration
branch's HEAD SHA and record it as `integration_base_sha=<HEAD-SHA>`.

  > "<ABS_ARTIFACT_DIR>/reviews/integration/phase-base.txt"
EOF
}

# Write a fixture test SKILL.md that CONTAINS the phase-base.txt write step.
write_valid_test_fixture() {
  local path="$1"
  cat >"${path}" <<'EOF'
# Test SKILL — fixture

## Process Steps

1. **Phase-start: write `reviews/test/phase-base.txt`** — this is the first
   orchestrator action of the Test phase, performed before any subagent
   dispatch. Capture the current integration-branch HEAD SHA and write the
   single-line file `<ABS_ARTIFACT_DIR>/reviews/test/phase-base.txt` with
   content `integration_base_sha=<HEAD-SHA-at-phase-entry>`.
EOF
}

# Test expectation: "skills/integrate/SKILL.md contains the phase-base.txt
# write step naming reviews/integration/phase-base.txt" AND
# "skills/test/SKILL.md contains the phase-base.txt write step naming
# reviews/test/phase-base.txt" (bullets 2 and 3 — meta-acceptance against the
# real repo SKILLs that the T21/T22 implementers already landed).
@test "lint passes against the real skills/integrate/SKILL.md and skills/test/SKILL.md (meta-acceptance)" {
  local integrate_skill="${REPO_ROOT}/skills/integrate/SKILL.md"
  local test_skill="${REPO_ROOT}/skills/test/SKILL.md"
  [[ -r "${integrate_skill}" ]] || {
    echo "fixture-setup: real integrate SKILL not readable at ${integrate_skill}" >&2
    return 1
  }
  [[ -r "${test_skill}" ]] || {
    echo "fixture-setup: real test SKILL not readable at ${test_skill}" >&2
    return 1
  }
  [[ -x "${LINT_SCRIPT}" ]] || {
    echo "lint-script-missing: expected executable lint at ${LINT_SCRIPT} (T24 implementer creates this)" >&2
    return 1
  }
  run --separate-stderr "${LINT_SCRIPT}"
  if (( status != 0 )); then
    echo "expected lint to PASS against the real skills/integrate/SKILL.md and skills/test/SKILL.md (meta-acceptance), but exited ${status}" >&2
    echo "stdout: ${output}" >&2
    echo "stderr: ${stderr}" >&2
    return 1
  fi
  # Silent-pass: no noise on the green path.
  if [[ -n "${output}" ]]; then
    echo "expected silent pass on real SKILLs but lint wrote to stdout: ${output}" >&2
    return 1
  fi
  if [[ -n "${stderr}" ]]; then
    echo "expected silent pass on real SKILLs but lint wrote to stderr: ${stderr}" >&2
    return 1
  fi
}

# Test expectation: "A fixture skill body missing the write step fails the
# lint with a named diagnostic identifying which of the two skill files
# (`skills/integrate/SKILL.md` or `skills/test/SKILL.md`) is missing the write
# step (named-diagnostic discipline; no opaque `FAIL` output)" — integrate
# half (bullet 4, integrate side).
@test "lint fails with named diagnostic when integrate SKILL fixture lacks the write step" {
  [[ -x "${LINT_SCRIPT}" ]] || {
    echo "lint-script-missing: expected executable lint at ${LINT_SCRIPT} (T24 implementer creates this)" >&2
    return 1
  }
  # Drifted integrate fixture: prose mentions integration phase start but
  # OMITS the `reviews/integration/phase-base.txt` write step entirely. This
  # is exactly the silent SKILL-prose drift the lint must catch.
  local bad_integrate="${FIXTURE_DIR}/integrate-SKILL.md"
  cat >"${bad_integrate}" <<'EOF'
# Integrate SKILL — drifted fixture

## Phase Start

At phase start, the orchestrator captures the integration branch's HEAD SHA
and proceeds to dispatch subagents. (The phase-base anchor write step has
been silently removed from this SKILL prose.)
EOF
  # Pair with a VALID test SKILL so the failure is unambiguously about the
  # integrate side — the diagnostic must name skills/integrate/SKILL.md
  # specifically, not skills/test/SKILL.md.
  local good_test="${FIXTURE_DIR}/test-SKILL.md"
  write_valid_test_fixture "${good_test}"

  run --separate-stderr "${LINT_SCRIPT}" \
    --integrate-skill "${bad_integrate}" \
    --test-skill "${good_test}"
  if (( status == 0 )); then
    echo "expected lint to FAIL on integrate fixture missing the phase-base.txt write step, but it exited 0" >&2
    echo "stdout: ${output}" >&2
    echo "stderr: ${stderr}" >&2
    return 1
  fi

  local combined="${output}"$'\n'"${stderr}"
  # Named-diagnostic discipline: must name the canonical SKILL path that is
  # missing the write step — skills/integrate/SKILL.md, NOT the test SKILL.
  if ! grep -qF -- 'skills/integrate/SKILL.md' <<<"${combined}"; then
    echo "named-diagnostic missing: expected 'skills/integrate/SKILL.md' in lint output to identify which SKILL is missing the write step" >&2
    echo "combined output: ${combined}" >&2
    return 1
  fi
  if grep -qF -- 'skills/test/SKILL.md' <<<"${combined}"; then
    echo "named-diagnostic false-positive: test SKILL is valid in this fixture, but lint output names 'skills/test/SKILL.md' as missing the write step" >&2
    echo "combined output: ${combined}" >&2
    return 1
  fi
  # The diagnostic must not be opaque — at minimum it must mention the
  # write target so the reader knows which step is missing.
  if ! grep -qF -- 'phase-base.txt' <<<"${combined}"; then
    echo "named-diagnostic too opaque: expected 'phase-base.txt' (the missing write target) in lint output" >&2
    echo "combined output: ${combined}" >&2
    return 1
  fi
}

# Test expectation: bullet 4 — test half.
@test "lint fails with named diagnostic when test SKILL fixture lacks the write step" {
  [[ -x "${LINT_SCRIPT}" ]] || {
    echo "lint-script-missing: expected executable lint at ${LINT_SCRIPT} (T24 implementer creates this)" >&2
    return 1
  }
  # Drifted test fixture: omits the reviews/test/phase-base.txt write step.
  local bad_test="${FIXTURE_DIR}/test-SKILL.md"
  cat >"${bad_test}" <<'EOF'
# Test SKILL — drifted fixture

## Process Steps

1. Dispatch the test-writer subagents.
2. Dispatch the test-execution subagents.
3. Aggregate findings and gate transitions.

(The phase-base anchor write step has been silently removed from this SKILL
prose.)
EOF
  # Pair with a VALID integrate SKILL.
  local good_integrate="${FIXTURE_DIR}/integrate-SKILL.md"
  write_valid_integrate_fixture "${good_integrate}"

  run --separate-stderr "${LINT_SCRIPT}" \
    --integrate-skill "${good_integrate}" \
    --test-skill "${bad_test}"
  if (( status == 0 )); then
    echo "expected lint to FAIL on test fixture missing the phase-base.txt write step, but it exited 0" >&2
    echo "stdout: ${output}" >&2
    echo "stderr: ${stderr}" >&2
    return 1
  fi

  local combined="${output}"$'\n'"${stderr}"
  if ! grep -qF -- 'skills/test/SKILL.md' <<<"${combined}"; then
    echo "named-diagnostic missing: expected 'skills/test/SKILL.md' in lint output to identify which SKILL is missing the write step" >&2
    echo "combined output: ${combined}" >&2
    return 1
  fi
  if grep -qF -- 'skills/integrate/SKILL.md' <<<"${combined}"; then
    echo "named-diagnostic false-positive: integrate SKILL is valid in this fixture, but lint output names 'skills/integrate/SKILL.md' as missing the write step" >&2
    echo "combined output: ${combined}" >&2
    return 1
  fi
  if ! grep -qF -- 'phase-base.txt' <<<"${combined}"; then
    echo "named-diagnostic too opaque: expected 'phase-base.txt' (the missing write target) in lint output" >&2
    echo "combined output: ${combined}" >&2
    return 1
  fi
}
