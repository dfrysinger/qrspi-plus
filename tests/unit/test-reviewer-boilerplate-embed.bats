#!/usr/bin/env bats
#
# Task 1 — reviewer-boilerplate.md (single consolidated reviewer-shared file)
#
# Test coverage maps to spec test expectations + critical constraints called out
# by L1 to prevent regressions seen in prior implementations:
#   1. File name MUST match Structure exactly (this file: test-reviewer-boilerplate-embed.bats).
#   2. Classifier section MUST include positive AND negative examples for each
#      of the five change_type values.
#   3. Bats assertions MUST be section-scoped, not file-global greps.
#   4. Frontmatter / rename-stability assertion MUST exist.
#
# The shared file under test:
#   skills/_shared/reviewer-boilerplate.md
#
# All assertions extract a target heading's section text first (until the next
# `^## ` heading) and then assert on the extracted slice — never on the whole
# file — so a string appearing under a different heading cannot vacuously
# satisfy a different section's check.

setup() {
  BOILERPLATE_FILE="$BATS_TEST_DIRNAME/../../skills/_shared/reviewer-boilerplate.md"
  export BOILERPLATE_FILE
}

# =============================================================================
# Helpers — section-scoped extraction
# =============================================================================

# extract_section <file> <heading-line>
# Prints the section starting at the given exact heading (e.g. "## Finding Schema")
# up to but NOT including the next "^## " heading. Heading line itself is included.
extract_section() {
  local file="$1"
  local heading="$2"
  awk -v h="$heading" '
    $0 == h { in_section = 1; print; next }
    in_section && /^## / { in_section = 0 }
    in_section { print }
  ' "$file"
}

# Sanity check the helper itself (constraint 3: verify scoping logic).
@test "helper: extract_section returns only the requested heading's slice" {
  local fixture
  fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
# Title

## Alpha
alpha-line-one
alpha-line-two

## Beta
beta-line-one
beta-line-two

## Gamma
gamma-line-one
EOF
  run extract_section "$fixture" "## Beta"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^## Beta$"
  echo "$output" | grep -q "^beta-line-one$"
  echo "$output" | grep -q "^beta-line-two$"
  ! echo "$output" | grep -q "alpha-line-one"
  ! echo "$output" | grep -q "gamma-line-one"
  rm -f "$fixture"
}

# =============================================================================
# Spec test expectation 1: file exists at the canonical path
# =============================================================================

@test "reviewer-boilerplate.md exists at skills/_shared/reviewer-boilerplate.md" {
  [ -f "$BOILERPLATE_FILE" ]
}

# =============================================================================
# Spec test expectation 2: ## Finding Schema heading + 5 field-name bullets
# (section-scoped per constraint 3)
# =============================================================================

@test "## Finding Schema heading is present" {
  run grep -c "^## Finding Schema$" "$BOILERPLATE_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

# Bullet-line assertions below intentionally avoid POSIX-incompatible \b
# word boundaries (codex round-2 finding: BSD grep on macOS does not honor
# \b reliably and would false-fail despite correct content). The schema
# bullets use markdown bold around backticked field names, e.g.
#   - **`finding_id`** — string. ...
# So we anchor on the literal markdown bold + backtick wrapper, which is
# both portable (basic ERE) and a stronger structural assertion than \b.

@test "## Finding Schema section enumerates finding_id as a bullet item" {
  local section
  section="$(extract_section "$BOILERPLATE_FILE" "## Finding Schema")"
  echo "$section" | grep -E '^[-*][[:space:]]+\*\*`finding_id`\*\*' >/dev/null
}

@test "## Finding Schema section enumerates severity as a bullet item" {
  local section
  section="$(extract_section "$BOILERPLATE_FILE" "## Finding Schema")"
  echo "$section" | grep -E '^[-*][[:space:]]+\*\*`severity`\*\*' >/dev/null
}

@test "## Finding Schema section enumerates change_type as a bullet item" {
  local section
  section="$(extract_section "$BOILERPLATE_FILE" "## Finding Schema")"
  echo "$section" | grep -E '^[-*][[:space:]]+\*\*`change_type`\*\*' >/dev/null
}

@test "## Finding Schema section enumerates message as a bullet item" {
  local section
  section="$(extract_section "$BOILERPLATE_FILE" "## Finding Schema")"
  echo "$section" | grep -E '^[-*][[:space:]]+\*\*`message`\*\*' >/dev/null
}

@test "## Finding Schema section enumerates referenced_files as a bullet item" {
  local section
  section="$(extract_section "$BOILERPLATE_FILE" "## Finding Schema")"
  echo "$section" | grep -E '^[-*][[:space:]]+\*\*`referenced_files`\*\*' >/dev/null
}

@test "## Finding Schema severity field lists low/medium/high allowed values" {
  # Silent-failure-hunter MEDIUM: bare greps for "low"/"medium"/"high" against
  # the entire schema section would pass on common English words ("low risk",
  # "medium" anywhere, etc.). Tighten to the single severity bullet line so
  # the three allowed values must co-occur in the bullet that defines them.
  local section severity_bullet
  section="$(extract_section "$BOILERPLATE_FILE" "## Finding Schema")"
  severity_bullet="$(echo "$section" | grep -E '^[-*][[:space:]]+\*\*`severity`\*\*')"
  [ -n "$severity_bullet" ]
  echo "$severity_bullet" | grep -q "low"
  echo "$severity_bullet" | grep -q "medium"
  echo "$severity_bullet" | grep -q "high"
}

@test "## Finding Schema change_type field lists style/clarity/correctness/scope/intent allowed values" {
  # Round-4 thoroughness MEDIUM F-04: mirror the severity-bullet enumeration
  # test above for the change_type schema bullet. Bare greps for these five
  # values against the entire schema section would pass on coincidental prose
  # mentions (e.g. the change_type bullet's tail prose says "auto-apply" /
  # "pause" and references the classifier). Tighten to the single change_type
  # bullet LINE so all five enum values must co-occur on the bullet that
  # defines them. Mutation target: silently dropping any value (e.g. `intent`)
  # from the schema bullet would make this test fail.
  local section change_type_bullet
  section="$(extract_section "$BOILERPLATE_FILE" "## Finding Schema")"
  change_type_bullet="$(echo "$section" | grep -E '^[-*][[:space:]]+\*\*`change_type`\*\*')"
  [ -n "$change_type_bullet" ]
  # Per-value word match against the captured bullet line. -w prevents a
  # substring like "intentional" from satisfying the `intent` assertion.
  echo "$change_type_bullet" | grep -qw "style"
  echo "$change_type_bullet" | grep -qw "clarity"
  echo "$change_type_bullet" | grep -qw "correctness"
  echo "$change_type_bullet" | grep -qw "scope"
  echo "$change_type_bullet" | grep -qw "intent"
}

# =============================================================================
# Spec test expectation 3: ## Change-Type Classifier
#   - all five change_type values named
#   - secondary-escalation rule references feedback/*.md
#   - per constraint 2: positive AND negative examples for each change_type
# =============================================================================

@test "## Change-Type Classifier heading is present" {
  run grep -c "^## Change-Type Classifier$" "$BOILERPLATE_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

@test "## Change-Type Classifier default-action rule names all five change_type values in dispatch lines" {
  # Round-4 thoroughness MEDIUM F-02 (REFRAME, not remove): the previous
  # version of this test grep'd the ENTIRE classifier section for each of the
  # five values as words. Because the section contains five `### style|...`
  # sub-headings AND prose mentions of the values throughout, that test was
  # essentially duplicative with the per-value positive/negative-example tests
  # below — those already prove all five sub-blocks exist by name.
  #
  # The reframe: assert the five values appear specifically in the
  # default-action rule's dispatch BULLET LINES (the lines that map values to
  # auto-apply vs pause behavior), not just as sub-headings or coincidental
  # prose. This proves the dispatch logic enumerates all five values — a
  # mutation that dropped "intent" from the pause line (or "correctness" from
  # the auto-apply line) while leaving the `### intent` sub-heading intact
  # would silently pass the old section-wide test, but fails this one.
  #
  # Note: the existing default-action chained-grep test below already asserts
  # the exact triple/pair groupings (style+clarity+correctness on the
  # auto-apply line; scope+intent on the pause line). This test is the
  # complementary "all five named" enumeration check, scoped to the rule
  # block rather than the whole classifier section, so the two are
  # independently load-bearing.
  local block
  block="$(extract_rule_block "**Default-action rule.**")"
  [ -n "$block" ]
  echo "$block" | grep -qw "style"
  echo "$block" | grep -qw "clarity"
  echo "$block" | grep -qw "correctness"
  echo "$block" | grep -qw "scope"
  echo "$block" | grep -qw "intent"
}

# extract_rule_block <bold-rule-heading>
# Extracts a bold-prefixed rule sub-block from inside the Change-Type
# Classifier section. The classifier uses paragraph-level rule headings of
# the form "**Default-action rule.**" / "**Secondary-escalation rule.**" /
# "> **Future-hook placeholder ...". This helper extracts from the named
# rule heading line up to the next bold-prefixed rule heading, the
# blockquote future-hook marker, or the next ### sub-section heading.
#
# Rationale (silent-failure-hunter MEDIUM): the previous tests grep'd the
# ENTIRE classifier section for "auto-apply"/"pause"/"escalat"/"intent" —
# words that appear elsewhere in the classifier prose (e.g. inside the
# scope/intent sub-blocks), so a bug that DELETED the default-action rule
# or the secondary-escalation rule would still pass. By extracting just
# the rule sub-block first, we force the assertions to bind to the rule
# they claim to verify.
extract_rule_block() {
  local heading="$1"
  extract_section "$BOILERPLATE_FILE" "## Change-Type Classifier" \
    | awk -v h="$heading" '
        $0 == h { in_b = 1; print; next }
        in_b && /^\*\*[A-Z].*\.\*\*$/ { exit }
        in_b && /^> \*\*/ { exit }
        in_b && /^### / { exit }
        in_b { print }
      '
}

@test "## Change-Type Classifier includes default-action rule (auto-apply for style/clarity/correctness, pause for scope/intent)" {
  # Silent-failure-hunter MEDIUM #1: tighten from section-wide greps to the
  # default-action sub-block, AND require the policy verbs to co-occur with
  # the change_types they govern on the same line. Otherwise a rule that
  # said "auto-apply" and "pause" but mis-mapped change_types would pass.
  local block
  block="$(extract_rule_block "**Default-action rule.**")"
  [ -n "$block" ]
  # Single-line co-occurrence: chain greps so each filter narrows the line set.
  # The auto-apply rule line MUST enumerate all three governed change_types
  # (style, clarity, correctness) on the same line. If the rule were split
  # across multiple lines, the chain would filter the line set down to empty
  # and grep -q would fail. (codex round-3 finding: previous independent
  # `grep "X" | grep -q "Y"` pairs only required X and Y to co-occur somewhere
  # in the auto-apply-filtered line set, not on a single line.)
  echo "$block" | grep -i "auto-apply" | grep "style" | grep "clarity" | grep -q "correctness"
  # Single-line co-occurrence: pause line must mention both scope and intent.
  echo "$block" | grep -i "pause" | grep "scope" | grep -q "intent"
}

@test "## Change-Type Classifier includes secondary-escalation rule referencing feedback/*.md" {
  # Silent-failure-hunter MEDIUM #2: previously three independent greps
  # against the whole classifier section — `feedback/*.md`, "escalat", and
  # "intent" all appear elsewhere (intent has its own ### sub-block, the
  # M44 future-hook placeholder also says "escalation"), so the rule could
  # be deleted and the test would still pass on coincidental matches.
  # Require all three terms to co-occur in the actual rule sub-block.
  local block
  block="$(extract_rule_block "**Secondary-escalation rule.**")"
  [ -n "$block" ]
  echo "$block" | grep -q "feedback/\*\.md"
  echo "$block" | grep -qi "escalat"
  echo "$block" | grep -qw "intent"
}

@test "## Change-Type Classifier includes M44 capture-corpus future-hook placeholder note (out-of-scope this run)" {
  local section
  section="$(extract_section "$BOILERPLATE_FILE" "## Change-Type Classifier")"
  echo "$section" | grep -q "M44"
}

# Constraint 2: positive AND negative examples for each of the five change_type values.
# We check that each change_type entry-line in the classifier section has both
# Positive and Negative example markers nearby (within its sub-block).

# extract_subblock <heading-line> — extract a ### sub-block from inside the
# Change-Type Classifier section. Heading must match exactly (e.g. "### style").
# Reads the classifier section first, then extracts from the named ### heading
# up to the next ### heading.
extract_subblock() {
  local heading="$1"
  extract_section "$BOILERPLATE_FILE" "## Change-Type Classifier" \
    | awk -v h="$heading" '
        $0 == h { in_b = 1; print; next }
        in_b && /^### / { exit }
        in_b { print }
      '
}

@test "## Change-Type Classifier has positive AND negative example for style" {
  local block
  block="$(extract_subblock "### style")"
  echo "$block" | grep -qi "Positive"
  echo "$block" | grep -qi "Negative"
}

@test "## Change-Type Classifier has positive AND negative example for clarity" {
  local block
  block="$(extract_subblock "### clarity")"
  echo "$block" | grep -qi "Positive"
  echo "$block" | grep -qi "Negative"
}

@test "## Change-Type Classifier has positive AND negative example for correctness" {
  local block
  block="$(extract_subblock "### correctness")"
  echo "$block" | grep -qi "Positive"
  echo "$block" | grep -qi "Negative"
}

@test "## Change-Type Classifier has positive AND negative example for scope" {
  local block
  block="$(extract_subblock "### scope")"
  echo "$block" | grep -qi "Positive"
  echo "$block" | grep -qi "Negative"
}

@test "## Change-Type Classifier has positive AND negative example for intent" {
  local block
  block="$(extract_subblock "### intent")"
  echo "$block" | grep -qi "Positive"
  echo "$block" | grep -qi "Negative"
}

# =============================================================================
# Spec test expectation 4: ## Disagreement-Valid Framing
#   - heading present
#   - text affirms contradictory findings as valid (not a violation)
# =============================================================================

@test "## Disagreement-Valid Framing heading is present" {
  run grep -c "^## Disagreement-Valid Framing$" "$BOILERPLATE_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

@test "## Disagreement-Valid Framing affirms contradictory findings as valid behavior" {
  # Silent-failure-hunter MEDIUM #4: previously three independent greps
  # against the whole framing section. The three terms (contradict/disagree,
  # user, valid/correct/not-a-violation) could each match unrelated prose
  # in different paragraphs while the actual affirmation sentence had been
  # deleted. Tighten to require all three concepts to co-occur in a SINGLE
  # sentence/line — that is the load-bearing claim "flagging contradictory
  # findings is correct behavior."
  local section
  section="$(extract_section "$BOILERPLATE_FILE" "## Disagreement-Valid Framing")"
  # Must mention contradicting/disagreeing with prior user decisions
  echo "$section" | grep -qiE "contradict|disagree"
  echo "$section" | grep -qi "user"
  # Must explicitly affirm: "valid", "correct behavior", "not a violation", etc.
  echo "$section" | grep -qiE "valid|correct behavior|not a violation"
  # Co-occurrence: split the section into sentences (period-terminated) and
  # require at least one sentence to contain a contradiction-keyword AND a
  # user-keyword AND a validity-keyword. Bold/markdown is preserved as-is.
  local cooccur
  cooccur="$(echo "$section" \
    | tr '\n' ' ' \
    | awk 'BEGIN { RS = "[.!?]" } { print }' \
    | grep -iE "contradict|disagree" \
    | grep -i "user" \
    | grep -iE "valid|correct behavior|not a violation" \
    || true)"
  [ -n "$cooccur" ]
}

# =============================================================================
# Spec test expectation 5: Frontmatter (if any) and file name unchanged across
# subsequent edits — rename-stability assertion (constraint 4).
# =============================================================================

@test "rename-stability: file lives at canonical path skills/_shared/reviewer-boilerplate.md" {
  # Path-stability check: the exact file path must exist (no rename).
  [ -f "$BOILERPLATE_FILE" ]
  # And no sibling file with a renamed/legacy name is present that would shadow it.
  ! [ -f "$BATS_TEST_DIRNAME/../../skills/_shared/reviewer-disagreement-valid.md" ]
  ! [ -f "$BATS_TEST_DIRNAME/../../skills/_shared/finding-schema.md" ]
  ! [ -f "$BATS_TEST_DIRNAME/../../skills/_shared/change-type-classifier.md" ]
}

@test "rename-stability: frontmatter state captured (either absent or contains a stable marker)" {
  # Capture the frontmatter state. The design choice is no frontmatter on this
  # shared content file (it is included verbatim into reviewer prompts; YAML
  # frontmatter would leak into the prompt). This assertion locks that choice
  # so a later edit that adds frontmatter will fail this test and force an
  # explicit rename-stability conversation.
  local first_line
  first_line="$(head -n 1 "$BOILERPLATE_FILE")"
  if [ "$first_line" = "---" ]; then
    # If the project later decides to introduce frontmatter, it MUST contain a
    # stable marker we lock here. Currently no frontmatter is expected.
    echo "Unexpected frontmatter present; design specifies no frontmatter." >&2
    return 1
  fi
  # Confirm the file starts with the H1/preface, not YAML.
  [ "$first_line" != "---" ]
}

# =============================================================================
# Designed-to-grow preface (per spec line 13 + constraint context):
#   File must mark itself as designed-to-grow so future reviewer-shared content
#   lands as additional sections without rename.
# =============================================================================

@test "preface notes the file is designed-to-grow for future reviewer-shared content" {
  # Preface = content before the first ## heading. Extract it and assert.
  local preface
  preface="$(awk '/^## / { exit } { print }' "$BOILERPLATE_FILE")"
  echo "$preface" | grep -qiE "designed[- ]to[- ]grow|grow|future.+sections|additional sections"
}
