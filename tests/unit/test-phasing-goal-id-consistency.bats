#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# Task 5 — Phasing skill: goal-ID consistency validation contract
#
# Asserts that the Phasing SKILL.md prescribes a goal-ID consistency
# validation procedure that:
#   (a) names all NINE target artifact files,
#   (b) defines the orphan-ID flag for both directions
#       (present-in-file/absent-from-canonical AND
#        present-in-canonical/absent-from-expected-file),
#   (c) names roadmap.md as the canonical reference once it exists.
#
# Per task-05 line 22 + spec test expectation: orphan goal IDs (present in
# goals.md but missing from roadmap.md, or vice versa) are flagged across
# all nine target files.
#
# These are SKILL.md-prompt assertions: the phasing skill is a prompt
# contract; the runtime check is performed by the synthesis + reviewer
# subagents per the procedure documented in the prompt. We assert the
# procedure is documented correctly and exhaustively.

setup() {
  SKILL_FILE="$BATS_TEST_DIRNAME/../../skills/phasing/SKILL.md"
  export SKILL_FILE
}

# Extract a "### child" sub-block out of a "## parent" heading, stopping
# at the next "### " or "## " heading.
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
# Section presence
# =============================================================================

@test "## Goal-ID Consistency Validation section is referenced in the skill" {
  # The validation procedure may live as a top-level "## Goal-ID Consistency
  # Validation" section OR as a "### Goal-ID Consistency Validation"
  # subsection inside Process. Either form satisfies the spec ("a section
  # documenting the procedure"). We require at least one heading that
  # matches the title.
  grep -E '^(##|###) Goal-ID Consistency Validation$' "$SKILL_FILE"
}

# =============================================================================
# Procedure names all NINE target artifact files
# =============================================================================

@test "Goal-ID Consistency Validation procedure names all nine target artifact files" {
  # Extract the procedure block — accept either ## or ### heading level.
  local proc_block
  proc_block="$(awk '
    /^## Goal-ID Consistency Validation$/ ||
    /^### Goal-ID Consistency Validation$/ { in_section = 1; print; next }
    in_section && /^## / && !/^## Goal-ID Consistency Validation$/ { in_section = 0 }
    in_section && /^### / && !/^### Goal-ID Consistency Validation$/ { in_section = 0 }
    in_section { print }
  ' "$SKILL_FILE")"
  [ -n "$proc_block" ]

  # Per design.md M54 + spec test expectation: the nine files are
  # goals.md, questions.md, research/summary.md, design.md,
  # future-goals.md, future-questions.md, future-research-summary.md,
  # future-design.md, roadmap.md.
  echo "$proc_block" | grep -q "goals.md"
  echo "$proc_block" | grep -q "questions.md"
  echo "$proc_block" | grep -q "research/summary.md"
  echo "$proc_block" | grep -q "design.md"
  echo "$proc_block" | grep -q "future-goals.md"
  echo "$proc_block" | grep -q "future-questions.md"
  echo "$proc_block" | grep -q "future-research-summary.md"
  echo "$proc_block" | grep -q "future-design.md"
  echo "$proc_block" | grep -q "roadmap.md"
}

# =============================================================================
# Orphan-ID flag defined for BOTH directions
# =============================================================================

@test "Goal-ID Consistency Validation defines orphan-ID flag (direction A: in file, missing from canonical)" {
  local proc_block
  proc_block="$(awk '
    /^## Goal-ID Consistency Validation$/ ||
    /^### Goal-ID Consistency Validation$/ { in_section = 1; print; next }
    in_section && /^## / && !/^## Goal-ID Consistency Validation$/ { in_section = 0 }
    in_section && /^### / && !/^### Goal-ID Consistency Validation$/ { in_section = 0 }
    in_section { print }
  ' "$SKILL_FILE")"
  [ -n "$proc_block" ]

  # Direction A: ID appears in one of the nine files but missing from the
  # canonical roadmap.md set. Orphan flag must be defined for this case.
  # Require co-occurrence on a single sentence/line of the orphan keyword
  # AND a "missing" keyword AND the canonical reference.
  local cooccur_a
  cooccur_a="$(echo "$proc_block" \
    | tr '\n' ' ' \
    | awk 'BEGIN { RS = "[.!?]" } { print }' \
    | grep -i "orphan" \
    | grep -iE "missing|not in|absent" \
    | grep -i "roadmap" \
    || true)"
  [ -n "$cooccur_a" ]
}

@test "Goal-ID Consistency Validation defines orphan-ID flag (direction B: in canonical, missing from expected file)" {
  local proc_block
  proc_block="$(awk '
    /^## Goal-ID Consistency Validation$/ ||
    /^### Goal-ID Consistency Validation$/ { in_section = 1; print; next }
    in_section && /^## / && !/^## Goal-ID Consistency Validation$/ { in_section = 0 }
    in_section && /^### / && !/^### Goal-ID Consistency Validation$/ { in_section = 0 }
    in_section { print }
  ' "$SKILL_FILE")"
  [ -n "$proc_block" ]

  # Direction B: ID is in canonical roadmap.md but missing from the file
  # expected to contain it (current-phase ID → must appear in goals.md etc;
  # deferred ID → must appear in future-*.md). The procedure must address
  # this case explicitly. We look for a sentence/segment that mentions
  # "expected" (or "current-phase" / "deferred") together with the missing
  # concept on the same logical statement.
  local cooccur_b
  cooccur_b="$(echo "$proc_block" \
    | tr '\n' ' ' \
    | awk 'BEGIN { RS = "[.!?]" } { print }' \
    | grep -iE "expected|current-phase|deferred|future-" \
    | grep -iE "missing|absent|not in|must appear" \
    || true)"
  [ -n "$cooccur_b" ]
}

# =============================================================================
# Canonical reference: roadmap.md when it exists; goals.md fallback
# =============================================================================

@test "Goal-ID Consistency Validation declares roadmap.md as the canonical reference (with goals.md fallback)" {
  local proc_block
  proc_block="$(awk '
    /^## Goal-ID Consistency Validation$/ ||
    /^### Goal-ID Consistency Validation$/ { in_section = 1; print; next }
    in_section && /^## / && !/^## Goal-ID Consistency Validation$/ { in_section = 0 }
    in_section && /^### / && !/^### Goal-ID Consistency Validation$/ { in_section = 0 }
    in_section { print }
  ' "$SKILL_FILE")"
  [ -n "$proc_block" ]

  # Must declare roadmap.md as the canonical set.
  echo "$proc_block" | grep -qiE "canonical.*roadmap.md|roadmap.md.*canonical"

  # Must mention a fallback path when roadmap.md does not yet exist —
  # design.md M54 says the canonical set is roadmap.md once it exists,
  # falling back to goals.md (+ future-goals.md union) before that.
  echo "$proc_block" | grep -qiE "fallback|until|before|when.*exists|once.*exists"
  echo "$proc_block" | grep -q "goals.md"
}

# =============================================================================
# Orphan list surfaced for user resolution (not silently dropped)
# =============================================================================

@test "Goal-ID Consistency Validation specifies orphans are surfaced for user resolution" {
  local proc_block
  proc_block="$(awk '
    /^## Goal-ID Consistency Validation$/ ||
    /^### Goal-ID Consistency Validation$/ { in_section = 1; print; next }
    in_section && /^## / && !/^## Goal-ID Consistency Validation$/ { in_section = 0 }
    in_section && /^### / && !/^### Goal-ID Consistency Validation$/ { in_section = 0 }
    in_section { print }
  ' "$SKILL_FILE")"
  [ -n "$proc_block" ]

  # Orphans must be presented to the user, not silently dropped or
  # auto-resolved by the synthesis subagent. Look for a phrase that names
  # user-side resolution.
  echo "$proc_block" | grep -qiE "user|surface|resolution|review"
}
