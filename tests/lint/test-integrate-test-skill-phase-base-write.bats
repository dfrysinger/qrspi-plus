#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# tests/lint/test-integrate-test-skill-phase-base-write.bats
#
# G5 phase-base-write lint — anchor-phrase grep asserting that
# skills/integrate/SKILL.md and skills/test/SKILL.md each carry the
# phase-base.txt write step at phase start.
#
# Locks the write side against silent SKILL-prose drift that would break
# the OBC integration/test read paths consumed by
# scripts/orchestration-boundary-check.sh --phase integration/test.
#
# Two anchors per skill:
#   1. The reviews/<phase>/phase-base.txt path token (write target).
#   2. The integration_base_sha= key format (consumed by the OBC script).

setup() {
  REPO_ROOT="$(git -C "${BATS_TEST_DIRNAME}" rev-parse --show-toplevel)"
  export REPO_ROOT
}

@test "[G5] skills/integrate/SKILL.md contains reviews/integration/phase-base.txt" {
  local file="${REPO_ROOT}/skills/integrate/SKILL.md"
  local anchor='reviews/integration/phase-base.txt'
  if ! grep -qF -- "${anchor}" "${file}"; then
    echo "phase-base write step missing in ${file}: expected literal string '${anchor}' — the integrate skill must write the OBC phase-base anchor at phase start so orchestration-boundary-check.sh --phase integration can resolve the phase range" >&2
    return 1
  fi
}

@test "[G5] skills/integrate/SKILL.md contains integration_base_sha=" {
  local file="${REPO_ROOT}/skills/integrate/SKILL.md"
  local anchor='integration_base_sha='
  if ! grep -qF -- "${anchor}" "${file}"; then
    echo "phase-base key format missing in ${file}: expected literal string '${anchor}' — the integrate skill must record the HEAD SHA at phase entry in this key format for the OBC script to parse" >&2
    return 1
  fi
}

@test "[G5] skills/test/SKILL.md contains reviews/test/phase-base.txt" {
  local file="${REPO_ROOT}/skills/test/SKILL.md"
  local anchor='reviews/test/phase-base.txt'
  if ! grep -qF -- "${anchor}" "${file}"; then
    echo "phase-base write step missing in ${file}: expected literal string '${anchor}' — the test skill must write the OBC phase-base anchor at phase start so orchestration-boundary-check.sh --phase test can resolve the phase range" >&2
    return 1
  fi
}

@test "[G5] skills/test/SKILL.md contains integration_base_sha=" {
  local file="${REPO_ROOT}/skills/test/SKILL.md"
  local anchor='integration_base_sha='
  if ! grep -qF -- "${anchor}" "${file}"; then
    echo "phase-base key format missing in ${file}: expected literal string '${anchor}' — the test skill must record the HEAD SHA at phase entry in this key format for the OBC script to parse" >&2
    return 1
  fi
}
