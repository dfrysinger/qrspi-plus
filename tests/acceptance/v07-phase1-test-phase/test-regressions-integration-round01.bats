#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# Regression / boundary tests for the three in-pipeline fixes captured in
# docs/qrspi/2026-06-04-v073-release/fixes/integration-round-01/.
#
# These tests register the specific failure modes that surfaced during
# Integrate so re-introduction is mechanically blocked:
#
#   fix-F01-phase-base-format.md
#     SKILL prose for reviews/<phase>/phase-base.txt MUST emit bare SHA
#     (printf '%s\n'), NOT the pre-fix key=value form
#     (printf 'integration_base_sha=%s\n'). OBC parses bare SHA only.
#
#   fix-F02-wave-sidecar-bridge.md
#     scripts/validate-stage-commit-parents.sh MUST dual-write wave-1.txt
#     (OBC's YAML-colon shape) alongside W1.sidecar when --capture --wave-id W1
#     fires; and MUST expose --seed-wave-1-obc for the fan-out-only Wave 1
#     case. OBC's implement-phase batch gate depends on wave-1.txt.
#
#   fix-CI-baseline-pins.md
#     Three v0.7.2-era count/string pins legitimately bumped during v0.7.3:
#     agent count 41→42, CI workflow count 1→2, marketplace v0.7.2→v0.7.3.
#     Once landed, the bumped pins MUST be observed by the live tree.

setup_file() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")"/../../.. && pwd)"
  export REPO_ROOT
  export INTEGRATE_SKILL="$REPO_ROOT/skills/integrate/SKILL.md"
  export TEST_SKILL="$REPO_ROOT/skills/test/SKILL.md"
  export VSCP="$REPO_ROOT/scripts/validate-stage-commit-parents.sh"
  export OBC="$REPO_ROOT/scripts/orchestration-boundary-check.sh"
  export VERSION_FILE="$REPO_ROOT/VERSION"
}

setup() {
  # Per-test scratch under bats-managed tmpdir (see g5 note).
  TMP_DIR="$BATS_TEST_TMPDIR/work"
  mkdir -p "$TMP_DIR"
  cd "$TMP_DIR"
  git init -q .
  git config user.email "human@example.com"
  git config user.name "Human Author"
  echo seed > seed.txt
  git add seed.txt
  git commit -q -m seed
  BASE_SHA="$(git rev-parse HEAD)"
  export TMP_DIR BASE_SHA
}

# No teardown() needed — bats removes $BATS_TEST_TMPDIR itself.

# -----------------------------------------------------------------------------
# fix-F01: bare-SHA phase-base.txt contract
# -----------------------------------------------------------------------------

@test "regression fix-F01: integrate SKILL emits phase-base.txt as bare SHA (no integration_base_sha= prefix)" {
  # NOTE: needles use single-quoted shape so the literal byte sequence handed
  # to grep is exactly one backslash before `n` — matching the SKILL prose
  # verbatim. The earlier double-quoted `"printf '...\\\\n'"` collapsed to
  # TWO backslashes, which made the negated pre-fix assertion pass
  # vacuously and the positive post-fix assertion impossible to satisfy.
  # Forbidden pre-fix shape:
  ! grep -qF 'printf '"'"'integration_base_sha=%s\n'"'"'' "$INTEGRATE_SKILL"
  # Required post-fix shape:
  grep -qF 'printf '"'"'%s\n'"'"'' "$INTEGRATE_SKILL"
  grep -qF 'reviews/integration/phase-base.txt' "$INTEGRATE_SKILL"
}

@test "regression fix-F01: test SKILL emits phase-base.txt as bare SHA (no integration_base_sha= prefix)" {
  ! grep -qF 'printf '"'"'integration_base_sha=%s\n'"'"'' "$TEST_SKILL"
  grep -qF 'printf '"'"'%s\n'"'"'' "$TEST_SKILL"
  grep -qF 'reviews/test/phase-base.txt' "$TEST_SKILL"
}

@test "regression fix-F01: OBC accepts bare-SHA phase-base.txt and produces clean report" {
  mkdir -p reviews/integration
  printf '%s\n' "$BASE_SHA" > reviews/integration/phase-base.txt
  run "$OBC" --phase integration --artifact-dir "$TMP_DIR"
  [ "$status" -eq 0 ]
  [ ! -s reviews/integration/orchestration-boundary.md ]
}

# -----------------------------------------------------------------------------
# fix-F02: wave-state sidecar bridge to OBC contract
# -----------------------------------------------------------------------------

@test "regression fix-F02: --capture --wave-id W1 dual-writes wave-1.txt alongside W1.sidecar" {
  # Reviewer's option #2: W1 capture writes BOTH schemas.
  git checkout -q -b task-A
  echo a > a.txt && git add a.txt && git commit -q -m a
  git checkout -q -
  run "$VSCP" --capture --wave-id W1 \
      --task-branch task-A \
      --wave-state-dir "$TMP_DIR/reviews/implement/wave-state"
  [ "$status" -eq 0 ]
  [ -f "$TMP_DIR/reviews/implement/wave-state/W1.sidecar" ]
  [ -f "$TMP_DIR/reviews/implement/wave-state/wave-1.txt" ]
  # OBC body shape: YAML colon, integration_base on its own line, task_tips: empty.
  grep -qE '^integration_base: [0-9a-f]{7,64}$' "$TMP_DIR/reviews/implement/wave-state/wave-1.txt"
  grep -qE '^task_tips:$' "$TMP_DIR/reviews/implement/wave-state/wave-1.txt"
}

@test "regression fix-F02: --seed-wave-1-obc writes wave-1.txt only (no W1.sidecar) — fan-out-only Wave 1 bridge" {
  run "$VSCP" --seed-wave-1-obc --integration-base "$BASE_SHA" \
      --artifact-dir "$TMP_DIR"
  [ "$status" -eq 0 ]
  [ -f "$TMP_DIR/reviews/implement/wave-state/wave-1.txt" ]
  [ ! -f "$TMP_DIR/reviews/implement/wave-state/W1.sidecar" ]
}

@test "regression fix-F02 e2e: --capture W1 → OBC implement-phase produces empty ## Dispatch defects" {
  # Closes the detection-gap the reviewer flagged.
  git checkout -q -b task-X
  echo x > x.txt && git add x.txt && git commit -q -m x
  git checkout -q -
  run "$VSCP" --capture --wave-id W1 \
      --task-branch task-X \
      --wave-state-dir "$TMP_DIR/reviews/implement/wave-state"
  [ "$status" -eq 0 ]

  run "$OBC" --phase implement --artifact-dir "$TMP_DIR"
  [ "$status" -eq 0 ]
  # No dispatch-defects section header at all (clean).
  if [ -f "$TMP_DIR/reviews/implement/orchestration-boundary.md" ]; then
    ! grep -q '^## Dispatch defects$' "$TMP_DIR/reviews/implement/orchestration-boundary.md"
  fi
}

# -----------------------------------------------------------------------------
# fix-CI-baseline-pins: three bumped v0.7.3-era count/string pins
# -----------------------------------------------------------------------------

@test "regression fix-CI-baseline-pins: VERSION = 0.7.3 (drives marketplace + plugin.json pins)" {
  v="$(tr -d '\n\r' < "$VERSION_FILE")"
  [ "$v" = "0.7.3" ]
  grep -qF '"0.7.3"' "$REPO_ROOT/.claude-plugin/marketplace.json"
}

@test "regression fix-CI-baseline-pins: agents/qrspi-*.md count ≥ 42 (Phase-1 added plan-apply-fix)" {
  count="$(ls -1 "$REPO_ROOT"/agents/qrspi-*.md 2>/dev/null | wc -l | tr -d ' ')"
  # Equality with 42 may drift up over time; the regression-direction is
  # "at least 42" and "qrspi-plan-apply-fix specifically exists".
  [ "$count" -ge 42 ]
  [ -f "$REPO_ROOT/agents/qrspi-plan-apply-fix.md" ]
}

@test "regression fix-CI-baseline-pins: .github/workflows/ carries both ci.yml and build-then-diff.yml" {
  # Pre-fix pin expected count=1; post-fix pin expects both files exist.
  [ -f "$REPO_ROOT/.github/workflows/ci.yml" ]
  [ -f "$REPO_ROOT/.github/workflows/build-then-diff.yml" ]
}
