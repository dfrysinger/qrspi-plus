#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# Task 5 — Phasing skill: roadmap-generation contract
#
# These tests assert that the Phasing SKILL.md prescribes a roadmap.md
# output template with at least one phase → slice → goal-ID mapping row,
# and that the synthesis subagent contract names roadmap.md as a required
# output. The skill prompt IS the contract for the synthesis subagent —
# so the assertions here grep the prompt for the structural commitments
# the spec requires (per task-05 line 22).
#
# Section-scoped extraction is used (mirroring test-reviewer-boilerplate-embed)
# so a string appearing under a different heading cannot vacuously satisfy
# a different section's check.

setup() {
  SKILL_FILE="$BATS_TEST_DIRNAME/../../skills/phasing/SKILL.md"
  export SKILL_FILE
}

# extract_section <file> <heading-line>
# Prints from the exact heading line up to (but not including) the next "^## "
# heading. Heading line itself is included in the output.
extract_section() {
  local file="$1"
  local heading="$2"
  awk -v h="$heading" '
    $0 == h { in_section = 1; print; next }
    in_section && /^## / { in_section = 0 }
    in_section { print }
  ' "$file"
}

# extract_subsection <file> <parent-heading> <child-heading>
# Extracts a "### child" sub-block from inside a "## parent" section.
extract_subsection() {
  local file="$1"
  local parent="$2"
  local child="$3"
  extract_section "$file" "$parent" \
    | awk -v h="$child" '
        $0 == h { in_b = 1; print; next }
        in_b && /^### / { exit }
        in_b && /^## / { exit }
        in_b { print }
      '
}

# =============================================================================
# Spec test expectation: SKILL.md exists at canonical path
# =============================================================================

@test "phasing SKILL.md exists at skills/phasing/SKILL.md" {
  [ -f "$SKILL_FILE" ]
}

# =============================================================================
# Outputs section names roadmap.md as a required artifact
# =============================================================================

@test "## Outputs (or ### Outputs) names roadmap.md as a synthesis output" {
  # Outputs may appear as a top-level "## Outputs" or as a "### Outputs"
  # nested under Process. Try both; require at least one to mention roadmap.md.
  local section_top section_sub
  section_top="$(extract_section "$SKILL_FILE" "## Outputs")"
  section_sub="$(awk '
    /^### Outputs$/ { in_section = 1; print; next }
    in_section && /^### / && !/^### Outputs$/ { in_section = 0 }
    in_section && /^## / { in_section = 0 }
    in_section { print }
  ' "$SKILL_FILE")"
  local combined="${section_top}${section_sub}"
  [ -n "$combined" ]
  echo "$combined" | grep -q "roadmap.md"
}

# =============================================================================
# Phasing OWNS section claims roadmap.md authoring
# =============================================================================

@test "## Phasing OWNS / Phasing DEFERS section names roadmap.md authoring under OWNS" {
  local owns_block
  owns_block="$(extract_subsection "$SKILL_FILE" "## Phasing OWNS / Phasing DEFERS" "### OWNS")"
  [ -n "$owns_block" ]
  # Must mention roadmap.md authoring/ownership specifically.
  echo "$owns_block" | grep -q "roadmap.md"
}

# =============================================================================
# Roadmap output template includes a phase → slice → goal-ID mapping row
# (spec test line 22: "given fixture goals/questions/research/design,
#  the synthesis output includes a roadmap.md with at least one
#  phase → slice → goal-ID mapping row")
# =============================================================================

@test "roadmap.md output template enumerates the three required columns (Goal ID, Phase, Slice)" {
  # The roadmap template is shown in the SKILL.md under a "### `roadmap.md`
  # Output Template" sub-heading. Extract the markdown code-fence inside it
  # and assert the column header line exists.
  local roadmap_section
  roadmap_section="$(awk '
    /^### `roadmap.md` Output Template$/ { in_section = 1; print; next }
    in_section && /^### / && !/^### `roadmap.md` Output Template$/ { in_section = 0 }
    in_section && /^## / { in_section = 0 }
    in_section { print }
  ' "$SKILL_FILE")"
  [ -n "$roadmap_section" ]
  # The column header line must mention Goal ID, Phase, and Slice on the same line.
  echo "$roadmap_section" | grep -E '^\| *Goal ID *\| *Phase *\| *Slice *\|'
}

@test "roadmap.md output template shows at least one example mapping row (phase → slice → goal-ID)" {
  # Example row shape: "| G1 | 1 | Slice 1 |" — at least one such row must be
  # present in the template so the synthesis subagent has a concrete shape
  # to follow. Per spec: "at least one phase → slice → goal-ID mapping row".
  local roadmap_section
  roadmap_section="$(awk '
    /^### `roadmap.md` Output Template$/ { in_section = 1; print; next }
    in_section && /^### / && !/^### `roadmap.md` Output Template$/ { in_section = 0 }
    in_section && /^## / { in_section = 0 }
    in_section { print }
  ' "$SKILL_FILE")"
  [ -n "$roadmap_section" ]
  # A data row in a markdown table starts with `|` and contains at least
  # three pipe-separated cells. We require at least one such row that is
  # NOT the header line (which contains "Goal ID") and NOT a separator row
  # (which contains only "|", "-", and ":"). The presence of an alphanumeric
  # token in the first cell confirms it is an example row, not a placeholder.
  local example_row_count
  example_row_count="$(echo "$roadmap_section" \
    | grep -E '^\|' \
    | grep -vE '^\| *Goal ID' \
    | grep -vE '^\|[-: |]+\|$' \
    | grep -cE '^\| *[A-Za-z0-9]' || true)"
  [ "$example_row_count" -ge 1 ]
}

# =============================================================================
# Synthesis subagent contract names the roadmap.md output explicitly
# =============================================================================

@test "Phasing Synthesis Subagent block lists roadmap.md among subagent outputs" {
  # The synthesis subagent block is under "### Phasing Synthesis Subagent"
  # inside Process. Its "Subagent outputs" enumeration must list roadmap.md.
  local subagent_block
  subagent_block="$(awk '
    /^### Phasing Synthesis Subagent$/ { in_section = 1; print; next }
    in_section && /^### / && !/^### Phasing Synthesis Subagent$/ { in_section = 0 }
    in_section && /^## / { in_section = 0 }
    in_section { print }
  ' "$SKILL_FILE")"
  [ -n "$subagent_block" ]
  echo "$subagent_block" | grep -q "roadmap.md"
}

# =============================================================================
# All four required input artifacts named in the synthesis subagent contract
# (Phasing's gating spec: goals.md, questions.md, research/summary.md, design.md)
# =============================================================================

@test "Phasing Synthesis Subagent block names all four required synthesizing-artifact inputs" {
  local subagent_block
  subagent_block="$(awk '
    /^### Phasing Synthesis Subagent$/ { in_section = 1; print; next }
    in_section && /^### / && !/^### Phasing Synthesis Subagent$/ { in_section = 0 }
    in_section && /^## / { in_section = 0 }
    in_section { print }
  ' "$SKILL_FILE")"
  [ -n "$subagent_block" ]
  echo "$subagent_block" | grep -q "goals.md"
  echo "$subagent_block" | grep -q "questions.md"
  echo "$subagent_block" | grep -q "research/summary.md"
  echo "$subagent_block" | grep -q "design.md"
}

# =============================================================================
# Scope-reviewer fail-closed on malformed OWNS/DEFERS (CodexF-2 / CodexF-4)
# =============================================================================

@test "scope-reviewer dispatch declares fail-closed on malformed OWNS/DEFERS" {
  # The scope-reviewer dispatch block lives under the review round; it must
  # explicitly state that a malformed/missing OWNS/DEFERS section triggers a
  # CRITICAL finding and a refusal to proceed (per scope-reviewer template's
  # malformed-case fail-closed clause).
  # Locate the scope-reviewer dispatch bullet (line containing
  # "scope-reviewer subagent dispatch") and capture text up to the next
  # top-level bullet ("- **Reviewer prompt block" / "- **Codex review").
  local block
  block="$(awk '
    /scope-reviewer subagent dispatch/ { in_block = 1 }
    in_block && /^- \*\*Reviewer prompt block/ { exit }
    in_block && /^- \*\*Codex review/ { exit }
    in_block { print }
  ' "$SKILL_FILE")"
  [ -n "$block" ]

  echo "$block" | grep -qiE "malformed|missing"
  echo "$block" | grep -qE "CRITICAL|fail-closed"
  echo "$block" | grep -qiE "refuse to proceed|MUST emit"
}
