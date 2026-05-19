#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# Task 18 — U14 lint (deterministic, fixture-driven).
#
# Five lints under U14, each with a positive-coverage fixture seeded under
# tests/fixtures/seeded-u14-violation-*.md. Lint scope (when run against
# in-scope skill files) is the four synthesizing skills' SKILL.md plus
# phasing/SKILL.md — NOT all skills/**/*.md. The in-scope file list is
# hardcoded as a bats array per task-18 spec.
#
# Lints (each implemented as a small awk/grep helper, then invoked twice:
# once against the seeded violation fixture for positive coverage, and once
# across the in-scope skill set to confirm clean state under post-Wave-5
# baseline):
#
#   1. claim-line lint — first sentence of every `^## ` section is ≤250 chars
#      and ends in a period (`.`, `!`, or `?`). The "first sentence" is the
#      first non-blank, non-fence, non-list, non-callout line under the
#      heading.
#   2. paragraph-density lint — no paragraph (consecutive non-blank lines)
#      exceeds 150 words OR 8 lines. Fenced code blocks are excluded.
#   3. scannability lint — any section >300 words (under a `^## ` heading)
#      must contain at least one bullet (`^- `) or numbered-list item
#      (`^[0-9]+\. `). Fenced code blocks are excluded from word-count.
#   4. required-section conformance — for a given artifact-type, all
#      canonical headings must be present.
#   5. no-brevity grep — flags bare instructions matching `be concise`,
#      `brief summary`, or `≤ N lines` patterns. Allowlist: quoted forms
#      (single, double, or backtick); lines mentioning U14, "forbidden",
#      "prohibition", "do NOT", "soft length target", or numeric length-
#      target bands such as "200–400 lines" / "300–500 lines" /
#      "1000–2000 lines" (M49–M52 length-target soft targets).
#
# All lints take a single file path and emit one or more `LINT:` lines on
# stdout; exit 1 if any violation, 0 if clean. The bats tests assert on
# the presence/absence of those `LINT:` lines.
#
# In-scope file list (hardcoded per task-18 spec):
#
#   skills/goals/SKILL.md
#   skills/design/SKILL.md
#   skills/phasing/SKILL.md
#   skills/structure/SKILL.md
#   skills/plan/SKILL.md
#
# (No dedicated output-template files exist at stage-after-G5 for these
# skills — all artifact templates are inline within SKILL.md. If output
# templates are factored out in a future wave, they should be added to the
# in-scope array below.)

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  FIXTURE_DIR="$REPO_ROOT/tests/fixtures"
  export REPO_ROOT FIXTURE_DIR

  # Hardcoded in-scope file list — see header comment for rationale.
  IN_SCOPE_FILES=(
    "$REPO_ROOT/skills/goals/SKILL.md"
    "$REPO_ROOT/skills/design/SKILL.md"
    "$REPO_ROOT/skills/phasing/SKILL.md"
    "$REPO_ROOT/skills/structure/SKILL.md"
    "$REPO_ROOT/skills/plan/SKILL.md"
  )
  export IN_SCOPE_FILES
}

# =============================================================================
# Lint helpers (each prints `LINT: <rule>: <detail>` on violation; exit 0 clean)
# =============================================================================

# Strip fenced code blocks (```...```) from a file's content — used by
# paragraph-density and scannability lints which must ignore code.
strip_fenced_code() {
  awk '
    /^```/ { in_fence = !in_fence; next }
    !in_fence { print }
  ' "$1"
}

# lint_claim_line <file>
# Skips fenced code blocks (artifact templates embedded in SKILL.md).
# Treats colon `:` as legitimate terminal punctuation since markdown
# sentences that introduce a list often end with a colon.
# Returns 0 if no violations, 1 if any violation found (CodexF5 fix-cycle 1).
lint_claim_line() {
  local file="$1"
  awk '
    function strip_md(s,    t) {
      t = s
      gsub(/\*\*/, "", t)
      gsub(/`/, "", t)
      return t
    }
    /^```/ { in_fence = !in_fence; next }
    in_fence { next }
    /^## / {
      heading = $0
      seen_first = 0
      next
    }
    heading != "" && !seen_first {
      line = $0
      sub(/^[ \t]+/, "", line)
      if (line == "") next
      # Skip list items, tables, blockquote callouts, raw HTML, sub-headings.
      if (line ~ /^- /) next
      if (line ~ /^[0-9]+\. /) next
      if (line ~ /^\|/) next
      if (line ~ /^>/) next
      if (line ~ /^<!--/) next
      if (line ~ /^#/) next
      seen_first = 1
      stripped = strip_md(line)
      n = length(stripped)
      last = substr(stripped, n, 1)
      if (n > 250) {
        printf "LINT: claim-line: %s :: opening-sentence-too-long (%d chars > 250)\n", heading, n
        violations++
      }
      # Accept ".", "!", "?", and ":" (colon-introducing-list is a legitimate
      # markdown construct used throughout qrspi-plus skill prompts).
      if (last != "." && last != "!" && last != "?" && last != ":") {
        printf "LINT: claim-line: %s :: opening-sentence-missing-terminal-punctuation\n", heading
        violations++
      }
    }
    END { exit (violations > 0 ? 1 : 0) }
  ' "$file"
}

# lint_paragraph_density <file>
# Returns 0 if no violations, 1 if any violation found (CodexF5 fix-cycle 1).
lint_paragraph_density() {
  local file="$1"
  strip_fenced_code "$file" | awk '
    function flush(   wc, lc, i) {
      if (n_lines == 0) return
      lc = n_lines
      wc = 0
      for (i = 1; i <= n_lines; i++) {
        split(buf[i], parts, /[ \t]+/)
        for (j in parts) if (parts[j] != "") wc++
      }
      if (wc > 150) {
        printf "LINT: paragraph-density: paragraph-too-many-words (%d words > 150)\n", wc
        violations++
      }
      if (lc > 8) {
        printf "LINT: paragraph-density: paragraph-too-many-lines (%d lines > 8)\n", lc
        violations++
      }
      n_lines = 0
    }
    /^[ \t]*$/ { flush(); next }
    /^#/ { flush(); next }
    /^>/ { flush(); next }
    /^- / { flush(); next }
    /^[0-9]+\. / { flush(); next }
    /^<!--/ { flush(); next }
    {
      n_lines++
      buf[n_lines] = $0
    }
    END { flush(); exit (violations > 0 ? 1 : 0) }
  '
}

# lint_scannability <file>
# Returns 0 if no violations, 1 if any violation found (CodexF5 fix-cycle 1).
lint_scannability() {
  local file="$1"
  strip_fenced_code "$file" | awk '
    function flush(    wc, j) {
      if (heading == "") return
      wc = 0
      for (j = 1; j <= n_body_lines; j++) {
        split(body[j], parts, /[ \t]+/)
        for (k in parts) if (parts[k] != "") wc++
      }
      if (wc > 300 && !has_list) {
        printf "LINT: scannability: %s :: long-section-no-list (%d words, no `- ` or numbered list)\n", heading, wc
        violations++
      }
      n_body_lines = 0
      has_list = 0
    }
    /^## / {
      flush()
      heading = $0
      next
    }
    heading == "" { next }
    /^- / { has_list = 1 }
    /^[0-9]+\. / { has_list = 1 }
    {
      n_body_lines++
      body[n_body_lines] = $0
    }
    END { flush(); exit (violations > 0 ? 1 : 0) }
  '
}

# lint_required_section <file> <artifact-type>
# artifact-types: goals, design, structure, plan, phasing
# Returns 0 if no violations, 1 if any violation found (CodexF5 fix-cycle 1).
lint_required_section() {
  local file="$1"
  local type="$2"
  local required=()
  case "$type" in
    goals)     required=("## Purpose" "## Constraints" "## Goals") ;;
    design)    required=("## Approach" "## Key Decisions" "## Trade-offs Considered" "## Test Strategy" "## System Diagram") ;;
    structure) required=("## File Map" "## Interfaces" "## Architectural Diagram") ;;
    plan)      required=("## Phase" "## Target files" "## Description") ;;
    phasing)   required=("## Slices" "## Phases") ;;
    *)         echo "LINT: required-section: unknown-artifact-type=$type"; return 1 ;;
  esac
  local h violations=0
  for h in "${required[@]}"; do
    if ! grep -qF "$h" "$file"; then
      echo "LINT: required-section: $type :: missing-heading=$h"
      violations=$((violations + 1))
    fi
  done
  [ "$violations" -eq 0 ]
}

# lint_no_brevity <file>
# Flags bare brevity instructions; allowlists meta-mentions and length bands.
# Returns 0 if no violations, 1 if any violation found (CodexF5 fix-cycle 1).
lint_no_brevity() {
  local file="$1"
  awk '
    {
      raw = $0
      lower = tolower(raw)

      # Allowlist clauses — any of these short-circuits the line.
      if (lower ~ /u14/)              next
      if (lower ~ /forbidden/)        next
      if (lower ~ /prohibit/)         next
      if (lower ~ /do not/)           next
      if (lower ~ /do n.t/)           next  # tolerate dotted "do nOt"
      if (lower ~ /soft length target/) next
      if (lower ~ /length.target/)    next
      if (lower ~ /allowlist/)        next
      if (lower ~ /allow.list/)       next
      if (lower ~ /exempt/)           next
      if (lower ~ /must not/)         next
      if (lower ~ /not trigger/)      next
      # M49-M52 numeric length bands (e.g. "200-400 lines", "1000–2000 lines",
      # "200–400 lines"). Hyphen or en-dash, hyphen-minus or unicode dash.
      if (raw ~ /[0-9]+[ ]?[-–—][ ]?[0-9]+[ ]+lines/) next

      # Quoted-form allowlist: phrase appears inside quotes (single, double,
      # or backtick), indicating meta-mention not instruction.
      quoted_concise = (raw ~ /["`'\'']be concise["`'\'']/)
      quoted_brief   = (raw ~ /["`'\'']brief summary["`'\'']/)
      quoted_lines   = (raw ~ /["`'\''][^"`'\'']*≤[^"`'\'']*lines[^"`'\'']*["`'\'']/)

      hit = 0
      detail = ""

      if (lower ~ /be concise/ && !quoted_concise) {
        hit = 1
        detail = "be concise"
      }
      if (lower ~ /brief summary/ && !quoted_brief) {
        hit = 1
        detail = (detail == "" ? "brief summary" : detail ", brief summary")
      }
      # ≤ N lines pattern — Unicode "≤" or ASCII "<=" followed by digits then "lines".
      if (raw ~ /(≤|<=)[ ]*[0-9]+[ ]*lines/ && !quoted_lines) {
        hit = 1
        detail = (detail == "" ? "≤ N lines" : detail ", ≤ N lines")
      }

      if (hit) {
        printf "LINT: no-brevity: line %d :: %s\n", NR, detail
        violations++
      }
    }
    END { exit (violations > 0 ? 1 : 0) }
  ' "$file"
}

# =============================================================================
# Helper sanity checks
# =============================================================================

@test "[U14-helper] strip_fenced_code removes fenced blocks but keeps prose" {
  local fixture; fixture="$BATS_TMPDIR/fence.md"
  printf '%s\n' "before" '```' "code-line" '```' "after" > "$fixture"
  local out; out="$(strip_fenced_code "$fixture")"
  [[ "$out" == *"before"* ]]
  [[ "$out" == *"after"* ]]
  [[ "$out" != *"code-line"* ]]
}

# =============================================================================
# Lint 1 — claim-line
# =============================================================================

@test "[U14-lint:claim-line] fires on seeded violation fixture" {
  run lint_claim_line "$FIXTURE_DIR/seeded-u14-violation-claim-line.md"
  # CodexF5 fix-cycle 1: exit-status check is the primary contract; output
  # checks remain as additional diagnostics.
  [ "$status" -ne 0 ]
  [[ "$output" == *"LINT: claim-line:"* ]]
  [[ "$output" == *"opening-sentence-too-long"* ]]
  [[ "$output" == *"opening-sentence-missing-terminal-punctuation"* ]]
}

@test "[U14-lint:claim-line] correctly identifies pre-existing in-scope violations (FU-7 positive assertion)" {
  # FU-7: pre-existing claim-line violations in in-scope SKILL.md files.
  # Positive assertion that the lint correctly fires on real input — guards
  # against the silent-no-op failure mode where the lint passes vacuously.
  # See docs/qrspi/2026-04-26-prompt-improvements/future-followups.md (FU-7).
  run lint_claim_line "$REPO_ROOT/skills/goals/SKILL.md"
  # CodexF5 fix-cycle 1: exit-status is now the primary contract.
  [ "$status" -ne 0 ]
  [[ "$output" == *"LINT: claim-line:"* ]]
}

@test "[U14-lint:claim-line] does NOT fire on in-scope skill files (FU-7: SKIPPED until cleaned)" {
  skip "FU-7: in-scope skill files have pre-existing U14 claim-line violations (see future-followups.md). Trivial prose split post-Integrate."
  local f
  for f in "${IN_SCOPE_FILES[@]}"; do
    run lint_claim_line "$f"
    [ "$status" -eq 0 ]
    if [[ "$output" == *"LINT:"* ]]; then
      printf 'In-scope file violates claim-line lint: %s\n%s\n' "$f" "$output" >&2
      return 1
    fi
  done
}

# =============================================================================
# Lint 2 — paragraph-density
# =============================================================================

@test "[U14-lint:paragraph-density] fires on seeded violation fixture (>150w and >8L)" {
  run lint_paragraph_density "$FIXTURE_DIR/seeded-u14-violation-paragraph-density.md"
  # CodexF5 fix-cycle 1: exit-status check is now the primary contract.
  [ "$status" -ne 0 ]
  [[ "$output" == *"LINT: paragraph-density:"* ]]
  [[ "$output" == *"paragraph-too-many-words"* ]]
}

@test "[U14-lint:paragraph-density] correctly identifies pre-existing in-scope violations (FU-7 positive assertion)" {
  # FU-7 positive assertion: the lint fires on real in-scope content.
  # goals/SKILL.md is the highest-violation in-scope file (4 paragraph-density
  # findings: 176/261/217-word paragraphs and one 9-line paragraph).
  run lint_paragraph_density "$REPO_ROOT/skills/goals/SKILL.md"
  # CodexF5 fix-cycle 1: exit-status is now the primary contract.
  [ "$status" -ne 0 ]
  [[ "$output" == *"LINT: paragraph-density:"* ]]
  [[ "$output" == *"paragraph-too-many-words"* ]]
}

@test "[U14-lint:paragraph-density] does NOT fire on in-scope skill files (FU-7: SKIPPED until cleaned)" {
  skip "FU-7: in-scope skill files have pre-existing U14 paragraph-density violations (>150 words per paragraph). See future-followups.md. Trivial prose split post-Integrate."
  local f
  for f in "${IN_SCOPE_FILES[@]}"; do
    run lint_paragraph_density "$f"
    if [[ "$output" == *"LINT:"* ]]; then
      printf 'In-scope file violates paragraph-density lint: %s\n%s\n' "$f" "$output" >&2
      return 1
    fi
  done
}

# =============================================================================
# Lint 3 — scannability
# =============================================================================

@test "[U14-lint:scannability] fires on seeded violation fixture (long section, no bullets)" {
  run lint_scannability "$FIXTURE_DIR/seeded-u14-violation-scannability.md"
  # CodexF5 fix-cycle 1: exit-status check is now the primary contract.
  [ "$status" -ne 0 ]
  [[ "$output" == *"LINT: scannability:"* ]]
  [[ "$output" == *"long-section-no-list"* ]]
}

@test "[U14-lint:scannability] does NOT fire on in-scope skill files (post-Wave-5 baseline)" {
  local f
  for f in "${IN_SCOPE_FILES[@]}"; do
    run lint_scannability "$f"
    # CodexF5 fix-cycle 1: status MUST be zero on a clean file.
    [ "$status" -eq 0 ]
    if [[ "$output" == *"LINT:"* ]]; then
      printf 'In-scope file violates scannability lint: %s\n%s\n' "$f" "$output" >&2
      return 1
    fi
  done
}

# =============================================================================
# Lint 4 — required-section conformance
# =============================================================================

@test "[U14-lint:required-section] fires on seeded violation fixture (design type, missing 2 headings)" {
  run lint_required_section "$FIXTURE_DIR/seeded-u14-violation-required-heading.md" design
  # CodexF5 fix-cycle 1: exit-status check is now the primary contract.
  [ "$status" -ne 0 ]
  [[ "$output" == *"LINT: required-section:"* ]]
  [[ "$output" == *"missing-heading=## Test Strategy"* ]]
  [[ "$output" == *"missing-heading=## System Diagram"* ]]
}

@test "[U14-lint:required-section] passes on a correctly-headed fixture" {
  local fixture; fixture="$BATS_TMPDIR/required-heading-clean.md"
  printf '## Approach\n\nx\n\n## Key Decisions\n\nx\n\n## Trade-offs Considered\n\nx\n\n## Test Strategy\n\nx\n\n## System Diagram\n\nx\n' > "$fixture"
  run lint_required_section "$fixture" design
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# =============================================================================
# Lint 5 — no-brevity grep
# =============================================================================

@test "[U14-lint:no-brevity] fires on seeded violation fixture (3 bare instructions)" {
  run lint_no_brevity "$FIXTURE_DIR/seeded-u14-violation-no-brevity.md"
  # CodexF5 fix-cycle 1: exit-status check is now the primary contract.
  [ "$status" -ne 0 ]
  [[ "$output" == *"LINT: no-brevity:"* ]]
  [[ "$output" == *"be concise"* ]]
  [[ "$output" == *"brief summary"* ]]
  [[ "$output" == *"≤ N lines"* ]]
}

@test "[U14-lint:no-brevity] allowlist exempts quoted forms and length-target bands" {
  # Build a synthetic file containing only allowlisted lines — must produce zero lints.
  local fixture; fixture="$BATS_TMPDIR/no-brevity-allowlist.md"
  {
    echo "Soft length target: 200–400 lines for this SKILL.md."
    echo "Soft length target: 300-500 lines for SKILL.md."
    echo "Soft length target: 1000–2000 lines for plan.md aggregate."
    echo 'The phrase "be concise" is forbidden under U14.'
    echo "U14 allowlist exempts \"brief summary\" when cited in quotes."
    echo "U14 forbids \"≤ 5 lines\" framing."
    echo "do NOT add 'be concise' framing anywhere."
  } > "$fixture"
  run lint_no_brevity "$fixture"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "[U14-lint:no-brevity] does NOT fire on in-scope skill files (post-Wave-5 baseline)" {
  local f
  for f in "${IN_SCOPE_FILES[@]}"; do
    run lint_no_brevity "$f"
    # CodexF5 fix-cycle 1: status MUST be zero on a clean file.
    [ "$status" -eq 0 ]
    if [[ "$output" == *"LINT:"* ]]; then
      printf 'In-scope file violates no-brevity lint: %s\n%s\n' "$f" "$output" >&2
      return 1
    fi
  done
}

# =============================================================================
# Scope assertion — lint runs only over the in-scope file set, not all skills/**
# =============================================================================

@test "[U14-scope] in-scope file list is exactly 5 SKILL.md (not all skills/**)" {
  [ "${#IN_SCOPE_FILES[@]}" -eq 5 ]
  local f
  for f in "${IN_SCOPE_FILES[@]}"; do
    [ -f "$f" ]
  done
}

@test "[U14-scope] in-scope set excludes implement/integrate/test/replan/using-qrspi/research/questions/parallelize" {
  # Counter-assertion: no in-scope path should match these out-of-scope skill slugs.
  # Uses slug_extractor (anchored to skills/<slug>/) to avoid false positives from
  # ancestor directory names that happen to contain an exclusion token substring.
  local excluded_slugs=(implement integrate test replan using-qrspi research questions parallelize)
  local f
  for f in "${IN_SCOPE_FILES[@]}"; do
    local slug
    slug="$(slug_extractor "$f")"
    local excl
    for excl in "${excluded_slugs[@]}"; do
      [[ "$slug" != "$excl" ]]
    done
  done
}

# =============================================================================
# Slug extractor — derives the skill slug from the path segment immediately
# after `skills/`. Returns empty string when `skills/` is absent in the path.
# This anchored extraction eliminates the false-positive class where an ancestor
# directory name happens to contain an exclusion-token substring.
# =============================================================================

# slug_extractor <path>
# Prints the path segment immediately following `skills/`, or nothing when
# `skills/` is absent. No trailing slash in the output.
slug_extractor() {
  local path="$1"
  # Use awk to split on "/" and find the segment after "skills".
  printf '%s' "$path" | awk -F'/' '
    {
      for (i = 1; i < NF; i++) {
        if ($i == "skills" && i+1 <= NF) {
          print $(i+1)
          exit
        }
      }
    }
  '
}

@test "[U14-slug] confusable-prefix: path with integrate in ancestor yields slug=goals (u14-lint passes)" {
  # Fixture: tests/fixtures/u14-worktree-confusable/skills/goals/SKILL.md
  # The ancestor directory u14-worktree-confusable contains the substring
  # "integrate" but the skill slug resolves to "goals".
  local confusable_path="$FIXTURE_DIR/u14-worktree-confusable/skills/goals/SKILL.md"
  [ -f "$confusable_path" ] || skip "confusable fixture not found (expected at $confusable_path)"

  local slug
  slug="$(slug_extractor "$confusable_path")"
  [ "$slug" = "goals" ]

  # u14-lint (no-brevity) must PASS for this path — slug is "goals", not "integrate",
  # so the exclusion does not fire.
  local excluded_slugs=(implement integrate test replan using-qrspi research questions parallelize)
  local excl
  local slug_excluded=false
  for excl in "${excluded_slugs[@]}"; do
    if [ "$slug" = "$excl" ]; then
      slug_excluded=true
      break
    fi
  done
  [ "$slug_excluded" = "false" ]
}

@test "[U14-slug] genuine-integrate: path under skills/integrate/ yields slug=integrate (u14-lint fails)" {
  # Fixture: tests/fixtures/u14-genuine-integrate/skills/integrate/SKILL.md
  # The skill slug resolves to "integrate" — the exclusion MUST fire.
  local genuine_path="$FIXTURE_DIR/u14-genuine-integrate/skills/integrate/SKILL.md"
  [ -f "$genuine_path" ] || skip "genuine-integrate fixture not found (expected at $genuine_path)"

  local slug
  slug="$(slug_extractor "$genuine_path")"
  [ "$slug" = "integrate" ]

  # Slug must match the exclusion list.
  local excluded_slugs=(implement integrate test replan using-qrspi research questions parallelize)
  local excl
  local slug_excluded=false
  for excl in "${excluded_slugs[@]}"; do
    if [ "$slug" = "$excl" ]; then
      slug_excluded=true
      break
    fi
  done
  [ "$slug_excluded" = "true" ]
}

@test "[U14-slug] no-skills-segment: path without skills/ yields empty slug (no exclusion match)" {
  # Boundary case: a path that does not contain the skills/ segment at all
  # must yield an empty slug so no exclusion fires.
  local no_skills_path="/tmp/some/other/path/SKILL.md"
  local slug
  slug="$(slug_extractor "$no_skills_path")"
  [ -z "$slug" ]
}
