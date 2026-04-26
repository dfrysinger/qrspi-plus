---
name: using-qrspi
description: Use when starting any conversation — establishes the QRSPI pipeline for agentic software development, requiring structured progression through Goals, Questions, Research, Design, Structure, Plan, Parallelize, Implement, Integrate, Test
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill entirely. Do not start a new QRSPI pipeline — just do your assigned work.
</SUBAGENT-STOP>

# Using QRSPI

## Overview

QRSPI is a pipeline for agentic software development with two route variants (quick fix and full). Each step produces a reviewable artifact, gets human approval, then invokes the next step. Most steps run as subagents for guaranteed clean context. Goals and Design run interactively in the main conversation with subagent synthesis.

## The Pipeline

**Full pipeline:**
```
Goals → Questions → Research → Design → Structure → Plan → Parallelize → Implement → Integrate → Test → Replan (if needed)
```

> **Read the `Parallelize → Implement → Integrate` segment carefully.** Implement is *not* a per-task chain — it is the per-phase orchestrator step. Parallelize produces the parallelization plan and gets human approval; Implement then fires one per-task subagent per task in the current phase, presents a batch gate when every task has returned, and only then routes to Integrate. **Implement runs once per phase (firing N per-task subagents). Integrate runs once per phase.** Canonical contract — including batch-gate release conditions and the `current_step` transition mechanism — lives in `implement/SKILL.md` → "Implement Is the Per-Phase Orchestration Loop". The state.json table below is a reader's quick reference, not a second source of truth.

**Quick Fix pipeline** (skip Design/Structure/Parallelize/Integrate):
```
Goals → Questions → Research → Plan → Implement → Test
```

> Quick fix has no Parallelize plan and no Integrate. Implement still owns per-task orchestration: it fires per-task subagents (typically one for the originally-requested task; more if fix-task rounds occur) and presents the **quick-fix batch gate** before routing to Test. See `implement/SKILL.md` § Quick Fix for the full batch-gate semantics in quick-fix mode.

| Step | # | What it does | Artifact |
|------|---|-------------|----------|
| **Goals** | 1 | Capture user intent, constraints, acceptance criteria | `goals.md` |
| **Questions** | 2 | Generate tagged research questions (no goal leakage) | `questions.md` |
| **Research** | 3 | Parallel specialist agents gather objective facts | `research/summary.md` |
| **Design** | 4 | Interactive design discussion, vertical slicing, phasing | `design.md` |
| **Structure** | 5 | Map design to files, interfaces, component boundaries | `structure.md` |
| **Plan** | 6 | Detailed task specs with test expectations | `plan.md` + `tasks/*.md` |
| **Parallelize** | 7 | Analyze dependencies and file overlap; produce symbolic parallelization plan | `parallelization.md` |
| **Implement** | 8 | Resolve symbolic bases, create worktrees + stage commits, run baseline tests, fire per-task subagents (×N) with TDD + tiered review loops, present batch gate | Working code |
| **Integrate** | 9 | Merge task branches, cross-task integration + security review, CI gate | Integration report |
| **Test** | 10 | Acceptance testing, PR creation, phase routing | Test results + PR (every phase) |
| **Replan** | 11 | Between phases — update remaining tasks based on learnings | Updated `plan.md` + `tasks/*.md` |

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
  - parallelize
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
  - parallelize
  - implement
  - integrate
  - test
```

> **Note:** Replan (step 11) is NOT included in any route list. It is invoked by Test when more phases remain in the design, not when Test fails. Test handles final-phase completion (PR creation) directly.

### Mid-Pipeline Route Change

Route changes are only allowed before Plan executes:

- **Full → Quick Fix:** Allowed only before Plan. Drop Design, Structure, Parallelize, Integrate from the route. Update `config.md`.
- **Quick Fix → Full:** Allowed only before Plan. Insert Design, Structure before Plan, and Parallelize, Integrate after Plan. Update `config.md`.
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
│   ├── baseline-failures.md       (Implement baseline)
│   ├── tasks/
│   │   └── ...
│   ├── integration/
│   │   └── round-NN-review.md
│   ├── ci/
│   │   └── round-NN-review.md
│   └── test/
│       ├── round-NN-review.md
│       └── baseline-failures.md   (Test baseline)
├── future-goals.md                (optional — captured future ideas, deferred scope)
└── .qrspi/                        (hook-managed, do not edit manually)
    ├── state.json                 (pipeline state cache)
    ├── task-NN-runtime.json       (per-task runtime overrides — user mid-task decisions)
    └── audit-task-NN.jsonl        (per-task audit logs)
```

The slug is generated during the Goals step: take the user's first description, extract 2-4 key words, convert to lowercase kebab-case (e.g., "user-auth", "product-search-api").

## Artifact Gating

Each skill checks that its required input artifacts exist on disk before proceeding:
- **Goals**: No prerequisites (first step)
- **Questions**: Requires `goals.md` with `status: approved`
- **Research**: Requires `questions.md` with `status: approved`
- **Design**: Requires `goals.md` and `research/summary.md` with `status: approved`
- **Structure**: Requires `goals.md`, `research/summary.md`, and `design.md` with `status: approved`
- **Plan**: Full pipeline requires `goals.md`, `research/summary.md`, `design.md`, and `structure.md` with `status: approved`. Quick fix requires only `goals.md` and `research/summary.md`.
- **Parallelize**: Requires `plan.md` with `status: approved`, `tasks/*.md`, `design.md` with `status: approved` (phase definitions), and `config.md`
- **Implement**: Mode is derived from `config.md.route` (full pipeline if `parallelize` precedes `implement`; quick fix otherwise). Full pipeline additionally requires `parallelization.md` with `status: approved`. Quick fix has no Parallelize, so no `parallelization.md`; Implement requires the per-run input set defined in `implement/SKILL.md` § Artifact Gating (approved `tasks/*.md` or `fixes/{type}-round-NN/*.md`). The `pipeline` field on individual task files is a per-task input-gating concern read by the per-task orchestrator subagent, not by the Implement skill itself.
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

**Commit after approval.** Every approved artifact (and its review file) should be committed to git immediately after the approval marker is written. This preserves the approved state as a checkpoint the user can return to. Use a descriptive commit message like `docs(qrspi): approve {step} for {project-slug}`.

## Hook-Managed State (`.qrspi/`)

The `.qrspi/` directory inside each artifact directory is created and maintained entirely by hooks:

- **SessionStart hook** — initializes `state.json` in the main project's artifact dir at session start by reconciling against artifact frontmatter on disk. Worktrees do not have `state.json` files — there is no per-worktree state. Subagent enforcement is target-based, not state-driven (see "How worktree enforcement works" below).
- **PostToolUse hook** — keeps `state.json` in sync whenever an artifact's frontmatter changes

During normal forward execution, skills do not need to create, read, or update any file in `.qrspi/`. State is always current when a skill needs it because the hooks maintain it continuously. The exceptions are narrow and explicit:

1. **Bootstrap recovery (Goals)** — the Goals skill calls `state_init_or_reconcile` if `state.json` is missing or unreadable at session start.
2. **`phase_start_commit` write (Plan)** — when `plan.md` is approved, Plan writes the current HEAD hash to `state.json.phase_start_commit`.
3. **Pre-emptive reconciliation on next-phase restart (Replan)** — Replan's minor-path terminal state calls `state_init_or_reconcile` immediately before invoking Goals, so Goals sees state that already matches the freshly-reset frontmatter (rather than relying on the PostToolUse hook's lazy catch-up). See `replan/SKILL.md` → "Terminal State" and `goals/SKILL.md` → "Next-Phase Restart Mode".

All three exceptions are bounded calls touching specific fields (or invoking the bootstrap helper), not general skill-level ownership of state. No other skill should read or write `.qrspi/` files.

**Pipeline enforcement:** PreToolUse hooks enforce pipeline step ordering. Attempting to write a downstream artifact (e.g., `design.md`) before its prerequisites are approved will be blocked by the hook. Pipeline progression is code-enforced, not just prompt-enforced.

### `state.json` field semantics (for human and agent readers)

Skills don't need to interpret `state.json`, but a reader (human or fresh agent recovering context between sessions) often does. Read these fields with the right mental model — getting one wrong is the most common cause of misordering pipeline steps.

| Field | Meaning | When it changes |
|-------|---------|-----------------|
| `current_step` | The pipeline step currently active. For full-pipeline phases that loop Implement (the per-phase orchestration loop in the `Implement → Integrate` segment), this stays at `implement` for the **entire** batch — across every per-task subagent fired by Implement. It only advances to `integrate` after Implement's batch gate releases. The canonical transition contract lives in `implement/SKILL.md` → "State Transition Contract" under "Implement Is the Per-Phase Orchestration Loop"; the hook layer in `hooks/lib/` is the intended implementation layer. (Current hook code may lag the contract for transitions outside the eight pre-Phase-4 steps; if a needed transition is missing, file a hook bug rather than working around it in skills.) | Advances when a step's terminal artifact is approved, when an Implement batch gate releases and Implement invokes the next route step, or when Integrate, Test, or Replan complete their gates. **Does not advance per-task.** Skills never write this field directly — the hook layer writes it. |
| `artifacts.{step}` | Approval status of each artifact (`draft`, `replan-draft`, or `approved`). Drives artifact gating. | Updated by the PostToolUse hook when an artifact's frontmatter changes. |
| `wireframe_requested` | Whether the run includes the optional UX step before Structure. | Set during Goals; never changes thereafter. |
| `phase_start_commit` | Git SHA at which the current phase began. Used by Replan and Test to scope diffs. | Set when a phase begins. |

**The trap to avoid:** `current_step: implement` + a single task done does *not* mean "advance to integrate." It means "Implement is mid-batch — expect another per-task firing." Verify against `parallelization.md` (which lists every task in the phase) before concluding the batch is done.

## How worktree enforcement works

The QRSPI hook enforces subagent containment using **target-based asymmetric** logic, not CWD-based logic.

**Subagent vs main chat detection:** The hook reads `agent_id` from the envelope JSON. If `agent_id` is non-empty, the call is from a subagent (Agent tool dispatch). Otherwise it's main chat.

**Subagent walls (target-based):**

- Write/Edit/NotebookEdit targeting any file outside `.worktrees/{slug}/(task-NN|baseline)/...` is BLOCKED
- Bash commands with detected file-write targets follow the same rule for each detected target
- Bash commands containing `DROP TABLE` or `TRUNCATE` are BLOCKED (subagents shouldn't do destructive DB ops)
- Bash commands containing universal destructive patterns (see below) are BLOCKED

Subagents may write to ANY worktree under `.worktrees/`, not just their own. This is "loose pinning" — strict pinning (subagent bound to its own task worktree) is a future enhancement.

**Main chat trust:** Main chat is not subject to the worktree wall — it can write anywhere. Pipeline ordering and universal destructive checks still apply.

**Universal destructive patterns (everyone, including main chat):**

- `rm -rf` with target containing `*`, `~`, leading `/`, or `..`
- `git push --force` / `git push -f`
- `git reset --hard <ref>` (any ref other than `HEAD`)
- `git clean -fd` / `-fdx`
- Redirect to `/dev/sd*`
- `DROP DATABASE` / `DROP SCHEMA`

**Artifact-dir audit log protection:** All agents are blocked from writing to `<artifact_dir>/.qrspi/` files. The hook is the only writer of these — that's what makes the audit log tamper-proof.

**Audit logging:** Every allowed/blocked write whose target is inside QRSPI scope (a worktree or an artifact dir) is appended to `<artifact_dir>/.qrspi/audit.jsonl`. Writes outside QRSPI scope (random side projects, superpowers spec work) are NOT audited — the audit log stays focused on QRSPI work.

**No `.qrspi/` in worktrees.** Worktrees contain only the user's task work. Audit and state both live in the artifact dir.

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

### Validation and Repair

Before checking artifact status, run these three validation checks in order:

**1. State schema validation (fail-closed)**

Call `state_init_or_reconcile <artifact_dir>` to bootstrap or reconcile `.qrspi/state.json`. If the state file is missing, it is created from artifact frontmatter. If the version field is absent (v0), it is migrated to v1. If any required v1 fields are missing (`wireframe_requested`, `artifacts`), each is added with a safe default and a repair message is emitted to stdout. If `state_init_or_reconcile` returns non-zero or if JSON is unparseable, **stop immediately** — do not proceed, do not silently pass. Emit a diagnostic:

```
ERROR: state.json is corrupted and could not be repaired. Run `state_init_or_reconcile <artifact_dir>` manually or delete .qrspi/state.json to rebuild.
```

This is fail-closed behavior: a corrupt state is worse than a stopped run.

**2. Config validation**

Apply the **Config Validation Procedure** below. Do not silently patch any field.

**3. Task spec scan (advisory, non-blocking)**

After state and config are valid, scan `tasks/task-*.md` for missing fields (`enforcement`, `allowed_files`, `constraints`). Output any warnings to stdout and continue — this is advisory only.

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

**Example — task list written by Goals after route selection:**
```
[x] Goals
[ ] Questions
[ ] Research
[ ] Design          # full pipeline only
[ ] Structure       # full pipeline only
[ ] Plan
[ ] Parallelize     # full pipeline only
[ ] Implement
[ ] Integrate       # full pipeline only
[ ] Test
```

The exact list mirrors the `route` field in `config.md`. Update each task as the pipeline progresses (mark `in_progress` when a step starts, `completed` when approved).

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
  - parallelize
  - implement
  - integrate
  - test
review_depth: deep  # or: quick — added by Implement at phase start
review_mode: loop   # or: single — added by Implement at phase start
---
```

**Field definitions:**
- `created`: ISO date the run was created (set once, never updated)
- `pipeline`: human-readable label (`full` or `quick`) — informational only; `route` is authoritative
- `codex_reviews`: whether to include Codex in review rounds
- `route`: ordered list of skill names this run will execute (see Route Templates above)
- `review_depth`: `quick` (4 correctness reviewers) or `deep` (all 8 reviewers) — written by Implement at phase start
- `review_mode`: `single` or `loop` — written alongside `review_depth`

**Writing `config.md`:** After the user selects a pipeline mode and answers the Codex question, write `created`, `pipeline`, `codex_reviews`, and `route` to `config.md` atomically. The `review_depth` and `review_mode` fields are added later by Implement. Use the appropriate route template from the Route Templates section.

**Codex detection:** Check if `codex:rescue` is available by globbing for `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs`. If the file doesn't exist, skip the Codex question silently and write `codex_reviews: false`. If available, ask:

> Codex reviews:
> 1) No Codex reviews
> 2) Use Codex for second reviews

**No legacy fallback.** All subsequent skills must read `config.md` for route and Codex config. If `config.md` is missing or has missing/invalid fields, apply the **Config Validation Procedure** (see below). Skills do not silently default any field that affects pipeline behavior. There is no automatic derivation of the route — this avoids conditional branches in every skill. Existing runs can be migrated by manually adding `pipeline` and `route` fields to their config.md.

## Config Validation Procedure

Every skill that reads config.md applies this procedure before using any field.

### When config.md is missing entirely

Stop and present:

  config.md not found in the artifact directory.

  1) Re-run Goals to create config.md and set the pipeline mode
  2) Abort

### When a required field is missing or has an invalid value

Stop and present the field-specific menu below. For an invalid value, also name the invalid value and the expected values before showing the menu. The set of fields each skill validates is per-skill (see each skill's Config Validation section); the menu for a given field is the same across all skills.

**If `route` is missing:**
1. Manually add a `route:` list to config.md
2. Abort

**If `pipeline` is missing or invalid (expected `full` or `quick`):**
1. Edit config.md and set `pipeline: full` or `pipeline: quick`
2. Abort

**If `codex_reviews` is missing or invalid (expected `true` or `false`):**
1. Edit config.md and set `codex_reviews: true` or `codex_reviews: false`
2. Abort

### No silent defaults

Skills must not:
- Assume `pipeline: full` when `pipeline` is missing
- Assume `codex_reviews: false` when `codex_reviews` is missing
- Attempt to derive `route` from `pipeline` when `route` is missing
- Proceed with a guessed or inferred field value

### Fields that affect pipeline behavior (must be validated)

| Field | Skills that validate it | Valid values |
|-------|------------------------|--------------|
| `route` | Goals, Plan, Parallelize, Implement, Integrate, using-qrspi | ordered list of skill names (see Route Templates) |
| `pipeline` | Goals, Plan, Parallelize | `full` or `quick` |
| `codex_reviews` | Goals, Plan, Implement, Integrate, Test | `true` or `false` |
| `review_depth` | Implement | `quick` or `deep` — set by Implement at phase start |
| `review_mode` | Implement | `single` or `loop` — set by Implement at phase start |

### Fields that do NOT require validation (informational only)

| Field | Note |
|-------|------|
| `created` | ISO date, informational only — missing is not an error |

## Standard Review Loop

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

## Review Output Handling

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

## Pipeline Iron Laws — Final Reminder

The four invariants that, when violated, produce the most damage:

1. **Each step requires its declared inputs approved.** Artifact gating is not advisory — skills refuse to run without approved prerequisites. Do not "skip ahead." Use mid-pipeline entry only with the existing-artifacts contract.

2. **`status: approved` in YAML frontmatter is the only approval marker.** Writing it triggers the PostToolUse hook to update `state.json`. Skills do NOT update `state.json` manually — see "Hook-Managed State" for the narrow exceptions.

3. **Backward loops cascade forward — never patch one artifact in isolation.** New learnings at step N require updating the earliest affected artifact, re-reviewing it, and re-approving every step from there to N. Drift between artifacts breaks every downstream contract.

4. **The `Implement → Integrate` segment is per-phase, not per-task.** Implement runs once per phase, firing N per-task subagents internally. Integrate runs once per phase. `current_step: implement` plus one task done does NOT mean "advance to integrate" — see `state.json` field semantics for the verification trap and `implement/SKILL.md` → "Implement Is the Per-Phase Orchestration Loop" for the canonical contract.

<BEHAVIORAL-DIRECTIVES>
D1 — Encourage reviews after changes: After any significant change to an artifact (whether from feedback, a fix round, or a re-run), recommend a review before proceeding. Reviews catch regressions that are invisible during forward-only execution.

D2 — Never suggest skipping steps for speed: Every step in the QRSPI pipeline exists for a reason. Do not offer shortcuts, suggest merging steps, or imply steps can be skipped to save time.

D3 — Resist time-pressure shortcuts: There is no time crunch. LLMs execute orders of magnitude faster than humans. There is no benefit to skipping LLM-driven steps — reviews, synthesis passes, and validation rounds cost seconds. Reassure the user that thoroughness is free. If the user signals urgency ("just move on," "skip the review this time"), acknowledge the constraint and offer the fastest compliant path. Do not use urgency as justification to skip required steps.
</BEHAVIORAL-DIRECTIVES>
