#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# T42 — G15 + G14: Replan Boundary-with-Goals pin against mixed-shape fixture.
#
# Asserts the Replan ↔ Goals boundary contract authored in T41 against the
# mixed-shape fixture at tests/fixtures/future-goals-mixed-shape.md:
#
#   - skills/replan/SKILL.md § Boundary with Goals declares the
#     promotion-only-of-Formal-entries rule.
#   - The section declares partial-Formal entries are SKIPPED with the
#     missing field/subsection named in the hand-off report.
#   - The section declares prose-only Idea entries are SKIPPED with
#     "prose-only Idea" as the skip reason.
#   - The section declares the hand-off report shape (promoted entries
#     by id+title, skipped entries with explicit reason).
#   - skills/replan/owns-defers.md OWNS list contains the
#     Boundary-with-Goals responsibility entry.
#   - skills/replan/owns-defers.md DEFERS list contains the
#     Idea-formalization deferral entry.
#   - The fixture carries exactly three deliberately-shaped entries:
#     Entry 1 (fully-Formal, PROMOTE), Entry 2 (partial-Formal missing
#     `## What we know so far`, SKIP), Entry 3 (prose-only Idea, SKIP).
#
# This is a documentation-shape pin per the T42 spec: the BATS surface
# asserts the codified contract in skill prose names the promotion
# outcomes and skip reasons that match the fixture's entries. Runtime
# promotion behavior is exercised separately at Integrate time when the
# Replan agent runs against the fixture during a real phase-boundary
# handoff.
#
# Uses skill-markdown.bash (T13). Bash 3.2 portable.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
  REPLAN_SKILL="$REPO_ROOT/skills/replan/SKILL.md"
  REPLAN_OWNS_DEFERS="$REPO_ROOT/skills/replan/owns-defers.md"
  FIXTURE="$REPO_ROOT/tests/fixtures/future-goals-mixed-shape.md"
  export REPLAN_SKILL REPLAN_OWNS_DEFERS FIXTURE
}

# =============================================================================
# Fixture existence + structural shape (exactly three labeled entries)
# =============================================================================

@test "[T42-boundary] Fixture exists at tests/fixtures/future-goals-mixed-shape.md" {
  [ -r "$FIXTURE" ]
}

@test "[T42-boundary] Fixture Entry 1 labeled fully-Formal (PROMOTE)" {
  grep -F "## Entry 1: fully-Formal (PROMOTE)" "$FIXTURE"
}

@test "[T42-boundary] Fixture Entry 2 labeled partial-Formal (SKIP — missing ## What we know so far)" {
  grep -F "## Entry 2: partial-Formal (SKIP — missing \`## What we know so far\`)" "$FIXTURE"
}

@test "[T42-boundary] Fixture Entry 3 labeled prose-only Idea (SKIP — no frontmatter, no subsections)" {
  grep -F "## Entry 3: prose-only Idea (SKIP — no frontmatter, no subsections)" "$FIXTURE"
}

@test "[T42-boundary] Fixture Entry 1 carries frontmatter id and type" {
  grep -F "id: G5" "$FIXTURE"
  grep -F "type: known-fix" "$FIXTURE"
}

@test "[T42-boundary] Fixture Entry 2 carries frontmatter id (partial-Formal shape)" {
  grep -F "id: G6" "$FIXTURE"
}

@test "[T42-boundary] Fixture Entry 1 carries all three required subsections" {
  grep -F "### ## Problem" "$FIXTURE"
  grep -F "### ## Why we care" "$FIXTURE"
  grep -F "### ## What we know so far" "$FIXTURE"
}

# =============================================================================
# skills/replan/SKILL.md § Boundary with Goals — documentation-shape contract
# =============================================================================

@test "[T42-boundary] Boundary with Goals section names Formal-only promotion rule" {
  extract_and_grep "$REPLAN_SKILL" H2 "Boundary with Goals" \
    "ONLY fully-Formal"
}

@test "[T42-boundary] Boundary with Goals section names frontmatter id and type requirements" {
  extract_and_grep "$REPLAN_SKILL" H2 "Boundary with Goals" \
    "id:"
  extract_and_grep "$REPLAN_SKILL" H2 "Boundary with Goals" \
    "type:"
}

@test "[T42-boundary] Boundary with Goals section names all three required subsections" {
  extract_and_grep "$REPLAN_SKILL" H2 "Boundary with Goals" \
    "## Problem"
  extract_and_grep "$REPLAN_SKILL" H2 "Boundary with Goals" \
    "## Why we care"
  extract_and_grep "$REPLAN_SKILL" H2 "Boundary with Goals" \
    "## What we know so far"
}

@test "[T42-boundary] Boundary with Goals section declares partial-Formal entries are SKIPPED" {
  # The section enumerates partial-Formal entries as one of the SKIPPED
  # entry types under the "Skip conditions" subsection. The two tokens
  # appear on adjacent lines (SKIPPED on the section-header line,
  # **Partial-Formal entries** on the immediately following bullet).
  # Pin asserts both tokens are present inside the same section body.
  extract_and_grep "$REPLAN_SKILL" H2 "Boundary with Goals" \
    "[Pp]artial-Formal"
  extract_and_grep "$REPLAN_SKILL" H2 "Boundary with Goals" \
    "SKIPPED"
}

@test "[T42-boundary] Boundary with Goals section declares prose-only Idea entries are SKIPPED" {
  extract_and_grep "$REPLAN_SKILL" H2 "Boundary with Goals" \
    "[Pp]rose-only Idea"
}

@test "[T42-boundary] Boundary with Goals section declares Replan does NOT mint IDs" {
  extract_and_grep "$REPLAN_SKILL" H2 "Boundary with Goals" \
    "[Mm]int new .id:"
}

@test "[T42-boundary] Boundary with Goals section declares Replan does NOT author acceptance criteria" {
  extract_and_grep "$REPLAN_SKILL" H2 "Boundary with Goals" \
    "[Aa]uthor acceptance criteria"
}

# =============================================================================
# Hand-off report shape (promoted by id+title, skipped with explicit reason)
# =============================================================================

@test "[T42-boundary] Hand-off report enumerates promoted Formal entries by id and title" {
  extract_and_grep "$REPLAN_SKILL" H2 "Boundary with Goals" \
    "[Pp]romoted.*id.*title"
}

@test "[T42-boundary] Hand-off report enumerates partial-Formal entries with missing field/subsection named" {
  extract_and_grep "$REPLAN_SKILL" H2 "Boundary with Goals" \
    "Skipped .partial-Formal."
}

@test "[T42-boundary] Hand-off report enumerates prose-only Idea entries with named skip reason" {
  extract_and_grep "$REPLAN_SKILL" H2 "Boundary with Goals" \
    "Skipped .prose-only Idea."
}

# =============================================================================
# skills/replan/owns-defers.md — OWNS + DEFERS entries
# =============================================================================

@test "[T42-boundary] owns-defers OWNS list contains Boundary-with-Goals responsibility" {
  extract_and_grep "$REPLAN_OWNS_DEFERS" H3 "Replan OWNS" \
    "Boundary with Goals"
}

@test "[T42-boundary] owns-defers OWNS entry names Formal-vs-Idea schema check" {
  extract_and_grep "$REPLAN_OWNS_DEFERS" H3 "Replan OWNS" \
    "Formal-vs-Idea schema check"
}

@test "[T42-boundary] owns-defers OWNS entry names hand-off report shape" {
  extract_and_grep "$REPLAN_OWNS_DEFERS" H3 "Replan OWNS" \
    "hand-off report"
}

@test "[T42-boundary] owns-defers DEFERS list contains Idea-formalization deferral" {
  extract_and_grep "$REPLAN_OWNS_DEFERS" H3 "Replan DEFERS" \
    "Idea formalization"
}

@test "[T42-boundary] owns-defers DEFERS entry routes Idea formalization to Goals" {
  # owns-defers Idea-formalization bullet uses "owned by **Goals**" as
  # the routing phrase (matching the canonical DEFERS-list style).
  extract_and_grep "$REPLAN_OWNS_DEFERS" H3 "Replan DEFERS" \
    "Idea formalization.*owned by .{0,4}Goals"
}
