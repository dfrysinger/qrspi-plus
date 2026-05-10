#!/usr/bin/env bats
#
# Research-isolation fail-loud refusal contract (Bucket-3 #7).
#
# Promotes cross-skill contract #7 from prose-only ("report the violation in
# your final confirmation") to a structural Pre-Flight Isolation Check that
# refuses dispatches carrying goals.md or cross-question content.
#
# Pinned shape:
#   - All three research subagents (specialist, collator, reviewer) carry a
#     "Pre-Flight Isolation Check (FAIL-LOUD)" section in their agent body
#   - Each agent enumerates the load-bearing detection patterns
#   - Each agent specifies the canonical RESEARCH-ISOLATION-VIOLATION: refusal
#     prefix that the orchestrator detects
#   - research/SKILL.md documents the orchestrator-side handler that responds
#     to a violation by repairing the dispatch (not silently retrying)
#
# Failure mode if any side drifts:
#   - Agent drops the Pre-Flight section ⇒ leak goes undetected at runtime,
#     specialist produces confirmation-bias-driven research
#   - Refusal prefix is renamed ⇒ orchestrator's detection branch silently
#     misses violations, treats them as malformed output and re-dispatches
#     with the same leak
#   - Pattern enumeration shrinks ⇒ a new leak shape (e.g., goals body
#     smuggled via defect_summary) bypasses the check

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
}

# ---------------------------------------------------------------------------
# Per-agent: Pre-Flight Isolation Check section is present
# ---------------------------------------------------------------------------

@test "fail-loud: specialist agent has Pre-Flight Isolation Check section" {
  run grep -F "Pre-Flight Isolation Check (FAIL-LOUD)" "$REPO_ROOT/agents/qrspi-research-specialist.md"
  [ "$status" -eq 0 ]
}

@test "fail-loud: collator agent has Pre-Flight Isolation Check section" {
  run grep -F "Pre-Flight Isolation Check (FAIL-LOUD)" "$REPO_ROOT/agents/qrspi-research-collator.md"
  [ "$status" -eq 0 ]
}

@test "fail-loud: reviewer agent has Pre-Flight Isolation Check section" {
  run grep -F "Pre-Flight Isolation Check (FAIL-LOUD)" "$REPO_ROOT/agents/qrspi-research-reviewer.md"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Per-agent: detection patterns are enumerated
# Patterns enumerated here are the load-bearing ones; cosmetic prose may
# rewrite around them but the named patterns must survive.
# ---------------------------------------------------------------------------

@test "fail-loud: specialist enumerates field-name + heading + triplet patterns" {
  # Field-name leakage (companion_goals or any goals-named field)
  run grep -F "Field-name leakage" "$REPO_ROOT/agents/qrspi-research-specialist.md"
  [ "$status" -eq 0 ]
  # Goals-heading leakage (# Goals / ## Goal N: / Environmental Context)
  run grep -F "Goals-heading leakage" "$REPO_ROOT/agents/qrspi-research-specialist.md"
  [ "$status" -eq 0 ]
  # Goal-framing triplet (Problem / Why we care / What we know so far)
  run grep -F "Goal-framing triplet" "$REPO_ROOT/agents/qrspi-research-specialist.md"
  [ "$status" -eq 0 ]
  run grep -F "What we know so far" "$REPO_ROOT/agents/qrspi-research-specialist.md"
  [ "$status" -eq 0 ]
  # Cross-question leakage (specialist-specific — Q\d+ for unassigned IDs)
  run grep -F "Cross-question leakage" "$REPO_ROOT/agents/qrspi-research-specialist.md"
  [ "$status" -eq 0 ]
  # Sanitization bypass (re-dispatch defect_summary smuggling goals)
  run grep -F "Sanitization bypass" "$REPO_ROOT/agents/qrspi-research-specialist.md"
  [ "$status" -eq 0 ]
}

@test "fail-loud: collator enumerates field-name + heading + triplet + questions-compendium patterns" {
  run grep -F "Field-name leakage" "$REPO_ROOT/agents/qrspi-research-collator.md"
  [ "$status" -eq 0 ]
  run grep -F "Goals-heading leakage" "$REPO_ROOT/agents/qrspi-research-collator.md"
  [ "$status" -eq 0 ]
  run grep -F "Goal-framing triplet" "$REPO_ROOT/agents/qrspi-research-collator.md"
  [ "$status" -eq 0 ]
  # Collator-specific: Questions-compendium leakage. Token unified with the
  # reviewer agent and the orchestrator's pattern→repair table in
  # research/SKILL.md so RESEARCH-ISOLATION-VIOLATION: questions-compendium-leakage
  # matches a single canonical entry on every emitter.
  run grep -F "Questions-compendium leakage" "$REPO_ROOT/agents/qrspi-research-collator.md"
  [ "$status" -eq 0 ]
}

@test "fail-loud: pattern token parity — collator + reviewer + orchestrator name the same questions-compendium-leakage token" {
  # Cross-emitter token parity. The canonical token must match across
  # all three emitters so the orchestrator's pattern→repair table matches
  # a single entry per family:
  #   (a) collator agent prose
  #   (b) reviewer agent prose  ← previously omitted; second-pass review F8 gap
  #   (c) orchestrator handler in skills/research/SKILL.md
  # A regression renaming the token in any one of these would silently
  # break the RESEARCH-ISOLATION-VIOLATION detection chain.
  run grep -F "questions-compendium-leakage" "$REPO_ROOT/agents/qrspi-research-collator.md"
  [ "$status" -eq 0 ]
  run grep -F "questions-compendium-leakage" "$REPO_ROOT/agents/qrspi-research-reviewer.md"
  [ "$status" -eq 0 ]
  run grep -F "questions-compendium-leakage" "$REPO_ROOT/skills/research/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "fail-loud: each research agent's exception clause references the structural <<<AGENT-BODY-END>>> marker" {
  # Codex review F6 — the prose-only "your own agent body" carve-out is
  # bypassable by injected content quoting the exception language. Pin
  # the structural-marker reference instead so the carve-out is positional.
  for agent in qrspi-research-specialist qrspi-research-collator qrspi-research-reviewer; do
    run grep -F "<<<AGENT-BODY-END>>>" "$REPO_ROOT/agents/$agent.md"
    [ "$status" -eq 0 ]
  done
}

@test "fail-loud: reviewer enumerates field-name + heading + triplet + questions-compendium patterns" {
  run grep -F "Field-name leakage" "$REPO_ROOT/agents/qrspi-research-reviewer.md"
  [ "$status" -eq 0 ]
  run grep -F "Goals-heading leakage" "$REPO_ROOT/agents/qrspi-research-reviewer.md"
  [ "$status" -eq 0 ]
  run grep -F "Goal-framing triplet" "$REPO_ROOT/agents/qrspi-research-reviewer.md"
  [ "$status" -eq 0 ]
  # Reviewer-specific: Questions-compendium leakage (companion_qfiles is OK,
  # questions.md compendium is not)
  run grep -F "Questions-compendium leakage" "$REPO_ROOT/agents/qrspi-research-reviewer.md"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Per-agent: refusal contract specifies the load-bearing prefix
# Renaming the prefix would silently break the orchestrator's detection branch.
# ---------------------------------------------------------------------------

@test "fail-loud: specialist refusal uses RESEARCH-ISOLATION-VIOLATION: prefix" {
  run grep -F "RESEARCH-ISOLATION-VIOLATION:" "$REPO_ROOT/agents/qrspi-research-specialist.md"
  [ "$status" -eq 0 ]
  # The agent must explicitly forbid Write on refusal — otherwise a partial
  # report could still hit disk before the refusal returns
  run grep -E "Do NOT call the .Write. tool|do NOT (call|use) the .Write." "$REPO_ROOT/agents/qrspi-research-specialist.md"
  [ "$status" -eq 0 ]
}

@test "fail-loud: collator refusal uses RESEARCH-ISOLATION-VIOLATION: prefix" {
  run grep -F "RESEARCH-ISOLATION-VIOLATION:" "$REPO_ROOT/agents/qrspi-research-collator.md"
  [ "$status" -eq 0 ]
  run grep -E "Do NOT call the .Write. tool|Do NOT produce ._collated\.md" "$REPO_ROOT/agents/qrspi-research-collator.md"
  [ "$status" -eq 0 ]
}

@test "fail-loud: reviewer refusal uses RESEARCH-ISOLATION-VIOLATION: prefix" {
  run grep -F "RESEARCH-ISOLATION-VIOLATION:" "$REPO_ROOT/agents/qrspi-research-reviewer.md"
  [ "$status" -eq 0 ]
  # Reviewer doesn't Write a report; it emits per-finding files. Refusal must
  # block emission of findings or the clean sentinel.
  run grep -E "Do NOT proceed to Step 2|Do NOT emit findings" "$REPO_ROOT/agents/qrspi-research-reviewer.md"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Per-agent: exception clause prevents self-referential false positives
# Each agent's own definition names goals.md, companion_goals, etc., for
# documentation. The check must explicitly carve those out so the agent
# doesn't refuse on its own body.
# ---------------------------------------------------------------------------

@test "fail-loud: agents carve out the self-reference exception" {
  for agent in qrspi-research-specialist qrspi-research-collator qrspi-research-reviewer; do
    run grep -E "Exception|NOT in this agent definition" "$REPO_ROOT/agents/$agent.md"
    [ "$status" -eq 0 ]
  done
}

# ---------------------------------------------------------------------------
# Orchestrator side: research/SKILL.md documents detection + repair
# ---------------------------------------------------------------------------

@test "fail-loud: research SKILL has Isolation-Violation Orchestrator Handling section" {
  run grep -F "Isolation-Violation Orchestrator Handling" "$REPO_ROOT/skills/research/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "fail-loud: research SKILL names the canonical refusal prefix" {
  # The orchestrator detection branch keys off this exact prefix
  run grep -F "RESEARCH-ISOLATION-VIOLATION:" "$REPO_ROOT/skills/research/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "fail-loud: research SKILL forbids retry-with-same-leak" {
  # The fail-loud upgrade is meaningful only if the orchestrator does NOT
  # silently re-dispatch with the same offending prompt — that would loop.
  run grep -E "not retry-with-same-leak|infinite (refusal )?loop|repair the dispatch|repaired prompt" "$REPO_ROOT/skills/research/SKILL.md"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Companion: contract-07 in test-cross-skill-contracts.bats still holds
# (loose-grep baseline persists alongside this fail-loud upgrade).
# This check guards against the fail-loud rename accidentally deleting the
# baseline grep target.
# ---------------------------------------------------------------------------

@test "fail-loud: contract-07 baseline (research-isolation invariant prose) still present" {
  # Side A — research/SKILL.md
  run grep -E "research.isolation|isolation.invariant" "$REPO_ROOT/skills/research/SKILL.md"
  [ "$status" -eq 0 ]
  # Side B — both agents reference the invariant by name
  run grep -iF "research-isolation" "$REPO_ROOT/agents/qrspi-research-specialist.md"
  [ "$status" -eq 0 ]
  run grep -iF "research-isolation" "$REPO_ROOT/agents/qrspi-research-reviewer.md"
  [ "$status" -eq 0 ]
}
