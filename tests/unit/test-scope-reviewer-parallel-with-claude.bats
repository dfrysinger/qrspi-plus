#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Task 17 — scope-reviewer running in parallel with Claude reviewer
#
# Asserts the contract that the scope-reviewer dispatch runs in parallel
# with the Claude review subagent, that both reviewers' findings flow
# through the M48 review-loop pause gate (using-qrspi/SKILL.md), and that
# the conflict-resolution / merge policy is documented (deduplication or
# both-flow framing).
#
# These are prompt-content invariant tests — assertion targets are the
# consuming SKILL prompts plus the using-qrspi review-loop content. The
# unit tier asserts the wiring; the acceptance tier exercises a real
# dispatch.

setup() {
  ROOT="$BATS_TEST_DIRNAME/../.."
  GOALS_FILE="$ROOT/skills/goals/SKILL.md"
  DESIGN_FILE="$ROOT/skills/design/SKILL.md"
  PHASING_FILE="$ROOT/skills/phasing/SKILL.md"
  STRUCTURE_FILE="$ROOT/skills/structure/SKILL.md"
  PLAN_FILE="$ROOT/skills/plan/SKILL.md"
  PARALLELIZE_FILE="$ROOT/skills/parallelize/SKILL.md"
  USING_QRSPI_FILE="$ROOT/skills/using-qrspi/SKILL.md"
  SCOPE_REVIEWER_TEMPLATE="$ROOT/skills/_shared/templates/scope-reviewer.md"
  REVIEWER_BOILERPLATE="$ROOT/skills/_shared/reviewer-boilerplate.md"
  export ROOT GOALS_FILE DESIGN_FILE PHASING_FILE STRUCTURE_FILE PLAN_FILE PARALLELIZE_FILE
  export USING_QRSPI_FILE SCOPE_REVIEWER_TEMPLATE REVIEWER_BOILERPLATE
}

# ── Per-skill: scope-reviewer dispatched in parallel with Claude reviewer ──

@test "goals SKILL: scope-reviewer dispatched in parallel with Claude reviewer" {
  # The quality-reviewer and scope-reviewer subagents are both listed in
  # the Review Round (commit 7/22 migration: Agent({subagent_type:...}) form).
  grep -qi "qrspi-goals-reviewer" "$GOALS_FILE"
  grep -qi "qrspi-goals-scope-reviewer" "$GOALS_FILE"
  grep -Eqi "in parallel|run in parallel|reviewers run in parallel|four reviewer dispatches run in parallel" "$GOALS_FILE"
}

@test "design SKILL: scope-reviewer dispatched in parallel with Claude reviewer" {
  # Commit 10/22 migration: Agent({subagent_type:...}) form.
  grep -qi "qrspi-design-reviewer" "$DESIGN_FILE"
  grep -qi "qrspi-design-scope-reviewer" "$DESIGN_FILE"
  grep -Eqi "in parallel|run in parallel|two parallel reviewer dispatches" "$DESIGN_FILE"
}

@test "phasing SKILL: scope-reviewer dispatched in parallel with Claude reviewer" {
  # Commit 12/22 migration: Agent({subagent_type:...}) form.
  grep -qi "qrspi-phasing-reviewer" "$PHASING_FILE"
  grep -qi "qrspi-phasing-scope-reviewer" "$PHASING_FILE"
  grep -Eqi "in parallel|run in parallel|two parallel reviewer dispatches" "$PHASING_FILE"
}

@test "structure SKILL: scope-reviewer dispatched in parallel with Claude reviewer" {
  # Commit 11/22 migration: Agent({subagent_type:...}) form.
  grep -qi "qrspi-structure-reviewer" "$STRUCTURE_FILE"
  grep -qi "qrspi-structure-scope-reviewer" "$STRUCTURE_FILE"
  grep -Eqi "in parallel|run in parallel|two parallel reviewer dispatches" "$STRUCTURE_FILE"
}

@test "plan SKILL: scope-reviewer dispatched in parallel with Claude reviewer" {
  grep -qi "Claude review subagent" "$PLAN_FILE"
  grep -qi "scope-reviewer" "$PLAN_FILE"
  grep -Eqi "in parallel|run in parallel" "$PLAN_FILE"
}

@test "parallelize SKILL: scope-reviewer dispatched in parallel with Claude reviewer" {
  grep -qi "Claude review subagent\|Claude reviewer" "$PARALLELIZE_FILE"
  grep -qi "scope-reviewer" "$PARALLELIZE_FILE"
  grep -Eqi "in parallel|run in parallel" "$PARALLELIZE_FILE"
}

# ── Shared finding schema: both reviewers emit M48 5-field findings ─────────

@test "reviewer-boilerplate.md ## Finding Schema declares M48 5-field schema (shared by both reviewers)" {
  [ -f "$REVIEWER_BOILERPLATE" ]
  local section
  section="$(awk '
    $0 == "## Finding Schema" { in_b = 1; print; next }
    in_b && /^## / { exit }
    in_b { print }
  ' "$REVIEWER_BOILERPLATE")"
  [ -n "$section" ]
  echo "$section" | grep -q "finding_id"
  echo "$section" | grep -q "severity"
  echo "$section" | grep -q "change_type"
  echo "$section" | grep -q "message"
  echo "$section" | grep -q "referenced_files"
}

@test "scope-reviewer template ## Output Contract references reviewer-boilerplate Finding Schema for unified output" {
  local section
  section="$(awk '
    $0 == "## Output Contract" { in_b = 1; print; next }
    in_b && /^## / { exit }
    in_b { print }
  ' "$SCOPE_REVIEWER_TEMPLATE")"
  [ -n "$section" ]
  echo "$section" | grep -q "reviewer-boilerplate.md"
  echo "$section" | grep -qi "Finding Schema"
}

# ── Conflict resolution / merger policy ─────────────────────────────────────

@test "scope-reviewer template names the embedded boilerplate so finding shapes are unified across reviewers" {
  # The boilerplate-embedding policy is the merger primitive — both the
  # Claude reviewer and the scope-reviewer emit findings in the same
  # 5-field shape, so deduplication / merger can run on a uniform set.
  local section
  section="$(awk '
    $0 == "## Embedded Boilerplate" { in_b = 1; print; next }
    in_b && /^## / { exit }
    in_b { print }
  ' "$SCOPE_REVIEWER_TEMPLATE")"
  [ -n "$section" ]
  echo "$section" | grep -q "reviewer-boilerplate.md"
  echo "$section" | grep -Eqi "embeds|verbatim|concatenates"
}

@test "goals SKILL Review Round writes findings from BOTH reviewers to the same review log file" {
  # Both Claude reviewer and scope-reviewer findings flow into the same
  # reviews/{artifact}-review.md file, which is the merger surface.
  grep -qi "reviews/goals-review.md" "$GOALS_FILE"
  # Both reviewer prose blocks must reference the same target log.
  local claude_count scope_count
  claude_count=$(grep -c "reviews/goals-review.md" "$GOALS_FILE")
  [ "$claude_count" -ge 2 ]
}

# ── M48 pause gate: both reviewers' findings flow through the gate ──────────

@test "using-qrspi/SKILL.md documents the M48 review-loop pause gate" {
  [ -f "$USING_QRSPI_FILE" ]
  grep -Eqi "Pause Gate|pause gate|review-loop pause" "$USING_QRSPI_FILE"
}

@test "using-qrspi/SKILL.md pause gate splits findings into auto-applied / proposed / paused classes" {
  # The Pause Gate uses the change_type tag (defined in reviewer-
  # boilerplate.md ## Change-Type Classifier) to split findings into
  # auto-applied (style/clarity/correctness) and paused (scope/intent).
  # The using-qrspi prose names the three classes.
  grep -Eqi "auto-applied|auto-apply|auto apply" "$USING_QRSPI_FILE"
  grep -Eqi "Paused findings|paused" "$USING_QRSPI_FILE"
  # And references the 3-option menu surfaced for paused findings.
  grep -Eqi "3-option menu|3-option" "$USING_QRSPI_FILE"
}

@test "reviewer-boilerplate change-type classifier assigns scope/intent to pause action" {
  local section
  section="$(awk '
    $0 == "## Change-Type Classifier" { in_b = 1; print; next }
    in_b && /^## / { exit }
    in_b { print }
  ' "$REVIEWER_BOILERPLATE")"
  [ -n "$section" ]
  # Default-action rule: scope and intent pause, others auto-apply.
  echo "$section" | grep -Eqi "scope.*intent.*pause|pause.*scope.*intent"
  echo "$section" | grep -Eqi "auto-apply|auto apply"
}
