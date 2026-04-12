---
name: using-qrspi
description: Use when starting any conversation — establishes the QRSPI pipeline for agentic software development, requiring structured progression through Goals, Questions, Research, Design, Structure, Plan, Worktree, Implement, Integrate, Test
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill entirely. Do not start a new QRSPI pipeline — just do your assigned work.
</SUBAGENT-STOP>

# Using QRSPI

## Overview

QRSPI is a pipeline for agentic software development with two route variants (quick fix and full). Each step produces a reviewable artifact, gets human approval, then invokes the next step. Most steps run as subagents for guaranteed clean context. Goals and Design run interactively in the main conversation with subagent synthesis.

**Core principles:**
- **Do not outsource the thinking.** Every phase produces a reviewable artifact (~200 lines, not ~2000 lines of code).
- **Context engineering is the only lever.** Each phase runs in a fresh subagent with only its declared inputs.
- **Structural enforcement over instructional discipline.** Constraints enforced architecturally where possible.

## The Pipeline

**Full pipeline:**
```
Goals → Questions → Research → Design → Structure → Plan → Worktree → Implement → Integrate → Test → Replan (if needed)
```

**Quick Fix pipeline** (skip Design/Structure/Worktree/Integrate):
```
Goals → Questions → Research → Plan → Implement → Test
```

| Step | # | What it does | Artifact |
|------|---|-------------|----------|
| **Goals** | 1 | Capture user intent, constraints, acceptance criteria | `goals.md` |
| **Questions** | 2 | Generate tagged research questions (no goal leakage) | `questions.md` |
| **Research** | 3 | Parallel specialist agents gather objective facts | `research/summary.md` |
| **Design** | 4 | Interactive design discussion, vertical slicing, phasing | `design.md` |
| **Structure** | 5 | Map design to files, interfaces, component boundaries | `structure.md` |
| **Plan** | 6 | Detailed task specs with test expectations | `plan.md` + `tasks/*.md` |
| **Worktree** | 7 | Analyze parallelization, create worktrees, dispatch | `parallelization.md` |
| **Implement** | 8 | TDD execution per task, tiered review loops | Working code |
| **Integrate** | 8.5 | Merge worktrees, cross-task integration + security review, CI gate | Integration report |
| **Test** | 9 | Acceptance testing, PR creation, phase routing | Test results + PR (every phase) |
| **Replan** | 9.5 | Between phases — update remaining tasks based on learnings | Updated `plan.md` + `tasks/*.md` |

> **Availability:** Steps 1-9.5 are implemented (Goals through Replan). All pipeline steps are available.

## Route Templates

When the user selects a pipeline mode, write the route into `config.md` (see Config File section below). Use one of these templates:

**Quick Fix route:**
```yaml
route:
  - goals
  - questions
  - research
  - plan
  - implement
  - test
```

**Full pipeline route:**
```yaml
route:
  - goals
  - questions
  - research
  - design
  - structure
  - plan
  - worktree
  - implement
  - integrate
  - test
```

**Full + UX (adds wireframing before Structure):**
```yaml
route:
  - goals
  - questions
  - research
  - design
  - ux
  - structure
  - plan
  - worktree
  - implement
  - integrate
  - test
```

> **Note:** Replan (step 9.5) is NOT included in any route list. It is invoked by Test when more phases remain in the design, not when Test fails. Test handles final-phase completion (PR creation) directly.

### Mid-Pipeline Route Change

Route changes are only allowed before Plan executes:

- **Full → Quick Fix:** Allowed only before Plan. Drop Design, Structure, Worktree, Integrate from the route. Update `config.md`.
- **Quick Fix → Full:** Allowed only before Plan. Insert Design, Structure before Plan, and Worktree, Integrate after Plan. Update `config.md`.
- **Add/remove UX step:** Allowed only before Structure. Insert or remove `ux` between `design` and `structure`. Update `config.md`.

After Plan is approved, the route is locked. Route changes after that point require a backward loop to re-run Plan.

## When to Trigger

Any time the user wants to build something — a feature, a fix, a project. If there's intent to write code, QRSPI applies. Default is always start with Goals and proceed through every step.

## Artifact Directory

Each QRSPI run creates an artifact directory. All paths are relative to the **project root** (the repository where QRSPI is being used, NOT the plugin install directory):

```
docs/qrspi/YYYY-MM-DD-{slug}/
├── config.md
├── goals.md
├── questions.md
├── research/
│   ├── summary.md
│   ├── q01-codebase.md
│   └── ...
├── design.md
├── structure.md
├── plan.md
├── parallelization.md
├── tasks/
│   ├── task-01.md
│   └── ...
├── fixes/
│   ├── integration-round-01/
│   ├── ci-round-01/
│   └── test-round-01/
├── feedback/
│   └── ...
├── reviews/
│   ├── goals-review.md
│   ├── questions-review.md
│   ├── research-review.md
│   ├── design-review.md
│   ├── structure-review.md
│   ├── plan-review.md
│   ├── replan-review.md
│   ├── baseline-failures.md       (Worktree baseline)
│   ├── tasks/
│   │   └── ...
│   ├── integration/
│   │   └── round-NN-review.md
│   ├── ci/
│   │   └── round-NN-review.md
│   └── test/
│       ├── round-NN-review.md
│       └── baseline-failures.md   (Test baseline)
└── .qrspi/                        (hook-managed, do not edit manually)
    ├── state.json                 (pipeline state cache)
    ├── task-NN-runtime.json       (per-task runtime overrides — user mid-task decisions)
    └── audit-task-NN.jsonl        (per-task audit logs)
```

The slug is generated during the Goals step: take the user's first description, extract 2-4 key words, convert to lowercase kebab-case (e.g., "user-auth", "product-search-api").

**Skill name convention:** All QRSPI skill names follow a one-word convention. When proposing new skills, use a single lowercase word (e.g., `align`, `drift`, `audit`). Multi-word names (`goal-alignment`, `prompt-audit`) are not accepted.

## Artifact Gating

Each skill checks that its required input artifacts exist on disk before proceeding:
- **Goals**: No prerequisites (first step)
- **Questions**: Requires `goals.md` with `status: approved`
- **Research**: Requires `questions.md` with `status: approved`
- **Design**: Requires `goals.md` and `research/summary.md` with `status: approved`
- **Structure**: Requires `goals.md`, `research/summary.md`, and `design.md` with `status: approved`
- **Plan**: Full pipeline requires `goals.md`, `research/summary.md`, `design.md`, and `structure.md` with `status: approved`. Quick fix requires only `goals.md` and `research/summary.md`.
- **Worktree**: Requires `plan.md` with `status: approved`, `tasks/*.md`, `design.md` with `status: approved` (phase definitions), and `config.md`
- **Implement**: Full pipeline requires `parallelization.md` with `status: approved`. Quick fix has no Worktree, so no `parallelization.md` — Implement reads the task file's `pipeline` field instead.
- **Integrate**: Requires all task review files in `reviews/tasks/`, `design.md` with `status: approved`, `structure.md` with `status: approved`, `parallelization.md` with `status: approved` (branch map), and `config.md` (for route)
- **Test**: Requires `goals.md` with `status: approved`, `design.md` with `status: approved` (full pipeline) or `research/summary.md` with `status: approved` (quick fix), `fixes/` directory (for regression tests), codebase with implementation merged
- **Replan**: Requires completed phase code (merged), `fixes/` and `reviews/` directories, remaining `tasks/*.md`, `plan.md` with `status: approved`, and `design.md` with `status: approved`

If a required artifact is missing, the skill refuses to run and tells the user which artifact is needed.

## Approval Markers

When the user approves an artifact, the skill writes `status: approved` in the artifact's YAML frontmatter:

```yaml
---
status: approved
---
```

**Status values:** `draft` (initial), `approved` (user-approved), `replan-draft` (transient — used during Replan's minor path re-approval cycle; artifact gating treats this the same as `draft`, so downstream skills correctly refuse to proceed until re-approval completes).

**Writing `status: approved` is sufficient.** The PostToolUse hook detects the frontmatter change and updates `state.json` automatically. Skills do not need to perform any explicit state update after writing the approval marker.

**Commit after approval.** Every approved artifact (and its review file) should be committed to git immediately after the approval marker is written. This preserves the approved state as a checkpoint the user can return to. Use a descriptive commit message like `docs(qrspi): approve {step} for {project-slug}`. Do not batch approvals across steps — commit each step's approval separately.

## Hook-Managed State (`.qrspi/`)

The `.qrspi/` directory inside each artifact directory is created and maintained entirely by hooks:

- **SessionStart hook** — initializes `state.json` at the start of each session by reconciling it against artifact frontmatter on disk (handles interrupted sessions and out-of-sync state)
- **PostToolUse hook** — keeps `state.json` in sync whenever an artifact's frontmatter changes

Skills do not need to create, read, or update any file in `.qrspi/`. State is always current when a skill needs it because the hooks maintain it continuously.

**Pipeline enforcement:** PreToolUse hooks enforce pipeline step ordering. Attempting to write a downstream artifact (e.g., `design.md`) before its prerequisites are approved will be blocked by the hook. Pipeline progression is code-enforced, not just prompt-enforced.

## Rejection Behavior

When the user rejects an artifact at any human gate, they provide feedback. A new subagent round is launched with the original inputs + a feedback file containing the rejected artifact and the user's feedback. Rejection never skips steps or moves backward — it re-runs the current step with feedback until approved.

## Backward Loops (New Learnings)

When a later step surfaces new requirements or contradictions — e.g., Figma wireframes reviewed during Structure reveal missing features, or implementation reveals a design flaw — **do not patch the current artifact in isolation.** Loop backward to the earliest affected artifact and cascade forward:

1. Identify the earliest artifact that needs updating (usually goals.md or design.md)
2. Update that artifact with the new information
3. Run its review round (Claude + Codex if enabled) until clean
4. Present to the user for re-approval
5. Move forward to the next artifact, updating it to reflect the changes
6. Repeat review + approval at each step until you reach the step where the new learning was discovered
7. Resume the original step with consistent, reviewed artifacts

**This is not optional.** Skipping backward loops creates drift between artifacts — goals say one thing, design says another, structure implements a third. Each artifact is a contract that downstream steps depend on. If the contract changes, every dependent must be updated.

**Common triggers for backward loops:**
- User shares wireframes/mockups that reveal new features or UX patterns
- Implementation exposes a design flaw or missing edge case
- Research findings (even informal) invalidate earlier assumptions
- User changes their mind about scope or approach during a later step

## Mid-Pipeline Entry

Users can enter mid-pipeline if they already have artifacts from prior work. As long as the required input files exist with `status: approved`, any step can run. This is an escape hatch, not the default path.

**Run selection for mid-pipeline entry:** When entering mid-pipeline, glob for `docs/qrspi/*/goals.md` directories. If multiple exist, present the list and ask the user which run to resume. Load `config.md` from the chosen directory to read the `route` list. Scan for approved artifacts, then invoke the first step in the route list that is not yet complete.

**Determining the next step:** Iterate through the `route` list in order. The first entry without a corresponding approved artifact is the next step to run. Do not hardcode the sequence — always derive it from `config.md`'s `route` field.

**Replan resume exception:** Replan is not in any route list. Detect the need to resume Replan when: all steps in the `route` list have approved artifacts AND `replan-pending.md` exists in the artifact directory (written by Test before invoking Replan, deleted by Replan before invoking the next step). If `replan-pending.md` exists, invoke Replan to resume. Note: for major changes, Replan deletes the marker and then invokes the loop-back target (Design or Structure) — the normal pipeline resumes from there. If a session is interrupted during the cascade (after Replan exits), the standard mid-pipeline resume logic handles it: it finds the first step in the route without an approved artifact (e.g., Design was reset to draft) and resumes there.

**Run selection for direct skill invocation:** When a skill is invoked directly (not via `using-qrspi`), it must resolve the artifact directory: glob for `docs/qrspi/*/goals.md`, filter to directories containing the skill's required input artifacts, and if multiple match, ask the user which run to use.

## Pipeline Progress

Pipeline task tracking uses a two-phase approach to avoid creating tasks for a route that hasn't been selected yet.

**Phase 1 — Provisional task (this skill):** Before invoking Goals, create a single Level 1 task:

```
[ ] Goals
```

Do not create tasks for any other steps yet. The pipeline mode (and therefore the full route) is not known until Goals runs.

**Phase 2 — Full task list (Goals skill):** After the user selects a pipeline mode and `config.md` is written with the `route` field, the Goals skill rewrites the task list based on `config.md`'s route. The Goals task itself is already `in_progress` at this point; Goals marks it `completed` after approval and then creates the remaining tasks.

**Example — Quick Fix task list (written by Goals after mode selection):**
```
[x] Goals
[ ] Questions
[ ] Research
[ ] Plan
[ ] Implement
[ ] Test
```

**Example — Full pipeline task list (written by Goals after mode selection):**
```
[x] Goals
[ ] Questions
[ ] Research
[ ] Design
[ ] Structure
[ ] Plan
[ ] Worktree
[ ] Implement
[ ] Integrate
[ ] Test
```

Update each task as the pipeline progresses (mark `in_progress` when a step starts, `completed` when approved).

**Mid-pipeline entry:** When a user enters mid-pipeline with pre-existing approved artifacts, read the `route` from `config.md`. Create the full route task list and immediately mark steps with approved artifacts as `completed`. Then invoke the first incomplete step's skill.

## Artifact Gating Check (Standard Pattern)

Every skill uses this standard pattern to verify its prerequisites:

1. Read the required artifact file
2. Parse YAML frontmatter (content between first two `---` markers)
3. Check that `status` field equals `approved`
4. If file missing: "Cannot proceed — {artifact} not found. Complete the {previous step} step first."
5. If file exists but not approved: "Cannot proceed — {artifact} exists but hasn't been approved yet. Review and approve it first."

## Config File (`config.md`)

`config.md` lives in the artifact directory and is written during the Goals skill (after the artifact directory is created). It is the single source of truth for pipeline configuration.

**Full format:**

```yaml
---
created: YYYY-MM-DD
pipeline: full  # or: quick
codex_reviews: true  # or false
route:
  - goals
  - questions
  - research
  - design
  - structure
  - plan
  - worktree
  - implement
  - integrate
  - test
review_depth: deep  # or: quick — added by Worktree/Implement at phase start
review_mode: loop   # or: single — added by Worktree/Implement at phase start
---
```

**Field definitions:**
- `created`: ISO date the run was created (set once, never updated)
- `pipeline`: human-readable label (`full` or `quick`) — informational only; `route` is authoritative
- `codex_reviews`: whether to include Codex in review rounds
- `route`: ordered list of skill names this run will execute (see Route Templates above)
- `review_depth`: `quick` (4 correctness reviewers) or `deep` (all 8 reviewers) — written by Worktree (or Implement in quick-fix mode) at phase start
- `review_mode`: `single` or `loop` — written alongside `review_depth`

**Writing `config.md`:** After the user selects a pipeline mode and answers the Codex question, write `created`, `pipeline`, `codex_reviews`, and `route` to `config.md` atomically. The `review_depth` and `review_mode` fields are added later by Worktree (or Implement in quick-fix mode). Use the appropriate route template from the Route Templates section.

**Codex detection:** Check if `codex:rescue` is available by globbing for `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs`. If the file doesn't exist, skip the Codex question silently and write `codex_reviews: false`. If available, ask:

> Use Codex for second reviews this run? (yes/no)

**No legacy fallback.** All subsequent skills must read `config.md` for route and Codex config. If `config.md` is missing or has missing/invalid fields, apply the **Config Validation Procedure** (see below). Skills do not silently default any field that affects pipeline behavior. There is no automatic derivation of the route — this avoids conditional branches in every skill. Existing runs can be migrated by manually adding `pipeline` and `route` fields to their config.md.

## Config Validation Procedure

Every skill that reads config.md applies this procedure before using any field.

### When config.md is missing entirely

Stop and present:

  config.md not found in the artifact directory.

  1) Re-run Goals to create config.md and set the pipeline mode
  2) Abort

### When a required field is missing or empty

Stop and present a numbered menu. The exact options depend on which field is missing — see each skill's Artifact Gating section for the field-specific menus.

### When a field has an invalid value

Stop and name the invalid value and the expected values. Present numbered options. The exact options depend on which field is invalid — see each skill's Artifact Gating section for the field-specific menus.

### No silent defaults

Skills must not:
- Assume `pipeline: full` when `pipeline` is missing
- Assume `codex_reviews: false` when `codex_reviews` is missing
- Attempt to derive `route` from `pipeline` when `route` is missing
- Proceed with a guessed or inferred field value

The only exception: fields that do not affect pipeline behavior may have defaults.
Fields that DO affect behavior (route, pipeline, codex_reviews, review_depth, review_mode) must be present and valid before the skill proceeds.

### Fields that affect pipeline behavior (must be validated)

| Field | Skills that validate it | Valid values |
|-------|------------------------|--------------|
| `route` | Goals, Plan, Worktree, Integrate, using-qrspi | ordered list of skill names (see Route Templates) |
| `pipeline` | Goals, Plan, Worktree | `full` or `quick` |
| `codex_reviews` | Goals, Plan | `true` or `false` |
| `review_depth` | Worktree, Implement (validated at dispatch time, set by Worktree) | `quick` or `deep` |
| `review_mode` | Worktree, Implement (validated at dispatch time, set by Worktree) | `single` or `loop` |

### Fields that do NOT require validation (informational only)

| Field | Note |
|-------|------|
| `created` | ISO date, informational only — missing is not an error |

### Review Round Flow

A "review round" consists of:
1. Claude review subagent runs → issues found are fixed
2. If Codex enabled: Codex review runs → issues found are fixed
3. If Codex errors during execution, report the error to the user and continue without blocking

After the first review round completes and fixes are applied, ask ONCE:

> `1) Present for review  2) Loop until clean (recommended)`

- **1 (Present):** Proceed to the human gate, but clearly state the review status: "Note: reviews found issues which were fixed but have not been re-verified in a clean round. The artifact may still have issues." The user can still approve, but they make an informed choice.
- **2 (Loop — recommended):** Loop autonomously — run review → fix → review → fix without re-prompting the user. Stop ONLY when a round finds zero issues across all reviewers ("Reviews passed clean") or 10 rounds are reached ("Hit 10-round review cap — presenting for your review."). Then proceed to the human gate.

**Default recommendation is always option 2.** Clean reviews before human review catch cross-reference inconsistencies that are hard to spot manually. The human cannot feasibly verify every cross-file reference — that's what the automated reviews are for.

**Once the user selects option 2, do not re-prompt between rounds.** The entire point of this option is autonomous iteration. Only return to the user when the loop terminates (clean or cap).

**At the human gate, always state the review status** when presenting: either "Reviews passed clean in round N" or "Reviews found issues in round N which were fixed but not re-verified." If the user approves but reviews have not passed clean, ask if they'd like a review loop before finalizing — this is strongly recommended.

This question is asked independently at each skill's review gate, not stored globally.

### Review Output Handling

The review file `reviews/{step}-review.md` is created on the first review round and appended on subsequent rounds:

```markdown
# {Step} Review

## Round 1 — Claude
{findings or "No issues found"}

## Round 1 — Codex
{findings or "No issues found" or "Skipped (not enabled)"}

## Post-review fixes (round 1)
- {what was changed and why}

## Round 2 — Claude
...
```

The orchestrating skill (not the review subagent) writes and appends to the review file based on each subagent's output. Review subagents return findings; the skill handles file I/O. Each round appends its section. Claude and Codex findings are attributed separately.

## Review Time Allocation

When presenting artifacts for human review, guide the user on where to invest review time:

- **Design and Structure** — invest heavy review here. These artifacts set the architecture. Errors here cascade through every downstream step.
- **Plan** — spot-check. Plan is a mechanical decomposition of approved artifacts. Sample a few task specs for correctness; you don't need to read every line.
- **Implementation code** — use task specs as a review guide. Each spec in `tasks/*.md` describes what a task was supposed to do, making code review efficient and traceable. Time saved on Plan review is time available to read the code.

## Compaction at Step Transitions

Each skill's terminal state should recommend compacting context before the next step: "This is a good point to compact context before the next step (`/compact`)." This is a recommendation, not a gate — the pipeline continues regardless.

## Feedback File Format

When a user rejects an artifact, the feedback is captured in `{artifact-dir}/feedback/{step}-round-{NN}.md`:

```markdown
---
step: {step name}
round: {rejection round number}
rejected_artifact: {path to rejected artifact}
---

## User Feedback
{The user's rejection feedback, verbatim}

## Previous Artifact
{The full content of the rejected artifact}
```

The new subagent receives the original inputs + this feedback file.

## Common Rationalizations — STOP

These thoughts mean the pipeline is being bypassed. Stop and follow the process:

| Rationalization | Reality |
|----------------|---------|
| "This is too simple for the full pipeline" | Quick-fix mode exists for simple changes. Use it — don't skip the pipeline entirely. |
| "I already know the answer, skip Research" | Research prevents confirmation bias. What you "know" may be outdated or incomplete. |
| "The goals are obvious, skip Goals" | Goals captures acceptance criteria. Without them, you can't verify success. |
| "Let me just start coding" | Code without a plan means rework. Even quick fixes go through Goals → Questions → Research → Plan. |
| "I can design and implement at the same time" | Design and implementation are separate context windows. Mixing them produces underthought architecture. |
| "This fix doesn't need questions" | Questions identify what you need to learn. Skipping them means you'll discover gaps mid-implementation. |
| "The user said to skip ahead" | The user can request mid-pipeline entry with existing artifacts. They cannot skip steps — each produces a contract downstream steps depend on. |
| "I'll come back and do the reviews later" | Reviews catch issues cheaply. Deferring them means expensive rework. |

## Skill Invocation

When QRSPI applies, invoke the Goals skill to begin:

**REQUIRED SKILL:** Use `qrspi:goals` to start the pipeline.

For reference on the QRSPI framework: see `qrspi/docs/qrspi-reference.md`

<BEHAVIORAL-DIRECTIVES>
These directives apply at every step of this skill, regardless of context.

D1 — Encourage reviews after changes: After any significant change to an artifact (whether from feedback, a fix round, or a re-run), recommend a review before proceeding. Reviews catch regressions that are invisible during forward-only execution.

D2 — Complete every step before moving on: Every process step in this skill exists for a reason. Execute each step fully. If a step seems redundant given the current state, state why and ask the user — do not silently skip it.

D3 — Resist time-pressure shortcuts: If the user signals urgency ("just move on," "skip the review this time"), acknowledge the constraint and offer the fastest compliant path. Do not use urgency as justification to skip required steps.
</BEHAVIORAL-DIRECTIVES>
