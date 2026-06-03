#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# T07 Slice 1 unit pin — initial G5 routing matrix application.
#
# Pins the G5 default model_routing: matrix shipped in
# skills/implement/SKILL.md § "Initial Routing Matrix" (the table that maps
# each `model_role:` to its default route + tier). Each dispatcher class is
# observable AND the conditional cells (citation-density-gated rows) route
# to the trusted tier by default.
#
# Bash 3.2 portable.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
  IMPLEMENT="$REPO_ROOT/skills/implement/SKILL.md"
  # G22 / T16 additions
  AGENTS_DIR="$REPO_ROOT/agents"
  PLAN_SKILL="$REPO_ROOT/skills/plan/SKILL.md"
  TEST_SKILL="$REPO_ROOT/skills/test/SKILL.md"
  USING_SKILL="$REPO_ROOT/skills/using-qrspi/SKILL.md"
  export IMPLEMENT AGENTS_DIR PLAN_SKILL TEST_SKILL USING_SKILL
}

# ---------------------------------------------------------------------------
# Per-role initial-matrix decisions: every documented role appears with its
# declared route + tier in the matrix table.
# ---------------------------------------------------------------------------

@test "matrix: qrspi-research-collator routes to cheap tier (DeepSeek V3)" {
  run grep -E "qrspi-research-collator.*DeepSeek V3|qrspi-research-collator.*cheap-model" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}

@test "matrix: qrspi-implementer-lightweight routes to cheap tier (DeepSeek V3)" {
  run grep -E "qrspi-implementer-lightweight.*DeepSeek V3|qrspi-implementer-lightweight.*cheap-model" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}

@test "matrix: qrspi-research-specialist routes to cheap tier with conditional citation-density gate" {
  run grep -E "qrspi-research-specialist.*citation-density gated|qrspi-research-specialist.*cheap-model eligible \\(conditional\\)" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}

@test "matrix: general-purpose / Explore agent routes to trusted (Sonnet)" {
  run grep -E "general-purpose.*Sonnet.*trusted|Explore agent.*Sonnet.*trusted" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}

@test "matrix: qrspi-test-writer routes to trusted (Sonnet)" {
  run grep -E "qrspi-test-writer.*Sonnet.*trusted" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Conditional-cell trusted-by-default routing: the citation-density-gated
# row notes that below-floor output re-runs on the trusted tier.
# ---------------------------------------------------------------------------

@test "conditional cell: below-floor specialist output re-runs on trusted tier (matrix row rationale)" {
  run grep -E "Cheap model is sufficient WHEN citation density meets the floor.*below-floor output triggers one re-run on the trusted model" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Matrix-to-test cross-reference: the prose explicitly names this pin file
# as the observability mechanism — a regression that drops the pin
# reference also drops the observability claim.
# ---------------------------------------------------------------------------

@test "matrix cross-reference: T07 routing-matrix pin file named as the observability mechanism" {
  run grep -F "test-routing-matrix-application.bats" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Slice 1 acceptance deliverable: the matrix is the G5 Slice 1 deliverable
# and is consumed by Implement at every dispatch through the four-layer
# routing chain — operator edits to model_routing: override defaults.
# ---------------------------------------------------------------------------

@test "matrix: declared as Slice 1 acceptance deliverable for G5" {
  run grep -E "Slice 1 acceptance deliverable for G5|G5 deliverable" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}

@test "matrix: operator-edited model_routing: entries override defaults without code changes" {
  run grep -F "operator-edited \`model_routing:\` entries override the defaults without code changes" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# G22 / T16 additions — agent-frontmatter sweep, reviewer DISPATCH_FILE,
# skill-prose cleanup, and implementer/test-writer co-escalation invariant.
# ===========================================================================

# ---------------------------------------------------------------------------
# Agent-frontmatter sweep: exactly five tier: low agents, rest tier: medium,
# no model_role: anywhere.
# Test expectation: Run an agent-frontmatter sweep: exactly five tier: low
# agents match the locked rubric, all other agents/qrspi-*.md carry
# tier: medium, and no agent file carries model_role:.
# ---------------------------------------------------------------------------

@test "agent sweep: exactly five agents carry tier: low" {
  # Test expectation: exactly five tier: low agents (locked G22 rubric)
  count=$(grep -rl "^tier: low$" "$AGENTS_DIR"/ | wc -l | tr -d ' ')
  [ "$count" -eq 5 ]
}

@test "agent sweep: qrspi-finding-verifier carries tier: low" {
  # Test expectation: qrspi-finding-verifier is one of the five low-tier agents
  run grep -q "^tier: low$" "$AGENTS_DIR/qrspi-finding-verifier.md"
  [ "$status" -eq 0 ]
}

@test "agent sweep: qrspi-implementer-lightweight carries tier: low" {
  # Test expectation: qrspi-implementer-lightweight is one of the five low-tier agents
  run grep -q "^tier: low$" "$AGENTS_DIR/qrspi-implementer-lightweight.md"
  [ "$status" -eq 0 ]
}

@test "agent sweep: qrspi-research-collator carries tier: low" {
  # Test expectation: qrspi-research-collator is one of the five low-tier agents
  run grep -q "^tier: low$" "$AGENTS_DIR/qrspi-research-collator.md"
  [ "$status" -eq 0 ]
}

@test "agent sweep: qrspi-research-specialist carries tier: low" {
  # Test expectation: qrspi-research-specialist is one of the five low-tier agents
  run grep -q "^tier: low$" "$AGENTS_DIR/qrspi-research-specialist.md"
  [ "$status" -eq 0 ]
}

@test "agent sweep: qrspi-scope-tagger carries tier: low" {
  # Test expectation: qrspi-scope-tagger is one of the five low-tier agents
  run grep -q "^tier: low$" "$AGENTS_DIR/qrspi-scope-tagger.md"
  [ "$status" -eq 0 ]
}

@test "agent sweep: qrspi-implementer carries tier: medium (not low or high)" {
  # Test expectation: all non-rubric-five agents carry tier: medium
  run grep -q "^tier: medium$" "$AGENTS_DIR/qrspi-implementer.md"
  [ "$status" -eq 0 ]
}

@test "agent sweep: qrspi-test-writer carries tier: medium" {
  # Test expectation: qrspi-test-writer is a medium-tier agent after model_role: deletion
  run grep -q "^tier: medium$" "$AGENTS_DIR/qrspi-test-writer.md"
  [ "$status" -eq 0 ]
}

@test "agent sweep: every qrspi-*.md file carries exactly one tier: field" {
  # Test expectation: every agent has a tier: frontmatter field (none missing)
  total=$(ls "$AGENTS_DIR"/qrspi-*.md | wc -l | tr -d ' ')
  with_tier=$(grep -rl "^tier:" "$AGENTS_DIR"/ | wc -l | tr -d ' ')
  [ "$with_tier" -eq "$total" ]
}

@test "agent sweep: no qrspi-*.md file carries model_role:" {
  # Test expectation: the four legacy model_role: declarations are removed (deprecated field)
  c=$(grep -rl "^model_role:" "$AGENTS_DIR"/ | wc -l | tr -d ' ')
  [ "$c" -eq 0 ]
}

@test "agent sweep: no agent carries a tier other than low or medium after sweep" {
  # Test expectation: after T16, the only tier values in agent frontmatter are low and medium;
  # this test will be RED now (no tiers exist at all → with_tier count == 0, total > 0)
  # and GREEN after implementation when all 41 agents have a tier: field
  total=$(ls "$AGENTS_DIR"/qrspi-*.md | wc -l | tr -d ' ')
  with_low_or_medium=$(grep -rl "^tier: \(low\|medium\)$" "$AGENTS_DIR"/ | wc -l | tr -d ' ')
  [ "$with_low_or_medium" -eq "$total" ]
}

# ---------------------------------------------------------------------------
# Reviewer agents: DISPATCH_FILE first-action instruction
# Test expectation: Grep reviewer agents for the DISPATCH_FILE=<path>
# first-action instruction.
# ---------------------------------------------------------------------------

@test "reviewer agents: qrspi-code-quality-reviewer body has DISPATCH_FILE first-action instruction" {
  # Test expectation: reviewer agent bodies carry the DISPATCH_FILE=<path> first-action read
  run grep -q "DISPATCH_FILE" "$AGENTS_DIR/qrspi-code-quality-reviewer.md"
  [ "$status" -eq 0 ]
}

@test "reviewer agents: qrspi-spec-reviewer body has DISPATCH_FILE first-action instruction" {
  # Test expectation: reviewer agent bodies carry the DISPATCH_FILE=<path> first-action read
  run grep -q "DISPATCH_FILE" "$AGENTS_DIR/qrspi-spec-reviewer.md"
  [ "$status" -eq 0 ]
}

@test "reviewer agents: qrspi-security-reviewer body has DISPATCH_FILE first-action instruction" {
  # Test expectation: reviewer agent bodies carry the DISPATCH_FILE=<path> first-action read
  run grep -q "DISPATCH_FILE" "$AGENTS_DIR/qrspi-security-reviewer.md"
  [ "$status" -eq 0 ]
}

@test "reviewer agents: qrspi-plan-reviewer body has DISPATCH_FILE first-action instruction" {
  # Test expectation: reviewer agent bodies carry the DISPATCH_FILE=<path> first-action read
  run grep -q "DISPATCH_FILE" "$AGENTS_DIR/qrspi-plan-reviewer.md"
  [ "$status" -eq 0 ]
}

@test "reviewer agents: qrspi-silent-failure-hunter body has DISPATCH_FILE first-action instruction" {
  # Test expectation: reviewer agent bodies carry the DISPATCH_FILE=<path> first-action read
  run grep -q "DISPATCH_FILE" "$AGENTS_DIR/qrspi-silent-failure-hunter.md"
  [ "$status" -eq 0 ]
}

@test "reviewer agents: DISPATCH_FILE instruction precedes any other procedural step in code-quality-reviewer" {
  # Test expectation: DISPATCH_FILE read is the FIRST action, not buried mid-body
  first_action_line=$(grep -n "DISPATCH_FILE\|Read your\|Your job\|You are the\|Step 1\|## " \
    "$AGENTS_DIR/qrspi-code-quality-reviewer.md" | head -1)
  [[ "$first_action_line" == *"DISPATCH_FILE"* ]]
}

# ---------------------------------------------------------------------------
# Skill prose cleanup: old schema, role-keyed G5 matrix, test_writer_model,
# and hardcoded model: "sonnet" dispatch args are gone.
# Test expectation: Grep skill prose to confirm the old per-host schema,
# role-keyed G5 routing matrix, model: task-routing field guidance,
# test_writer_model, and hardcoded model: "sonnet" dispatch arguments are
# gone from the migrated surfaces.
# ---------------------------------------------------------------------------

@test "using-qrspi: old per-host model_routing schema (haiku/sonnet/opus/inherit keys) is gone" {
  # Test expectation: the old claude-code/copilot-cli host-keyed haiku/sonnet/opus/inherit
  # schema is removed from using-qrspi and replaced with the vendor-neutral five-tier schema
  c=$(grep -c "inherit:" "$USING_SKILL" || true)
  [ "$c" -eq 0 ]
}

@test "implement: role-keyed G5 routing matrix (model_role: column) is gone" {
  # Test expectation: old four-layer chain + role-keyed G5 matrix removed from implement/SKILL.md
  c=$(grep -c "model_role:.*Default route\|model_role.*Tier\|Initial Routing Matrix" "$IMPLEMENT" || true)
  [ "$c" -eq 0 ]
}

@test "implement: hardcoded Agent model: sonnet dispatch arguments are gone" {
  # Test expectation: no hardcoded model: \"sonnet\" dispatch arguments remain after migration
  c=$(grep -c 'model: "sonnet"' "$IMPLEMENT" || true)
  [ "$c" -eq 0 ]
}

@test "test SKILL.md: test_writer_model reference is gone (replaced by per-task tier:)" {
  # Test expectation: skills/test/SKILL.md no longer references the deprecated
  # test_writer_model plan frontmatter field; it reads per-task tier: instead
  c=$(grep -c "test_writer_model" "$TEST_SKILL" || true)
  [ "$c" -eq 0 ]
}

@test "plan SKILL.md: per-task spec emits tier: not model: for routing" {
  # Test expectation: plan/SKILL.md Step 2 heuristic emits tier: field in task frontmatter,
  # not the legacy model: field (lightweight→low, ordinary code→medium, escalated code→high)
  run grep -E "tier:[[:space:]]*(low|medium|high)" "$PLAN_SKILL"
  [ "$status" -eq 0 ]
}

@test "plan SKILL.md: test_writer_model field is gone from plan.md frontmatter template" {
  # Test expectation: test_writer_model is removed from the plan.md frontmatter template
  # in plan/SKILL.md; per-task tier: drives test-writer dispatch now
  c=$(grep -c "test_writer_model" "$PLAN_SKILL" || true)
  [ "$c" -eq 0 ]
}

@test "plan SKILL.md: lightweight tasks emit tier: low (not model: sonnet)" {
  # Test expectation: plan/SKILL.md documents lightweight → tier: low (not model: sonnet)
  run grep -E "lightweight.*tier.*low|tier.*low.*lightweight" "$PLAN_SKILL"
  [ "$status" -eq 0 ]
}

@test "plan SKILL.md: escalated code tasks emit tier: high (not model: opus)" {
  # Test expectation: plan/SKILL.md documents escalated code task → tier: high (not model: opus)
  run grep -E "tier.*high|high.*tier" "$PLAN_SKILL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Implementer/test-writer co-escalation invariant
# Test expectation: Run/extend test-routing-matrix-application.bats for
# per-tag --tier-override application in multi-agent dispatches and the
# implementer/test-writer co-escalation invariant.
# ---------------------------------------------------------------------------

@test "implement: high-tier code task co-escalation is documented (both dispatches same tier)" {
  # Test expectation: a high-tier code task's per-task implementer dispatch AND the TDD
  # test-writer dispatch resolve to the same (vendor, model) pair (co-escalation invariant)
  run grep -E "co.escalat" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}

@test "implement: co-escalation applies the same --tier-override to both implementer and test-writer dispatches" {
  # Test expectation: the dispatcher applies the same --tier-override to both dispatches for
  # a high-tier task; tier is not split between implementer and test-writer
  run grep -E "tier.*override.*both|both.*dispatch.*tier|same.*tier.*implementer.*test.writer|test.writer.*same.*tier" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}

@test "implement: old four-layer routing chain reference (layer 1a/1b/2/3) is gone after G22 migration" {
  # Test expectation: implement/SKILL.md no longer documents the old four-layer chain;
  # it now points to CD-1 universal dispatch and G22 tier rubric
  c=$(grep -c "Layer 1a\|Layer 1b\|layer 1a\|layer 1b" "$IMPLEMENT" || true)
  [ "$c" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Per-Task Routing residue sweep (G22) — the retired per-task model schema
# (model ∈ {sonnet,opus}, the model: <model> dispatch arg, and the
# default-to-sonnet-via-model_role: prose) must be deleted from the
# ### Per-Task Routing section. (vendor, model) resolution defers to the
# #### Tier Resolution Chain that follows.
# ---------------------------------------------------------------------------

@test "implement: retired per-task model ∈ {sonnet,opus} schema line is gone" {
  # Test expectation: the per-task model schema line is replaced by tier resolution
  c=$(grep -c "model ∈" "$IMPLEMENT" || true)
  [ "$c" -eq 0 ]
}

@test "implement: dispatch pseudo-code carries no model: <model> argument" {
  # Test expectation: the dispatch line resolves (vendor, model) via the tier chain,
  # not a per-task model: <model> argument read from task frontmatter
  c=$(grep -c "model: <model>" "$IMPLEMENT" || true)
  [ "$c" -eq 0 ]
}

@test "implement: Per-Task Routing no longer claims tasks default to a sonnet model via model_role:" {
  # Test expectation: the default-flow prose no longer routes a missing-schema task to a
  # sonnet model via the retired model_role: key; model/vendor resolution defers to the
  # Tier Resolution Chain. The retired-default phrasing "default to `code` / `sonnet`"
  # must be gone.
  c=$(grep -c "default to .code. / .sonnet." "$IMPLEMENT" || true)
  [ "$c" -eq 0 ]
}

@test "implement: Tier Resolution Chain section still owns (vendor, model) resolution" {
  # Test expectation: the migrated successor section remains present (guard against an
  # over-zealous deletion that removes the tier chain along with the residue)
  run grep -E "Tier Resolution Chain" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# F05 (G22 completion sweep) — DISPATCH_FILE reviewer pins extended to the
# two deep-mode reviewers (qrspi-code-simplifier, qrspi-type-design-analyzer)
# and the test/SKILL.md reviewer dispatches resolve via tier (no hardcoded
# model: "sonnet" argument).
# ---------------------------------------------------------------------------

@test "reviewer agents: qrspi-code-simplifier body has DISPATCH_FILE first-action instruction" {
  run grep -q "DISPATCH_FILE" "$AGENTS_DIR/qrspi-code-simplifier.md"
  [ "$status" -eq 0 ]
}

@test "reviewer agents: qrspi-type-design-analyzer body has DISPATCH_FILE first-action instruction" {
  run grep -q "DISPATCH_FILE" "$AGENTS_DIR/qrspi-type-design-analyzer.md"
  [ "$status" -eq 0 ]
}

@test "reviewer agents: DISPATCH_FILE instruction precedes any other procedural step in code-simplifier" {
  first_action_line=$(grep -n "DISPATCH_FILE\|You are the\|Your job\|## " \
    "$AGENTS_DIR/qrspi-code-simplifier.md" | head -1)
  [[ "$first_action_line" == *"DISPATCH_FILE"* ]]
}

@test "reviewer agents: DISPATCH_FILE instruction precedes any other procedural step in type-design-analyzer" {
  first_action_line=$(grep -n "DISPATCH_FILE\|You are the\|Your job\|## " \
    "$AGENTS_DIR/qrspi-type-design-analyzer.md" | head -1)
  [[ "$first_action_line" == *"DISPATCH_FILE"* ]]
}

@test "test SKILL.md: reviewer dispatches contain no hardcoded model: \"sonnet\" argument" {
  # Test expectation: every reviewer dispatch resolves vendor+model via tier,
  # mirroring the test-writer dispatch; no model: "sonnet" arg remains.
  c=$(grep -c 'model: "sonnet"' "$TEST_SKILL" || true)
  [ "$c" -eq 0 ]
}
