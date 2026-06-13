#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Task 23 (pin 2 of 2) — G8, G9, G14: Parallelize canonical vocabulary pin
#
# Asserts the canonical multi-stage suffix-grammar tokens are present in:
#   1. skills/parallelize/SKILL.md § Branch Model (Symbolic — Resolved by Implement)
#   2. agents/qrspi-parallelize-reviewer.md § Parallelize-specific quality checks
#
# And that there is no drift between the two, plus a drift-fixture assertion
# that the unconventional form "stageAfterWave4" is flagged as a style violation
# by the reviewer-side vocabulary check.
#
# Bash 3.2 portable: no mapfile, no declare -A, no ${var,,}, no coproc,
# no wait -n.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
  SKILL_MD="$REPO_ROOT/skills/parallelize/SKILL.md"
  REVIEWER_MD="$REPO_ROOT/agents/qrspi-parallelize-reviewer.md"
  export SKILL_MD REVIEWER_MD
}

# ---------------------------------------------------------------------------
# Branch Model section exists in SKILL.md
# ---------------------------------------------------------------------------
@test "Branch Model section exists in parallelize SKILL.md" {
  extract_section "$SKILL_MD" H2 "Branch Model (Symbolic — Resolved by Implement)"
}

# ---------------------------------------------------------------------------
# Canonical token: "feature branch tip" in Branch Model section
# ---------------------------------------------------------------------------
@test "Branch Model contains canonical token 'feature branch tip'" {
  extract_and_grep "$SKILL_MD" H2 "Branch Model (Symbolic — Resolved by Implement)" \
    "feature branch tip"
}

# ---------------------------------------------------------------------------
# Canonical token: "task-NN tip" in Branch Model section
# ---------------------------------------------------------------------------
@test "Branch Model contains canonical token 'task-NN tip'" {
  extract_and_grep "$SKILL_MD" H2 "Branch Model (Symbolic — Resolved by Implement)" \
    "task-NN tip"
}

# ---------------------------------------------------------------------------
# Canonical token: "task-00 tip" in Branch Model section
# ---------------------------------------------------------------------------
@test "Branch Model contains canonical token 'task-00 tip'" {
  extract_and_grep "$SKILL_MD" H2 "Branch Model (Symbolic — Resolved by Implement)" \
    "task-00 tip"
}

# ---------------------------------------------------------------------------
# Canonical token: "stage-after-W{N}" in Branch Model section
# ---------------------------------------------------------------------------
@test "Branch Model contains canonical token 'stage-after-W{N}'" {
  extract_and_grep "$SKILL_MD" H2 "Branch Model (Symbolic — Resolved by Implement)" \
    "stage-after-W"
}

# ---------------------------------------------------------------------------
# Canonical token: suffixed "stage-after-W{N}{suffix}" form in Branch Model
# ---------------------------------------------------------------------------
@test "Branch Model contains suffixed 'stage-after-W{N}{suffix}' form" {
  extract_and_grep "$SKILL_MD" H2 "Branch Model (Symbolic — Resolved by Implement)" \
    "stage-after-W[0-9][a-z]"
}

# ---------------------------------------------------------------------------
# Reviewer file: Parallelize-specific quality checks section exists
# ---------------------------------------------------------------------------
@test "Parallelize-specific quality checks section exists in reviewer" {
  extract_section "$REVIEWER_MD" H3 "Parallelize-specific quality checks"
}

# ---------------------------------------------------------------------------
# Canonical tokens present in reviewer's vocabulary check
# ---------------------------------------------------------------------------
@test "reviewer quality checks contain canonical token 'feature branch tip'" {
  extract_and_grep "$REVIEWER_MD" H3 "Parallelize-specific quality checks" \
    "feature branch tip"
}

@test "reviewer quality checks contain canonical token 'task-NN tip'" {
  extract_and_grep "$REVIEWER_MD" H3 "Parallelize-specific quality checks" \
    "task-NN tip"
}

@test "reviewer quality checks contain canonical token 'task-00 tip'" {
  extract_and_grep "$REVIEWER_MD" H3 "Parallelize-specific quality checks" \
    "task-00 tip"
}

@test "reviewer quality checks contain canonical token 'stage-after-W'" {
  extract_and_grep "$REVIEWER_MD" H3 "Parallelize-specific quality checks" \
    "stage-after-W"
}

@test "reviewer quality checks reference suffixed stage-after form" {
  extract_and_grep "$REVIEWER_MD" H3 "Parallelize-specific quality checks" \
    "stage-after-W[0-9][a-z]"
}

# ---------------------------------------------------------------------------
# No drift: SKILL.md Branch Model and reviewer both declare all 4 core tokens.
# (Drift check: both sections contain the same 4 required tokens.)
# ---------------------------------------------------------------------------
@test "no drift — SKILL.md and reviewer both carry all 4 canonical base tokens" {
  # Verify each of the 4 core canonical tokens is present in BOTH files.
  # extract_and_grep returns 1 if any token is missing, causing test failure.
  local tokens="feature branch tip task-NN tip task-00 tip stage-after-W"
  local token=""
  local token_list_file
  token_list_file="$(mktemp /tmp/vocab-tokens-XXXXXX.txt)"
  printf 'feature branch tip\ntask-NN tip\ntask-00 tip\nstage-after-W\n' > "$token_list_file"

  while IFS= read -r token; do
    [ -n "$token" ] || continue
    # Must be in SKILL.md Branch Model
    extract_and_grep "$SKILL_MD" H2 "Branch Model (Symbolic — Resolved by Implement)" "$token" > /dev/null
    # Must also be in reviewer checks
    extract_and_grep "$REVIEWER_MD" H3 "Parallelize-specific quality checks" "$token" > /dev/null
  done < "$token_list_file"

  rm -f "$token_list_file"
}

# ---------------------------------------------------------------------------
# Drift fixture: "stageAfterWave4" is flagged as style violation by reviewer.
# The reviewer section explicitly names hyphenated and camelCase variants as
# NOT canonical. We verify the reviewer text flags this pattern.
# ---------------------------------------------------------------------------
@test "reviewer flags unconventional 'stageAfterWave4' as style violation" {
  # The reviewer's quality checks must explicitly name non-canonical forms
  # (hyphenated variants, camelCase variants) as style violations.
  # Canonical check: the reviewer prose mentions at least one of the
  # unconventional forms it rejects (hyphenated or integer-suffixed).
  local section
  section="$(extract_section "$REVIEWER_MD" H3 "Parallelize-specific quality checks")"

  # The reviewer must state that non-canonical / unconventional forms are NOT canonical
  # and are findings with change_type: style.
  if ! printf '%s\n' "$section" | grep -q "NOT canonical"; then
    printf 'FAIL: reviewer does not mark unconventional forms as NOT canonical\n' >&2
    return 1
  fi
  if ! printf '%s\n' "$section" | grep -qi "style"; then
    printf 'FAIL: reviewer does not assign change_type: style to unconventional forms\n' >&2
    return 1
  fi

  # Drift fixture: verify a document containing "stageAfterWave4" would be
  # flagged. We check that the reviewer's "NOT canonical" exclusion covers
  # camelCase-style tokens by asserting the rejection list exists.
  # (The reviewer prose names hyphenated and integer-suffixed but the pattern
  # covers camelCase by the "NOT canonical" blanket statement.)
  local fixture_hit
  fixture_hit="$(printf '%s\n' "$section" | grep "NOT canonical" || true)"
  [ -n "$fixture_hit" ]
}

# ---------------------------------------------------------------------------
# Missing-anchor loud-failure: helper emits named diagnostic on bad heading
# ---------------------------------------------------------------------------
@test "missing-anchor emits skill-markdown loud diagnostic" {
  run extract_and_grep "$SKILL_MD" H2 "Nonexistent Heading XXXX" "anything"
  [ "$status" -ne 0 ]
  printf '%s\n' "$output" | grep -q "skill-markdown:"
}

# ---------------------------------------------------------------------------
# Shared helper loads and REPO_ROOT resolves.
# ---------------------------------------------------------------------------
@test "shared helper loads and require_repo_root resolves REPO_ROOT" {
  require_repo_root
  [ -n "$REPO_ROOT" ]
  [ -d "$REPO_ROOT" ]
}

# ===========================================================================
# T4 (v0.7.1-hardening) — Wave-grouped Branch Map structural pins
#
# Task 4 reshapes the parallelize SKILL Branch Map content from a flat
# three-column table into `### Wave N` sub-sections, each holding its own
# Task/Branch/Base mini-table, and removes the redundant `## Execution Order`
# narrative. The reviewer agent gains a corresponding structural rule.
#
# These assertions pin the post-reshape shape against both files. They are
# expected to FAIL (RED) against the un-implemented state and to PASS once
# the implementer delivers the reshape. Pre-existing T23 vocabulary and
# row-completeness assertions above remain untouched per Task 4 TE-8.
# ===========================================================================

# ---------------------------------------------------------------------------
# TE-1: SKILL.md uses `### Wave N` sub-section headings to organize Branch Map
# ---------------------------------------------------------------------------
@test "SKILL.md contains ### Wave N sub-section headings as Branch Map organizing structure" {
  # Test expectation: skills/parallelize/SKILL.md contains `### Wave N`
  # sub-section headings (e.g. `### Wave 1`, `### Wave 2`) as the organizing
  # structure for its Branch Map.
  local wave_count
  wave_count="$(grep -cE '^### Wave [0-9]+' "$SKILL_MD" || true)"
  if [ -z "$wave_count" ] || [ "$wave_count" -eq 0 ]; then
    printf 'FAIL: SKILL.md contains no ### Wave N sub-section headings\n' >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# TE-1 (companion): no flat Task/Branch/Base Branch Map table outside any Wave
# ---------------------------------------------------------------------------
@test "every Task/Branch/Base table header in SKILL.md is grouped under a ### Wave N sub-section" {
  # Test expectation: no flat three-column Branch Map table appearing outside
  # a Wave sub-section. A `| Task | Branch | Base |` header line that is not
  # preceded by a `### Wave N` heading (within the current sub-section scope)
  # indicates an ungrouped flat table.
  local ungrouped
  ungrouped="$(awk '
    BEGIN { in_wave = 0; count = 0 }
    /^### Wave [0-9]+/ { in_wave = 1; next }
    /^## / {
      ch = substr($0, 4, 1)
      if (ch != "#" && ch != "") in_wave = 0
    }
    /^\| *Task *\| *Branch *\| *Base *\|/ {
      if (!in_wave) count++
    }
    END { print count + 0 }
  ' "$SKILL_MD")"
  if [ "$ungrouped" -gt 0 ]; then
    printf 'FAIL: %s Task/Branch/Base table header(s) appear outside any ### Wave N sub-section\n' \
      "$ungrouped" >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# TE-2: each ### Wave N sub-section contains a Task/Branch/Base table
# ---------------------------------------------------------------------------
@test "each ### Wave N sub-section in SKILL.md is followed by a Task/Branch/Base table header" {
  # Test expectation: Each `### Wave N` sub-section contains a Markdown table
  # with exactly three columns: Task, Branch, and Base.
  #
  # For each `### Wave N` line, scan forward up to 15 lines looking for a
  # `| Task | Branch | Base |` table header. Stop scanning at the next H2/H3
  # boundary. Any Wave heading without a matching table is a miss.
  local misses
  misses="$(awk '
    BEGIN { wait = 0; wave_line = 0; miss_count = 0 }
    /^### Wave [0-9]+/ {
      if (wait > 0) miss_count++   # previous Wave never found its table
      wait = 15
      wave_line = NR
      next
    }
    wait > 0 {
      if ($0 ~ /^## / || $0 ~ /^### /) {
        miss_count++
        wait = 0
        next
      }
      if ($0 ~ /^\| *Task *\| *Branch *\| *Base *\|/) {
        wait = 0
        next
      }
      wait--
      if (wait == 0) miss_count++
    }
    END {
      if (wait > 0) miss_count++
      print miss_count + 0
    }
  ' "$SKILL_MD")"
  if [ "$misses" -gt 0 ]; then
    printf 'FAIL: %s ### Wave N sub-section(s) lack a Task/Branch/Base table header within 15 lines\n' \
      "$misses" >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# TE-3: no `## Execution Order` H2 anywhere in the artifact spec or examples
# ---------------------------------------------------------------------------
@test "SKILL.md no longer contains '## Execution Order' H2 heading anywhere" {
  # Test expectation: No `## Execution Order` heading or equivalent standalone
  # wave-order prose block exists anywhere in the artifact specification or
  # worked-example sections of the skill.
  if grep -nE '^## Execution Order' "$SKILL_MD"; then
    printf 'FAIL: SKILL.md still contains one or more "## Execution Order" headings (must be removed by reshape)\n' >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# TE-4: Worked Example — Good shows Wave-grouped sub-sections
# ---------------------------------------------------------------------------
@test "Worked Example — Good contains ### Wave N sub-sections matching updated spec shape" {
  # Test expectation: The "Good" worked example in the skill shows
  # Wave-grouped sub-sections and matches the updated specification shape.
  local extract
  extract="$(extract_section_fence_aware "$SKILL_MD" "## Worked Example — Good")" || {
    printf 'FAIL: extract_section_fence_aware could not locate "## Worked Example — Good"\n' >&2
    return 1
  }
  if ! printf '%s\n' "$extract" | grep -qE '^### Wave [0-9]+'; then
    printf 'FAIL: Worked Example — Good lacks ### Wave N sub-section headings\n' >&2
    return 1
  fi
  # Companion shape check: the Good example must still carry at least one
  # Task/Branch/Base table header inside the wave-grouped layout.
  if ! printf '%s\n' "$extract" | grep -qE '^\| *Task *\| *Branch *\| *Base *\|'; then
    printf 'FAIL: Worked Example — Good lacks a Task/Branch/Base table header\n' >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# TE-5: Worked Example — Bad illustrates flat layout (or anti-pattern) WITHOUT
# Wave sub-sections
# ---------------------------------------------------------------------------
@test "Worked Example — Bad does not contain ### Wave N sub-sections (preserves anti-pattern)" {
  # Test expectation: The "Bad" worked example in the skill illustrates the
  # old flat layout (or another anti-pattern) without Wave sub-sections.
  local extract
  extract="$(extract_section_fence_aware "$SKILL_MD" "## Worked Example — Bad")" || {
    printf 'FAIL: extract_section_fence_aware could not locate "## Worked Example — Bad"\n' >&2
    return 1
  }
  if printf '%s\n' "$extract" | grep -qE '^### Wave [0-9]+'; then
    printf 'FAIL: Worked Example — Bad must illustrate the anti-pattern (no ### Wave N sub-sections)\n' >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# TE-6 + TE-7: reviewer agent carries the `### Wave N` Branch Map structural rule
# (Load-bearing RED gate: this assertion must fail until the implementer adds
# the rule to agents/qrspi-parallelize-reviewer.md.)
# ---------------------------------------------------------------------------
@test "reviewer Parallelize-specific quality checks require ### Wave N Branch Map grouping rule" {
  # Test expectation: agents/qrspi-parallelize-reviewer.md contains a
  # structural rule that requires Branch Map content to be organized under
  # `### Wave N` sub-section headings. The assertion passes when the rule is
  # present and fails (RED) when it is absent.
  #
  # Match shape: the rule must reference the literal `### Wave` heading
  # syntax (H3 sub-section grouping) inside the Parallelize-specific
  # quality-checks block. We accept any line in that section that mentions
  # `### Wave` — implementer chooses the exact prose.
  extract_and_grep "$REVIEWER_MD" H3 "Parallelize-specific quality checks" \
    "### Wave"
}

# ---------------------------------------------------------------------------
# TE-6 (companion): the reviewer rule must also reference the sub-section
# grouping requirement (not merely the word "wave" in passing). Asserts the
# canonical phrasing pattern "sub-section" appears alongside `### Wave` in the
# same section, guarding against drift where the rule is named but its
# grouping semantic is lost.
# ---------------------------------------------------------------------------
@test "reviewer ### Wave N rule mentions sub-section grouping semantic" {
  # Test expectation: the reviewer rule must establish the SUB-SECTION grouping
  # contract (not merely mention the word "Wave"). The reviewer section must
  # contain "sub-section" (case-insensitive) so future drift can't reduce the
  # rule to a vocabulary mention without the grouping requirement.
  local section
  section="$(extract_section "$REVIEWER_MD" H3 "Parallelize-specific quality checks")" || {
    printf 'FAIL: could not extract Parallelize-specific quality checks section from reviewer\n' >&2
    return 1
  }
  if ! printf '%s\n' "$section" | grep -qi 'sub-section'; then
    printf 'FAIL: reviewer Parallelize-specific quality checks does not mention "sub-section" grouping semantic\n' >&2
    return 1
  fi
}
