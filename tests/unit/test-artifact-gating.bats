#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Task 39 — Integration round-1 fix
#
# Verifies that the four post-Phasing skills missed by the M54 phasing-extraction
# sweep now list `phasing.md` in their `## Artifact Gating` (or required-inputs)
# section. Replan is fixed by task-34 and is not asserted here.
#
# Skills under test:
#   - skills/plan/SKILL.md
#   - skills/parallelize/SKILL.md
#   - skills/integrate/SKILL.md
#   - skills/test/SKILL.md
#
# All assertions extract the `## Artifact Gating` section text first (until the
# next `^## ` heading) and assert on the extracted slice — so a `phasing.md`
# mention elsewhere in the file (e.g., DEFERS prose) cannot vacuously satisfy
# the gating-input check.

setup() {
  PLAN_FILE="$BATS_TEST_DIRNAME/../../skills/plan/SKILL.md"
  PARALLELIZE_FILE="$BATS_TEST_DIRNAME/../../skills/parallelize/SKILL.md"
  INTEGRATE_FILE="$BATS_TEST_DIRNAME/../../skills/integrate/SKILL.md"
  TEST_FILE="$BATS_TEST_DIRNAME/../../skills/test/SKILL.md"
  export PLAN_FILE PARALLELIZE_FILE INTEGRATE_FILE TEST_FILE
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

# assert_phasing_in_artifact_gating <file>
# Common assertion: the `## Artifact Gating` section must contain a list-item
# entry naming `phasing.md` with `status: approved`.
assert_phasing_in_artifact_gating() {
  local file="$1"
  local block
  block="$(extract_h2_section "$file" "## Artifact Gating")"
  [ -n "$block" ]
  # The list-item entry must reference phasing.md and require status: approved.
  echo "$block" | grep -Eq "^[[:space:]]*-[[:space:]]+\`phasing\.md\`.*\`status: approved\`"
}

# ── plan/SKILL.md — Artifact Gating must list phasing.md ───────────────────

@test "[task-39] skills/plan/SKILL.md exists" {
  [ -f "$PLAN_FILE" ]
}

@test "[task-39] plan SKILL Artifact Gating lists phasing.md as required input (full pipeline)" {
  assert_phasing_in_artifact_gating "$PLAN_FILE"
}

# ── parallelize/SKILL.md — Artifact Gating must list phasing.md ────────────

@test "[task-39] skills/parallelize/SKILL.md exists" {
  [ -f "$PARALLELIZE_FILE" ]
}

@test "[task-39] parallelize SKILL Artifact Gating lists phasing.md as required input" {
  assert_phasing_in_artifact_gating "$PARALLELIZE_FILE"
}

# ── integrate/SKILL.md — Artifact Gating must list phasing.md ──────────────

@test "[task-39] skills/integrate/SKILL.md exists" {
  [ -f "$INTEGRATE_FILE" ]
}

@test "[task-39] integrate SKILL Artifact Gating lists phasing.md as required input" {
  assert_phasing_in_artifact_gating "$INTEGRATE_FILE"
}

# ── test/SKILL.md — Artifact Gating must list phasing.md ───────────────────

@test "[task-39] skills/test/SKILL.md exists" {
  [ -f "$TEST_FILE" ]
}

@test "[task-39] test SKILL Artifact Gating lists phasing.md as required input" {
  assert_phasing_in_artifact_gating "$TEST_FILE"
}
