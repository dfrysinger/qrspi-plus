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
  # Strengthened: the pruning bullet must name all four artifacts. We collapse
  # the OWNS block onto bullet boundaries (`- ` markers) and require a single
  # bullet that contains "prun" plus all four artifact names. This catches
  # mutations that drop pruning ownership of any artifact.
  local cooccur
  cooccur="$(echo "$owns_block" \
    | awk 'BEGIN { RS = "\n- " } { gsub(/\n/, " "); print }' \
    | grep -i "prun" \
    | grep -i "goals" \
    | grep -i "questions" \
    | grep -i "research" \
    | grep -i "design" \
    || true)"
  [ -n "$cooccur" ]
}

# =============================================================================
# Synthesis subagent output enumerates all 8 pruned/future-* targets
# =============================================================================

@test "Phasing Synthesis Subagent block enumerates all 8 pruning targets (4 pruned + 4 future-*)" {
  local subagent_block
  subagent_block="$(awk '
    /^### Phasing Synthesis Subagent$/ { in_section = 1; print; next }
    in_section && /^### / && !/^### Phasing Synthesis Subagent$/ { in_section = 0 }
    in_section && /^## / { in_section = 0 }
    in_section { print }
  ' "$SKILL_FILE")"
  [ -n "$subagent_block" ]

  # All 4 pruned current-phase targets:
  echo "$subagent_block" | grep -qE "[Pp]runed.*goals.md|goals.md.*[Pp]runed|goals.md.*current-phase|current-phase.*goals.md"
  echo "$subagent_block" | grep -qE "[Pp]runed.*questions.md|questions.md.*[Pp]runed|questions.md.*current-phase|current-phase.*questions.md"
  echo "$subagent_block" | grep -qE "[Pp]runed.*research/summary.md|research/summary.md.*[Pp]runed|research/summary.md.*current-phase"
  echo "$subagent_block" | grep -qE "[Pp]runed.*design.md|design.md.*[Pp]runed|design.md.*current-phase|current-phase.*design.md"

  # All 4 future-* targets:
  echo "$subagent_block" | grep -q "future-goals.md"
  echo "$subagent_block" | grep -q "future-questions.md"
  echo "$subagent_block" | grep -q "future-research-summary.md"
  echo "$subagent_block" | grep -q "future-design.md"
}

# =============================================================================
# Fail-closed: atomicity of pruning emission (CodexF-2 / Silent-failure F-3)
# =============================================================================

@test "Four-Artifact Pruning Procedure mandates atomic 8-file emission (partial = fail-closed)" {
  local proc_block
  proc_block="$(awk '
    /^### Four-Artifact Pruning Procedure$/ ||
    /^## Four-Artifact Pruning Procedure$/ { in_section = 1; print; next }
    in_section && /^## / && !/^## Four-Artifact Pruning Procedure$/ { in_section = 0 }
    in_section && /^### / && !/^### Four-Artifact Pruning Procedure$/ { in_section = 0 }
    in_section { print }
  ' "$SKILL_FILE")"
  [ -n "$proc_block" ]

  # Must declare atomicity: 8 files in single emission, partial = invalid.
  echo "$proc_block" | grep -qiE "atomic"
  echo "$proc_block" | grep -qE "8 files|all 8|eight files"
  echo "$proc_block" | grep -qiE "partial|invalid|fail-closed|restart"
}

@test "Phasing Synthesis Subagent block declares atomic emission as fail-closed" {
  local subagent_block
  subagent_block="$(awk '
    /^### Phasing Synthesis Subagent$/ { in_section = 1; print; next }
    in_section && /^### / && !/^### Phasing Synthesis Subagent$/ { in_section = 0 }
    in_section && /^## / { in_section = 0 }
    in_section { print }
  ' "$SKILL_FILE")"
  [ -n "$subagent_block" ]

  # The synthesis subagent block must declare atomicity for the 10-artifact
  # (or 8-file pruning) emission and label partial returns fail-closed.
  echo "$subagent_block" | grep -qiE "atomic|single (return|emission)"
  echo "$subagent_block" | grep -qiE "partial.*(invalid|fail|restart)|fail-closed"
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
