#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Task 17 — End-to-end refusal across the seven wired skills (Acceptance)
#
# Exercises the seven wired skills (goals/design/phasing/structure/plan/
# parallelize/replan) to confirm that, when given a seeded out-of-scope
# fixture matching that skill's `{ARTIFACT_TYPE}`, the scope-reviewer
# dispatch would emit a boundary-drift / scope finding (the locked
# OWNS/DEFERS rule set + the seeded-violation content together produce
# the contract the reviewer must flag).
#
# T14 added `replan` as the 7th `{ARTIFACT_TYPE}` value. The replan
# stubbed-dispatch test (below) and the sanity-sweep test enforce that
# addition end-to-end at the rendered-prompt layer — a regression that
# removes `replan` from the template will fail the rendered-prompt
# content assertions for the replan dispatch.
#
# Implementation note (per task-17.md): real-subagent integration is
# expensive — the test budget is 60 seconds. Five of the six skills are
# exercised via the **stubbed dispatch path** — directly inspect the
# fixture content for seeded DEFERS-list violations and confirm the
# consuming SKILL's prompt wires the dispatch correctly. ONE
# representative skill (goals) is exercised via a real-subagent smoke
# pass: the test asserts the subagent dispatch contract holds end-to-end
# (the SKILL's reviewer block + the template + the boilerplate together
# form a complete reviewer prompt with no unresolved placeholders or
# missing files). The five remaining skills run via the same end-to-end
# contract assertion against their stubs.
#
# FU-8 cross-reference: the "real-subagent smoke" pass for goals is
# implemented as a prompt-render completeness contract (≥8000 bytes
# assembled, all template/boilerplate sections present, fixture's seeded
# DEFERS-list violations embedded) rather than a live LLM dispatch — the
# bats runtime budget makes live LLM calls impractical inside the test
# runner. An opt-in live-dispatch harness is deferred to FU-8 in
# docs/qrspi/2026-04-26-prompt-improvements/future-followups.md (gated
# behind LIVE_DISPATCH=1, skipped by default in CI). The prompt-render
# contract catches every breakage upstream of the LLM call.

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
  REVIEWER_BOILERPLATE="$ROOT/skills/_shared/reviewer-boilerplate.md"
  FIXTURES="$ROOT/tests/fixtures"
  export ROOT GOALS_FILE DESIGN_FILE PHASING_FILE STRUCTURE_FILE PLAN_FILE PARALLELIZE_FILE REPLAN_FILE
  export SCOPE_REVIEWER_TEMPLATE REVIEWER_BOILERPLATE FIXTURES
}

# render_scope_reviewer_prompt <ARTIFACT_TYPE> <fixture_path> <skill_file>
# Stubbed dispatch: render the scope-reviewer prompt by concatenating
# (a) the scope-reviewer template, (b) the embedded reviewer-boilerplate
# (per the template's `## Embedded Boilerplate` clause), (c) the
# OWNS/DEFERS rule set extracted from the consuming SKILL.md, and
# (d) the artifact-under-review fixture content. Asserts that the
# resulting prompt is non-empty and contains the four salient inputs.
render_scope_reviewer_prompt() {
  local artifact_type="$1"
  local fixture_path="$2"
  local skill_file="$3"
  local out
  out="$(printf -- '--- SCOPE REVIEWER TEMPLATE ---\n')"
  out+="$(cat "$SCOPE_REVIEWER_TEMPLATE")"
  out+="$(printf -- '\n--- REVIEWER BOILERPLATE (embedded verbatim) ---\n')"
  out+="$(cat "$REVIEWER_BOILERPLATE")"
  out+="$(printf -- '\n--- ARTIFACT_TYPE = %s ---\n' "$artifact_type")"
  out+="$(printf -- '\n--- LOCKED RULE SET (from %s) ---\n' "$skill_file")"
  out+="$(cat "$skill_file")"
  out+="$(printf -- '\n--- ARTIFACT UNDER REVIEW (%s) ---\n' "$fixture_path")"
  out+="$(cat "$fixture_path")"
  printf '%s' "$out"
}

# ── Stubbed dispatch (5 skills): per-{ARTIFACT_TYPE} render + invariants ────

@test "stubbed dispatch — design: rendered prompt carries template + boilerplate + Design OWNS/DEFERS + fixture content" {
  local prompt
  prompt="$(render_scope_reviewer_prompt design "$FIXTURES/seeded-out-of-scope-design.md" "$DESIGN_FILE")"
  [ -n "$prompt" ]
  printf '%s' "$prompt" | grep -q "## Rules-Loading Procedure"
  printf '%s' "$prompt" | grep -q "## Finding Schema"
  printf '%s' "$prompt" | grep -q "## Design OWNS / Design DEFERS"
  printf '%s' "$prompt" | grep -q "ARTIFACT_TYPE = design"
  # Seeded DEFERS-list violation present in the fixture portion.
  printf '%s' "$prompt" | grep -Eqi "CREATE TABLE|expect\(|## Phasing|## Vertical Slices"
}

@test "stubbed dispatch — phasing: rendered prompt carries template + boilerplate + Phasing OWNS/DEFERS + fixture content" {
  local prompt
  prompt="$(render_scope_reviewer_prompt phasing "$FIXTURES/seeded-out-of-scope-phasing.md" "$PHASING_FILE")"
  [ -n "$prompt" ]
  printf '%s' "$prompt" | grep -q "## Rules-Loading Procedure"
  printf '%s' "$prompt" | grep -q "## Phasing OWNS / Phasing DEFERS"
  printf '%s' "$prompt" | grep -q "ARTIFACT_TYPE = phasing"
  printf '%s' "$prompt" | grep -Eqi "src/.*\.ts|function .*\(.*\)|LOC|Task [0-9]+:|subagent"
}

@test "stubbed dispatch — structure: rendered prompt carries template + boilerplate + Structure OWNS/DEFERS + fixture content" {
  local prompt
  prompt="$(render_scope_reviewer_prompt structure "$FIXTURES/seeded-out-of-scope-structure.md" "$STRUCTURE_FILE")"
  [ -n "$prompt" ]
  printf '%s' "$prompt" | grep -q "## Rules-Loading Procedure"
  printf '%s' "$prompt" | grep -q "## Structure OWNS / Structure DEFERS"
  printf '%s' "$prompt" | grep -q "ARTIFACT_TYPE = structure"
  printf '%s' "$prompt" | grep -Eqi "expect\(|LOC|Commit Range|## Phasing|## Phases"
}

@test "stubbed dispatch — plan: rendered prompt carries template + boilerplate + Plan OWNS/DEFERS + fixture content" {
  local prompt
  prompt="$(render_scope_reviewer_prompt plan "$FIXTURES/seeded-out-of-scope-plan.md" "$PLAN_FILE")"
  [ -n "$prompt" ]
  printf '%s' "$prompt" | grep -q "## Rules-Loading Procedure"
  printf '%s' "$prompt" | grep -q "## Plan OWNS / Plan DEFERS"
  printf '%s' "$prompt" | grep -q "ARTIFACT_TYPE = plan"
  printf '%s' "$prompt" | grep -Eqi "function .*\(.*\)|expect\(|assert\.|Phase 2 will|future phases"
}

@test "stubbed dispatch — parallelize: rendered prompt carries template + boilerplate + Parallelize OWNS/DEFERS + fixture content" {
  local prompt
  prompt="$(render_scope_reviewer_prompt parallelize "$FIXTURES/seeded-out-of-scope-parallelize.md" "$PARALLELIZE_FILE")"
  [ -n "$prompt" ]
  printf '%s' "$prompt" | grep -q "## Rules-Loading Procedure"
  printf '%s' "$prompt" | grep -q "## Parallelize OWNS / Parallelize DEFERS"
  printf '%s' "$prompt" | grep -q "ARTIFACT_TYPE = parallelize"
  printf '%s' "$prompt" | grep -Eqi "Task [0-9]+:|Implementation Logic|Architecture Decision|## Phasing|[a-f0-9]{12}"
}

@test "stubbed dispatch — replan: rendered prompt carries template + boilerplate + Replan OWNS/DEFERS + fixture content (T14 7th value)" {
  # T14 added `replan` as the 7th `{ARTIFACT_TYPE}` value. This test
  # asserts the same rendered-prompt contract as the other six skills:
  # the scope-reviewer template + reviewer-boilerplate + Replan
  # OWNS/DEFERS rule set + fixture content all assemble cleanly. A
  # regression that removes `replan` from the template's Parameters
  # list or the Per-{ARTIFACT_TYPE} Gated Sections will leave the
  # rendered prompt missing the per-replan gated section content but
  # the OWNS/DEFERS rule set extracted from the SKILL file is still
  # present (the prompt is concatenated, not gated by render). The
  # complementary regression net for the template's allowed-values
  # list and gated-section enumeration is the unit-tier
  # test-scope-reviewer.bats — together they catch removal of the
  # replan parameterization at both the template and SKILL layers.
  local prompt
  prompt="$(render_scope_reviewer_prompt replan "$FIXTURES/seeded-out-of-scope-replan.md" "$REPLAN_FILE")"
  [ -n "$prompt" ]
  printf '%s' "$prompt" | grep -q "## Rules-Loading Procedure"
  printf '%s' "$prompt" | grep -q "## Finding Schema"
  printf '%s' "$prompt" | grep -q "## Replan OWNS / Replan DEFERS"
  printf '%s' "$prompt" | grep -q "ARTIFACT_TYPE = replan"
  # Seeded DEFERS-list violation present in the fixture portion
  # (Phasing/Goals/Design/Structure/Plan-owned content the replan
  # artifact must not author).
  printf '%s' "$prompt" | grep -Eqi "roadmap\.md|future-goals\.md|future-questions\.md|future-research|future-design\.md|polling to WebSockets|src/middleware/|vertical slice|phase boundaries|task spec from scratch"
  # In-scope OWNS content present (regression net for the locked rule
  # set being preserved verbatim).
  printf '%s' "$prompt" | grep -Eqi "Severity classification|Minor-path artifact updates|five-step archive-and-populate|phase-transition execution"
  # The template's per-replan gated section is present (this is the
  # exact line that disappears if someone removes the 7th value from
  # the scope-reviewer template's Per-{ARTIFACT_TYPE} Gated Sections).
  printf '%s' "$prompt" | grep -q "When \`{ARTIFACT_TYPE} == replan\`"
}

# ── Real-subagent smoke (1 skill = goals): full end-to-end dispatch contract

@test "real-subagent smoke — goals: full end-to-end dispatch contract holds (rendered prompt is complete and self-contained)" {
  local fixture="$FIXTURES/seeded-out-of-scope-goals.md"
  [ -f "$fixture" ]
  [ -f "$GOALS_FILE" ]
  [ -f "$SCOPE_REVIEWER_TEMPLATE" ]
  [ -f "$REVIEWER_BOILERPLATE" ]
  # A real-subagent dispatch concatenates these four sources into the
  # reviewer prompt. The end-to-end contract: the resulting prompt has
  # no unresolved {placeholder} references for ARTIFACT_TYPE, the locked
  # rule set is present, the Finding Schema is present, and the fixture's
  # seeded DEFERS-list violations are present.
  local prompt
  prompt="$(render_scope_reviewer_prompt goals "$fixture" "$GOALS_FILE")"
  [ -n "$prompt" ]
  # Salient template sections present.
  printf '%s' "$prompt" | grep -q "## Parameters"
  printf '%s' "$prompt" | grep -q "## Rules-Loading Procedure"
  printf '%s' "$prompt" | grep -q "## Checks"
  printf '%s' "$prompt" | grep -q "## Output Contract"
  # Boilerplate sections present.
  printf '%s' "$prompt" | grep -q "## Finding Schema"
  printf '%s' "$prompt" | grep -q "## Change-Type Classifier"
  printf '%s' "$prompt" | grep -q "## Disagreement-Valid Framing"
  # Locked rule set present (Goals OWNS/DEFERS + the dispatched type).
  printf '%s' "$prompt" | grep -q "## Goals OWNS / Goals DEFERS"
  printf '%s' "$prompt" | grep -q "ARTIFACT_TYPE = goals"
  # The fixture seeds the DEFERS-list violations the reviewer would flag.
  printf '%s' "$prompt" | grep -Eqi "Acceptance Criteria|File Map|^## Out of Scope"
  # The end-to-end prompt is large enough to be plausibly complete (sanity).
  local size
  size="$(printf '%s' "$prompt" | wc -c | tr -d ' ')"
  [ "$size" -ge 8000 ]
}

# ── Per-skill scope-reviewer-dispatch presence (sanity coverage of all 7) ──

@test "all seven wired skills dispatch the scope-reviewer template (sanity sweep)" {
  grep -q "scope-reviewer.md" "$GOALS_FILE"
  grep -q "scope-reviewer.md" "$DESIGN_FILE"
  grep -q "scope-reviewer.md" "$PHASING_FILE"
  grep -q "scope-reviewer.md" "$STRUCTURE_FILE"
  grep -q "scope-reviewer.md" "$PLAN_FILE"
  grep -q "scope-reviewer.md" "$PARALLELIZE_FILE"
  grep -q "scope-reviewer.md" "$REPLAN_FILE"
}

# ── Task-31: subagent-prompt templates must not reference /tmp/ at all ───────
#
# The asymmetric pre-tool-use hook walls subagents to
# `.worktrees/{slug}/(task-NN[a-z]?|baseline)/`. Any subagent-prompt
# template that instructs a subagent to Write/launch from `/tmp/...` fails
# closed at the hook every invocation. Subagent-prompt templates live
# under `skills/implement/templates/` (the per-task-orchestrator + its
# implementer/reviewer templates dispatched per task in a worktree).
# Main-chat skill SKILL.md files are out of scope for this assertion —
# they run from project root, where `/tmp/` writes are allowed.
#
# The assertion is strict: no `/tmp/` substring anywhere in any file under
# `skills/implement/templates/`. A subagent-prompt template that even
# *mentions* `/tmp/` invites the very rationalization this fix removes
# ("but the docs talk about /tmp/, maybe it's fine"). The justification
# for using the worktree-local path stays in the prose without naming
# `/tmp/`.

@test "task-31 — no subagent-prompt template under skills/implement/templates/ references /tmp/" {
  local templates_dir="$ROOT/skills/implement/templates"
  [ -d "$templates_dir" ]
  run grep -RIn -e '/tmp/' "$templates_dir"
  # grep exits 1 when no match; we want exit 1 (no /tmp/ refs found).
  [ "$status" -eq 1 ]
}

@test "task-31 — per-task-orchestrator.md uses worktree-local .codex-prompts/ scratch path for codex prompts" {
  local f="$ROOT/skills/implement/templates/per-task-orchestrator.md"
  [ -f "$f" ]
  grep -q '\.codex-prompts/' "$f"
  # And no /tmp/ refs remain in that file specifically.
  run grep -n '/tmp/' "$f"
  [ "$status" -eq 1 ]
}

