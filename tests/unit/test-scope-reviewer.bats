#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Task 17 — scope-reviewer per-{ARTIFACT_TYPE} dispatch (cross-cutting)
#
# This file asserts the contract that each consuming SKILL dispatches the
# parameterized scope-reviewer template with its declared {ARTIFACT_TYPE}
# value, and that for each of the seven values (goals/design/phasing/
# structure/plan/parallelize/replan) a per-artifact-type seeded
# out-of-scope fixture carries content that the scope-reviewer's
# boundary-drift detection MUST flag with `change_type: scope` (or
# `intent`).
#
# T14 added `replan` as the 7th `{ARTIFACT_TYPE}` value; this test file
# enforces that addition (and acts as a regression net — a checkin that
# removes `replan` from the template's allowed-values list, the gated
# sections, or the Replan SKILL's dispatch wiring will fail this test).
#
# These are prompt-content / fixture-shape invariant tests — the actual
# subagent dispatch is exercised by the acceptance-tier test
# (test-skill-output-quality.bats); this unit-tier test asserts the
# dispatch contract is wired and the fixtures carry the seeded violations.
#
# All assertions extract a target heading's section text first (until the
# next `^## ` heading) and assert on the extracted slice — never on the
# whole file — so a string appearing under a different heading cannot
# vacuously satisfy a different section's check.

setup() {
  ROOT="$BATS_TEST_DIRNAME/../.."
  GOALS_FILE="$ROOT/skills/goals/SKILL.md"
  DESIGN_FILE="$ROOT/skills/design/SKILL.md"
  PHASING_FILE="$ROOT/skills/phasing/SKILL.md"
  STRUCTURE_FILE="$ROOT/skills/structure/SKILL.md"
  PLAN_FILE="$ROOT/skills/plan/SKILL.md"
  PARALLELIZE_FILE="$ROOT/skills/parallelize/SKILL.md"
  REPLAN_FILE="$ROOT/skills/replan/SKILL.md"
  SCOPE_REVIEWER_TEMPLATE="$ROOT/skills/_shared/templates/scope-reviewer.md"
  FIXTURES="$ROOT/tests/fixtures"
  export ROOT GOALS_FILE DESIGN_FILE PHASING_FILE STRUCTURE_FILE PLAN_FILE PARALLELIZE_FILE REPLAN_FILE
  export SCOPE_REVIEWER_TEMPLATE FIXTURES
}

# extract_h2_section <file> <h2-heading>
extract_h2_section() {
  local file="$1"
  local heading="$2"
  awk -v h="$heading" '
    $0 == h { in_b = 1; print; next }
    in_b && /^## / { exit }
    in_b { print }
  ' "$file"
}

# ── scope-reviewer template Parameters list includes all seven values ──────

@test "scope-reviewer template ## Parameters allowed-values list includes all seven artifact types" {
  [ -f "$SCOPE_REVIEWER_TEMPLATE" ]
  local section
  section="$(extract_h2_section "$SCOPE_REVIEWER_TEMPLATE" "## Parameters")"
  [ -n "$section" ]
  echo "$section" | grep -qE "^[[:space:]]*-[[:space:]]+\`goals\`$"
  echo "$section" | grep -qE "^[[:space:]]*-[[:space:]]+\`design\`$"
  echo "$section" | grep -qE "^[[:space:]]*-[[:space:]]+\`phasing\`$"
  echo "$section" | grep -qE "^[[:space:]]*-[[:space:]]+\`structure\`$"
  echo "$section" | grep -qE "^[[:space:]]*-[[:space:]]+\`plan\`$"
  echo "$section" | grep -qE "^[[:space:]]*-[[:space:]]+\`parallelize\`$"
  echo "$section" | grep -qE "^[[:space:]]*-[[:space:]]+\`replan\`$"
}

@test "scope-reviewer template ## Output Contract requires change_type tag in M48 5-field schema" {
  local section
  section="$(extract_h2_section "$SCOPE_REVIEWER_TEMPLATE" "## Output Contract")"
  [ -n "$section" ]
  echo "$section" | grep -q "change_type"
  echo "$section" | grep -Eqi "scope|intent"
}

# ── Per-{ARTIFACT_TYPE} dispatch: each consuming SKILL wires the template ──

@test "{ARTIFACT_TYPE}=goals — goals SKILL dispatches scope-reviewer with parameter goals" {
  # Commit 7/22 migration: scope-reviewer is now dispatched as a dedicated
  # agent (qrspi-goals-scope-reviewer) rather than via the shared template.
  # The old scope-reviewer.md + {ARTIFACT_TYPE}=goals pattern is retired.
  grep -q "qrspi-goals-scope-reviewer" "$GOALS_FILE"
}

@test "{ARTIFACT_TYPE}=design — design SKILL dispatches scope-reviewer with parameter design" {
  # Commit 10/22 migration: scope-reviewer is now dispatched as a dedicated
  # agent (qrspi-design-scope-reviewer) rather than via the shared template.
  # The old scope-reviewer.md + {ARTIFACT_TYPE}=design pattern is retired.
  grep -q "qrspi-design-scope-reviewer" "$DESIGN_FILE"
}

@test "{ARTIFACT_TYPE}=phasing — phasing SKILL dispatches scope-reviewer with parameter phasing" {
  grep -q "scope-reviewer.md" "$PHASING_FILE"
  grep -qE "\{ARTIFACT_TYPE\}=phasing" "$PHASING_FILE"
}

@test "{ARTIFACT_TYPE}=structure — structure SKILL dispatches scope-reviewer with parameter structure" {
  # Commit 11/22 migration: scope-reviewer is now dispatched as a dedicated
  # agent (qrspi-structure-scope-reviewer) rather than via the shared template.
  # The old scope-reviewer.md + {ARTIFACT_TYPE}=structure pattern is retired.
  grep -q "qrspi-structure-scope-reviewer" "$STRUCTURE_FILE"
}

@test "{ARTIFACT_TYPE}=plan — plan SKILL dispatches scope-reviewer with parameter plan" {
  grep -q "scope-reviewer.md" "$PLAN_FILE"
  grep -qE "\{ARTIFACT_TYPE\}=plan" "$PLAN_FILE"
}

@test "{ARTIFACT_TYPE}=parallelize — parallelize SKILL dispatches scope-reviewer with parameter parallelize" {
  grep -q "scope-reviewer.md" "$PARALLELIZE_FILE"
  grep -qE "\{ARTIFACT_TYPE\}=parallelize" "$PARALLELIZE_FILE"
}

@test "{ARTIFACT_TYPE}=replan — replan SKILL dispatches scope-reviewer with parameter replan (T14 7th value)" {
  [ -f "$REPLAN_FILE" ]
  grep -q "scope-reviewer.md" "$REPLAN_FILE"
  grep -qE "\{ARTIFACT_TYPE\}=replan" "$REPLAN_FILE"
}

# ── Per-fixture seeding: each fixture carries content that fires change_type=scope

@test "seeded-out-of-scope-goals.md fixture exists and seeds at least one DEFERS-list violation" {
  local fixture="$FIXTURES/seeded-out-of-scope-goals.md"
  [ -f "$fixture" ]
  # Goals DEFERS: file maps, phasing, acceptance criteria, top-level
  # Out-of-Scope. Fixture must seed at least one of these.
  grep -Eqi "Acceptance Criteria|File Map|Phasing|^## Out of Scope" "$fixture"
}

@test "seeded-out-of-scope-design.md fixture exists and seeds at least one DEFERS-list violation" {
  local fixture="$FIXTURES/seeded-out-of-scope-design.md"
  [ -f "$fixture" ]
  # Design DEFERS: full DDL, full function signatures, assertion text,
  # phase splits, vertical slice authoring.
  grep -Eqi "CREATE TABLE|expect\(|## Phasing|## Vertical Slices" "$fixture"
}

@test "seeded-out-of-scope-phasing.md fixture exists and seeds at least one DEFERS-list violation" {
  local fixture="$FIXTURES/seeded-out-of-scope-phasing.md"
  [ -f "$fixture" ]
  # Phasing DEFERS: file paths, function signatures, task specs, LOC
  # estimates, architecture re-litigation, skill-implementation jargon.
  grep -Eqi "src/.*\.ts|function .*\(.*\)|LOC|Task [0-9]+:|subagent" "$fixture"
}

@test "seeded-out-of-scope-structure.md fixture exists and seeds at least one DEFERS-list violation" {
  local fixture="$FIXTURES/seeded-out-of-scope-structure.md"
  [ -f "$fixture" ]
  # Structure DEFERS: implementation body, assertion text, per-task LOC,
  # commit ranges, phase boundaries.
  grep -Eqi "expect\(|LOC|Commit Range|## Phasing|## Phases" "$fixture"
}

@test "seeded-out-of-scope-plan.md fixture exists and seeds at least one DEFERS-list violation" {
  local fixture="$FIXTURES/seeded-out-of-scope-plan.md"
  [ -f "$fixture" ]
  # Plan DEFERS: function signatures inline, expect/assert in test
  # expectations, line-by-line logic, design-layer prose, phasing forward
  # references.
  grep -Eqi "function .*\(.*\)|expect\(|assert\.|Phase 2 will|future phases" "$fixture"
}

@test "seeded-out-of-scope-parallelize.md fixture exists and seeds at least one DEFERS-list violation" {
  local fixture="$FIXTURES/seeded-out-of-scope-parallelize.md"
  [ -f "$fixture" ]
  # Parallelize DEFERS: task specs, implementation logic, architecture
  # decisions, phasing, concrete commit hashes (vs symbolic bases).
  grep -Eqi "Task [0-9]+:|Implementation Logic|Architecture Decision|## Phasing|[a-f0-9]{12}" "$fixture"
}

@test "seeded-out-of-scope-replan.md fixture exists and seeds at least one DEFERS-list violation" {
  local fixture="$FIXTURES/seeded-out-of-scope-replan.md"
  [ -f "$fixture" ]
  # Replan DEFERS: phasing decisions / slice decomposition (Phasing-owned),
  # roadmap.md authoring (Phasing-owned), future-*.md authoring
  # (Phasing-owned), goal-text expansion (Goals-owned), architecture
  # re-litigation (Design-owned), file maps (Structure-owned), full task
  # spec authoring (Plan-owned). Fixture must seed at least one of these.
  grep -Eqi "roadmap\.md|future-goals\.md|future-questions\.md|future-research|future-design\.md|goal-text expansion|polling to WebSockets|src/middleware/|vertical slice|phase boundaries|task spec from scratch" "$fixture"
}

@test "seeded-out-of-scope-replan.md fixture also includes in-scope (Replan-owned) examples (regression net)" {
  # The fixture intentionally carries BOTH in-scope (OWNS) and
  # out-of-scope (DEFERS) content. The in-scope block names operations
  # Replan owns — severity classification, minor-path artifact updates,
  # phase-transition execution. If a regression removes the replan
  # parameterization from the scope-reviewer template, the rendered
  # prompt for {ARTIFACT_TYPE}=replan will lose the locked rule set,
  # which the acceptance test (test-skill-output-quality.bats) catches
  # via the rendered-prompt content assertion. This unit-tier test
  # asserts the in-scope content block exists in the fixture so the
  # acceptance test has something stable to grep on.
  local fixture="$FIXTURES/seeded-out-of-scope-replan.md"
  [ -f "$fixture" ]
  grep -Eqi "Severity classification|Minor-path artifact updates|five-step archive-and-populate|phase-transition execution" "$fixture"
}

# ── change_type tag presence in scope-reviewer Output Contract per-fixture ──

@test "scope-reviewer template ## Output Contract names change_type values scope and intent" {
  local section
  section="$(extract_h2_section "$SCOPE_REVIEWER_TEMPLATE" "## Output Contract")"
  [ -n "$section" ]
  # The structured-error fail-closed clause uses `correctness`; the
  # boundary-drift findings use `scope` (or `intent`). Both must be named
  # in the template's classifier reference.
  echo "$section" | grep -Eq "style.*clarity.*correctness.*scope.*intent|change_type.*scope.*intent"
}

@test "scope-reviewer template Per-{ARTIFACT_TYPE} Gated Sections names all seven skill rule files" {
  local section
  section="$(extract_h2_section "$SCOPE_REVIEWER_TEMPLATE" "## Per-\`{ARTIFACT_TYPE}\` Gated Sections")"
  [ -n "$section" ]
  echo "$section" | grep -q "skills/goals/SKILL.md"
  echo "$section" | grep -q "skills/design/SKILL.md"
  echo "$section" | grep -q "skills/phasing/SKILL.md"
  echo "$section" | grep -q "skills/structure/SKILL.md"
  echo "$section" | grep -q "skills/plan/SKILL.md"
  echo "$section" | grep -q "skills/parallelize/SKILL.md"
  echo "$section" | grep -q "skills/replan/SKILL.md"
}
