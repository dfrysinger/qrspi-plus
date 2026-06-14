#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# tests/lint/test-obc-script-absent-anchor.bats
#
# Task 24b (G5): structural lint for the consumer-side OBC-script-absent
# dispatch-defect anchor across the three phase SKILLs.
#
# Spec: docs/qrspi/2026-06-04-v073-release/plan.md task T24b — "Create
# tests/lint/test-obc-script-absent-anchor.bats". The lint asserts that
# `skills/implement/SKILL.md`, `skills/integrate/SKILL.md`, and
# `skills/test/SKILL.md` each carry the verbatim pre-invocation OBC-script-
# existence check that:
#
#   1. names `obc-script-absent:` as the diagnostic entry,
#   2. writes that entry under a `## Dispatch defects` section, and
#   3. halts before invocation when the OBC script is absent or non-executable.
#
# Per design.md G5 and structure.md L97 / L711, the halt is consumer-side SKILL
# prose (not script behavior), so the observable is anchor-phrase presence in
# each SKILL body rather than a runtime fixture. This lint locks that prose
# against silent SKILL-prose drift that would break the G5 Step-N caller-side
# existence-check contract.
#
# These tests drive an external lint script created by the T24b implementer at
# scripts/structural-lints/check-obc-script-absent-anchor.sh. Contract:
#
#   Usage:  check-obc-script-absent-anchor.sh [--skill-base <DIR>]
#
#   With no --skill-base flag: scans the three real SKILL files at
#     <repo>/skills/implement/SKILL.md
#     <repo>/skills/integrate/SKILL.md
#     <repo>/skills/test/SKILL.md
#
#   With --skill-base <DIR>: scans the three files at
#     <DIR>/implement/SKILL.md
#     <DIR>/integrate/SKILL.md
#     <DIR>/test/SKILL.md
#   (Used by these tests to swap in fixture SKILL bodies without mutating the
#   real repo SKILLs.)
#
#   Exit 0 silently when each of the three skill files contains all anchor
#   tokens (the `obc-script-absent:` diagnostic name, the `## Dispatch defects`
#   section heading, and the halt-before-invocation direction).
#
#   Exit non-zero on violation, with stderr emitting at least one named
#   diagnostic that identifies which of the three skill files
#   (`implement/SKILL.md`, `integrate/SKILL.md`, or `test/SKILL.md`) is missing
#   the anchor. No opaque `FAIL` output (named-diagnostic discipline).
#
# Bullet coverage (Test Expectations from wave4-task-24b.md):
#   - bullet 2 (verbatim pre-invocation OBC-script-existence check present in
#     all three SKILLs — anchor-phrase greps, one per skill file)
#       → @test "lint passes against the three real SKILLs post-T20b/T21/T22"
#   - bullet 3 (negative fixture: missing anchor fails with named diagnostic
#     identifying which of the three skill files is missing the anchor)
#       → @test "lint fails when implement SKILL is missing the OBC-script-absent anchor and names the offending file"
#       → @test "lint fails when integrate SKILL is missing the OBC-script-absent anchor and names the offending file"
#       → @test "lint fails when test SKILL is missing the OBC-script-absent anchor and names the offending file"
#   - bullet 4 (positive direction: all three SKILLs pass post-impl) is the
#     same observable as bullet 2's positive grep — covered by the first @test.

setup() {
  REPO_ROOT="$(git -C "${BATS_TEST_DIRNAME}" rev-parse --show-toplevel)"
  export REPO_ROOT
  LINT_SCRIPT="${REPO_ROOT}/scripts/structural-lints/check-obc-script-absent-anchor.sh"
  export LINT_SCRIPT
  FIXTURE_DIR="$(mktemp -d "${BATS_TMPDIR:-/tmp}/t24b-obc-anchor.XXXXXX")"
  export FIXTURE_DIR
  # Pre-populate a fixture skill-base mirroring the real SKILL files; individual
  # tests then mutate one file to remove the anchor and re-run the lint.
  mkdir -p "${FIXTURE_DIR}/implement" "${FIXTURE_DIR}/integrate" "${FIXTURE_DIR}/test"
  cp "${REPO_ROOT}/skills/implement/SKILL.md"  "${FIXTURE_DIR}/implement/SKILL.md"
  cp "${REPO_ROOT}/skills/integrate/SKILL.md"  "${FIXTURE_DIR}/integrate/SKILL.md"
  cp "${REPO_ROOT}/skills/test/SKILL.md"       "${FIXTURE_DIR}/test/SKILL.md"
}

teardown() {
  if [[ -n "${FIXTURE_DIR:-}" && -d "${FIXTURE_DIR}" ]]; then
    rm -rf "${FIXTURE_DIR}"
  fi
}

# Strip every line containing the load-bearing diagnostic name from the given
# skill file. The anchor sentence and the `## Dispatch defects` write direction
# both reference `obc-script-absent:`, so removing those lines reliably breaks
# the anchor for the purposes of the negative fixture tests without otherwise
# perturbing the SKILL body.
_strip_obc_anchor() {
  local file="$1"
  local tmp
  tmp="$(mktemp "${FIXTURE_DIR}/strip.XXXXXX")"
  grep -v 'obc-script-absent:' "${file}" >"${tmp}"
  mv "${tmp}" "${file}"
}

# Test expectation: bullet 2 + bullet 4 — all three real SKILLs carry the
# anchor post-T20b/T21/T22 and the lint passes silently against them.
@test "lint passes against the three real SKILLs post-T20b/T21/T22" {
  [[ -x "${LINT_SCRIPT}" ]] || {
    echo "lint-script-missing: expected executable lint at ${LINT_SCRIPT} (T24b implementer creates this)" >&2
    return 1
  }
  # Sanity check: confirm the three upstream tasks landed their prose so a
  # failure here is the lint's fault, not a missing-anchor regression upstream.
  for skill in implement integrate test; do
    if ! grep -qF 'obc-script-absent:' "${REPO_ROOT}/skills/${skill}/SKILL.md"; then
      echo "fixture-setup: skills/${skill}/SKILL.md is missing the obc-script-absent anchor — upstream task (T20b/T21/T22) did not land" >&2
      return 1
    fi
  done
  run --separate-stderr "${LINT_SCRIPT}"
  if (( status != 0 )); then
    echo "expected lint to PASS against the three real SKILLs, but exited ${status}" >&2
    echo "stdout: ${output}" >&2
    echo "stderr: ${stderr}" >&2
    return 1
  fi
  # Silent-pass: stdout/stderr empty on the green path.
  if [[ -n "${output}" ]]; then
    echo "expected silent pass on real SKILLs but lint wrote to stdout: ${output}" >&2
    return 1
  fi
  if [[ -n "${stderr}" ]]; then
    echo "expected silent pass on real SKILLs but lint wrote to stderr: ${stderr}" >&2
    return 1
  fi
}

# Test expectation: bullet 3 — fixture missing the anchor in implement/SKILL.md
# fails with a named diagnostic identifying that specific file.
@test "lint fails when implement SKILL is missing the OBC-script-absent anchor and names the offending file" {
  [[ -x "${LINT_SCRIPT}" ]] || {
    echo "lint-script-missing: expected executable lint at ${LINT_SCRIPT} (T24b implementer creates this)" >&2
    return 1
  }
  _strip_obc_anchor "${FIXTURE_DIR}/implement/SKILL.md"
  run --separate-stderr "${LINT_SCRIPT}" --skill-base "${FIXTURE_DIR}"
  if (( status == 0 )); then
    echo "expected lint to FAIL on fixture with implement SKILL missing the anchor, but it exited 0" >&2
    echo "stdout: ${output}" >&2
    echo "stderr: ${stderr}" >&2
    return 1
  fi
  local combined="${output}"$'\n'"${stderr}"
  if ! grep -qF -- 'implement/SKILL.md' <<<"${combined}"; then
    echo "named-diagnostic missing offending file: expected 'implement/SKILL.md' in lint output" >&2
    echo "combined output: ${combined}" >&2
    return 1
  fi
  # Negative cross-check: the diagnostic must not falsely accuse the two
  # untouched SKILLs (which still carry the anchor in the fixture base).
  if grep -qF -- 'integrate/SKILL.md' <<<"${combined}"; then
    echo "named-diagnostic falsely names integrate/SKILL.md when only implement/SKILL.md is missing the anchor" >&2
    echo "combined output: ${combined}" >&2
    return 1
  fi
  if grep -qE -- '(^|[^-/])test/SKILL\.md' <<<"${combined}"; then
    echo "named-diagnostic falsely names test/SKILL.md when only implement/SKILL.md is missing the anchor" >&2
    echo "combined output: ${combined}" >&2
    return 1
  fi
}

# Test expectation: bullet 3 — fixture missing the anchor in integrate/SKILL.md
# fails with a named diagnostic identifying that specific file.
@test "lint fails when integrate SKILL is missing the OBC-script-absent anchor and names the offending file" {
  [[ -x "${LINT_SCRIPT}" ]] || {
    echo "lint-script-missing: expected executable lint at ${LINT_SCRIPT} (T24b implementer creates this)" >&2
    return 1
  }
  _strip_obc_anchor "${FIXTURE_DIR}/integrate/SKILL.md"
  run --separate-stderr "${LINT_SCRIPT}" --skill-base "${FIXTURE_DIR}"
  if (( status == 0 )); then
    echo "expected lint to FAIL on fixture with integrate SKILL missing the anchor, but it exited 0" >&2
    echo "stdout: ${output}" >&2
    echo "stderr: ${stderr}" >&2
    return 1
  fi
  local combined="${output}"$'\n'"${stderr}"
  if ! grep -qF -- 'integrate/SKILL.md' <<<"${combined}"; then
    echo "named-diagnostic missing offending file: expected 'integrate/SKILL.md' in lint output" >&2
    echo "combined output: ${combined}" >&2
    return 1
  fi
  if grep -qF -- 'implement/SKILL.md' <<<"${combined}"; then
    echo "named-diagnostic falsely names implement/SKILL.md when only integrate/SKILL.md is missing the anchor" >&2
    echo "combined output: ${combined}" >&2
    return 1
  fi
  if grep -qE -- '(^|[^-/])test/SKILL\.md' <<<"${combined}"; then
    echo "named-diagnostic falsely names test/SKILL.md when only integrate/SKILL.md is missing the anchor" >&2
    echo "combined output: ${combined}" >&2
    return 1
  fi
}

# Test expectation: bullet 3 — fixture missing the anchor in test/SKILL.md
# fails with a named diagnostic identifying that specific file.
@test "lint fails when test SKILL is missing the OBC-script-absent anchor and names the offending file" {
  [[ -x "${LINT_SCRIPT}" ]] || {
    echo "lint-script-missing: expected executable lint at ${LINT_SCRIPT} (T24b implementer creates this)" >&2
    return 1
  }
  _strip_obc_anchor "${FIXTURE_DIR}/test/SKILL.md"
  run --separate-stderr "${LINT_SCRIPT}" --skill-base "${FIXTURE_DIR}"
  if (( status == 0 )); then
    echo "expected lint to FAIL on fixture with test SKILL missing the anchor, but it exited 0" >&2
    echo "stdout: ${output}" >&2
    echo "stderr: ${stderr}" >&2
    return 1
  fi
  local combined="${output}"$'\n'"${stderr}"
  if ! grep -qE -- '(^|[^-/])test/SKILL\.md' <<<"${combined}"; then
    echo "named-diagnostic missing offending file: expected 'test/SKILL.md' in lint output" >&2
    echo "combined output: ${combined}" >&2
    return 1
  fi
  if grep -qF -- 'implement/SKILL.md' <<<"${combined}"; then
    echo "named-diagnostic falsely names implement/SKILL.md when only test/SKILL.md is missing the anchor" >&2
    echo "combined output: ${combined}" >&2
    return 1
  fi
  if grep -qF -- 'integrate/SKILL.md' <<<"${combined}"; then
    echo "named-diagnostic falsely names integrate/SKILL.md when only test/SKILL.md is missing the anchor" >&2
    echo "combined output: ${combined}" >&2
    return 1
  fi
}
