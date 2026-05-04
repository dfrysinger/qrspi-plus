#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Task 17 — M49-M52 per-goal SKILL.md content patterns
#
# Per-goal targeted assertions against the four synthesizing-skill SKILL.md
# files. Each goal's assertions run independently so a regression in one
# skill localizes to that skill's tests:
#
#   M49 — skills/goals/SKILL.md
#         (type: known-fix|exploratory; three-section Problem/Why/What;
#          no acceptance-criteria push points; no top-level Out-of-Scope;
#          solutions-as-possibilities framing)
#   M50 — skills/design/SKILL.md
#         (Design OWNS / Design DEFERS heading; 200-400 length-target
#          marker; per-section guidance markers; no Vertical Slices /
#          Phases Output blocks; no Iron Laws 1/2 authoring text)
#   M51 — skills/structure/SKILL.md
#         (Structure OWNS / Structure DEFERS heading; 300-500 length
#          marker; signature-not-implementation rule; C-header phrase;
#          no per-task LOC / assertion text / commit ranges in OWNS)
#   M52 — skills/plan/SKILL.md
#         (Plan OWNS / Plan DEFERS heading; 1000-2000 length marker;
#          INVEST Negotiable framing; no function-signatures /
#          full-assertion-text / line-by-line in OWNS)
#
# All assertions extract a target heading's section text first (until the
# next `^## ` or `^### ` heading) and assert on the extracted slice — so a
# string appearing under a different heading cannot vacuously satisfy a
# different section's check.

setup() {
  GOALS_FILE="$BATS_TEST_DIRNAME/../../skills/goals/SKILL.md"
  DESIGN_FILE="$BATS_TEST_DIRNAME/../../skills/design/SKILL.md"
  STRUCTURE_FILE="$BATS_TEST_DIRNAME/../../skills/structure/SKILL.md"
  PLAN_FILE="$BATS_TEST_DIRNAME/../../skills/plan/SKILL.md"
  GOALS_OWNS_FILE="$BATS_TEST_DIRNAME/../../skills/goals/owns-defers.md"
  STRUCTURE_OWNS_FILE="$BATS_TEST_DIRNAME/../../skills/structure/owns-defers.md"
  PLAN_OWNS_FILE="$BATS_TEST_DIRNAME/../../skills/plan/owns-defers.md"
  export GOALS_FILE DESIGN_FILE STRUCTURE_FILE PLAN_FILE
  export GOALS_OWNS_FILE STRUCTURE_OWNS_FILE PLAN_OWNS_FILE
}

# extract_h2_section <file> <h2-heading>
# Prints the section starting at the given exact H2 heading up to but not
# including the next `^## ` heading.
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
# Prints the H3 sub-block from inside the given H2 section, scoped to that
# H3 only (stops at the next H3 or H2).
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

# ── M49: skills/goals/SKILL.md content patterns ─────────────────────────────

@test "[M49] skills/goals/SKILL.md exists" {
  [ -f "$GOALS_FILE" ]
}

@test "[M49] goals SKILL has ## Goals OWNS / Goals DEFERS heading" {
  run grep -c "^## Goals OWNS / Goals DEFERS$" "$GOALS_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

@test "[M49] goals SKILL OWNS subsection mandates type field with known-fix|exploratory values" {
  local block
  block="$(extract_h3_direct "$GOALS_OWNS_FILE" "### Goals OWNS")"
  [ -n "$block" ]
  echo "$block" | grep -qi "type"
  echo "$block" | grep -q "known-fix"
  echo "$block" | grep -q "exploratory"
}

@test "[M49] goals SKILL OWNS subsection mandates three-section Problem / Why we care / What we know so far per goal" {
  local block
  block="$(extract_h3_direct "$GOALS_OWNS_FILE" "### Goals OWNS")"
  [ -n "$block" ]
  echo "$block" | grep -qi "Problem"
  echo "$block" | grep -qi "Why we care"
  echo "$block" | grep -qi "What we know so far"
  echo "$block" | grep -Eqi "three subsections|exactly three"
}

@test "[M49] goals SKILL DEFERS subsection lists acceptance criteria as deferred (no acceptance-criteria push)" {
  local block
  block="$(extract_h3_direct "$GOALS_OWNS_FILE" "### Goals DEFERS")"
  [ -n "$block" ]
  echo "$block" | grep -qi "Acceptance criteria"
}

@test "[M49] goals SKILL forbids top-level Out-of-Scope section in goals.md" {
  # The Iron Rule paragraph asserts the artifact has no top-level Out of
  # Scope heading. Search for the prohibition directly.
  grep -Eqi "no top-level .Out of Scope|NO top-level .Out of Scope" "$GOALS_FILE"
}

@test "[M49] goals SKILL frames solution candidates as possibilities (solutions-as-possibilities)" {
  # The OWNS subsection or template prose must frame solution candidates
  # as possibilities Design will weigh, not commitments.
  local block
  block="$(extract_h3_direct "$GOALS_OWNS_FILE" "### Goals OWNS")"
  [ -n "$block" ]
  echo "$block" | grep -Eqi "candidates? Design should weigh|possibilit(y|ies)|possibilities for Design"
}

# ── M50: skills/design/SKILL.md content patterns ────────────────────────────

@test "[M50] skills/design/SKILL.md exists" {
  [ -f "$DESIGN_FILE" ]
}

@test "[M50] design SKILL has ## Design OWNS / Design DEFERS heading" {
  run grep -c "^## Design OWNS / Design DEFERS$" "$DESIGN_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

@test "[M50] design SKILL has 200-400 length-target marker" {
  # En-dash or hyphen tolerated; comment-style HTML marker present at top.
  grep -Eq "200[-–]400" "$DESIGN_FILE"
}

@test "[M50] design SKILL has per-section template guidance markers (HTML comments)" {
  # Per-section guidance comments live inside the design.md output template
  # block. Count must be ≥3 distinct guidance comments.
  local count
  count=$(grep -c "Per-section guidance" "$DESIGN_FILE" || true)
  [ "$count" -ge 3 ]
}

@test "[M50] design SKILL output template has NO ## Vertical Slices Output block" {
  # The design.md template block (between ```` fences) must not author a
  # ## Vertical Slices section — that's Phasing's OWNS.
  ! grep -Eq "^## Vertical Slices" "$DESIGN_FILE"
}

@test "[M50] design SKILL output template has NO ## Phases Output block" {
  ! grep -Eq "^## Phases" "$DESIGN_FILE"
}

@test "[M50] design SKILL has NO standalone ## Iron Law 1 or ## Iron Law 2 H2 sections (Phasing owns)" {
  # Iron Law 1 / Iron Law 2 are Phasing's authoring concern. Design may
  # *reference* them in DEFERS as deferred, but must not author them as
  # standalone H2 sections.
  ! grep -Eq "^## Iron Law 1" "$DESIGN_FILE"
  ! grep -Eq "^## Iron Law 2" "$DESIGN_FILE"
}

# ── Task 36: integration-round-01 fixes for design SKILL ────────────────────
#
# T36 bundles two findings on skills/design/SKILL.md:
#   T36-1 (R1 Claude-I4) — design reviewer prompt's "addresses ... acceptance
#         criteria" wording is post-T9 deprecated; goals.md no longer authors
#         acceptance criteria (T9 strip-from-goals contract — plan.md owns
#         them now). The Review Round subsection's Claude reviewer checks
#         must drop the deprecated phrasing.
#   T36-2 (R2 I-N5) — design's Artifact Gating subsection silently defaults
#         codex_reviews to false when config.md is missing; using-qrspi:411
#         requires every skill that reads config.md to invoke the Config
#         Validation Procedure instead. Design must validate codex_reviews.

# extract_review_round <file>
# Extracts the `### Review Round` subsection from the design SKILL.md, robust
# to fenced code-block content (which contains `## Approach`, `## Key
# Decisions`, etc., that would otherwise confuse the simple H2 extractor).
# Tracks code-fence state and only stops on a real (out-of-fence) `### `/`## `
# heading after the Review Round heading is entered.
extract_review_round() {
  local file="$1"
  awk '
    /^```/ { fence = !fence; if (in_b) print; next }
    !fence && $0 == "### Review Round" { in_b = 1; print; next }
    in_b && !fence && /^### / { exit }
    in_b && !fence && /^## / { exit }
    in_b { print }
  ' "$file"
}

@test "[T36-1] design SKILL Review Round Claude-reviewer checks no longer reference deprecated 'acceptance criteria' phrasing" {
  # The Review Round subsection (under ### Review Round) authors the Claude
  # reviewer prompt's check list. Per T9's strip-from-goals contract,
  # acceptance criteria are owned by plan.md, not goals.md — so a design
  # reviewer cannot meaningfully check "design addresses ... acceptance
  # criteria" at design time. The deprecated wording must be gone.
  local section
  section=$(extract_review_round "$DESIGN_FILE")
  if [ -z "$section" ]; then
    echo "Could not extract '### Review Round' subsection from design SKILL.md" >&2
    return 1
  fi
  # The phrase "acceptance criteria" must not appear inside the Review Round
  # subsection (case-insensitive, hyphen/space tolerant).
  if echo "$section" | grep -Eiq "acceptance[ -]criteria"; then
    echo "Deprecated 'acceptance criteria' phrasing still present in ### Review Round:" >&2
    echo "$section" | grep -Ei "acceptance[ -]criteria" >&2
    return 1
  fi
}

@test "[T36-1] design SKILL Review Round still asserts the design addresses all goals" {
  # Replacement wording: the reviewer should still verify that design
  # addresses goals (T9 keeps goals as the upstream traceability anchor).
  # We assert the post-T9 canonical phrasing — "addresses all goals"
  # (matches structure SKILL's analogous reviewer-prompt phrasing) — is
  # present inside the Review Round subsection.
  local section
  section=$(extract_review_round "$DESIGN_FILE")
  if [ -z "$section" ]; then
    echo "Could not extract '### Review Round' subsection from design SKILL.md" >&2
    return 1
  fi
  echo "$section" | grep -Eiq "addresses (all )?goals"
}

@test "[T36-2] design SKILL Artifact Gating no longer silently defaults codex_reviews to false" {
  # The deprecated wording: "If `config.md` doesn't exist, default to
  # `codex_reviews: false`." This is forbidden by using-qrspi:438 ("No
  # silent defaults"). The Artifact Gating subsection must not contain it.
  local section
  section=$(extract_h2_section "$DESIGN_FILE" "## Artifact Gating")
  if [ -z "$section" ]; then
    echo "Could not extract '## Artifact Gating' section from design SKILL.md" >&2
    return 1
  fi
  if echo "$section" | grep -Eiq "default to .*codex_reviews: false"; then
    echo "Silent codex_reviews default still present in ## Artifact Gating:" >&2
    echo "$section" | grep -Ei "default to .*codex_reviews: false" >&2
    return 1
  fi
}

@test "[T36-2] design SKILL Artifact Gating invokes the Config Validation Procedure for codex_reviews" {
  # Per using-qrspi:411 ("Every skill that reads config.md applies this
  # procedure before using any field"), Design must invoke the procedure
  # by name. Canonical phrasing in peer skills (goals/plan/test/integrate):
  #   "Apply the **Config Validation Procedure** in `using-qrspi/SKILL.md`.
  #    {Skill} validates `codex_reviews`."
  local section
  section=$(extract_h2_section "$DESIGN_FILE" "## Artifact Gating")
  if [ -z "$section" ]; then
    echo "Could not extract '## Artifact Gating' section from design SKILL.md" >&2
    return 1
  fi
  # Must mention the Config Validation Procedure inside Artifact Gating.
  echo "$section" | grep -q "Config Validation Procedure"
  # Must name codex_reviews as one of the validated fields.
  echo "$section" | grep -q "codex_reviews"
}

# ── M51: skills/structure/SKILL.md content patterns ─────────────────────────

@test "[M51] skills/structure/SKILL.md exists" {
  [ -f "$STRUCTURE_FILE" ]
}

@test "[M51] structure SKILL has ## Structure OWNS / Structure DEFERS heading" {
  run grep -c "^## Structure OWNS / Structure DEFERS$" "$STRUCTURE_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

@test "[M51] structure SKILL has 300-500 length-target marker" {
  grep -Eq "300[-–]500" "$STRUCTURE_FILE"
}

@test "[M51] structure SKILL has signature-not-implementation rule" {
  # The contract phrase is "function/class signatures, not implementations"
  # (Process step) plus the C-header analogy. Either phrasing is acceptable.
  grep -Eqi "signatures?, not implementations?|signature, not implementation" "$STRUCTURE_FILE"
}

@test "[M51] structure SKILL contains C-header analogy phrase" {
  grep -qi "C-header" "$STRUCTURE_OWNS_FILE"
}

@test "[M51] structure SKILL OWNS subsection does NOT positively enumerate per-task LOC, assertion text, or commit ranges" {
  local block
  block="$(extract_h3_direct "$STRUCTURE_OWNS_FILE" "### Structure OWNS")"
  [ -n "$block" ]
  # OWNS must not enumerate per-task LOC, assertion text, or commit ranges
  # as positively-owned items. The Test-file-layout bullet may *negate*
  # these (e.g., "Not assertion code, not assertion text, not commit
  # ranges") to clarify scope; that's compliant. The check below is that
  # any mention of these terms inside the OWNS sub-block is paired with a
  # negation marker — never asserted as a positive responsibility.
  ! echo "$block" | grep -Eqi "^[[:space:]]*-[[:space:]]+\*\*Per-task LOC"
  ! echo "$block" | grep -Eqi "^[[:space:]]*-[[:space:]]+\*\*LOC estimates?"
  ! echo "$block" | grep -Eqi "^[[:space:]]*-[[:space:]]+\*\*Assertion text"
  ! echo "$block" | grep -Eqi "^[[:space:]]*-[[:space:]]+\*\*Commit ranges?"
  ! echo "$block" | grep -Eqi "^[[:space:]]*-[[:space:]]+\*\*Per-task commit ranges?"
}

# ── M52: skills/plan/SKILL.md content patterns ──────────────────────────────

@test "[M52] skills/plan/SKILL.md exists" {
  [ -f "$PLAN_FILE" ]
}

@test "[M52] plan SKILL has ## Plan OWNS / Plan DEFERS heading" {
  run grep -c "^## Plan OWNS / Plan DEFERS$" "$PLAN_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

@test "[M52] plan SKILL has 1000-2000 length-target marker" {
  grep -Eq "1000[-–]2000" "$PLAN_OWNS_FILE"
}

@test "[M52] plan SKILL has INVEST Negotiable framing" {
  grep -qi "INVEST Negotiable" "$PLAN_OWNS_FILE"
  grep -Eqi "conversation, not a contract|conversation, not contract" "$PLAN_OWNS_FILE"
}

@test "[M52] plan SKILL OWNS subsection does NOT include function signatures, full assertion text, or line-by-line logic" {
  local block
  block="$(extract_h3_direct "$PLAN_OWNS_FILE" "### Plan OWNS")"
  [ -n "$block" ]
  # The OWNS list itself must not enumerate function signatures, full
  # assertion text, or line-by-line logic as plan.md's responsibilities.
  # (These belong in the DEFERS list.)
  ! echo "$block" | grep -Eqi "function signatures?|parameter shapes"
  ! echo "$block" | grep -Eqi "expect\(|assert\."
  ! echo "$block" | grep -Eqi "line-by-line|control-flow detail|algorithm pseudocode"
}

@test "[M52] plan SKILL DEFERS lists function signatures as deferred to structure.md" {
  local block
  block="$(extract_h3_direct "$PLAN_OWNS_FILE" "### Plan DEFERS")"
  [ -n "$block" ]
  echo "$block" | grep -Eqi "[Ff]unction signatures?"
  echo "$block" | grep -qi "structure.md"
}
