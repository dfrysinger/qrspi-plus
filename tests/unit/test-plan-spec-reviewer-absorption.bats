#!/usr/bin/env bats
#
# Task 17a — Plan-spec reviewer absorption-map rubric coverage.
#
# Synthetic-dispatch verification that the T16 rubric clauses in
# agents/qrspi-plan-spec-reviewer.md (a) fire `change_type: scope`
# findings on a plan.md task carrying an absorbed-goal ID, (b) do not
# false-positive on a clean plan.md, and (c) halt non-zero with the
# `dispatch-defect:` named diagnostic when `absorption_map_path:` is
# absent at the Plan step (silent-claude R2-F02 fail-loud direction).
#
# Reviewer agents are LLM-driven (no executable to invoke). The test
# proves rubric coverage by:
#   - drafting synthetic plan.md / design.md fixtures inline,
#   - running the real `scripts/design-absorption-markers.sh` against
#     the design fixture to produce a TSV redirect map,
#   - asserting the rubric clause anchors that govern the reviewer's
#     behaviour on that synthetic input set are present verbatim in
#     `agents/qrspi-plan-spec-reviewer.md` (the load-bearing input to
#     the LLM dispatch), and
#   - confirming the synthetic fixtures actually intersect the map in
#     the way each rubric clause expects (positive fixture: absorbed
#     ID appears in both map and plan; clean fixture: zero intersection).

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
  REVIEWER="$REPO_ROOT/agents/qrspi-plan-spec-reviewer.md"
  export REVIEWER
  MARKERS="$REPO_ROOT/scripts/design-absorption-markers.sh"
  export MARKERS
  FIX_DIR="$REPO_ROOT/tests/fixtures/plan-spec-reviewer-absorption"
  export FIX_DIR
}

setup() {
  TMP="$(mktemp -d "$REPO_ROOT/.bats-tmp-17a.XXXXXX")"
  export TMP
}

teardown() {
  [ -n "$TMP" ] && [ -d "$TMP" ] && rm -rf "$TMP"
}

# ---------------------------------------------------------------------------
# Preconditions: T02 script and T16 rubric file must be present (dependencies).
# ---------------------------------------------------------------------------

@test "T02 dependency: design-absorption-markers.sh exists and is executable" {
  # Test expectation: dispatch order (T02 prereq must be in place before T17a runs).
  [ -f "$MARKERS" ]
  [ -x "$MARKERS" ]
}

@test "T16 dependency: plan-spec reviewer agent body exists" {
  # Test expectation: dispatch order (T16 prereq must be in place before T17a runs).
  [ -f "$REVIEWER" ]
}

# ---------------------------------------------------------------------------
# Rubric-anchor coverage: the load-bearing clauses must be present verbatim.
# These anchors are what the LLM reviewer reads to know to emit the finding.
# ---------------------------------------------------------------------------

@test "rubric clause: absorbed-ID task is a change_type: scope finding" {
  # Test expectation: a synthetic plan.md drafted with an absorbed-ID task
  # produces a `change_type: scope` finding from the plan-spec reviewer.
  # The behaviour is governed by a verbatim rubric clause; assert the
  # anchor phrases that bind absorbed-ID tasks to `change_type: scope`.
  grep -qF 'absorption map at `absorption_map_path`' "$REVIEWER"
  grep -qF '<absorbed-ID> → <absorbing-ID|"no-task">' "$REVIEWER"
  grep -qF 'change_type: scope' "$REVIEWER"
  # The clause must explicitly bind the framing-bypass anti-pattern
  # ("post-<CD> cleanup" / "<absorbed-ID> regression prevention") to the
  # change_type: scope outcome so reviewers do not silently exempt
  # cosmetically-renamed absorbed-ID tasks.
  grep -qF 'post-<CD> cleanup' "$REVIEWER"
  grep -qF 'regression prevention' "$REVIEWER"
}

@test "rubric clause: dispatch-defect halt when absorption_map_path absent at Plan step" {
  # Test expectation: a Plan-step dispatch with absorption_map_path absent
  # halts the reviewer with a `dispatch-defect:` named diagnostic and
  # non-zero exit (silent-claude R2-F02 fail-loud direction).
  grep -qF 'Dispatch-defect contract' "$REVIEWER"
  grep -qF 'dispatch-defect: absorption_map_path absent at plan step' "$REVIEWER"
  grep -qF 'exit non-zero' "$REVIEWER"
  # The clause must forbid the silent-pass direction explicitly so the
  # reviewer cannot satisfy the rubric by emitting zero findings.
  grep -qiE 'do NOT proceed with an empty absorbed-ID set' "$REVIEWER"
}

@test "rubric clause: Plan step is named as a mandatory dispatch site for absorption_map_path" {
  # Test expectation: the Plan step is enumerated as one of exactly two
  # steps where absorption_map_path: is mandatory (so the dispatch-defect
  # halt cannot be neutralised by re-classifying the Plan step as optional).
  grep -qF 'mandatory at exactly two steps — Plan and Design' "$REVIEWER"
}

# ---------------------------------------------------------------------------
# Positive synthetic dispatch: absorbed-ID task intersects the redirect map.
# ---------------------------------------------------------------------------

@test "positive synthetic: absorbed-ID task in plan.md intersects the absorption map" {
  # Test expectation: a synthetic plan.md drafted with a task labeled
  # with an absorbed goal ID (per a fixture absorption-map produced by
  # T02's script) produces a `change_type: scope` finding from the
  # plan-spec reviewer (Acceptance bullet 4, second half).
  #
  # Because the reviewer is LLM-driven, we prove the synthetic dispatch
  # input is well-formed: (1) the script produces a map containing the
  # absorbed ID, (2) the plan.md fixture carries a task whose goal_ids
  # row contains that same absorbed ID, (3) the rubric clause anchored
  # above governs the reviewer's response. Intersection is the
  # necessary-and-sufficient pre-LLM proof.
  design="$TMP/design.md"
  plan="$TMP/plan.md"
  cat >"$design" <<'EOF'
# Design — synthetic absorbed-goal fixture for T17a

## G99 — Cross-cutting absorbed goal: absorbed by CD-1

Body prose for the absorbed goal.
EOF
  cat >"$plan" <<'EOF'
# Plan — synthetic fixture for T17a (positive case)

| ID | Title | Goal | type | tier | LOC | Deps | Acceptance |
|----|-------|------|------|------|-----|------|------------|
| T01 | Post-CD-1 cleanup pass for G99 | G99 | lightweight | low | ~10 | none | Cleanup task for absorbed goal. |
EOF
  run "$MARKERS" "$design"
  [ "$status" -eq 0 ]
  # Map must list G99 → CD-1.
  echo "$output" | grep -qE '^G99	CD-1$'
  # Plan must carry a task whose goal column references G99.
  grep -qF '| G99 |' "$plan"
}

# ---------------------------------------------------------------------------
# Negative synthetic dispatch: clean plan.md produces zero absorption matches.
# ---------------------------------------------------------------------------

@test "negative synthetic: clean plan.md has zero intersection with absorption map (no-false-positive)" {
  # Test expectation: a clean plan.md fixture (no absorbed-ID tasks)
  # produces zero absorption findings (no-false-positive guard).
  design="$TMP/design.md"
  plan="$TMP/plan.md"
  cat >"$design" <<'EOF'
# Design — synthetic absorbed-goal fixture for T17a (clean case)

## G99 — Cross-cutting absorbed goal: absorbed by CD-1

Body prose for the absorbed goal.

## G42 — Independent live goal:

Body prose; this goal carries no absorption marker.
EOF
  cat >"$plan" <<'EOF'
# Plan — synthetic fixture for T17a (clean case — only live goals)

| ID | Title | Goal | type | tier | LOC | Deps | Acceptance |
|----|-------|------|------|------|-----|------|------------|
| T01 | Implement G42 surface | G42 | lightweight | low | ~10 | none | Behaviour change for live goal. |
EOF
  run "$MARKERS" "$design"
  [ "$status" -eq 0 ]
  map="$output"
  # Map should list G99 (absorbed) but not G42 (live).
  echo "$map" | grep -qE '^G99	CD-1$'
  ! echo "$map" | grep -qE '^G42	'
  # For every absorbed ID in the map, assert plan.md carries no task
  # row referencing that ID. Zero intersection ⇒ zero absorption findings.
  while IFS=$'\t' read -r absorbed _absorbing; do
    [ -n "$absorbed" ] || continue
    if grep -qE "\| ${absorbed} \|" "$plan"; then
      echo "false positive: plan.md unexpectedly carries absorbed ID ${absorbed}" >&2
      return 1
    fi
  done <<<"$map"
}

# ---------------------------------------------------------------------------
# Dispatch-defect synthetic: parameter-absent input has no absorption_map_path
# and the rubric clause text mandates non-zero halt with the named diagnostic.
# ---------------------------------------------------------------------------

@test "dispatch-defect synthetic: Plan-step dispatch without absorption_map_path is rubric-required to halt non-zero" {
  # Test expectation: a Plan-step plan-spec-reviewer dispatch with
  # `absorption_map_path:` absent halts the reviewer with a
  # `dispatch-defect:` named diagnostic and non-zero exit — the
  # reviewer does not silently produce a zero-finding pass
  # (silent-claude R2-F02 fail-loud direction).
  #
  # Build a synthetic dispatch parameter set that omits the parameter
  # (Plan-step pipeline=full but no absorption_map_path: line) and
  # assert (a) the parameter is genuinely absent from the synthetic
  # dispatch and (b) the rubric body carries the halt-non-zero
  # contract that governs this input.
  dispatch="$TMP/dispatch.prompt"
  cat >"$dispatch" <<'EOF'
artifact_path: /tmp/plan.md
route: full
round: 1
reviewer_tag: claude
output: /tmp/findings
EOF
  # Synthetic dispatch must NOT contain the parameter — this is the
  # input shape that the dispatch-defect contract is supposed to halt on.
  ! grep -q 'absorption_map_path' "$dispatch"
  # Rubric body must mandate the non-zero halt + named diagnostic +
  # forbid the silent zero-findings direction.
  grep -qF 'halt immediately' "$REVIEWER"
  grep -qF 'dispatch-defect: absorption_map_path absent at plan step' "$REVIEWER"
  grep -qF 'exit non-zero' "$REVIEWER"
  grep -qF 'false-satisfies' "$REVIEWER"
  grep -qF 'fail-loud rule forbids' "$REVIEWER"
}
