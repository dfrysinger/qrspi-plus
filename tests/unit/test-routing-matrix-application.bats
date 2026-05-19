#!/usr/bin/env bats
#
# T07 Slice 1 unit pin — initial G5 routing matrix application.
#
# Pins the G5 default model_routing: matrix shipped in
# skills/implement/SKILL.md § "Initial Routing Matrix" (the table that maps
# each `model_role:` to its default route + tier). Each dispatcher class is
# observable AND the conditional cells (citation-density-gated rows) route
# to the trusted tier by default.
#
# Bash 3.2 portable.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
  IMPLEMENT="$REPO_ROOT/skills/implement/SKILL.md"
  export IMPLEMENT
}

# ---------------------------------------------------------------------------
# Per-role initial-matrix decisions: every documented role appears with its
# declared route + tier in the matrix table.
# ---------------------------------------------------------------------------

@test "matrix: qrspi-research-collator routes to cheap tier (DeepSeek V3)" {
  run grep -E "qrspi-research-collator.*DeepSeek V3|qrspi-research-collator.*cheap-model" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}

@test "matrix: qrspi-implementer-lightweight routes to cheap tier (DeepSeek V3)" {
  run grep -E "qrspi-implementer-lightweight.*DeepSeek V3|qrspi-implementer-lightweight.*cheap-model" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}

@test "matrix: qrspi-research-specialist routes to cheap tier with conditional citation-density gate" {
  run grep -E "qrspi-research-specialist.*citation-density gated|qrspi-research-specialist.*cheap-model eligible \\(conditional\\)" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}

@test "matrix: general-purpose / Explore agent routes to trusted (Sonnet)" {
  run grep -E "general-purpose.*Sonnet.*trusted|Explore agent.*Sonnet.*trusted" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}

@test "matrix: qrspi-test-writer routes to trusted (Sonnet)" {
  run grep -E "qrspi-test-writer.*Sonnet.*trusted" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Conditional-cell trusted-by-default routing: the citation-density-gated
# row notes that below-floor output re-runs on the trusted tier.
# ---------------------------------------------------------------------------

@test "conditional cell: below-floor specialist output re-runs on trusted tier (matrix row rationale)" {
  run grep -E "Cheap model is sufficient WHEN citation density meets the floor.*below-floor output triggers one re-run on the trusted model" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Matrix-to-test cross-reference: the prose explicitly names this pin file
# as the observability mechanism — a regression that drops the pin
# reference also drops the observability claim.
# ---------------------------------------------------------------------------

@test "matrix cross-reference: T07 routing-matrix pin file named as the observability mechanism" {
  run grep -F "test-routing-matrix-application.bats" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Slice 1 acceptance deliverable: the matrix is the G5 Slice 1 deliverable
# and is consumed by Implement at every dispatch through the four-layer
# routing chain — operator edits to model_routing: override defaults.
# ---------------------------------------------------------------------------

@test "matrix: declared as Slice 1 acceptance deliverable for G5" {
  run grep -E "Slice 1 acceptance deliverable for G5|G5 deliverable" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}

@test "matrix: operator-edited model_routing: entries override defaults without code changes" {
  run grep -F "operator-edited \`model_routing:\` entries override the defaults without code changes" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}
