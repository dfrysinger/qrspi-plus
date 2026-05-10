#!/usr/bin/env bats
#
# task_definition absence fail-loud contract.
#
# Pins the test-phase reuse contract — the absence of task_definition
# is the load-bearing signal that selects test-phase mode on the three
# reusable per-task reviewer agents (spec, code-quality, goal-traceability).
# Enforced at two layers:
#
#   1. CI gate (primary) — pin that skills/test/SKILL.md test-step
#      dispatches do NOT carry task_definition (Claude bullets) or
#      --task-def (Codex wrapper invocations). A future "for clarity" edit
#      that adds either form fails this test at PR time before merge.
#
#   2. Agent-side defense-in-depth — pin that the three reusable reviewer
#      agents (spec, code-quality, goal-traceability) carry a
#      "Phase Routing (FAIL-LOUD)" section that refuses dispatches where
#      task_definition is present AND the output dir contains
#      /reviews/test/, returning a load-bearing PHASE-ROUTING-VIOLATION:
#      prefix the orchestrator detects.
#
# Failure mode if either side drifts:
#   - test/SKILL.md adds --task-def or task_definition to a test-step
#     dispatch ⇒ agent silently routes to Implement-phase checklist,
#     judges test files on production-code criteria (wrong checklist,
#     no error)
#   - Agent drops the Phase Routing section / renames the refusal prefix
#     ⇒ orchestrator's detection branch silently misses the contradiction,
#     runtime defense-in-depth disappears

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
}

# ---------------------------------------------------------------------------
# CI gate (primary): test/SKILL.md test-step dispatches must not carry
# task_definition or --task-def.
# ---------------------------------------------------------------------------

@test "ci-gate: test/SKILL.md Codex wrapper invocations do NOT pass --task-def" {
  local f="$REPO_ROOT/skills/test/SKILL.md"
  [ -f "$f" ]
  # Count run-codex-review.sh invocations (≥3 expected — spec, code-quality,
  # goal-traceability) and assert ZERO --task-def flags.
  local n_wrapper n_task_def
  n_wrapper=$(grep -cE '^[[:space:]]*scripts/run-codex-review\.sh \\$' "$f" || true)
  n_task_def=$(grep -cE '^[[:space:]]*--task-def ' "$f" || true)
  if [ "$n_wrapper" -lt 3 ]; then
    printf 'FAIL: expected ≥3 run-codex-review.sh invocations (spec + code-quality + goal-traceability), got %d\n' "$n_wrapper" >&2
    return 1
  fi
  if [ "$n_task_def" -ne 0 ]; then
    printf 'FAIL: test/SKILL.md has %d --task-def flag(s); test-phase reuse requires absence\n' "$n_task_def" >&2
    return 1
  fi
}

@test "ci-gate: test/SKILL.md Claude dispatch parameter bullets do NOT include task_definition" {
  local f="$REPO_ROOT/skills/test/SKILL.md"
  [ -f "$f" ]
  # Bulleted dispatch-parameter lines like "- `task_definition`:" or "- task_definition:".
  # Reviewer-protocol section + agent-body excerpts + prose paragraphs may
  # MENTION task_definition (that's expected — they describe the contract).
  # Forbid only the bulleted-parameter-line shape that signifies an actual
  # dispatch carrying the field.
  local n_bullet
  n_bullet=$(grep -cE '^[[:space:]]*-[[:space:]]+`?task_definition`?:' "$f" || true)
  if [ "$n_bullet" -ne 0 ]; then
    printf 'FAIL: test/SKILL.md has %d bulleted task_definition: parameter line(s); test-phase reuse requires absence\n' "$n_bullet" >&2
    grep -nE '^[[:space:]]*-[[:space:]]+`?task_definition`?:' "$f" >&2 || true
    return 1
  fi
}

@test "ci-gate: test/SKILL.md still names the absence-as-signal contract in prose" {
  # Defense-in-depth: the prose marker that documents the contract must
  # remain — it is the single point of truth a reader edits when they
  # mistakenly add task_definition. If the prose disappears, the contract
  # becomes invisible to a future editor.
  local f="$REPO_ROOT/skills/test/SKILL.md"
  run grep -F "absence of \`task_definition\`" "$f"
  [ "$status" -eq 0 ]
  run grep -F "Test-phase reuse contract" "$f"
  [ "$status" -eq 0 ]
  run grep -E "Do NOT pass.*task_definition|task_definition.*absent|no --task-def" "$f"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Agent-side defense-in-depth: each reusable reviewer carries a Phase
# Routing stub naming both branches and references the canonical contract
# in reviewer-protocol/SKILL.md (loaded via `skills:` frontmatter). The
# full contradiction-refusal procedure lives in the shared skill, NOT
# duplicated inline in each agent.
# ---------------------------------------------------------------------------

@test "agent-side: each reusable reviewer has a Phase Routing section" {
  for agent in qrspi-spec-reviewer qrspi-code-quality-reviewer qrspi-goal-traceability-reviewer; do
    run grep -F "## Phase Routing" "$REPO_ROOT/agents/$agent.md"
    [ "$status" -eq 0 ]
  done
}

@test "agent-side: each reusable reviewer loads reviewer-protocol via skills frontmatter" {
  # The Phase Routing contract is preloaded automatically when the
  # reviewer-protocol skill is named here. Match the canonical inline-list
  # shape and require the skill name to be bounded by an actual YAML list
  # separator — `[`, `,`, whitespace, or a wrapping quote (single/double)
  # before; `]`, `,`, whitespace, or a wrapping quote after — so a
  # hypothetical `skills: [reviewer-protocol-mock]` entry does not falsely
  # satisfy the assertion, but the quoted form `skills: ["reviewer-protocol"]`
  # does (the wrapper's awk parser strips quotes, so CI must accept the
  # same shapes the runtime accepts). Generic word-boundary anchors (\<\>)
  # treat `-` as a non-word character on both BSD and GNU grep, so
  # `\<reviewer-protocol\>` would mismatch `reviewer-protocol-mock` at
  # the `l-` boundary and falsely pass.
  for agent in qrspi-spec-reviewer qrspi-code-quality-reviewer qrspi-goal-traceability-reviewer; do
    run grep -E "^skills:[[:space:]]*\[(.*[[:space:],\"']|[[:space:]\"']*)reviewer-protocol([[:space:],\"'].*|[[:space:]\"']*)\]" "$REPO_ROOT/agents/$agent.md"
    [ "$status" -eq 0 ]
  done
}

@test "agent-side: each reusable reviewer documents both branches (task_definition present vs absent)" {
  for agent in qrspi-spec-reviewer qrspi-code-quality-reviewer qrspi-goal-traceability-reviewer; do
    run grep -E "task_definition.*present|present.*task_definition|task_definition\` present" "$REPO_ROOT/agents/$agent.md"
    [ "$status" -eq 0 ]
    run grep -E "task_definition.*absent|absent.*task_definition|task_definition\` absent" "$REPO_ROOT/agents/$agent.md"
    [ "$status" -eq 0 ]
  done
}

# ---------------------------------------------------------------------------
# Shared contract: reviewer-protocol/SKILL.md owns the fail-loud
# detection signal, refusal prefix, and refusal procedure once.
# ---------------------------------------------------------------------------

@test "shared: reviewer-protocol/SKILL.md documents the contradiction signal (output dir contains /reviews/test/)" {
  run grep -F "/reviews/test/" "$REPO_ROOT/skills/reviewer-protocol/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "shared: reviewer-protocol/SKILL.md specifies the PHASE-ROUTING-VIOLATION refusal prefix" {
  run grep -F "PHASE-ROUTING-VIOLATION:" "$REPO_ROOT/skills/reviewer-protocol/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "shared: reviewer-protocol/SKILL.md refusal procedure forbids the Write tool" {
  run grep -E "Do NOT call the .Write. tool|Do NOT proceed to" "$REPO_ROOT/skills/reviewer-protocol/SKILL.md"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Orchestrator side: test/SKILL.md documents detection + repair contract
# ---------------------------------------------------------------------------

@test "orchestrator: test/SKILL.md names the PHASE-ROUTING-VIOLATION prefix for detection" {
  run grep -F "PHASE-ROUTING-VIOLATION:" "$REPO_ROOT/skills/test/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "orchestrator: test/SKILL.md forbids retry-with-same-leak (would loop)" {
  # If the orchestrator silently re-dispatched the same prompt the agent's
  # Pre-Flight refusal would fire again — infinite loop. Pin the imperative.
  run grep -E "do not silently retry|infinite (refusal )?loop|repair the dispatch|after repair" "$REPO_ROOT/skills/test/SKILL.md"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Companion: contract-04 in test-cross-skill-contracts.bats still holds
# (loose-grep prose baseline persists alongside this fail-loud upgrade).
# ---------------------------------------------------------------------------

@test "fail-loud: contract-04 baseline (test-phase reuse prose) still present" {
  local f="$REPO_ROOT/skills/test/SKILL.md"
  run grep -F "absence of \`task_definition\`" "$f"
  [ "$status" -eq 0 ]
  run grep -E "Do NOT pass.*task_definition|task_definition.*absent" "$f"
  [ "$status" -eq 0 ]
  run grep -F "Test-phase reuse" "$f"
  [ "$status" -eq 0 ]
}
