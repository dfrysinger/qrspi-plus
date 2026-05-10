#!/usr/bin/env bats
#
# Research-isolation fail-loud refusal contract.
#
# Pins the Pre-Flight Isolation Check that refuses dispatches carrying
# goals.md or cross-question content reaching any of the three research
# subagents (specialist, collator, reviewer).
#
# Pinned shape:
#   - The shared check lives in skills/research-isolation/SKILL.md
#   - All three research agents load it via `skills:` frontmatter
#   - Each agent body retains a "Pre-Flight Isolation Check" section that
#     names the agent's specific 5th detection pattern
#   - The canonical RESEARCH-ISOLATION-VIOLATION: refusal prefix is
#     emitted on detection
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
# Per-agent: each research agent loads research-isolation via skills
# frontmatter and retains a Pre-Flight Isolation Check section that names
# its agent-specific 5th detection pattern. The shared rules (patterns 1-4
# + sanitization bypass + structural carve-out + refusal procedure) live
# once in skills/research-isolation/SKILL.md.
# ---------------------------------------------------------------------------

@test "fail-loud: each research agent loads research-isolation via skills frontmatter" {
  for agent in qrspi-research-specialist qrspi-research-collator qrspi-research-reviewer; do
    run grep -E "^skills:.*research-isolation" "$REPO_ROOT/agents/$agent.md"
    [ "$status" -eq 0 ]
  done
}

@test "fail-loud: each research agent has a Pre-Flight Isolation Check section" {
  # Match either `## Pre-Flight Isolation Check` (specialist, collator)
  # or `## Step N — Pre-Flight Isolation Check` (reviewer, where the
  # check sits inside the reviewer's step sequence).
  for agent in qrspi-research-specialist qrspi-research-collator qrspi-research-reviewer; do
    run grep -E "^## (Step [0-9.]+ — )?Pre-Flight Isolation Check" "$REPO_ROOT/agents/$agent.md"
    [ "$status" -eq 0 ]
  done
}

@test "fail-loud: specialist names its agent-specific cross-question leakage pattern" {
  run grep -iF "cross-question leakage" "$REPO_ROOT/agents/qrspi-research-specialist.md"
  [ "$status" -eq 0 ]
  # Canonical lowercase token used in the refusal prefix
  run grep -F "cross-question-leakage" "$REPO_ROOT/agents/qrspi-research-specialist.md"
  [ "$status" -eq 0 ]
}

@test "fail-loud: collator + reviewer name their agent-specific questions-compendium leakage pattern" {
  for agent in qrspi-research-collator qrspi-research-reviewer; do
    run grep -iF "questions-compendium leakage" "$REPO_ROOT/agents/$agent.md"
    [ "$status" -eq 0 ]
  done
}

# ---------------------------------------------------------------------------
# Shared contract: research-isolation/SKILL.md owns the patterns, refusal
# prefix, refusal procedure, and structural carve-out marker once.
# ---------------------------------------------------------------------------

@test "shared: research-isolation/SKILL.md enumerates the common detection patterns" {
  local f="$REPO_ROOT/skills/research-isolation/SKILL.md"
  run grep -F "Field-name leakage" "$f"
  [ "$status" -eq 0 ]
  run grep -F "Filename leakage" "$f"
  [ "$status" -eq 0 ]
  run grep -F "Goals-heading leakage" "$f"
  [ "$status" -eq 0 ]
  run grep -F "Goal-framing triplet" "$f"
  [ "$status" -eq 0 ]
  run grep -F "What we know so far" "$f"
  [ "$status" -eq 0 ]
  run grep -F "Sanitization bypass" "$f"
  [ "$status" -eq 0 ]
}

@test "shared: research-isolation/SKILL.md specifies the RESEARCH-ISOLATION-VIOLATION refusal prefix" {
  run grep -F "RESEARCH-ISOLATION-VIOLATION:" "$REPO_ROOT/skills/research-isolation/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "shared: research-isolation/SKILL.md refusal procedure forbids the Write tool" {
  run grep -E "Do NOT call the .Write. tool|Do NOT produce" "$REPO_ROOT/skills/research-isolation/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "shared: research-isolation/SKILL.md references the structural <<<AGENT-BODY-END>>> marker" {
  # Positional carve-out — the marker delimits trusted protocol+agent body
  # from orchestrator-supplied dispatch parameters. A buggy refactor that
  # drops this reference re-opens the prose-only carve-out bypass.
  run grep -F "<<<AGENT-BODY-END>>>" "$REPO_ROOT/skills/research-isolation/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "shared: research-isolation/SKILL.md enumerates every canonical pattern token" {
  # The orchestrator's pattern→repair table in skills/research/SKILL.md
  # keys off these canonical tokens; any rename here without a matching
  # rename there would silently break the detection chain.
  local f="$REPO_ROOT/skills/research-isolation/SKILL.md"
  for token in field-name-leakage filename-leakage goals-heading-leakage goal-framing-triplet cross-question-leakage questions-compendium-leakage sanitization-bypass; do
    run grep -F "$token" "$f"
    [ "$status" -eq 0 ]
  done
}

# ---------------------------------------------------------------------------
# Cross-emitter token parity: the canonical questions-compendium-leakage
# token appears in every emitter so the orchestrator's pattern→repair
# table matches a single entry per family.
# ---------------------------------------------------------------------------

@test "fail-loud: pattern token parity — research-isolation skill + orchestrator name the same questions-compendium-leakage token" {
  run grep -F "questions-compendium-leakage" "$REPO_ROOT/skills/research-isolation/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -F "questions-compendium-leakage" "$REPO_ROOT/skills/research/SKILL.md"
  [ "$status" -eq 0 ]
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
