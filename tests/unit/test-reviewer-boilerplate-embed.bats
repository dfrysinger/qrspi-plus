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

@test "## Finding Schema section enumerates finding_id as a bullet item" {
  local section
  section="$(extract_section "$BOILERPLATE_FILE" "## Finding Schema")"
  echo "$section" | grep -E "^[-*] .*\bfinding_id\b" >/dev/null
}

@test "## Finding Schema section enumerates severity as a bullet item" {
  local section
  section="$(extract_section "$BOILERPLATE_FILE" "## Finding Schema")"
  echo "$section" | grep -E "^[-*] .*\bseverity\b" >/dev/null
}

@test "## Finding Schema section enumerates change_type as a bullet item" {
  local section
  section="$(extract_section "$BOILERPLATE_FILE" "## Finding Schema")"
  echo "$section" | grep -E "^[-*] .*\bchange_type\b" >/dev/null
}

@test "## Finding Schema section enumerates message as a bullet item" {
  local section
  section="$(extract_section "$BOILERPLATE_FILE" "## Finding Schema")"
  echo "$section" | grep -E "^[-*] .*\bmessage\b" >/dev/null
}

@test "## Finding Schema section enumerates referenced_files as a bullet item" {
  local section
  section="$(extract_section "$BOILERPLATE_FILE" "## Finding Schema")"
  echo "$section" | grep -E "^[-*] .*\breferenced_files\b" >/dev/null
}

@test "## Finding Schema severity field lists low/medium/high allowed values" {
  local section
  section="$(extract_section "$BOILERPLATE_FILE" "## Finding Schema")"
  echo "$section" | grep -q "low"
  echo "$section" | grep -q "medium"
  echo "$section" | grep -q "high"
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

@test "## Change-Type Classifier names all five change_type values" {
  local section
  section="$(extract_section "$BOILERPLATE_FILE" "## Change-Type Classifier")"
  echo "$section" | grep -qw "style"
  echo "$section" | grep -qw "clarity"
  echo "$section" | grep -qw "correctness"
  echo "$section" | grep -qw "scope"
  echo "$section" | grep -qw "intent"
}

@test "## Change-Type Classifier includes default-action rule (auto-apply for style/clarity/correctness, pause for scope/intent)" {
  local section
  section="$(extract_section "$BOILERPLATE_FILE" "## Change-Type Classifier")"
  echo "$section" | grep -qi "auto-apply"
  echo "$section" | grep -qi "pause"
}

@test "## Change-Type Classifier includes secondary-escalation rule referencing feedback/*.md" {
  local section
  section="$(extract_section "$BOILERPLATE_FILE" "## Change-Type Classifier")"
  echo "$section" | grep -q "feedback/\*\.md"
  echo "$section" | grep -qi "escalat"
  echo "$section" | grep -qw "intent"
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
  local section
  section="$(extract_section "$BOILERPLATE_FILE" "## Disagreement-Valid Framing")"
  # Must mention contradicting/disagreeing with prior user decisions
  echo "$section" | grep -qiE "contradict|disagree"
  echo "$section" | grep -qi "user"
  # Must explicitly affirm: "valid", "correct behavior", "not a violation", etc.
  echo "$section" | grep -qiE "valid|correct behavior|not a violation"
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
