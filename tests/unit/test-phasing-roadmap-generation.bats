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
  OWNS_FILE="$BATS_TEST_DIRNAME/../../skills/phasing/owns-defers.md"
  export SKILL_FILE OWNS_FILE
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
  owns_block="$(extract_h3_direct "$OWNS_FILE" "### Phasing OWNS")"
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
  # high-severity finding and a refusal to proceed (per scope-reviewer template's
  # malformed-case fail-closed clause). Severity must conform to the M48 schema
  # which only permits low|medium|high.
  # Commit 12/22 migration: "scope-reviewer subagent dispatch" pattern is
  # replaced by "Claude scope-reviewer subagent" Agent({subagent_type:...}) form.
  # Locate the scope-reviewer dispatch bullet (line containing
  # "scope-reviewer subagent") and capture its block.
  local block
  block="$(awk '
    /Claude scope-reviewer subagent/ { in_block = 1 }
    in_block && /^- \*\*Codex reviews/ { exit }
    in_block { print }
  ' "$SKILL_FILE")"
  [ -n "$block" ]

  echo "$block" | grep -qiE "malformed|missing"
  echo "$block" | grep -qiE "fail-closed|severity: high|high-severity"
  echo "$block" | grep -qiE "refuse to proceed|MUST emit"
}

# =============================================================================
# M48 schema compliance — phasing emissions never use `critical` severity
# (R1 3-way converged: Claude-I1 + Codex-I4 + Codex-S5)
# The shared M48 finding schema in skills/_shared/reviewer-boilerplate.md only
# permits severity ∈ {low, medium, high}. Phasing previously instructed the
# dispatched reviewer to emit "CRITICAL" findings in 3 places. A reviewer that
# obeys phasing/SKILL.md emits findings the pause-gate cannot dispatch on
# (severity outside enum). Normalize to `high` to match the shared
# scope-reviewer template's malformed-case wording.
# =============================================================================

@test "phasing/SKILL.md never instructs emitting CRITICAL severity (M48 schema)" {
  # The shared M48 finding schema only permits severity ∈ {low, medium, high}.
  # Search the entire SKILL.md for any occurrence of the literal token
  # "CRITICAL" (case-sensitive) — every prior occurrence in this file was a
  # severity-emission instruction. The fix replaces them all with `high`.
  # We allow "critical" lower-case as a normal English word (e.g. "critical
  # path") only outside severity-emission contexts; this test enforces the
  # uppercase token absence which previously appeared exclusively in severity
  # contexts at lines 119, 234, 258.
  if grep -nE "\bCRITICAL\b" "$SKILL_FILE"; then
    echo "phasing/SKILL.md still contains CRITICAL severity tokens; M48 schema only allows low|medium|high" >&2
    return 1
  fi
}

@test "phasing/SKILL.md never instructs emitting severity-critical (M48 schema)" {
  # Stronger structural guard: the literal pattern `severity: critical`
  # (case-insensitive) must not appear anywhere in the skill prompt. Phasing
  # emissions must conform to the shared M48 5-field schema.
  if grep -niE "severity[[:space:]]*:[[:space:]]*critical" "$SKILL_FILE"; then
    echo "phasing/SKILL.md instructs emitting severity: critical, which is outside the M48 schema" >&2
    return 1
  fi
}

@test "orphan-ID fail-closed clause uses high severity (not CRITICAL)" {
  # The Goal-ID Consistency Validation section's "Fail-closed semantics."
  # paragraph previously said "MUST emit a CRITICAL finding". After the M48
  # alignment fix it must read as a high-severity emission.
  local block
  block="$(awk '
    /^\*\*Fail-closed semantics\.\*\*/ { in_block = 1 }
    in_block && /^## / { exit }
    in_block && /^\*\*[A-Z]/ && !/^\*\*Fail-closed/ { exit }
    in_block { print }
  ' "$SKILL_FILE")"
  [ -n "$block" ]

  # Must NOT contain CRITICAL token
  ! echo "$block" | grep -qE "\bCRITICAL\b"
  # Must contain a high-severity reference (or fail-closed wording naming `high`)
  echo "$block" | grep -qiE "severity: high|high-severity|emit a high"
}

@test "Red Flags — STOP entry for malformed OWNS/DEFERS uses high severity" {
  # The "Red Flags — STOP" bullet about scope-reviewer fail-closed previously
  # ended with "scope-reviewer fail-closed CRITICAL". After the M48 fix it
  # must not name CRITICAL, AND must explicitly name the replacement
  # severity (`high`) so that a future edit cannot accidentally drop the
  # severity wording entirely (closes Codex round-1 GTR-001 / TCR-001:
  # the absence-of-CRITICAL check alone is too weak — verify the
  # replacement actually preserved the intended `severity: high` wording).
  local block
  block="$(extract_section "$SKILL_FILE" "## Red Flags — STOP")"
  [ -n "$block" ]

  ! echo "$block" | grep -qE "\bCRITICAL\b"

  # Locate the malformed-OWNS/DEFERS bullet specifically and require it to
  # name `severity: high` (M48-conforming severity for the fail-closed path).
  local bullet
  bullet="$(echo "$block" | grep -E "Phasing OWNS / Phasing DEFERS.*malformed|malformed.*Phasing OWNS / Phasing DEFERS")"
  [ -n "$bullet" ]
  echo "$bullet" | grep -qiE "severity: high|high.*M48|M48.*high"
}

# =============================================================================
# Config Validation — codex_reviews must invoke the procedure, not silent default
# (R2 I-N5: Phasing silently defaults codex_reviews: false)
# using-qrspi:411 says "Every skill that reads config.md applies this procedure
# before using any field." The "No silent defaults" subsection forbids assuming
# `codex_reviews: false` when missing.
# =============================================================================

@test "phasing/SKILL.md invokes the Config Validation Procedure" {
  # The skill must reference the Config Validation Procedure from using-qrspi
  # and name codex_reviews as a validated field — mirroring the pattern used
  # by Plan/Implement/Integrate/Test.
  grep -qE "Config Validation Procedure" "$SKILL_FILE"
  grep -qiE "validates.*codex_reviews|codex_reviews.*validation" "$SKILL_FILE"
}

@test "phasing/SKILL.md does NOT silently default codex_reviews to false" {
  # The Required-inputs line previously said: "default codex_reviews: false if
  # absent". This silent default violates using-qrspi's "No silent defaults"
  # contract. After the fix the silent-default phrase must be gone.
  if grep -niE "default[[:space:]]+(to[[:space:]]+)?(\`)?codex_reviews:[[:space:]]*false(\`)?[[:space:]]+if[[:space:]]+absent" "$SKILL_FILE"; then
    echo "phasing/SKILL.md still contains a silent codex_reviews:false default" >&2
    return 1
  fi
  # Also reject the looser variant "default codex_reviews: false"
  if grep -niE "default[[:space:]]+(to[[:space:]]+)?(\`)?codex_reviews:[[:space:]]*false" "$SKILL_FILE"; then
    echo "phasing/SKILL.md still contains a silent codex_reviews:false default" >&2
    return 1
  fi
}
