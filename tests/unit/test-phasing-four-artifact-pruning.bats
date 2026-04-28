#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# Task 5 — Phasing skill: four-artifact pruning contract
#
# Asserts that the Phasing SKILL.md prescribes a pruning procedure that:
#   (a) splits ALL FOUR synthesizing artifacts (goals.md, questions.md,
#       research/summary.md, design.md) into current-phase + future-* files,
#   (b) names each future-* target file by exact name,
#   (c) explicitly excludes individual research/q*.md files from splitting,
#   (d) is referenced from the Phasing OWNS section (so reviewers know it
#       is owned by this skill, not Replan).
#
# Per task-05 line 24: "pruning splits goals.md, questions.md,
# research/summary.md, design.md into current-phase + future-* files;
# individual research/q*.md files are not split."

setup() {
  SKILL_FILE="$BATS_TEST_DIRNAME/../../skills/phasing/SKILL.md"
  export SKILL_FILE
}

# Extract a "## parent" section up to the next "## " heading.
extract_section() {
  local file="$1"
  local heading="$2"
  awk -v h="$heading" '
    $0 == h { in_section = 1; print; next }
    in_section && /^## / { in_section = 0 }
    in_section { print }
  ' "$file"
}

# Extract a "### child" sub-block out of a "## parent" heading, stopping at
# the next "### " or "## " heading.
extract_subsection() {
  local file="$1"
  local parent="$2"
  local child="$3"
  awk -v p="$parent" -v c="$child" '
    $0 == p { in_parent = 1; next }
    in_parent && $0 == c { in_child = 1; print; next }
    in_child && /^### / { exit }
    in_child && /^## / { exit }
    in_parent && /^## / && $0 != p { in_parent = 0 }
    in_child { print }
  ' "$file"
}

# =============================================================================
# Pruning procedure section is present
# =============================================================================

@test "Four-Artifact Pruning Procedure section is present in the skill prompt" {
  # The procedure must be named explicitly so reviewers and synthesis
  # subagents can find it. Accept ## or ### heading level.
  grep -E '^(##|###) Four-Artifact Pruning Procedure$' "$SKILL_FILE"
}

# =============================================================================
# All four current-phase source artifacts named
# =============================================================================

@test "Four-Artifact Pruning Procedure names all four source artifacts" {
  local proc_block
  proc_block="$(awk '
    /^### Four-Artifact Pruning Procedure$/ ||
    /^## Four-Artifact Pruning Procedure$/ { in_section = 1; print; next }
    in_section && /^## / && !/^## Four-Artifact Pruning Procedure$/ { in_section = 0 }
    in_section && /^### / && !/^### Four-Artifact Pruning Procedure$/ { in_section = 0 }
    in_section { print }
  ' "$SKILL_FILE")"
  [ -n "$proc_block" ]

  # The four artifacts in scope of pruning:
  echo "$proc_block" | grep -q "goals.md"
  echo "$proc_block" | grep -q "questions.md"
  echo "$proc_block" | grep -q "research/summary.md"
  echo "$proc_block" | grep -q "design.md"
}

# =============================================================================
# All four future-* targets named
# =============================================================================

@test "Four-Artifact Pruning Procedure names all four future-* target artifacts" {
  local proc_block
  proc_block="$(awk '
    /^### Four-Artifact Pruning Procedure$/ ||
    /^## Four-Artifact Pruning Procedure$/ { in_section = 1; print; next }
    in_section && /^## / && !/^## Four-Artifact Pruning Procedure$/ { in_section = 0 }
    in_section && /^### / && !/^### Four-Artifact Pruning Procedure$/ { in_section = 0 }
    in_section { print }
  ' "$SKILL_FILE")"
  [ -n "$proc_block" ]

  # The four future-* targets:
  echo "$proc_block" | grep -q "future-goals.md"
  echo "$proc_block" | grep -q "future-questions.md"
  echo "$proc_block" | grep -q "future-research-summary.md"
  echo "$proc_block" | grep -q "future-design.md"
}

# =============================================================================
# Individual research/q*.md files are explicitly excluded from splitting
# =============================================================================

@test "Four-Artifact Pruning Procedure excludes individual research/q*.md files from splitting" {
  local proc_block
  proc_block="$(awk '
    /^### Four-Artifact Pruning Procedure$/ ||
    /^## Four-Artifact Pruning Procedure$/ { in_section = 1; print; next }
    in_section && /^## / && !/^## Four-Artifact Pruning Procedure$/ { in_section = 0 }
    in_section && /^### / && !/^### Four-Artifact Pruning Procedure$/ { in_section = 0 }
    in_section { print }
  ' "$SKILL_FILE")"
  [ -n "$proc_block" ]

  # Must explicitly mention research/q*.md (or equivalent q*.md file pattern)
  # AND the negation (NOT split / not pruned / remain / stay / kept).
  # Co-occurrence required on a single sentence so a stray mention elsewhere
  # cannot vacuously satisfy.
  local cooccur
  cooccur="$(echo "$proc_block" \
    | tr '\n' ' ' \
    | awk 'BEGIN { RS = "[.!?]" } { print }' \
    | grep -iE "q\*\.md|research/q" \
    | grep -iE "NOT split|not pruned|remain|stay|kept|reference|do NOT" \
    || true)"
  [ -n "$cooccur" ]
}

# =============================================================================
# Pruning is named under Phasing OWNS (boundary ownership)
# =============================================================================

@test "Phasing OWNS section names current-phase pruning of the four synthesizing artifacts" {
  local owns_block
  owns_block="$(extract_subsection "$SKILL_FILE" "## Phasing OWNS / Phasing DEFERS" "### OWNS")"
  [ -n "$owns_block" ]

  # OWNS must mention pruning specifically — Phasing owns this; Design and
  # Structure DEFER it. Per design.md M54.
  echo "$owns_block" | grep -qi "prun"
}

# =============================================================================
# DEFERS section does NOT claim pruning ownership for any other skill
# (this is a guard against accidental boundary violation in the prompt itself)
# =============================================================================

@test "Phasing DEFERS section does not redirect pruning ownership to another skill" {
  local defers_block
  defers_block="$(extract_subsection "$SKILL_FILE" "## Phasing OWNS / Phasing DEFERS" "### DEFERS")"
  [ -n "$defers_block" ]

  # DEFERS must NOT contain a "pruning ... → Design" or "pruning ...
  # → Structure" entry — pruning is owned by Phasing, not deferred.
  ! echo "$defers_block" | grep -qiE "pruning.*(Design|Structure|Plan|Replan|Goals)"
}
