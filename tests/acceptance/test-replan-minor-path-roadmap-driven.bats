#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Task 14 — Acceptance: Replan minor path is roadmap-driven and produces
# next-phase drafts that cascade through Goals → Questions → Research → Design.
#
# This is a content-level acceptance test that the SKILL.md procedure
# documents the expected file contracts end-to-end:
#   - Replan reads roadmap.md to find next-phase goal IDs
#   - Replan extracts entries from each future-*.md by goal ID
#   - Replan writes four next-phase drafts (goals, questions, research/summary,
#     design) carrying status: draft
#   - Goals → Questions → Research → Design picks up the populated drafts
#     via the standard cross-skill handoff, with each artifact still in draft
#     so it is re-reviewed before advancing.

setup() {
  REPLAN_FILE="$BATS_TEST_DIRNAME/../../skills/replan/SKILL.md"
  GOALS_FILE="$BATS_TEST_DIRNAME/../../skills/goals/SKILL.md"
  export REPLAN_FILE GOALS_FILE
}

extract_section() {
  local file="$1"
  local heading="$2"
  awk -v h="$heading" '
    $0 == h { in_section = 1; print; next }
    in_section && /^## / { in_section = 0 }
    in_section { print }
  ' "$file"
}

# ── Roadmap-driven minor path ───────────────────────────────────────────────

@test "Replan minor path reads roadmap.md to identify next-phase goal IDs" {
  # Step 2 of the five-step sequence binds roadmap.md to next-phase goal IDs.
  grep -qE "Read roadmap.*roadmap.md.*next phase|roadmap.md.*next-phase goal IDs" "$REPLAN_FILE"
}

@test "Replan minor path extracts from all four future-* artifacts by goal ID" {
  # Step 3: extract entries by goal ID from each future-* artifact.
  local block
  block="$(awk '
    /^### Archive-and-Populate Sequence/ { in_b = 1; print; next }
    in_b && /^## / { exit }
    in_b && /^### / && !/^### Archive-and-Populate Sequence/ { exit }
    in_b { print }
  ' "$REPLAN_FILE")"
  [ -n "$block" ]
  echo "$block" | grep -q "future-goals.md"
  echo "$block" | grep -q "future-questions.md"
  echo "$block" | grep -q "future-research-summary.md"
  echo "$block" | grep -q "future-design.md"
  echo "$block" | grep -qiE "goal ID"
}

@test "Replan minor path writes four next-phase drafts (goals, questions, research/summary, design)" {
  local block
  block="$(awk '
    /^### Archive-and-Populate Sequence/ { in_b = 1; print; next }
    in_b && /^## / { exit }
    in_b && /^### / && !/^### Archive-and-Populate Sequence/ { exit }
    in_b { print }
  ' "$REPLAN_FILE")"
  # Step 4 must enumerate the four drafts by name.
  echo "$block" | grep -E "^4\. " >/dev/null
  # The drafts named in the surrounding step-4 prose:
  echo "$block" | grep -q "goals.md"
  echo "$block" | grep -q "questions.md"
  echo "$block" | grep -q "research/summary.md"
  echo "$block" | grep -q "design.md"
}

@test "All four next-phase drafts carry status: draft" {
  local block
  block="$(awk '
    /^### Archive-and-Populate Sequence/ { in_b = 1; print; next }
    in_b && /^## / { exit }
    in_b && /^### / && !/^### Archive-and-Populate Sequence/ { exit }
    in_b { print }
  ' "$REPLAN_FILE")"
  echo "$block" | grep -qE "status: ?draft"
}

@test "Replan minor path invokes Goals (unchanged invocation target)" {
  local block
  block="$(awk '
    /^### Archive-and-Populate Sequence/ { in_b = 1; print; next }
    in_b && /^## / { exit }
    in_b && /^### / && !/^### Archive-and-Populate Sequence/ { exit }
    in_b { print }
  ' "$REPLAN_FILE")"
  echo "$block" | grep -q "qrspi:goals"
}

# ── Cascade through Goals → Questions → Research → Design ──────────────────

@test "Goals Next-Phase Restart Mode is the documented entry point for the populated drafts" {
  # The minor-path Terminal State (and the OWNS section) reference Goals'
  # Next-Phase Restart Mode as the cascade entry point.
  grep -qE "Next-Phase Restart Mode" "$REPLAN_FILE"
  # And Goals SKILL.md must actually define that mode (cross-skill handoff
  # contract). If Goals doesn't have it, the cascade is broken.
  grep -qE "Next-Phase Restart Mode" "$GOALS_FILE"
}

@test "Major path remains unchanged (loop back to upstream skill on substantive learnings)" {
  # The Human Gate — Major Changes section still routes through Goals/Design/
  # Structure loop-back targets.
  local section
  section="$(extract_section "$REPLAN_FILE" "## Human Gate — Major Changes")"
  echo "$section" | grep -qE "qrspi:goals"
  echo "$section" | grep -qE "qrspi:design"
  echo "$section" | grep -qE "qrspi:structure"
  echo "$section" | grep -qiE "loop[- ]back"
}

# ── String-contract: future-research naming normalization ──────────────────

@test "no future-research/ directory references remain in skills/replan/SKILL.md" {
  ! grep -q "future-research/" "$REPLAN_FILE"
}

@test "future-research-summary.md appears in the minor-path region (acceptance contract)" {
  local minor_region
  minor_region="$(awk '
    /^## Human Gate — Minor Changes/ { in_b = 1 }
    in_b && /^## Human Gate — Major Changes/ { exit }
    in_b { print }
  ' "$REPLAN_FILE")"
  echo "$minor_region" | grep -q "future-research-summary.md"
}
