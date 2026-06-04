#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# #118 / #115 Interactive-skill UX bundle — defends the prose anchors in the
# collaborative-skill preambles (auto-mode detection in goals + design) and
# the per-researcher dispatch contract pins (direct-write + summary-last
# authoring order in research). Cheap grep guards; catch accidental deletion
# during future SKILL.md edits.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  export REPO_ROOT
}

@test "goals/SKILL.md carries the auto-mode detection paragraph" {
  grep -F "Auto Mode Active" "$REPO_ROOT/skills/goals/SKILL.md"
}

@test "design/SKILL.md carries the auto-mode detection paragraph" {
  grep -F "Auto Mode Active" "$REPO_ROOT/skills/design/SKILL.md"
}

@test "research/SKILL.md carries the direct-write and summary-last contract pins" {
  grep -F "Direct-write contract" "$REPO_ROOT/skills/research/SKILL.md"
  grep -F "Summary-last authoring order" "$REPO_ROOT/skills/research/SKILL.md"
}

# Rule 5 presence + absence contract: the literal Rule 5 phrase is
# Design-only per user scope (v0.7.2); Goals must not carry it.

@test "design/SKILL.md carries the Rule 5 simple-language-and-context phrase" {
  grep -F "Use simple language and provide context when presenting ideas" \
    "$REPO_ROOT/skills/design/SKILL.md"
}

@test "goals/SKILL.md does not carry the Rule 5 simple-language-and-context phrase (Design-only scope)" {
  [ -f "$REPO_ROOT/skills/goals/SKILL.md" ]
  run grep -F "Use simple language and provide context when presenting ideas" \
    "$REPO_ROOT/skills/goals/SKILL.md"
  [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Goals dialogue-conduct subset — Rules 1, 2, 3 (codebase→web), 4, 6, 7, 8
# mirror the Design wording verbatim. Rule 5 absence is pinned above.
# ---------------------------------------------------------------------------

@test "goals/SKILL.md carries Rule 1 — Open with questions" {
  grep -F "Open with questions" "$REPO_ROOT/skills/goals/SKILL.md"
}

@test "goals/SKILL.md carries Rule 2 — One question at a time, with a recommended answer" {
  grep -F "One question at a time, with a recommended answer" "$REPO_ROOT/skills/goals/SKILL.md"
}

@test "goals/SKILL.md carries Rule 3 — Ground first, ask second (codebase then web; no research-summary tier)" {
  grep -F "Ground first, ask second" "$REPO_ROOT/skills/goals/SKILL.md"
  grep -F "the codebase, then the web" "$REPO_ROOT/skills/goals/SKILL.md"
  # Goals runs before Research; the research-summary grounding tier is Design-only.
  run grep -F "research summary" "$REPO_ROOT/skills/goals/SKILL.md"
  [ "$status" -eq 1 ]
}

@test "goals/SKILL.md carries Rule 4 — When the user asks for your call, provide one" {
  grep -F "When the user asks for your call, provide one" "$REPO_ROOT/skills/goals/SKILL.md"
}

@test "goals/SKILL.md carries Rule 6 — Sharpen fuzzy language" {
  grep -F "Sharpen fuzzy language" "$REPO_ROOT/skills/goals/SKILL.md"
}

@test "goals/SKILL.md carries Rule 7 — Walk every branch of the decision tree, including flow gaps" {
  grep -F "Walk every branch of the decision tree, including flow gaps" "$REPO_ROOT/skills/goals/SKILL.md"
}

@test "goals/SKILL.md carries Rule 8 — Lock decisions as they settle" {
  grep -F "Lock decisions as they settle" "$REPO_ROOT/skills/goals/SKILL.md"
}

# ---------------------------------------------------------------------------
# Incremental persistence: direct writes to the draft artifact with status: draft
# ---------------------------------------------------------------------------

@test "design/SKILL.md instructs direct incremental writes to design.md with status: draft" {
  grep -F "directly to \`design.md\`" "$REPO_ROOT/skills/design/SKILL.md"
  grep -F "status: draft" "$REPO_ROOT/skills/design/SKILL.md"
}

@test "goals/SKILL.md instructs direct incremental writes to goals.md with status: draft" {
  grep -F "directly to \`goals.md\`" "$REPO_ROOT/skills/goals/SKILL.md"
  grep -F "status: draft" "$REPO_ROOT/skills/goals/SKILL.md"
}

@test "design/SKILL.md authors Cross-Goal Decisions in a dedicated top-level section" {
  grep -F "## Cross-Goal Decisions" "$REPO_ROOT/skills/design/SKILL.md"
}

# ---------------------------------------------------------------------------
# Lock semantics — presence ≡ locked; placeholder/TODO/to-be-filled bodies forbidden;
# re-locking overwrites the keyed block in place rather than appending a duplicate.
# ---------------------------------------------------------------------------

@test "design/SKILL.md documents presence-as-locked semantics" {
  grep -iF "presence" "$REPO_ROOT/skills/design/SKILL.md" | grep -qiF "locked"
}

@test "goals/SKILL.md documents presence-as-locked semantics" {
  grep -iF "presence" "$REPO_ROOT/skills/goals/SKILL.md" | grep -qiF "locked"
}

@test "design/SKILL.md prohibits placeholder/TODO/to-be-filled bodies in the draft artifact" {
  grep -F "to be filled" "$REPO_ROOT/skills/design/SKILL.md"
  grep -F "TODO" "$REPO_ROOT/skills/design/SKILL.md"
  grep -F "placeholder" "$REPO_ROOT/skills/design/SKILL.md"
}

@test "goals/SKILL.md prohibits placeholder/TODO/to-be-filled bodies in the draft artifact" {
  grep -F "to be filled" "$REPO_ROOT/skills/goals/SKILL.md"
  grep -F "TODO" "$REPO_ROOT/skills/goals/SKILL.md"
  grep -F "placeholder" "$REPO_ROOT/skills/goals/SKILL.md"
}

@test "design/SKILL.md documents keyed in-place overwrite on re-lock (no duplicate append)" {
  grep -F "overwrite" "$REPO_ROOT/skills/design/SKILL.md" | grep -qF "in place"
}

@test "goals/SKILL.md documents keyed in-place overwrite on re-lock (no duplicate append)" {
  grep -F "overwrite" "$REPO_ROOT/skills/goals/SKILL.md" | grep -qF "in place"
}

# ---------------------------------------------------------------------------
# Resume-after-compaction diagnostic — anchor phrase MUST be exact in both skills.
# ---------------------------------------------------------------------------

@test "design/SKILL.md carries the exact resume-after-compaction diagnostic" {
  grep -F "Resumed after compaction — last locked decision: GNN (M decisions locked, K remaining). Continuing from G(NN+1)." \
    "$REPO_ROOT/skills/design/SKILL.md"
}

@test "goals/SKILL.md carries the exact resume-after-compaction diagnostic" {
  grep -F "Resumed after compaction — last locked decision: GNN (M decisions locked, K remaining). Continuing from G(NN+1)." \
    "$REPO_ROOT/skills/goals/SKILL.md"
}

# ---------------------------------------------------------------------------
# Remaining-work computation differs by skill: Goals asks the user; Design diffs
# `goals.md` goals against locked per-goal blocks in `design.md`.
# ---------------------------------------------------------------------------

@test "goals/SKILL.md remaining-work is asked of the user (no upstream inventory at Goals stage)" {
  grep -F "remaining" "$REPO_ROOT/skills/goals/SKILL.md" | grep -qiF "user"
}

@test "design/SKILL.md remaining-work computed from goals.md goals minus locked design.md decisions" {
  grep -F "remaining" "$REPO_ROOT/skills/design/SKILL.md" | grep -qF "goals.md"
}

# ---------------------------------------------------------------------------
# End-of-phase finalize: Goals → approved; Design → approved-pending-review.
# ---------------------------------------------------------------------------

@test "goals/SKILL.md finalize pass flips status: draft to approved" {
  grep -F "finalize" "$REPO_ROOT/skills/goals/SKILL.md"
  # Pin a finalize-block-unique phrase so this test fails if the finalize block is deleted
  # but the mid-phase prohibition line (which also contains "status: draft" and "approved") remains.
  grep -F "Validate that every locked goal" "$REPO_ROOT/skills/goals/SKILL.md"
}

@test "design/SKILL.md finalize pass flips status: draft to approved-pending-review" {
  grep -F "finalize" "$REPO_ROOT/skills/design/SKILL.md"
  grep -F "approved-pending-review" "$REPO_ROOT/skills/design/SKILL.md"
}

# ---------------------------------------------------------------------------
# Simulated-compaction durability contract — both skills MUST pin the
# acceptance invariant that a mid-phase compaction (e.g., at G15) followed by
# resume produces a final artifact identical to a no-compaction run.
# ---------------------------------------------------------------------------

@test "design/SKILL.md pins the simulated-compaction durability contract (G15 mid-phase)" {
  grep -F "simulated compaction" "$REPO_ROOT/skills/design/SKILL.md"
  grep -F "identical to a no-compaction run" "$REPO_ROOT/skills/design/SKILL.md"
}

@test "goals/SKILL.md pins the simulated-compaction durability contract (G15 mid-phase)" {
  grep -F "simulated compaction" "$REPO_ROOT/skills/goals/SKILL.md"
  grep -F "identical to a no-compaction run" "$REPO_ROOT/skills/goals/SKILL.md"
}

# ---------------------------------------------------------------------------
# spec-F01: five-field per-goal template fields in design/SKILL.md
# ---------------------------------------------------------------------------

@test "design/SKILL.md references the five-field per-goal template fields" {
  grep -F "Outcome" "$REPO_ROOT/skills/design/SKILL.md"
  grep -F "Solution" "$REPO_ROOT/skills/design/SKILL.md"
  grep -F "Why this approach" "$REPO_ROOT/skills/design/SKILL.md"
  grep -F "Dependencies + edge cases" "$REPO_ROOT/skills/design/SKILL.md"
  grep -F "Acceptance" "$REPO_ROOT/skills/design/SKILL.md"
}

# ---------------------------------------------------------------------------
# spec-F02: Goals preservation — question-topic checklist, Pipeline Mode
# Selection step, and per-goal template fields
# ---------------------------------------------------------------------------

@test "goals/SKILL.md preserves the Interactive Dialogue question-topic checklist" {
  grep -F "Questions to cover" "$REPO_ROOT/skills/goals/SKILL.md"
}

@test "goals/SKILL.md preserves the Pipeline Mode Selection step" {
  grep -F "Pipeline Mode Selection" "$REPO_ROOT/skills/goals/SKILL.md"
}

@test "goals/SKILL.md preserves the existing per-goal template fields" {
  grep -F "Problem" "$REPO_ROOT/skills/goals/SKILL.md"
  grep -F "Why we care" "$REPO_ROOT/skills/goals/SKILL.md"
  grep -F "What we know so far" "$REPO_ROOT/skills/goals/SKILL.md"
}

# ---------------------------------------------------------------------------
# sf-F01: Synthesis subagents must include on-disk incremental draft as input
# and instruct merge-with-draft rather than re-synthesizing from conversation.
# ---------------------------------------------------------------------------

@test "goals/SKILL.md synthesis subagent lists on-disk incremental draft as a REQUIRED input" {
  # The synthesis subagent inputs section must explicitly list the incremental draft
  # so that pre-compaction locked decisions survive a /compact + resume cycle.
  grep -F "MUST merge" "$REPO_ROOT/skills/goals/SKILL.md"
}

@test "design/SKILL.md synthesis subagent lists on-disk incremental draft as a REQUIRED input" {
  # Same requirement for the Design synthesis subagent.
  grep -F "MUST merge" "$REPO_ROOT/skills/design/SKILL.md"
}

# ---------------------------------------------------------------------------
# sf-F02: Iron Rule must align with presence-as-locked — re-enter dialogue
# for missing subsections, not write placeholders.
# ---------------------------------------------------------------------------

@test "goals/SKILL.md Iron Rule directs re-enter dialogue for missing subsections (not placeholder)" {
  # The Iron Rule (three subsections) must instruct re-entering dialogue rather than
  # emitting a placeholder, which would violate the presence-as-locked contract.
  grep -F "re-enter dialogue" "$REPO_ROOT/skills/goals/SKILL.md"
}

# ---------------------------------------------------------------------------
# sf-F01: Finalize pass must gate the status flip on all-validations-passed.
# If any validation fails, halt before the status flip and re-enter dialogue.
# ---------------------------------------------------------------------------

@test "goals/SKILL.md finalize pass gates status flip on all-validations-passed (sf-F01)" {
  grep -F "Only flip status if all validations pass" "$REPO_ROOT/skills/goals/SKILL.md"
}

@test "design/SKILL.md finalize pass gates status flip on all-validations-passed (sf-F01)" {
  grep -F "Only flip status if all validations pass" "$REPO_ROOT/skills/design/SKILL.md"
}
