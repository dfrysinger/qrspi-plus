#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# Plan-level acceptance / e2e tests for G5 (Orchestration Boundary HARD-RULE
# observable beyond Implement).
#
# Maps to design.md § G5 Acceptance and plan.md Phase 1 Acceptance Criteria
# bullets 10-11 (integration phase produces empty
# reviews/integration/orchestration-boundary.md; Implement-phase autopilot
# halts and writes HALT-orchestration-boundary-undeterminable.md on any
# dispatch defect; subagent commits carry qrspi-<agent> author marker).
#
# Per-script mechanics are exhaustively covered by
# tests/unit/test-orchestration-boundary-check.bats; this file proves the
# observable end-to-end chain: clean phase → byte-empty report → exit 0;
# dispatch defect → non-zero exit + named section + section-header-emitted-
# only-when-populated invariant.

setup_file() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")"/../../.. && pwd)"
  export REPO_ROOT
  export OBC="$REPO_ROOT/scripts/orchestration-boundary-check.sh"
  export INTEGRATE_SKILL="$REPO_ROOT/skills/integrate/SKILL.md"
  export TEST_SKILL="$REPO_ROOT/skills/test/SKILL.md"
  export IMPLEMENT_SKILL="$REPO_ROOT/skills/implement/SKILL.md"
  export DISPATCH_AGENT="$REPO_ROOT/scripts/dispatch-agent.sh"
}

setup() {
  # Per-test scratch under bats-managed tmpdir — auto-removed by bats even
  # on crash/SIGKILL/timeout, so an aborted test cannot leave a nested
  # `.bats-tmp-*` git repo inside $REPO_ROOT.
  TMP_DIR="$BATS_TEST_TMPDIR/work"
  mkdir -p "$TMP_DIR"
  cd "$TMP_DIR"
  git init -q .
  git config user.email "human@example.com"
  git config user.name "Human Author"
  echo "seed" > seed.txt
  git add seed.txt
  git commit -q -m "seed"
  PHASE_BASE_SHA="$(git rev-parse HEAD)"
  export TMP_DIR PHASE_BASE_SHA
}

# No teardown() needed — bats removes $BATS_TEST_TMPDIR itself.

@test "acceptance: integrate SKILL carries verbatim HARD-RULE and OBC Step prose" {
  # G5 acceptance bullets 1 + 6.
  grep -qF 'MAIN CHAT ONLY ORCHESTRATES' "$INTEGRATE_SKILL"
  grep -qE '^#+ Step .*Orchestration boundary observability check|orchestration-boundary-check\.sh --phase integration' "$INTEGRATE_SKILL"
}

@test "acceptance: test SKILL carries verbatim HARD-RULE and OBC Step prose" {
  grep -qF 'MAIN CHAT ONLY ORCHESTRATES' "$TEST_SKILL"
  grep -qE '^#+ Step .*Orchestration boundary observability check|orchestration-boundary-check\.sh --phase test' "$TEST_SKILL"
}

@test "acceptance: implement SKILL carries OBC step prose" {
  grep -qE 'orchestration-boundary-check\.sh --phase implement|Orchestration boundary observability check' "$IMPLEMENT_SKILL"
}

@test "acceptance: integrate SKILL writes reviews/integration/phase-base.txt as first orchestrator action" {
  # plan.md Phase 1 Acceptance bullet 10 (precondition: bare-SHA write).
  grep -qF 'reviews/integration/phase-base.txt' "$INTEGRATE_SKILL"
  # Bare-SHA shape (post fix-F01). NOTE: needle uses single-quoted shape so
  # the literal byte sequence handed to grep is `printf '%s\n'` (one
  # backslash) — matching the SKILL prose verbatim. Earlier double-quoted
  # `"printf '%s\\\\n'"` collapsed to TWO backslashes and never matched.
  grep -qF 'printf '"'"'%s\n'"'"'' "$INTEGRATE_SKILL"
}

@test "acceptance: test SKILL writes reviews/test/phase-base.txt as first orchestrator action" {
  grep -qF 'reviews/test/phase-base.txt' "$TEST_SKILL"
  grep -qF 'printf '"'"'%s\n'"'"'' "$TEST_SKILL"
}

@test "acceptance: dispatch-agent wraps subagent git commands with qrspi-<agent> GIT_AUTHOR_NAME marker" {
  # G5 acceptance bullet 5 — author marker the OBC filter relies on.
  grep -qE 'GIT_AUTHOR_NAME=.*qrspi-|GIT_AUTHOR_NAME="qrspi-' "$DISPATCH_AGENT"
}

@test "e2e: clean integration phase (only seed commit; only allowlisted reviews/ tree) → byte-empty report + exit 0" {
  # plan.md Phase 1 Acceptance bullet 10 — clean run is byte-empty.
  mkdir -p reviews/integration
  printf '%s\n' "$PHASE_BASE_SHA" > reviews/integration/phase-base.txt
  run "$OBC" --phase integration --artifact-dir "$TMP_DIR"
  [ "$status" -eq 0 ]
  [ -f reviews/integration/orchestration-boundary.md ]
  # Byte-empty by acceptance contract.
  [ ! -s reviews/integration/orchestration-boundary.md ]
}

@test "e2e: dispatch-defect (missing phase-base.txt) → ## Dispatch defects populated + non-zero exit" {
  # plan.md Phase 1 Acceptance bullet 10/11 — fail-loud + autopilot halt branch.
  mkdir -p reviews/integration
  # NOTE: phase-base.txt intentionally absent.
  run "$OBC" --phase integration --artifact-dir "$TMP_DIR"
  [ "$status" -ne 0 ]
  [ -f reviews/integration/orchestration-boundary.md ]
  grep -q '^## Dispatch defects$' reviews/integration/orchestration-boundary.md
  grep -qE 'phase-base-missing:|missing' reviews/integration/orchestration-boundary.md
}

@test "e2e: dispatch-defect (malformed bare-SHA phase-base.txt) → sha-format-invalid: + non-zero exit" {
  mkdir -p reviews/integration
  printf 'ZZZZNOTASHA\n' > reviews/integration/phase-base.txt
  run "$OBC" --phase integration --artifact-dir "$TMP_DIR"
  [ "$status" -ne 0 ]
  grep -qE 'sha-format-invalid:|phase-base-malformed:' reviews/integration/orchestration-boundary.md
}

@test "e2e: section-header-emitted-only-when-populated invariant holds on clean run" {
  # design.md § G5 Acceptance bullet 4 — clean run produces no section headers.
  mkdir -p reviews/integration
  printf '%s\n' "$PHASE_BASE_SHA" > reviews/integration/phase-base.txt
  run "$OBC" --phase integration --artifact-dir "$TMP_DIR"
  [ "$status" -eq 0 ]
  ! grep -q '^## Boundary violations$' reviews/integration/orchestration-boundary.md
  ! grep -q '^## Dispatch defects$' reviews/integration/orchestration-boundary.md
}

@test "e2e: non-subagent commit in phase range surfaces under ## Boundary violations (fail-soft)" {
  # design.md § G5 Acceptance bullet 4 — commit-violation row.
  echo "drift" > drift.txt
  git add drift.txt
  git commit -q -m "human drift commit"
  mkdir -p reviews/integration
  printf '%s\n' "$PHASE_BASE_SHA" > reviews/integration/phase-base.txt
  run "$OBC" --phase integration --artifact-dir "$TMP_DIR"
  # fail-soft: exit 0 even though boundary violation present (autopilot uses
  # report content for routing, script exit reserved for dispatch defects).
  [ "$status" -eq 0 ]
  grep -q '^## Boundary violations$' reviews/integration/orchestration-boundary.md
  # Should NOT carry a ## Dispatch defects section (none populated).
  ! grep -q '^## Dispatch defects$' reviews/integration/orchestration-boundary.md
}

@test "acceptance: subagent author marker (qrspi-) is excluded from the non-subagent filter" {
  # G5 acceptance bullet 5 round-trip: a commit authored with the qrspi-
  # marker MUST NOT surface as a boundary violation.
  GIT_AUTHOR_NAME='qrspi-test-writer' GIT_AUTHOR_EMAIL='qrspi-test-writer@example.com' \
    GIT_COMMITTER_NAME='qrspi-test-writer' GIT_COMMITTER_EMAIL='qrspi-test-writer@example.com' \
    bash -c 'echo work > work.txt && git add work.txt && git commit -q -m "subagent commit"'
  mkdir -p reviews/integration
  printf '%s\n' "$PHASE_BASE_SHA" > reviews/integration/phase-base.txt
  run "$OBC" --phase integration --artifact-dir "$TMP_DIR"
  [ "$status" -eq 0 ]
  # subagent commit does NOT populate Boundary violations.
  ! grep -q '^## Boundary violations$' reviews/integration/orchestration-boundary.md
}
