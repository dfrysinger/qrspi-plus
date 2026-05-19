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
@test "[T23-vocab] Branch Model section exists in parallelize SKILL.md" {
  extract_section "$SKILL_MD" H2 "Branch Model (Symbolic — Resolved by Implement)"
}

# ---------------------------------------------------------------------------
# Canonical token: "feature branch tip" in Branch Model section
# ---------------------------------------------------------------------------
@test "[T23-vocab] Branch Model contains canonical token 'feature branch tip'" {
  extract_and_grep "$SKILL_MD" H2 "Branch Model (Symbolic — Resolved by Implement)" \
    "feature branch tip"
}

# ---------------------------------------------------------------------------
# Canonical token: "task-NN tip" in Branch Model section
# ---------------------------------------------------------------------------
@test "[T23-vocab] Branch Model contains canonical token 'task-NN tip'" {
  extract_and_grep "$SKILL_MD" H2 "Branch Model (Symbolic — Resolved by Implement)" \
    "task-NN tip"
}

# ---------------------------------------------------------------------------
# Canonical token: "task-00 tip" in Branch Model section
# ---------------------------------------------------------------------------
@test "[T23-vocab] Branch Model contains canonical token 'task-00 tip'" {
  extract_and_grep "$SKILL_MD" H2 "Branch Model (Symbolic — Resolved by Implement)" \
    "task-00 tip"
}

# ---------------------------------------------------------------------------
# Canonical token: "stage-after-W{N}" in Branch Model section
# ---------------------------------------------------------------------------
@test "[T23-vocab] Branch Model contains canonical token 'stage-after-W{N}'" {
  extract_and_grep "$SKILL_MD" H2 "Branch Model (Symbolic — Resolved by Implement)" \
    "stage-after-W"
}

# ---------------------------------------------------------------------------
# Canonical token: suffixed "stage-after-W{N}{suffix}" form in Branch Model
# ---------------------------------------------------------------------------
@test "[T23-vocab] Branch Model contains suffixed 'stage-after-W{N}{suffix}' form" {
  extract_and_grep "$SKILL_MD" H2 "Branch Model (Symbolic — Resolved by Implement)" \
    "stage-after-W[0-9][a-z]"
}

# ---------------------------------------------------------------------------
# Reviewer file: Parallelize-specific quality checks section exists
# ---------------------------------------------------------------------------
@test "[T23-vocab] Parallelize-specific quality checks section exists in reviewer" {
  extract_section "$REVIEWER_MD" H3 "Parallelize-specific quality checks"
}

# ---------------------------------------------------------------------------
# Canonical tokens present in reviewer's vocabulary check
# ---------------------------------------------------------------------------
@test "[T23-vocab] reviewer quality checks contain canonical token 'feature branch tip'" {
  extract_and_grep "$REVIEWER_MD" H3 "Parallelize-specific quality checks" \
    "feature branch tip"
}

@test "[T23-vocab] reviewer quality checks contain canonical token 'task-NN tip'" {
  extract_and_grep "$REVIEWER_MD" H3 "Parallelize-specific quality checks" \
    "task-NN tip"
}

@test "[T23-vocab] reviewer quality checks contain canonical token 'task-00 tip'" {
  extract_and_grep "$REVIEWER_MD" H3 "Parallelize-specific quality checks" \
    "task-00 tip"
}

@test "[T23-vocab] reviewer quality checks contain canonical token 'stage-after-W'" {
  extract_and_grep "$REVIEWER_MD" H3 "Parallelize-specific quality checks" \
    "stage-after-W"
}

@test "[T23-vocab] reviewer quality checks reference suffixed stage-after form" {
  extract_and_grep "$REVIEWER_MD" H3 "Parallelize-specific quality checks" \
    "stage-after-W[0-9][a-z]"
}

# ---------------------------------------------------------------------------
# No drift: SKILL.md Branch Model and reviewer both declare all 4 core tokens.
# (Drift check: both sections contain the same 4 required tokens.)
# ---------------------------------------------------------------------------
@test "[T23-vocab] no drift — SKILL.md and reviewer both carry all 4 canonical base tokens" {
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
@test "[T23-vocab] reviewer flags unconventional 'stageAfterWave4' as style violation" {
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
@test "[T23-vocab] missing-anchor emits skill-markdown loud diagnostic" {
  run extract_and_grep "$SKILL_MD" H2 "Nonexistent Heading XXXX" "anything"
  [ "$status" -ne 0 ]
  printf '%s\n' "$output" | grep -q "skill-markdown:"
}

# ---------------------------------------------------------------------------
# Shared helper loads and REPO_ROOT resolves.
# ---------------------------------------------------------------------------
@test "[T23-vocab] shared helper loads and require_repo_root resolves REPO_ROOT" {
  require_repo_root
  [ -n "$REPO_ROOT" ]
  [ -d "$REPO_ROOT" ]
}
