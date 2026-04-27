#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Acceptance tests for Phase 4 Hardening — Skill prompt verification goals.
#
# These tests verify that specific required text patterns exist in SKILL.md files.
# They are grep-based structural tests that confirm Phase 4 prompt improvements
# were applied to the skill templates.
#
# Covers:
#   U7  — Review result persistence: implement SKILL.md contains persistence logic
#   M21 — Replan rework: scope-unknown severity, Goals loop-back, default to stepping back
#   M22 — Config validation: numbered options for invalid config
#   M24 — Test checkboxes: test SKILL.md has criterion-to-test mapping + checkbox update
#   M25 — Artifact management: replan SKILL.md has archive/promote workflow
#   M26 — Skill prompt improvements: D1, D2, D3 directives + selected observations
#   M27 — Self-healing relocation: validate.sh absent or empty; using-qrspi refs validation
#   M28 — Phase learnings capture: test and integrate SKILL.md have phase learnings prompts
#   M29 — Amendment classification: three-tier amendment classification exists
#   M32 — REMOVED in 2026-04-26 implement-runtime-fix: per-worktree .claude/settings.json
#         is no longer used; subagent containment is hook-governed (target-based).
#   M33 — Plan-level architectural review: plan SKILL.md mentions architectural review
#   M34 — Amendment-to-goal mapping validation: replan SKILL.md has the mapping rule
#   M35 — Goal-text decomposition check: goal-traceability-reviewer.md has decomp check
#   M36 — Amendment compression rule: design SKILL.md has bare-number compression rule
#   M37 — Phase-scoped artifact rules: design/structure/plan SKILL.md have current-phase rules
#   M38 — Roadmap artifact rules: design SKILL.md has roadmap.md rules
#   M40 — Goal specificity rule: goals SKILL.md has independently-scopeable + late splitting

setup() {
  export SKILLS_DIR
  SKILLS_DIR="$(dirname "$BATS_TEST_FILENAME")/../../skills"
  export HOOKS_DIR
  HOOKS_DIR="$(dirname "$BATS_TEST_FILENAME")/../../hooks"
}

teardown() {
  # Most tests are read-only grep — nothing to clean. F-14 live git tests set
  # LIVE_GIT_TMPDIR so the temp repo gets removed even on assertion failure
  # (bats aborts the test on the first failed [ ] assertion, skipping any
  # in-test rm -rf).
  if [[ -n "${LIVE_GIT_TMPDIR:-}" && -d "$LIVE_GIT_TMPDIR" ]]; then
    rm -rf "$LIVE_GIT_TMPDIR"
  fi
}

# ── U7: Review result persistence ────────────────────────────────────────────
# Criterion: Implement skill template contains review result persistence logic.

# U7 — implement SKILL.md references writing review results to files
@test "[U7] implement SKILL.md references writing review results/findings to artifact files" {
  # AC: review results from the inner loop must be persisted; the skill must instruct
  # the implementer to write findings to files in the artifact directory
  local skill_file="$SKILLS_DIR/implement/SKILL.md"
  [ -f "$skill_file" ]
  # The skill must reference writing review output to files (reviews/ directory)
  grep -qi "reviews/" "$skill_file"
}

# U7 — implement template references reviews/tasks/ for per-task review output
# (Reference moved from implement/SKILL.md to per-task-orchestrator.md during the
# R1 skill refactor; behavior preserved, test updated to follow.)
@test "[U7] per-task-orchestrator template references reviews/tasks/ directory for per-task review persistence" {
  # AC: each task's review results are persisted to reviews/tasks/ so Integrate can use them
  local template_file="$SKILLS_DIR/implement/templates/per-task-orchestrator.md"
  grep -q "reviews/tasks" "$template_file"
}

# ── M21: Replan rework ────────────────────────────────────────────────────────
# Criterion: Replan SKILL.md contains scope-unknown severity, Goals as loop-back
# target, and default to most stringent treatment.

# M21 — Replan SKILL.md contains "scope unknown" severity classification
@test "[M21] replan SKILL.md contains 'Scope Unknown' severity classification" {
  # AC: scope-unknown changes must be recognized as a distinct severity level
  local skill_file="$SKILLS_DIR/replan/SKILL.md"
  [ -f "$skill_file" ]
  grep -qi "scope.unknown\|scope unknown" "$skill_file"
}

# M21 — Replan SKILL.md contains Goals as a valid loop-back target
@test "[M21] replan SKILL.md lists Goals as a backward loop-back target" {
  # AC: major changes that affect acceptance criteria must loop back to Goals
  local skill_file="$SKILLS_DIR/replan/SKILL.md"
  grep -q "Loop back to Goals\|loop.*back.*Goals\|back.*to Goals\|loop-back target.*Goals\|Goals.*loop-back" "$skill_file"
}

# M21 — Replan SKILL.md instructs defaulting to most stringent treatment for scope-unknown
@test "[M21] replan SKILL.md instructs treating scope-unknown as major (most stringent)" {
  # AC: when scope is ambiguous, Replan must default to the most stringent treatment,
  # not guess minor — the Iron Law enforces this
  local skill_file="$SKILLS_DIR/replan/SKILL.md"
  grep -q "most stringent\|Treat as Major\|treat.*as.*major" "$skill_file"
}

# ── M22: Config validation ────────────────────────────────────────────────────
# Criterion: using-qrspi or skill prompts contain numbered option menus for
# invalid config states.

# M22 — using-qrspi SKILL.md contains numbered options when config is missing/invalid
@test "[M22] using-qrspi SKILL.md contains numbered config validation options" {
  # AC: agents must not silently default invalid config; they must present numbered menus
  local skill_file="$SKILLS_DIR/using-qrspi/SKILL.md"
  [ -f "$skill_file" ]
  # Config Validation Procedure section must exist with numbered options
  grep -q "Config Validation\|config validation" "$skill_file"
  # Must have numbered options (1), 2), 3) style menus)
  grep -q "1) Re-run Goals\|1) Abort\|numbered" "$skill_file"
}

# M22 — goals SKILL.md contains numbered options for invalid config fields
@test "[M22] goals SKILL.md contains numbered config validation options for invalid fields" {
  # AC: Goals is the first skill to write config.md; it must validate on resume
  local skill_file="$SKILLS_DIR/goals/SKILL.md"
  [ -f "$skill_file" ]
  grep -q "Config Validation\|1) Re-run Goals\|1) Manually add" "$skill_file"
}

# M22 — plan SKILL.md contains numbered config validation options
@test "[M22] plan SKILL.md contains numbered config validation options" {
  # AC: Plan reads config.md for route/pipeline; must validate with numbered menus
  local skill_file="$SKILLS_DIR/plan/SKILL.md"
  [ -f "$skill_file" ]
  grep -q "Config Validation\|1) Re-run Goals\|config.*missing\|config.*invalid" "$skill_file"
}

# ── M24: Test checkboxes ──────────────────────────────────────────────────────
# Criterion: test SKILL.md contains criterion-to-test mapping instructions
# and goals.md checkbox update instructions.

# M24 — test SKILL.md contains criterion-to-test mapping
@test "[M24] test SKILL.md contains criterion-to-test mapping instructions" {
  # AC: each acceptance criterion must map to at least one test; the SKILL.md must
  # instruct the test-writer to build this mapping
  local skill_file="$SKILLS_DIR/test/SKILL.md"
  [ -f "$skill_file" ]
  grep -q "criterion\|acceptance criteria" "$skill_file"
  # Must reference the traceability/mapping from criteria to tests
  grep -qi "maps to\|map.*to.*test\|criterion.*test\|coverage" "$skill_file"
}

# M24 — test SKILL.md contains goals.md checkbox update instructions
@test "[M24] test SKILL.md contains goals.md checkbox update instructions" {
  # AC: after tests pass, the test skill must update goals.md checkboxes
  # (- [ ] → - [x]) for passing criteria
  local skill_file="$SKILLS_DIR/test/SKILL.md"
  grep -q "checkbox\|\[ \].*\[x\]\|\[x\].*checkbox\|goals\.md.*check" "$skill_file"
}

# M24 — test SKILL.md contains coverage table or analysis section
@test "[M24] test SKILL.md contains coverage table or coverage analysis section" {
  # AC: the test-writer must produce a coverage analysis; the SKILL.md must instruct this
  local skill_file="$SKILLS_DIR/test/SKILL.md"
  grep -qi "coverage\|Coverage" "$skill_file"
}

# ── M25: Artifact management ──────────────────────────────────────────────────
# Criterion: Replan SKILL.md contains archive/promote workflow, phases/phase-NN
# archive path, future-goals.md promotion.

# M25 — Replan SKILL.md contains artifact_snapshot_phase function reference
@test "[M25] replan SKILL.md contains artifact_snapshot_phase for phase archiving" {
  # AC: completed phases must be archived before promoting to next phase
  local skill_file="$SKILLS_DIR/replan/SKILL.md"
  grep -q "artifact_snapshot_phase\|snapshot.*phase\|phase.*snapshot" "$skill_file"
}

# M25 — Replan SKILL.md contains artifact_promote_next_phase function reference
@test "[M25] replan SKILL.md contains artifact_promote_next_phase for next-phase setup" {
  # AC: after archiving, the next phase is set up by promoting artifacts
  local skill_file="$SKILLS_DIR/replan/SKILL.md"
  grep -q "artifact_promote_next_phase\|promote.*next.*phase" "$skill_file"
}

# M25 — Replan SKILL.md references phases/phase-NN archive path
@test "[M25] replan SKILL.md references phases/phase-NN archive directory" {
  # AC: archived artifacts go under phases/phase-NN/ — the skill must specify this path
  local skill_file="$SKILLS_DIR/replan/SKILL.md"
  grep -q "phases/phase-" "$skill_file"
}

# M25 — Replan SKILL.md references future-goals.md for goal promotion
@test "[M25] replan SKILL.md references future-goals.md for goal promotion across phases" {
  # AC: goals promoted to the next phase come from future-goals.md; Replan must handle this
  local skill_file="$SKILLS_DIR/replan/SKILL.md"
  grep -q "future-goals.md\|future-goals" "$skill_file"
}

# ── M26: Skill prompt improvements (D1, D2, D3 + selected observations) ──────
# Criterion: Behavioral directives D1, D2, D3 applied across multiple skills;
# specific observation fixes applied to designated skills.

# M26 — D1 (encourage reviews after changes) appears across multiple skills
@test "[M26][D1] D1 directive (encourage reviews after changes) is in replan SKILL.md" {
  local skill_file="$SKILLS_DIR/replan/SKILL.md"
  grep -q "D1\|Encourage reviews after changes\|reviews after changes" "$skill_file"
}

@test "[M26][D1] D1 directive is in using-qrspi SKILL.md" {
  local skill_file="$SKILLS_DIR/using-qrspi/SKILL.md"
  grep -q "D1\|Encourage reviews after changes\|reviews after changes" "$skill_file"
}

@test "[M26][D1] D1 directive is in questions SKILL.md" {
  local skill_file="$SKILLS_DIR/questions/SKILL.md"
  grep -q "D1\|Encourage reviews after changes\|reviews after changes" "$skill_file"
}

# M26 — D2 (never suggest skipping steps) consolidated into using-qrspi.
# Per-skill copies were cut as R1-redundant during the skill refactor; the
# using-qrspi assertion below is the canonical check.
@test "[M26][D2] D2 directive is in using-qrspi SKILL.md" {
  local skill_file="$SKILLS_DIR/using-qrspi/SKILL.md"
  grep -q "D2\|Never suggest skipping\|skipping steps" "$skill_file"
}

# M26 — D3 (no time crunch reassurance) appears across multiple skills
@test "[M26][D3] D3 directive (no time crunch) is in replan SKILL.md" {
  local skill_file="$SKILLS_DIR/replan/SKILL.md"
  grep -q "D3\|time crunch\|no time crunch\|time.*pressure\|urgency" "$skill_file"
}

@test "[M26][D3] D3 directive is in using-qrspi SKILL.md" {
  local skill_file="$SKILLS_DIR/using-qrspi/SKILL.md"
  grep -q "D3\|time crunch\|no time crunch\|time.*pressure\|urgency" "$skill_file"
}

@test "[M26][D3] D3 directive is in questions SKILL.md" {
  local skill_file="$SKILLS_DIR/questions/SKILL.md"
  grep -q "D3\|time crunch\|no time crunch\|time.*pressure\|urgency" "$skill_file"
}

# M26 — Obs 1 (post-feedback options) in using-qrspi SKILL.md
# Obs 1 concern: after feedback, user should have options (not just auto-review).
# Implementation: rejection behavior + 2-choice review menu + D1 review-after-changes.
@test "[M26][Obs1] using-qrspi SKILL.md has post-feedback options (review choice + rejection cycle)" {
  local skill_file="$SKILLS_DIR/using-qrspi/SKILL.md"
  # Must have the review choice menu (Present or Loop)
  grep -q "Present for review.*Loop until clean" "$skill_file"
  # Must have rejection behavior (user can give more feedback by rejecting)
  grep -q "Rejection Behavior\|user rejects.*feedback" "$skill_file"
}

# M26 — Obs 3 (one-word naming convention) was cut as R1 meta-prose during
# the skill refactor (orchestrator doesn't act on it during a run). Test
# removed; convention persists informally across the codebase by example.

# M26 — Obs 5 (review time allocation) in using-qrspi SKILL.md
@test "[M26][Obs5] using-qrspi SKILL.md has review time allocation guidance" {
  # AC: Obs 5 — guide users on where to invest review time (Design/Structure vs Plan)
  local skill_file="$SKILLS_DIR/using-qrspi/SKILL.md"
  grep -q "Review Time\|review time\|invest.*review\|where to.*review" "$skill_file"
}

# M26 — Obs 9 (Mermaid to files) in design SKILL.md
@test "[M26][Obs9] design SKILL.md references Mermaid system diagram" {
  # AC: Obs 9 — Mermaid diagrams must be written to files, not just output inline
  local skill_file="$SKILLS_DIR/design/SKILL.md"
  grep -q "Mermaid\|mermaid" "$skill_file"
}

# M26 — Obs 27 (questions presents full content) in questions SKILL.md
@test "[M26][Obs27] questions SKILL.md instructs presenting full questions.md content at human gate" {
  # AC: Obs 27 — human gate must show full content, not summary or headers
  local skill_file="$SKILLS_DIR/questions/SKILL.md"
  grep -q "full content\|every question\|verbatim\|full.*questions\.md" "$skill_file"
}

# M26 — Obs 14 (test pause for code review) in test SKILL.md
@test "[M26][Obs14] test SKILL.md contains code review checkpoint before PR creation" {
  # AC: Obs 14 — after tests pass, Test should pause to allow code review
  local skill_file="$SKILLS_DIR/test/SKILL.md"
  grep -qi "code review\|Code Review\|review.*code.*PR\|PR.*review" "$skill_file"
}

# M26 — Obs 19 (heavy commenting directive) was intentionally removed during
# the skill refactor — it contradicts global CLAUDE.md "default to no comments"
# guidance. Test removed (the directive shouldn't be reintroduced).

# M26 — Obs 10 (TodoWrite per parallel group) in implement SKILL.md
@test "[M26][Obs10] implement SKILL.md references batch gate before parallel dispatch" {
  # AC: Obs 10 — TodoWrite / task tracking should be set up per parallel group
  local skill_file="$SKILLS_DIR/implement/SKILL.md"
  grep -qi "TodoWrite\|batch.*gate\|batch gate\|parallel.*group\|dispatch" "$skill_file"
}

# M26 — Obs 12 (conditional batch gate) in implement SKILL.md
@test "[M26][Obs12] implement SKILL.md has batch gate concept for dispatch" {
  # AC: Obs 12 — batch gate controls when parallel tasks are dispatched
  local skill_file="$SKILLS_DIR/implement/SKILL.md"
  grep -qi "batch\|parallelization plan\|dispatch" "$skill_file"
}

# M26 — Obs 8 (numbered multiple choice) across all skills that present user options
# Skills that present configuration or decision choices must use numbered options.
@test "[M26][Obs8] All skills with human gates use numbered options for user choices" {
  # AC: Obs 8 — when presenting choices to user, use numbered format (1) / 2) etc.)
  # Every skill that has a human gate should have at least one numbered option pattern.
  local skills_with_gates=(
    "design" "goals" "implement" "integrate" "parallelize" "plan" "questions"
    "replan" "research" "structure" "test" "using-qrspi"
  )
  for skill in "${skills_with_gates[@]}"; do
    local skill_file="$SKILLS_DIR/$skill/SKILL.md"
    [ -f "$skill_file" ]
    # Must contain at least one numbered option pattern (N) or N.)
    grep -qE "[1-9]\)" "$skill_file"
  done
}

# M26 — Obs 13 (compaction reminders) across all skills with terminal states
# Skills that complete and invoke the next skill should remind user to compact.
@test "[M26][Obs13] All skills with terminal states have compaction reminders" {
  # AC: Obs 13 — after completing a skill step, remind user to compact context
  local skills_with_terminal=(
    "design" "goals" "implement" "integrate" "parallelize" "plan" "questions"
    "replan" "research" "structure" "test"
  )
  for skill in "${skills_with_terminal[@]}"; do
    local skill_file="$SKILLS_DIR/$skill/SKILL.md"
    [ -f "$skill_file" ]
    # Must mention compaction somewhere
    grep -qi "compact" "$skill_file"
  done
}

# ── M27: Self-healing relocation ──────────────────────────────────────────────
# Criterion: validate functions NOT in hooks/lib/validate.sh (file absent or empty).
# using-qrspi SKILL.md references validation at pipeline start.

# M27 — validate.sh does not exist (removed in Phase 4)
@test "[M27] hooks/lib/validate.sh does not exist (validate functions relocated)" {
  # AC: M27 required moving validate functions out of validate.sh;
  # the file should no longer exist (or be empty if it remains as a stub)
  local validate_lib="$HOOKS_DIR/lib/validate.sh"
  # Either file doesn't exist, or it exists but is empty/near-empty
  if [ -f "$validate_lib" ]; then
    local size
    size=$(wc -c < "$validate_lib")
    # If the file exists, it must be effectively empty (comments only, no function definitions)
    run grep "^[a-z_][a-z_]*()" "$validate_lib"
    [ "$status" -ne 0 ]
  else
    # File doesn't exist — the expected state
    [ ! -f "$validate_lib" ]
  fi
}

# M27 — using-qrspi SKILL.md references validation at pipeline start
@test "[M27] using-qrspi SKILL.md references validation checks at pipeline entry" {
  # AC: M27 moved validation to pipeline entry point; using-qrspi must instruct
  # running validation before checking artifact status
  local skill_file="$SKILLS_DIR/using-qrspi/SKILL.md"
  grep -q "validation\|Validation\|validate\|schema validation" "$skill_file"
}

# ── M28: Phase learnings capture ──────────────────────────────────────────────
# Criterion: test and integrate SKILL.md contain prompts for phase learnings,
# future-goals.md references.

# M28 — test SKILL.md references phase routing / phase completion
@test "[M28] test SKILL.md contains phase routing or completion references" {
  # AC: Test drives phase progression; it must prompt for capturing learnings
  local skill_file="$SKILLS_DIR/test/SKILL.md"
  grep -q "phase\|Replan\|replan" "$skill_file"
}

# M28 — replan SKILL.md references future-goals.md for ideas capture
@test "[M28] replan SKILL.md references future-goals.md for capturing phase learnings" {
  # AC: phase learnings (ideas for future phases) go into future-goals.md
  local skill_file="$SKILLS_DIR/replan/SKILL.md"
  grep -q "future-goals\|future-goals\.md" "$skill_file"
}

# M28 — integrate SKILL.md exists (required artifact for this goal)
@test "[M28] integrate SKILL.md exists" {
  # AC: integrate skill must exist; M28 requires it to have phase learnings prompts
  local skill_file="$SKILLS_DIR/integrate/SKILL.md"
  [ -f "$skill_file" ]
}

# ── M29: Amendment classification ────────────────────────────────────────────
# Criterion: using-qrspi or design SKILL.md contains three-tier amendment
# classification (clarifying, additive, architectural).

# M29 — Replan SKILL.md contains three-tier amendment classification
@test "[M29] replan SKILL.md has three-tier amendment classification (clarifying, additive, architectural)" {
  # AC: amendments must be classified before applying; replan contains the full procedure
  local skill_file="$SKILLS_DIR/replan/SKILL.md"
  grep -qi "clarifying\|Clarifying" "$skill_file"
  grep -qi "additive\|Additive" "$skill_file"
  grep -qi "architectural\|Architectural" "$skill_file"
}

# M29 — Amendment classification table covers cascade behavior
@test "[M29] replan SKILL.md clarifying/additive amendments have --skip-cascade behavior" {
  # AC: clarifying and additive amendments do not cascade; only architectural does
  local skill_file="$SKILLS_DIR/replan/SKILL.md"
  grep -q "skip.cascade\|skip-cascade\|no downstream reset\|no.*cascade" "$skill_file"
}

# ── M32: REMOVED ─────────────────────────────────────────────────────────────
# The per-worktree `.claude/settings.json` mechanism was removed in the
# 2026-04-26 implement-runtime-fix. Subagent containment is now enforced by
# the QRSPI pre-tool-use hook (target-based asymmetric model). The Implement
# skill no longer writes per-worktree settings files. M32 tests deleted.

# ── M33: Plan-level architectural review ─────────────────────────────────────
# Criterion: Plan SKILL.md contains architectural review round.

# M33 — plan SKILL.md contains review round using reviewer templates
@test "[M33] plan SKILL.md contains review round using reviewer subagents" {
  # AC: Plan must include a review round to catch architectural inconsistencies
  # before task specs are written
  local skill_file="$SKILLS_DIR/plan/SKILL.md"
  grep -q "review\|Review" "$skill_file"
  # Must reference Claude review subagent
  grep -q "review subagent\|Claude review\|Review round" "$skill_file"
}

# ── M34: Amendment-to-goal mapping validation ────────────────────────────────
# Criterion: Replan SKILL.md contains the rule "Never map an amendment to a goal
# whose criterion text doesn't describe it".

# M34 — replan SKILL.md contains amendment-to-goal mapping validation rule
@test "[M34] replan SKILL.md contains rule against mapping amendments to non-covering goals" {
  # AC: the exact rule or equivalent must appear; prevents goal text inflation
  local skill_file="$SKILLS_DIR/replan/SKILL.md"
  grep -q "Never map an amendment\|never map.*amendment\|criterion text.*describe" "$skill_file"
}

# ── M35: Goal-text decomposition check ───────────────────────────────────────
# Criterion: goal-traceability-reviewer.md contains decomposition check criterion.

# M35 — goal-traceability-reviewer.md exists
@test "[M35] goal-traceability-reviewer.md template exists in implement/templates/thoroughness/" {
  # AC: the template must exist for test SKILL.md to reference it in review
  local template_file="$SKILLS_DIR/implement/templates/thoroughness/goal-traceability-reviewer.md"
  [ -f "$template_file" ]
}

# M35 — goal-traceability-reviewer.md contains traceability analysis sections
@test "[M35] goal-traceability-reviewer.md has forward and backward trace sections" {
  # AC: decomposition check means verifying each goal traces to tests and back
  local template_file="$SKILLS_DIR/implement/templates/thoroughness/goal-traceability-reviewer.md"
  grep -q "Forward Trace\|Backward Trace\|Gap Analysis" "$template_file"
}

# M35 — goal-traceability-reviewer.md has UNCOVERED_CRITERION gap type
@test "[M35] goal-traceability-reviewer.md defines UNCOVERED_CRITERION gap type" {
  # AC: the decomposition check must identify goals that have no test coverage
  local template_file="$SKILLS_DIR/implement/templates/thoroughness/goal-traceability-reviewer.md"
  grep -q "UNCOVERED_CRITERION\|uncovered.*criterion\|criterion.*uncovered" "$template_file"
}

# ── M36: Amendment compression rule ──────────────────────────────────────────
# Criterion: Design SKILL.md contains rule against bare-number compression.

# M36 — design SKILL.md contains rule against bare-number compression in amendments
@test "[M36] design SKILL.md contains rule against bare-number compression in amendments" {
  # AC: "5/8/10 -> U1" style compression is banned when goal text doesn't cover all items
  local skill_file="$SKILLS_DIR/design/SKILL.md"
  grep -q "bare.number compression\|bare-number compression\|compression\|Never use bare" "$skill_file"
}

# ── M37: Phase-scoped artifact rules ─────────────────────────────────────────
# Criterion: Design, Structure, and Plan SKILL.md contain current-phase-only rules.
# Design entries keyed by ### {GOAL_ID}.

# M37 — design SKILL.md contains current-phase-only content rule
@test "[M37] design SKILL.md has Phase-Scoped Content Rules section" {
  # AC: design.md must only contain current-phase entries
  local skill_file="$SKILLS_DIR/design/SKILL.md"
  grep -q "Phase-Scoped\|phase-scoped\|current.*phase.*only\|ONLY current" "$skill_file"
}

# M37 — design SKILL.md requires entries keyed by ### {GOAL_ID}
@test "[M37] design SKILL.md requires entries keyed by ### {GOAL_ID}" {
  # AC: each design section must be traceable to a goal ID
  local skill_file="$SKILLS_DIR/design/SKILL.md"
  grep -q "GOAL_ID\|{GOAL_ID}" "$skill_file"
}

# M37 — structure SKILL.md contains current-phase-only content rule
@test "[M37] structure SKILL.md has Phase-Scoped Content Rules section" {
  # AC: structure.md must only contain current-phase file maps and interfaces
  local skill_file="$SKILLS_DIR/structure/SKILL.md"
  grep -q "Phase-Scoped\|phase-scoped\|current.*phase.*only\|ONLY current" "$skill_file"
}

# M37 — plan SKILL.md contains current-phase-only content rule
@test "[M37] plan SKILL.md has Phase-Scoped Content Rules section" {
  # AC: plan.md must only contain current-phase tasks
  local skill_file="$SKILLS_DIR/plan/SKILL.md"
  grep -q "Phase-Scoped\|phase-scoped\|current.*phase.*only\|ONLY current" "$skill_file"
}

# ── M38: Roadmap artifact rules ───────────────────────────────────────────────
# Criterion: Design SKILL.md contains roadmap.md creation/maintenance rules,
# pure assignment table description.

# M38 — design SKILL.md contains roadmap.md maintenance rules
@test "[M38] design SKILL.md contains roadmap.md creation/maintenance rules" {
  # AC: roadmap.md is the phase-to-goal assignment table; Design is responsible for it
  local skill_file="$SKILLS_DIR/design/SKILL.md"
  grep -q "roadmap\|Roadmap\|roadmap\.md" "$skill_file"
}

# M38 — design SKILL.md describes roadmap as pure assignment table
@test "[M38] design SKILL.md describes roadmap as a pure goal-to-phase assignment table" {
  # AC: roadmap contains ONLY goal ID, phase, slice columns — no design content
  local skill_file="$SKILLS_DIR/design/SKILL.md"
  grep -q "goal ID.*phase\|phase.*slice.*column\|only.*goal ID\|pure.*assignment\|assignment table\|ONLY goal" "$skill_file"
}

# ── M40: Goal specificity rule ────────────────────────────────────────────────
# Criterion: Goals SKILL.md contains independently-scopeable goals rule
# and late splitting guidance.

# M40 — goals SKILL.md or using-qrspi SKILL.md contains independently-scopeable rule
@test "[M40] using-qrspi SKILL.md contains scope check / decomposition guidance for large goals" {
  # AC: goals must be independently scopeable; if scope is too large, decompose
  local skill_file="$SKILLS_DIR/using-qrspi/SKILL.md"
  grep -q "Scope check\|scope check\|decompos\|independent.*subsystem\|multiple independent" "$skill_file"
}

# M40 — goals SKILL.md contains scope check guidance
@test "[M40] goals SKILL.md contains scope check step to detect over-large goals" {
  # AC: the Goals skill must detect when scope is too large and suggest decomposition
  local skill_file="$SKILLS_DIR/goals/SKILL.md"
  grep -q "Scope check\|scope check\|too large\|decomposition\|multiple independent" "$skill_file"
}

# ── F-2: Sub-skill bootstrap precondition ────────────────────────────────────
# Criterion: every QRSPI sub-skill SKILL.md contains a PRECONDITION line
# pointing at using-qrspi, so direct invocation (mid-pipeline resume,
# debugging, recovery) doesn't silently miss the master rules.

@test "[F-2] All QRSPI sub-skills have PRECONDITION line invoking using-qrspi" {
  # AC: F-2 — direct sub-skill invocation must bootstrap using-qrspi
  local sub_skills=(
    "goals" "questions" "research" "design" "structure" "plan"
    "parallelize" "implement" "integrate" "test" "replan"
  )
  for skill in "${sub_skills[@]}"; do
    local skill_file="$SKILLS_DIR/$skill/SKILL.md"
    [ -f "$skill_file" ]
    grep -q "PRECONDITION.*using-qrspi" "$skill_file"
  done
}

# ── F-4: REJECTED git pre-flight + replacement: conditional commit guidance ──
# F-4 in the 2026-04-26 findings doc proposed Goals verify PWD is a git repo
# and offer to `git init` it. REJECTED — the workspace (CWD) is intentionally
# NOT a git repo per user policy. Only code projects and per-task worktrees
# are git-managed; QRSPI artifacts under docs/qrspi/{slug}/ are working state,
# not source. A git pre-flight at workspace level would either falsely-flag
# or produce data loss via nested git repos.
#
# Replacement (applied in this commit): the "commit after approval" guidance
# in every pre-Plan terminal-state has been made CONDITIONAL on whether the
# artifact directory is inside a git repo (walk up from artifact_dir, NOT
# CWD). The canonical rule lives in using-qrspi → "Commit after approval
# (conditional)"; per-skill terminal states reference it. Tests below pin
# the canonical rule + per-skill conditional language so the conditional
# can't silently drift back to unconditional "commit to git" guidance.

@test "[F-4-replacement] using-qrspi SKILL.md has conditional 'Commit after approval' rule" {
  # AC: canonical rule must mention git-repo conditional + walking up from
  # artifact_dir (not CWD) — the two ways this rule can silently regress.
  local skill_file="$SKILLS_DIR/using-qrspi/SKILL.md"
  grep -q "Commit after approval (conditional)" "$skill_file"
  grep -q "artifact_dir.*rev-parse\|rev-parse.*--show-toplevel" "$skill_file"
  grep -q "NOT.*CWD\|not.*from CWD\|NOT from CWD" "$skill_file"
}

@test "[F-4-replacement] all pre-Plan terminal states reference the conditional commit rule" {
  # AC: every skill that committed artifacts unconditionally before this fix
  # must now defer to the canonical conditional rule. Pre-Plan only — Implement
  # / Integrate / Test / Replan / Parallelize commit inside code worktrees,
  # which are always git, so unconditional language there is correct.
  local pre_plan=("goals" "questions" "research" "design" "structure" "plan")
  for skill in "${pre_plan[@]}"; do
    local skill_file="$SKILLS_DIR/$skill/SKILL.md"
    [ -f "$skill_file" ]
    grep -q "if the artifact directory is inside a git repository" "$skill_file"
  done
}

# ── F-5: Fix-altitude rule in Standard Review Loop ───────────────────────────
# Criterion: using-qrspi SKILL.md documents the fix-altitude rule so review
# loops don't self-induce churn by pulling next-step content into the current
# artifact (R7-R10 anti-pattern at artifact level).

@test "[F-5] using-qrspi SKILL.md contains fix-altitude rule" {
  # AC: F-5 — review loops must prefer minimal additions at the current altitude
  local skill_file="$SKILLS_DIR/using-qrspi/SKILL.md"
  grep -q "Fix-altitude\|fix-altitude\|altitude rule\|next pipeline step" "$skill_file"
}

# ── F-14: Branch model uses qrspi/{slug}/main (sibling-with-tasks naming) ────
# Criterion: feature branch is `qrspi/{slug}/main`, not bare `qrspi/{slug}`,
# so it can coexist with task branches `qrspi/{slug}/task-NN` under the
# `qrspi/{slug}/` namespace. Bare `qrspi/{slug}` would deadlock the very
# first task-branch creation with `fatal: cannot lock ref ...`.

@test "[F-14] parallelize SKILL.md uses qrspi/{slug}/main for feature branch" {
  # AC: F-14 — feature branch must be /main suffix to coexist with task branches
  local skill_file="$SKILLS_DIR/parallelize/SKILL.md"
  grep -q "qrspi/{slug}/main" "$skill_file"
}

@test "[F-14] implement SKILL.md uses qrspi/{slug}/main for feature branch" {
  local skill_file="$SKILLS_DIR/implement/SKILL.md"
  grep -q "qrspi/{slug}/main" "$skill_file"
}

@test "[F-14] no bare qrspi/{slug} references remain in skills (would deadlock task creation)" {
  # AC: F-14 — bare `qrspi/{slug}` (not followed by /) is git-incompatible
  # because it cannot coexist with `qrspi/{slug}/task-NN` namespace siblings.
  # Scan covers SKILLS_DIR recursively (templates/, references/, examples).
  # Two checks:
  #   (1) literal placeholder `qrspi/{slug}` not followed by `/`
  #   (2) bare concrete branch refs (e.g. `qrspi/user-auth`) used as full branch
  #       names in markdown — i.e. NOT preceded by `-` (which would make it
  #       part of `using-qrspi/...` file paths) AND NOT followed by `/`.
  local placeholder_matches concrete_matches
  placeholder_matches=$(grep -rn "qrspi/{slug}" "$SKILLS_DIR/" 2>/dev/null | grep -v "qrspi/{slug}/" || true)
  if [[ -n "$placeholder_matches" ]]; then
    echo "Found bare qrspi/{slug} placeholder references (not followed by /) — F-14 regression:"
    echo "$placeholder_matches"
    return 1
  fi
  # Concrete bare refs: `qrspi/<word>` preceded by whitespace, backtick, or
  # line start (not preceded by `-`, which excludes `using-qrspi/...` paths)
  # and followed by something OTHER than `/` (whitespace, backtick, EOL, etc.).
  # Use ERE; `(^|[ \t\`])` anchors the prefix and `($|[^A-Za-z0-9_/-])` the suffix.
  concrete_matches=$(grep -rnE "(^|[[:space:]\`])qrspi/[A-Za-z][A-Za-z0-9_-]*($|[^A-Za-z0-9_/-])" "$SKILLS_DIR/" 2>/dev/null || true)
  if [[ -n "$concrete_matches" ]]; then
    echo "Found bare concrete qrspi/<name> references (without trailing /) — F-14 regression:"
    echo "$concrete_matches"
    return 1
  fi
}

@test "[F-14] feature + task branches can coexist as siblings under namespace (live git integration)" {
  # AC: F-14 — live integration test that the documented naming actually works
  # in git. Creates a temp repo, makes the feature branch, then attempts to
  # create a task branch as a sibling. Both must coexist.
  LIVE_GIT_TMPDIR=$(mktemp -d)
  cd "$LIVE_GIT_TMPDIR"
  git init -q
  git config user.email "test@test"
  git config user.name "test"
  git commit --allow-empty -q -m "initial"
  git branch "qrspi/myslug/main"
  run git branch "qrspi/myslug/task-01"
  [ "$status" -eq 0 ]
  # Both branches must exist
  run git rev-parse --verify "qrspi/myslug/main"
  [ "$status" -eq 0 ]
  run git rev-parse --verify "qrspi/myslug/task-01"
  [ "$status" -eq 0 ]
}

# ── F-17: Per-task orchestrator commit-message file path ─────────────────────
# Criterion: per-task-orchestrator template instructs subagents to use a
# worktree-internal commit-message file (not /tmp/...), since the asymmetric
# hook walls subagents out of /tmp.

@test "[F-17] per-task-orchestrator template warns against /tmp commit-message paths" {
  # AC: F-17 — template must guide subagents to worktree-internal paths
  local template_file="$SKILLS_DIR/implement/templates/per-task-orchestrator.md"
  grep -q "F-17" "$template_file"
  grep -q ".qrspi-commit-msg.txt\|worktree-internal" "$template_file"
}

@test "[F-14] bare qrspi/{slug} branch + task branch demonstrably deadlock (regression evidence)" {
  # AC: F-14 — pin the failure mode so future maintainers can't reintroduce
  # the bare naming without seeing exactly why it doesn't work.
  LIVE_GIT_TMPDIR=$(mktemp -d)
  cd "$LIVE_GIT_TMPDIR"
  git init -q
  git config user.email "test@test"
  git config user.name "test"
  git commit --allow-empty -q -m "initial"
  git branch "qrspi/myslug"
  # This MUST fail because qrspi/myslug is a leaf ref blocking the namespace
  run git branch "qrspi/myslug/task-01"
  [ "$status" -ne 0 ]
  [[ "$output" == *"cannot lock"* ]] || [[ "$output" == *"exists"* ]]
}
