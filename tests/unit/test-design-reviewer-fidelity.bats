#!/usr/bin/env bats
#
# tests/unit/test-design-reviewer-fidelity.bats — T17b
#
# Covers task-17b Test Expectations:
#   - A synthetic design.md with an intent/marker contradiction produces a
#     fidelity-mismatch finding from the design reviewer (G3 Acceptance
#     bullet 5, second half).
#   - A clean design.md fixture (markers consistent with goal-block bodies)
#     produces zero fidelity-mismatch findings (no-false-positive guard).
#
# Since an LLM cannot run inside bats, the assertion surface is the
# synthetic dispatch prompt assembled by `scripts/dispatch-agent.sh
# --dry-run`. That prompt carries the design-reviewer agent body (including
# the T16 fidelity-check rubric clause), the artifact_body wrapper around
# the synthetic design.md, and the threaded `absorption_map_path:` field —
# the three inputs an LLM reviewer requires to emit a fidelity-mismatch
# finding. A contradictory fixture co-locates (a) a heading-suffix
# absorption marker and (b) a body that describes independent scope, so the
# rubric's clause (a) ("a goal block whose prose describes independent
# scope but whose marker says absorbed (intent/marker contradiction)") has
# concrete fuel to fire on. The clean fixture removes the contradiction —
# body intent matches the marker — so the rubric clause has no fuel.

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
  WRAPPER="$REPO_ROOT/scripts/dispatch-agent.sh"
  AGENT="$REPO_ROOT/agents/qrspi-design-reviewer.md"
  export WRAPPER AGENT
}

setup() {
  # TMP_DIR must canonicalize UNDER $REPO_ROOT/ so dispatch-agent's
  # repo-boundary guard (assert_path_under_repo_root) accepts fixture paths.
  TMP_DIR="$(mktemp -d "$REPO_ROOT/.bats-tmp-fidelity.XXXXXX")"
  export TMP_DIR
}

teardown() {
  cd /
  rm -rf "$TMP_DIR"
}

# Build a contradictory design.md fixture: heading-suffix marker claims
# "absorbed by CD-1" but the goal body describes independent scope.
write_contradictory_design() {
  cat > "$TMP_DIR/design.md" <<'EOF'
# Design

## G99 — Standalone caching layer: absorbed by CD-1

**Outcome.** Ship a standalone caching layer with its own configuration
surface, dedicated worker pool, and independent on-disk eviction policy.
The cache is reachable from every consumer module via a published client
API and has no dependency on CD-1's review-prep machinery.

**Solution.** Implement the cache as an independent component with its own
release lifecycle. Nothing in this goal's scope reduces to or composes
with CD-1; the heading marker above is the only place CD-1 is referenced.

**Acceptance.** Cache hit-rate ≥ 80% on the v0.7.3 self-host fixture.
EOF
}

# Build a clean design.md fixture: marker and body are consistent — the
# body explicitly describes the goal as absorbed by CD-1, no contradiction.
write_clean_design() {
  cat > "$TMP_DIR/design.md" <<'EOF'
# Design

## G99 — Standalone caching layer: absorbed by CD-1

**Outcome.** No separate task ships under G99. The caching concern is
absorbed in full by CD-1's review-prep generation: CD-1's per-step
output-cache primitive subsumes every caching need this goal originally
scoped, and no residual independent work remains.

**Solution.** Deleted. See CD-1 § review-prep output-cache for the
implementation. This block is preserved only as a traceability anchor for
the absorbed-goal ID.

**Acceptance.** CD-1's review-prep output-cache acceptance covers G99.
EOF
}

# Write a synthetic absorption map matching the heading-suffix marker.
write_absorption_map() {
  printf 'G99\tCD-1\n' > "$TMP_DIR/absorption-map.tsv"
}

# Invoke dispatch-agent.sh --dry-run with the design-reviewer agent body,
# the fixture design.md as the artifact_body, and the absorption map as
# both a companion artifact and a scalar dispatch field. Echo the
# assembled prompt to stdout for assertion via `$output`.
run_dry_dispatch() {
  run "$WRAPPER" \
    --agent-file "$AGENT" \
    --reviewer-tag design-fidelity-test \
    --output-dir "$TMP_DIR/out" \
    --round 1 \
    --artifact-body "$TMP_DIR/design.md" \
    --companion "absorption_map=$TMP_DIR/absorption-map.tsv" \
    --field "absorption_map_path=$TMP_DIR/absorption-map.tsv" \
    --dry-run
}

# Test expectation: the design-reviewer fidelity rubric clause fires on a
# synthetic design.md where the heading-suffix marker contradicts the goal
# body's intent — the assembled dispatch prompt must carry all three
# inputs an LLM reviewer needs to emit a fidelity-mismatch finding:
#   1. The rubric clause itself (intent/marker contradiction language)
#   2. The contradictory fixture data (marker AND independent-scope body)
#   3. The threaded absorption_map_path field
@test "intent/marker contradiction: dispatch carries rubric, contradictory fixture, and absorption_map_path" {
  write_contradictory_design
  write_absorption_map
  run_dry_dispatch
  [ "$status" -eq 0 ] || return 1
  # Rubric clause from the design-reviewer agent body (T16):
  [[ "$output" == *"intent/marker contradiction"* ]] || return 1
  [[ "$output" == *"absorption_map_path"* ]] || return 1
  # The contradictory fixture: heading-suffix absorption marker
  [[ "$output" == *"G99 — Standalone caching layer: absorbed by CD-1"* ]] || return 1
  # And the body describing independent scope (the contradiction):
  [[ "$output" == *"independent on-disk eviction policy"* ]] || return 1
  [[ "$output" == *"no dependency on CD-1"* ]] || return 1
  # And the absorption-map companion content:
  [[ "$output" == *"G99"*"CD-1"* ]] || return 1
}

# Test expectation: no-false-positive guard. A clean design.md whose body
# intent matches its marker carries the same rubric clause in the
# assembled prompt (the rubric is always present), but the fixture body
# itself declares the goal absorbed — so the LLM reviewer has no
# contradiction to flag. The bats assertion is the negative form: the
# clean fixture body must NOT contain independent-scope language.
@test "clean fixture: marker and body consistent — no contradiction signal in the dispatched artifact" {
  write_clean_design
  write_absorption_map
  run_dry_dispatch
  [ "$status" -eq 0 ] || return 1
  # Rubric clause still present (always-on rubric):
  [[ "$output" == *"intent/marker contradiction"* ]] || return 1
  # Marker present:
  [[ "$output" == *"G99 — Standalone caching layer: absorbed by CD-1"* ]] || return 1
  # Body explicitly affirms absorption (no contradiction):
  [[ "$output" == *"No separate task ships under G99"* ]] || return 1
  [[ "$output" == *"absorbed in full by CD-1"* ]] || return 1
  # And the body does NOT carry independent-scope language that would be
  # a false-positive contradiction signal:
  [[ "$output" != *"independent on-disk eviction policy"* ]] || return 1
  [[ "$output" != *"no dependency on CD-1"* ]] || return 1
}
