#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# Plan-level INTEGRATION tests for cross-slice interactions in the v0.7.3
# universal dispatch chain. These verify multiple components compose
# correctly across boundaries — not individual component contracts (which
# live in per-script unit tests).
#
# Chains covered:
#   (A) upstream-paths.sh → reviewer/verifier dispatch parameter (G1 + G4)
#       Plan-step full pipeline emits a deterministic set the verifier
#       receives via <upstream_paths>.
#   (B) design-absorption-markers.sh → review-prep.sh (G3 + CD-2)
#       For --step plan/design, review-prep.sh writes the absorption-map
#       to the reviewer-dispatch-consumed path under
#       reviews/<step>/round-NN.absorption-map.tsv.
#   (C) integrate phase-base.txt write → orchestration-boundary-check.sh
#       (G5 + fix-F01) The bare-SHA contract written by the SKILL is
#       readable by the OBC script in the same phase.

setup_file() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")"/../../.. && pwd)"
  export REPO_ROOT
  export UPSTREAM="$REPO_ROOT/scripts/upstream-paths.sh"
  export ABS_MARKERS="$REPO_ROOT/scripts/design-absorption-markers.sh"
  export REVIEW_PREP="$REPO_ROOT/scripts/review-prep.sh"
  export OBC="$REPO_ROOT/scripts/orchestration-boundary-check.sh"
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
# (A) upstream-paths.sh → dispatch parameter chain
# -----------------------------------------------------------------------------

@test "integration: upstream-paths.sh Plan-step full set is a strict superset of the quick set" {
  # Cross-checks that the two pipeline branches share a stable core (the
  # always-appended SKILL trio + goals.md + research/summary.md) so a
  # downstream dispatch consumer can rely on the intersection regardless
  # of pipeline mode.
  printf 'pipeline: full\n' > "$TMP_DIR/config.md"
  run "$UPSTREAM" --step plan --artifact-dir "$TMP_DIR"
  [ "$status" -eq 0 ]
  full_out="$output"
  printf 'pipeline: quick\n' > "$TMP_DIR/config.md"
  run "$UPSTREAM" --step plan --artifact-dir "$TMP_DIR"
  [ "$status" -eq 0 ]
  quick_out="$output"

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    echo "$full_out" | grep -qxF "$line" || {
      echo "quick-set entry '$line' missing from full set" >&2
      false
    }
  done <<<"$quick_out"
}

# -----------------------------------------------------------------------------
# (B) design-absorption-markers.sh → review-prep.sh chain
# -----------------------------------------------------------------------------

@test "integration: review-prep.sh --step plan writes the absorption-map TSV at the documented path" {
  # CD-2 contract: design's and plan's review-prep run produces an
  # absorption-map.tsv consumed by the plan-spec reviewer.
  mkdir -p "$TMP_DIR/docs/release"
  cat > "$TMP_DIR/docs/release/design.md" <<'EOF'
# Design
## G7 — Some goal: absorbed by CD-1
Body.
EOF
  cat > "$TMP_DIR/docs/release/plan.md" <<'EOF'
# Plan
EOF
  cd "$TMP_DIR"
  git add docs/release/design.md docs/release/plan.md
  git commit -q -m "round 1 design+plan"

  # review-prep depends on round-anchor for narrowing on rounds >= 2; round 1
  # uses --base-ref. We give the seed SHA as the base ref.
  run "$REVIEW_PREP" --step plan --round 01 \
      --artifact-dir "$TMP_DIR/docs/release" --base-ref "$BASE_SHA"
  [ "$status" -eq 0 ]
  # Positive direction: this fixture carries a marker (`## G7 — ... absorbed
  # by CD-1`) that MUST trigger an absorption-map write. Assert
  # unconditionally so a regression in the chain (review-prep stops calling
  # design-absorption-markers.sh, or the output-path contract drifts) red-
  # tests instead of vacuously passing under a `[ -f "$map" ]` guard.
  map="$TMP_DIR/docs/release/reviews/plan/round-01.absorption-map.tsv"
  [ -f "$map" ] || {
    echo "expected absorption-map at $map, not found; ls of dir:" >&2
    ls -la "$TMP_DIR/docs/release/reviews/plan/" >&2 || true
    false
  }
  # Per G3 fixture: G7 → CD-1 row must be present.
  grep -qE '^G7[[:space:]]+CD-1$' "$map" || {
    echo "absorption-map written but missing expected G7→CD-1 row" >&2
    cat "$map" >&2
    false
  }
}

# -----------------------------------------------------------------------------
# (C) phase-base.txt write → OBC read chain (post fix-F01)
# -----------------------------------------------------------------------------

@test "integration: bare-SHA phase-base.txt written per fix-F01 contract is consumed cleanly by OBC" {
  # End-to-end bridge: emit phase-base.txt using the exact SKILL incantation
  # shape (printf '%s\n' bare SHA — fix-F01 contract), then run OBC.
  mkdir -p "$TMP_DIR/reviews/integration"
  # Mirror the SKILL prose: `printf '%s\n' "$(git rev-parse HEAD)"`.
  printf '%s\n' "$(git rev-parse HEAD)" > "$TMP_DIR/reviews/integration/phase-base.txt"

  run "$OBC" --phase integration --artifact-dir "$TMP_DIR"
  [ "$status" -eq 0 ]
  # Byte-empty report on a clean phase (no commits past base, no workspace drift).
  [ -f "$TMP_DIR/reviews/integration/orchestration-boundary.md" ]
  [ ! -s "$TMP_DIR/reviews/integration/orchestration-boundary.md" ]
}

@test "integration: key=value phase-base.txt (pre-fix-F01 shape) is REJECTED by OBC as dispatch defect" {
  # Regression-direction: the pre-fix-F01 key=value form MUST surface as a
  # dispatch defect under the post-fix contract, proving the bridge fix
  # actually closed the SKILL↔OBC schema gap.
  mkdir -p "$TMP_DIR/reviews/integration"
  printf 'integration_base_sha=%s\n' "$BASE_SHA" > "$TMP_DIR/reviews/integration/phase-base.txt"
  run "$OBC" --phase integration --artifact-dir "$TMP_DIR"
  [ "$status" -ne 0 ]
  grep -qE '## Dispatch defects' "$TMP_DIR/reviews/integration/orchestration-boundary.md"
}
