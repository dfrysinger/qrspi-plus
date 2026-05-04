#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Task 17 — scope-reviewer Rules-Loading Procedure
#
# Post-migration (commit 19/22, 2026-05-04): the parameterized scope-reviewer
# template is replaced by seven dedicated agent files
# (`agents/qrspi-{name}-scope-reviewer.md`), one per artifact type. Each
# agent reads its corresponding `skills/{name}/owns-defers.md` for the
# OWNS/DEFERS rule set. This test asserts that every per-artifact agent
# exists and references its rule-file.
#
# Two halves:
#  1. Per-skill positive-path: the family-shape headings exist and the
#     OWNS/DEFERS H3 sub-blocks each contain ≥1 enumerated bullet.
#     Phasing positive-path is SKIPPED pending FU-5 (phasing/SKILL.md
#     still uses bare `### OWNS` / `### DEFERS` rather than the family-
#     shape `### Phasing OWNS` / `### Phasing DEFERS`).
#  2. Per-malformed-fixture: the four malformed-OWNS/DEFERS fixtures
#     (no heading, no OWNS, no DEFERS, empty bodies) each match exactly
#     one structural defect that the scope-reviewer fail-closed rules
#     (`## Rules-Loading Procedure` ## Fail-closed malformed cases) trip
#     on. One assertion per case, one fixture per case.
#
# Section extraction uses awk to scope assertions to the H2 OWNS/DEFERS
# section (and its H3 children) so unrelated content in the SKILL.md
# cannot vacuously satisfy the check.

setup() {
  ROOT="$BATS_TEST_DIRNAME/../.."
  GOALS_FILE="$ROOT/skills/goals/SKILL.md"
  DESIGN_FILE="$ROOT/skills/design/SKILL.md"
  PHASING_FILE="$ROOT/skills/phasing/SKILL.md"
  STRUCTURE_FILE="$ROOT/skills/structure/SKILL.md"
  PLAN_FILE="$ROOT/skills/plan/SKILL.md"
  PARALLELIZE_FILE="$ROOT/skills/parallelize/SKILL.md"
  GOALS_OWNS_FILE="$ROOT/skills/goals/owns-defers.md"
  DESIGN_OWNS_FILE="$ROOT/skills/design/owns-defers.md"
  PHASING_OWNS_FILE="$ROOT/skills/phasing/owns-defers.md"
  STRUCTURE_OWNS_FILE="$ROOT/skills/structure/owns-defers.md"
  PLAN_OWNS_FILE="$ROOT/skills/plan/owns-defers.md"
  PARALLELIZE_OWNS_FILE="$ROOT/skills/parallelize/owns-defers.md"
  AGENTS_DIR="$ROOT/agents"
  FIXTURES="$ROOT/tests/fixtures"
  export ROOT GOALS_FILE DESIGN_FILE PHASING_FILE STRUCTURE_FILE PLAN_FILE PARALLELIZE_FILE
  export GOALS_OWNS_FILE DESIGN_OWNS_FILE PHASING_OWNS_FILE STRUCTURE_OWNS_FILE PLAN_OWNS_FILE PARALLELIZE_OWNS_FILE
  export AGENTS_DIR FIXTURES
}

# extract_h2_section <file> <h2-heading>
# Prints the H2 section from <h2-heading> until the next ^## boundary.
extract_h2_section() {
  local file="$1"
  local heading="$2"
  awk -v h="$heading" '
    $0 == h { in_b = 1; print; next }
    in_b && /^## / { exit }
    in_b { print }
  ' "$file"
}

# extract_h3_subsection <file> <h2-heading> <h3-heading>
# Extracts the H3 sub-block scoped to the H2 first.
extract_h3_subsection() {
  local file="$1"
  local h2="$2"
  local h3="$3"
  extract_h2_section "$file" "$h2" \
    | awk -v h="$h3" '
        $0 == h { in_b = 1; print; next }
        in_b && /^### / { exit }
        in_b && /^## / { exit }
        in_b { print }
      '
}

# extract_h3_direct <file> <h3-heading>
# Extracts an H3 sub-block directly from a file (no H2 wrapper required).
# Used for owns-defers.md files which start at H3 level.
extract_h3_direct() {
  local file="$1"
  local h3="$2"
  awk -v h="$h3" '
    $0 == h { in_b = 1; print; next }
    in_b && /^### / { exit }
    in_b && /^## / { exit }
    in_b { print }
  ' "$file"
}

# count_enumerated_items <stdin>
# Counts bulleted (`- `) or numbered (`1.`) items in piped block.
count_enumerated_items() {
  awk '
    /^[[:space:]]*-[[:space:]]/ { c++ }
    /^[[:space:]]*[0-9]+\.[[:space:]]/ { c++ }
    END { print c+0 }
  '
}

# ── Per-artifact scope-reviewer agents read the OWNS/DEFERS rule file ───────
# Commit 19/22 migration: spec § Test-suite migration inventory says
# "narrow iteration to 7 artifacts — Questions/Research excluded". Each
# scope-reviewer agent reads `skills/{name}/owns-defers.md` for its
# locked rule set.

@test "qrspi-goals-scope-reviewer agent reads skills/goals/owns-defers.md" {
  local agent="$AGENTS_DIR/qrspi-goals-scope-reviewer.md"
  [ -f "$agent" ]
  grep -q "skills/goals/owns-defers.md" "$agent"
  grep -qE "Goals OWNS.*Goals DEFERS" "$agent"
}

@test "qrspi-design-scope-reviewer agent reads skills/design/owns-defers.md" {
  local agent="$AGENTS_DIR/qrspi-design-scope-reviewer.md"
  [ -f "$agent" ]
  grep -q "skills/design/owns-defers.md" "$agent"
  grep -qE "Design OWNS.*Design DEFERS" "$agent"
}

@test "qrspi-phasing-scope-reviewer agent reads skills/phasing/owns-defers.md" {
  local agent="$AGENTS_DIR/qrspi-phasing-scope-reviewer.md"
  [ -f "$agent" ]
  grep -q "skills/phasing/owns-defers.md" "$agent"
  grep -qE "Phasing OWNS.*Phasing DEFERS" "$agent"
}

@test "qrspi-structure-scope-reviewer agent reads skills/structure/owns-defers.md" {
  local agent="$AGENTS_DIR/qrspi-structure-scope-reviewer.md"
  [ -f "$agent" ]
  grep -q "skills/structure/owns-defers.md" "$agent"
  grep -qE "Structure OWNS.*Structure DEFERS" "$agent"
}

@test "qrspi-plan-scope-reviewer agent reads skills/plan/owns-defers.md" {
  local agent="$AGENTS_DIR/qrspi-plan-scope-reviewer.md"
  [ -f "$agent" ]
  grep -q "skills/plan/owns-defers.md" "$agent"
  grep -qE "Plan OWNS.*Plan DEFERS" "$agent"
}

@test "qrspi-parallelize-scope-reviewer agent reads skills/parallelize/owns-defers.md" {
  local agent="$AGENTS_DIR/qrspi-parallelize-scope-reviewer.md"
  [ -f "$agent" ]
  grep -q "skills/parallelize/owns-defers.md" "$agent"
  grep -qE "Parallelize OWNS.*Parallelize DEFERS" "$agent"
}

@test "qrspi-replan-scope-reviewer agent reads skills/replan/owns-defers.md" {
  local agent="$AGENTS_DIR/qrspi-replan-scope-reviewer.md"
  [ -f "$agent" ]
  grep -q "skills/replan/owns-defers.md" "$agent"
  grep -qE "Replan OWNS.*Replan DEFERS" "$agent"
}

# ── Per-skill positive-path: family-shape headings + ≥1 enumerated item ─────

@test "positive-path: skills/goals/SKILL.md exposes ## Goals OWNS / Goals DEFERS with H3 family-shape sub-blocks (each ≥1 bullet)" {
  run grep -c "^## Goals OWNS / Goals DEFERS$" "$GOALS_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
  local owns defers owns_count defers_count
  owns="$(extract_h3_direct "$GOALS_OWNS_FILE" "### Goals OWNS")"
  defers="$(extract_h3_direct "$GOALS_OWNS_FILE" "### Goals DEFERS")"
  [ -n "$owns" ]
  [ -n "$defers" ]
  owns_count="$(printf '%s\n' "$owns" | count_enumerated_items)"
  defers_count="$(printf '%s\n' "$defers" | count_enumerated_items)"
  [ "$owns_count" -ge 1 ]
  [ "$defers_count" -ge 1 ]
}

@test "positive-path: skills/design/SKILL.md exposes ## Design OWNS / Design DEFERS with H3 family-shape sub-blocks (each ≥1 bullet)" {
  run grep -c "^## Design OWNS / Design DEFERS$" "$DESIGN_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
  local owns defers owns_count defers_count
  owns="$(extract_h3_direct "$DESIGN_OWNS_FILE" "### Design OWNS")"
  defers="$(extract_h3_direct "$DESIGN_OWNS_FILE" "### Design DEFERS")"
  [ -n "$owns" ]
  [ -n "$defers" ]
  owns_count="$(printf '%s\n' "$owns" | count_enumerated_items)"
  defers_count="$(printf '%s\n' "$defers" | count_enumerated_items)"
  [ "$owns_count" -ge 1 ]
  [ "$defers_count" -ge 1 ]
}

@test "positive-path: skills/phasing/SKILL.md exposes ## Phasing OWNS / Phasing DEFERS with family-shape H3 sub-blocks (each ≥1 bullet)" {
  run grep -c "^## Phasing OWNS / Phasing DEFERS$" "$PHASING_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
  local owns defers owns_count defers_count
  owns="$(extract_h3_direct "$PHASING_OWNS_FILE" "### Phasing OWNS")"
  defers="$(extract_h3_direct "$PHASING_OWNS_FILE" "### Phasing DEFERS")"
  [ -n "$owns" ]
  [ -n "$defers" ]
  owns_count="$(printf '%s\n' "$owns" | count_enumerated_items)"
  defers_count="$(printf '%s\n' "$defers" | count_enumerated_items)"
  [ "$owns_count" -ge 1 ]
  [ "$defers_count" -ge 1 ]
}

@test "positive-path: skills/structure/SKILL.md exposes ## Structure OWNS / Structure DEFERS with H3 family-shape sub-blocks (each ≥1 bullet)" {
  run grep -c "^## Structure OWNS / Structure DEFERS$" "$STRUCTURE_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
  local owns defers owns_count defers_count
  owns="$(extract_h3_direct "$STRUCTURE_OWNS_FILE" "### Structure OWNS")"
  defers="$(extract_h3_direct "$STRUCTURE_OWNS_FILE" "### Structure DEFERS")"
  [ -n "$owns" ]
  [ -n "$defers" ]
  owns_count="$(printf '%s\n' "$owns" | count_enumerated_items)"
  defers_count="$(printf '%s\n' "$defers" | count_enumerated_items)"
  [ "$owns_count" -ge 1 ]
  [ "$defers_count" -ge 1 ]
}

@test "positive-path: skills/plan/SKILL.md exposes ## Plan OWNS / Plan DEFERS with H3 family-shape sub-blocks (each ≥1 bullet)" {
  run grep -c "^## Plan OWNS / Plan DEFERS$" "$PLAN_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
  local owns defers owns_count defers_count
  owns="$(extract_h3_direct "$PLAN_OWNS_FILE" "### Plan OWNS")"
  defers="$(extract_h3_direct "$PLAN_OWNS_FILE" "### Plan DEFERS")"
  [ -n "$owns" ]
  [ -n "$defers" ]
  owns_count="$(printf '%s\n' "$owns" | count_enumerated_items)"
  defers_count="$(printf '%s\n' "$defers" | count_enumerated_items)"
  [ "$owns_count" -ge 1 ]
  [ "$defers_count" -ge 1 ]
}

@test "positive-path: skills/parallelize/SKILL.md exposes ## Parallelize OWNS / Parallelize DEFERS with H3 family-shape sub-blocks (each ≥1 bullet)" {
  run grep -c "^## Parallelize OWNS / Parallelize DEFERS$" "$PARALLELIZE_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
  local owns defers owns_count defers_count
  owns="$(extract_h3_direct "$PARALLELIZE_OWNS_FILE" "### Parallelize OWNS")"
  defers="$(extract_h3_direct "$PARALLELIZE_OWNS_FILE" "### Parallelize DEFERS")"
  [ -n "$owns" ]
  [ -n "$defers" ]
  owns_count="$(printf '%s\n' "$owns" | count_enumerated_items)"
  defers_count="$(printf '%s\n' "$defers" | count_enumerated_items)"
  [ "$owns_count" -ge 1 ]
  [ "$defers_count" -ge 1 ]
}

# ── Per-malformed-fixture: each fixture matches exactly one fail-closed case

@test "malformed case 1 (no-heading): fixture omits ## {Skill} OWNS / {Skill} DEFERS H2 entirely → fail-closed" {
  local fixture="$FIXTURES/malformed-owns-defers-no-heading.md"
  [ -f "$fixture" ]
  # The fixture must NOT contain the OWNS/DEFERS H2 family heading at all.
  # The scope-reviewer's Rules-Loading Procedure case 1 fires when the
  # heading is missing entirely.
  ! grep -Eq "^## .* OWNS / .* DEFERS$" "$fixture"
}

@test "malformed case 2 (no-OWNS): fixture has H2 family heading but no ### {Skill} OWNS H3 → fail-closed" {
  local fixture="$FIXTURES/malformed-owns-defers-no-owns.md"
  [ -f "$fixture" ]
  # H2 family heading is present.
  grep -Eq "^## Malformed OWNS / Malformed DEFERS$" "$fixture"
  # But the OWNS H3 is missing.
  ! grep -Eq "^### Malformed OWNS$" "$fixture"
  # And the DEFERS H3 is present (so this is specifically the "no OWNS"
  # case, not "both missing").
  grep -Eq "^### Malformed DEFERS$" "$fixture"
}

@test "malformed case 3 (no-DEFERS): fixture has H2 family heading and OWNS H3 but no ### {Skill} DEFERS H3 → fail-closed" {
  local fixture="$FIXTURES/malformed-owns-defers-no-defers.md"
  [ -f "$fixture" ]
  grep -Eq "^## Malformed OWNS / Malformed DEFERS$" "$fixture"
  grep -Eq "^### Malformed OWNS$" "$fixture"
  ! grep -Eq "^### Malformed DEFERS$" "$fixture"
}

@test "malformed case 4 (empty-body): fixture has both H3 sub-blocks but neither contains an enumerated item → fail-closed" {
  local fixture="$FIXTURES/malformed-owns-defers-empty-body.md"
  [ -f "$fixture" ]
  grep -Eq "^## Malformed OWNS / Malformed DEFERS$" "$fixture"
  grep -Eq "^### Malformed OWNS$" "$fixture"
  grep -Eq "^### Malformed DEFERS$" "$fixture"
  # The H3 sub-blocks must contain ZERO enumerated bulleted/numbered items.
  local owns defers owns_count defers_count
  owns="$(extract_h3_subsection "$fixture" "## Malformed OWNS / Malformed DEFERS" "### Malformed OWNS")"
  defers="$(extract_h3_subsection "$fixture" "## Malformed OWNS / Malformed DEFERS" "### Malformed DEFERS")"
  [ -n "$owns" ]
  [ -n "$defers" ]
  owns_count="$(printf '%s\n' "$owns" | count_enumerated_items)"
  defers_count="$(printf '%s\n' "$defers" | count_enumerated_items)"
  [ "$owns_count" -eq 0 ]
  [ "$defers_count" -eq 0 ]
}
