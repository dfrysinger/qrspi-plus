---
name: using-qrspi
description: Use when starting any conversation — establishes the QRSPI pipeline for agentic software development, requiring structured progression through Goals, Questions, Research, Design, Phasing, Structure, Plan, Parallelize, Implement, Integrate, Test, with Replan firing between phases
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill entirely. Do not start a new QRSPI pipeline — just do your assigned work.
</SUBAGENT-STOP>

# Using QRSPI

## Overview

QRSPI is a pipeline for agentic software development with two route variants (quick fix and full). Each step produces a reviewable artifact, gets human approval, then invokes the next step. Most steps run as subagents for guaranteed clean context. Goals and Design run interactively in the main conversation with subagent synthesis.

## Recommended Workspace Layout

QRSPI separates two kinds of files:

- **Artifacts** (goals, questions, research, design, structure, plan, reviews) — written under `docs/qrspi/{slug}/` by the pipeline skills.
- **Code** — lives in a separate target repository that Implement clones/forks into worktrees under `.worktrees/{slug}/task-NN/`.

The recommended layout is to keep these as siblings inside a single workspace directory, e.g.:

```
my-workspace/
├── docs/qrspi/{slug}/   # artifacts (this pipeline's outputs)
└── code/{repo}/         # the target git repo Implement operates on
```

This is a recommendation, not a requirement. Both locations can be configured to whatever the user prefers — for example, artifacts inside the target repo, or the target repo at an arbitrary absolute path. The skills detect the artifact directory at runtime and don't assume any particular topology.

**Greenfield (no target repo yet):** Implement currently assumes the target repo exists with a base branch it can fork worktrees from. If you're starting greenfield, create and `git init` the target repo before reaching Implement (Goals/Design/Structure can still run without it). A future improvement (tracked in the project's future-goals) will let `config.md` carry an explicit `code_path` and let Goals offer a greenfield bootstrap step.

## The Pipeline

**Full pipeline:**
```
Goals → Questions → Research → Design → Phasing → Structure → Plan → Parallelize → Implement → Integrate → Test → Replan (if needed)
```

> **Read the `Parallelize → Implement → Integrate` segment carefully.** Implement is *not* a per-task chain — it is the per-phase orchestrator step. Parallelize produces the parallelization plan and gets human approval; Implement then, for each task in the current phase, dispatches an implementer subagent (TDD) and on its DONE / DONE_WITH_CONCERNS terminal status dispatches the configured reviewer subagents in parallel against that task; main chat itself is the per-task orchestrator (flat dispatch — there is no per-task orchestrator subagent layer). When every task has cleared its review/fix cycles, Implement presents a batch gate and only then routes to Integrate. **Implement runs once per phase. Integrate runs once per phase.** Canonical batch-gate contract lives in `implement/SKILL.md` → "Implement Is the Per-Phase Orchestration Loop".

**Quick Fix pipeline** (skip Design/Phasing/Structure/Parallelize/Integrate):
```
Goals → Questions → Research → Plan → Implement → Test
```

> Quick fix has no Parallelize plan and no Integrate. Implement still owns per-task orchestration: for each task (typically one for the originally-requested fix; more if fix-task rounds occur) main chat dispatches an implementer subagent and reviewer subagents directly, then presents the **quick-fix batch gate** before routing to Test. See `implement/SKILL.md` § Quick Fix for the full batch-gate semantics in quick-fix mode.

| Step | # | What it does | Artifact |
|------|---|-------------|----------|
| **Goals** | 1 | Capture user intent, environmental constraints, per-goal problem framing (Problem / Why we care / What we know so far) | `goals.md` |
| **Questions** | 2 | Generate tagged research questions (no goal leakage) | `questions.md` |
| **Research** | 3 | Parallel specialist agents gather objective facts | `research/summary.md` |
| **Design** | 4 | Interactive design discussion: approach selection, key decisions, trade-offs, design-level test strategy, system diagram | `design.md` |
| **Phasing** | 5 | Author vertical slices and phase boundaries with replan gates; maintain `roadmap.md` and `future-*.md` | `phasing.md` |
| **Structure** | 6 | Map design to files, interfaces, component boundaries | `structure.md` |
| **Plan** | 7 | Detailed task specs with test expectations | `plan.md` + `tasks/*.md` |
| **Parallelize** | 8 | Analyze dependencies and file overlap; produce symbolic parallelization plan | `parallelization.md` |
| **Implement** | 9 | Resolve symbolic bases, create worktrees + stage commits, run baseline tests, dispatch implementer + reviewer subagents per task with TDD + tiered review loops, present batch gate | Working code |
| **Integrate** | 10 | Merge task branches, cross-task integration + security review, CI gate | Integration report |
| **Test** | 11 | Acceptance testing, PR creation, phase routing | Test results + PR (every phase) |
| **Replan** | — | Between phases — update remaining tasks based on learnings (out-of-route) | Updated `plan.md` + `tasks/*.md` |

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
  - phasing
  - structure
  - plan
  - parallelize
  - implement
  - integrate
  - test
```

**Full + UX (adds wireframing after Phasing, before Structure):**
```yaml
route:
  - goals
  - questions
  - research
  - design
  - phasing
  - ux
  - structure
  - plan
  - parallelize
  - implement
  - integrate
  - test
```

> **Note:** Replan is NOT included in any route list (it is out-of-route). It is invoked by Test when more phases remain in the design, not when Test fails. Test handles final-phase completion (PR creation) directly.

### Mid-Pipeline Route Change

Route changes are only allowed before Plan executes:

- **Full → Quick Fix:** Allowed only before Plan. Drop Design, Phasing, Structure, Parallelize, Integrate from the route. Update `config.md`.
- **Quick Fix → Full:** Allowed only before Plan. Insert Design, Phasing, Structure before Plan, and Parallelize, Integrate after Plan. Update `config.md`.
- **Add/remove UX step:** Allowed only before Structure. Insert or remove `ux` between `phasing` and `structure`. Update `config.md`.

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
├── phasing.md
├── roadmap.md
├── future-goals.md                (optional — Phasing-managed cross-phase scope)
├── future-questions.md            (optional — Phasing-managed cross-phase scope)
├── future-research-summary.md     (optional — Phasing-managed cross-phase scope)
├── future-design.md               (optional — Phasing-managed cross-phase scope)
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
└── reviews/
    ├── goals/
    │   ├── round-01-claude.md
    │   ├── round-01-scope-claude.md
    │   ├── round-01-codex.md
    │   ├── round-01-scope-codex.md
    │   └── round-01-fixes.md      (main-chat-authored: what was fixed this round)
    ├── questions/                 (same shape; no scope reviewer for questions)
    ├── research/                  (same shape; no scope reviewer for research)
    ├── design/                    (same shape as goals/)
    ├── phasing/                   (same shape as goals/)
    ├── structure/                 (same shape as goals/)
    ├── plan/                      (same shape as goals/)
    ├── parallelize/               (same shape as goals/)
    ├── replan/                    (same shape as goals/)
    ├── baseline-failures.md       (Implement baseline)
    ├── tasks/
    │   └── ...
    ├── integration/
    │   ├── round-NN-integration-claude.md
    │   ├── round-NN-security-claude.md
    │   ├── round-NN-integration-codex.md
    │   ├── round-NN-security-codex.md
    │   ├── round-NN-implement-gate-claude.md   (when "Re-run all reviews" selected at Implement batch gate)
    │   └── round-NN-implement-gate-codex.md    (same condition; only when codex_reviews: true)
    ├── ci/
    │   └── round-NN-review.md
    └── test/
        ├── round-NN-goal-traceability-claude.md
        ├── round-NN-spec-claude.md
        ├── round-NN-code-quality-claude.md
        ├── round-NN-{template}-codex.md   (per-template Codex stdout)
        ├── round-NN-results.md            (main-chat-authored test results)
        └── baseline-failures.md           (Test baseline)
```

The slug is generated during the Goals step: take the user's first description, extract 2-4 key words, convert to lowercase kebab-case (e.g., "user-auth", "product-search-api").

## Artifact Gating

Each skill checks that its required input artifacts exist on disk before proceeding:
- **Goals**: No prerequisites (first step)
- **Questions**: Requires `goals.md` with `status: approved`
- **Research**: Requires `questions.md` with `status: approved`
- **Design**: Requires `goals.md` and `research/summary.md` with `status: approved`
- **Phasing**: Requires `goals.md`, `questions.md`, `research/summary.md`, and `design.md` with `status: approved`
- **Structure**: Requires `goals.md`, `research/summary.md`, `design.md`, and `phasing.md` with `status: approved`
- **Plan**: Full pipeline requires `goals.md`, `research/summary.md`, `design.md`, `phasing.md`, and `structure.md` with `status: approved`. Quick fix requires only `goals.md` and `research/summary.md`.
- **Parallelize**: Requires `plan.md` with `status: approved`, `tasks/*.md`, `phasing.md` with `status: approved` (phase definitions), and `config.md`
- **Implement**: Mode is derived from `config.md.route` (full pipeline if `parallelize` precedes `implement`; quick fix otherwise). Full pipeline additionally requires `parallelization.md` with `status: approved`. Quick fix has no Parallelize, so no `parallelization.md`; Implement requires the per-run input set defined in `implement/SKILL.md` § Artifact Gating (approved `tasks/*.md` or `fixes/{type}-round-NN/*.md`). The `pipeline` field on individual task files is a per-task input-gating concern read by the per-task dispatch in `implement/SKILL.md` § Per-Task Execution, not by the Implement skill's run-mode derivation.
- **Integrate**: Requires all task review files in `reviews/tasks/`, `design.md` with `status: approved`, `phasing.md` with `status: approved`, `structure.md` with `status: approved`, `parallelization.md` with `status: approved` (branch map), and `config.md` (for route)
- **Test**: Requires `goals.md` with `status: approved`, `design.md` and `phasing.md` with `status: approved` (full pipeline) or `research/summary.md` with `status: approved` (quick fix), `fixes/` directory (for regression tests), codebase with implementation merged
- **Replan**: Requires completed phase code (merged), `fixes/` and `reviews/` directories, remaining `tasks/*.md`, `plan.md` with `status: approved`, `design.md` with `status: approved`, and `phasing.md` with `status: approved`

If a required artifact is missing, the skill refuses to run and tells the user which artifact is needed.

## Approval Markers

When the user approves an artifact, the skill writes `status: approved` in the artifact's YAML frontmatter:

```yaml
---
status: approved
---
```

**Status values:** `draft` (initial), `approved` (user-approved), `replan-draft` (transient — used during Replan's minor path re-approval cycle; artifact gating treats this the same as `draft`, so downstream skills correctly refuse to proceed until re-approval completes).

**Writing `status: approved` is sufficient.** Pipeline progression is derived from artifact frontmatter; skills do not need to perform any explicit state update after writing the approval marker.

**Commit after approval (when applicable).** When the artifact directory is inside a git repository, commit each approved artifact (and its review file) immediately after the approval marker is written — this preserves the approved state as a checkpoint. Use a descriptive commit message like `docs(qrspi): approve {step} for {project-slug}`. When the artifact directory is not inside a git repository, skip the commit step — the approved frontmatter on disk is the durable record, and that's a fully supported pipeline configuration.

**How to detect:** Run `git -C <artifact_dir> rev-parse --show-toplevel` and inspect the exit code. Detect from the **artifact directory**, not from CWD — these can differ, and the artifact directory is the right anchor for this decision.

This applies to every skill terminal state in this pipeline that says "commit … to git" — the per-skill instructions all defer to this canonical rule.

## State and Pipeline Ordering

Pipeline state is derived from artifact frontmatter (`status: approved`). No pipeline-state cache file gates step ordering — the legacy hook layer's `.qrspi/state.json` is unrelated runtime state and is not consulted by skills when computing the next step. To determine the current step, walk `config.md.route` and find the first entry whose artifact does not have `status: approved`.

Pipeline ordering is enforced by the `<HARD-GATE>` blocks in each skill — every skill checks predecessor approval at its top and refuses to run if missing. Subagent containment is the runtime sandbox's responsibility (auto-mode plus Claude's judgment); there is no in-pipeline worktree wall.

The single piece of derived state worth persisting is `phase_start_commit`, which Replan and Test use to scope post-phase diffs. It lives in `plan.md` frontmatter, written when `plan.md` is approved. See `plan/SKILL.md` → "`phase_start_commit` capture at approval time" for the exact mechanic and the git-log fallback for non-git or unpopulated runs.

**The Implement batch trap to avoid:** "one task done" does NOT mean "advance to integrate." Implement runs once per phase and fires per-task subagents in a wave; the batch is only done when every task in `parallelization.md` has cleared its review/fix cycles. Verify against `parallelization.md` before routing forward.

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

Before checking artifact status, run these validation checks in order:

**1. Config validation**

Apply the **Config Validation Procedure** below. Do not silently patch any field.

**2. Task spec scan (advisory, non-blocking)**

After config is valid, scan `tasks/task-*.md` for missing fields (`enforcement`, `allowed_files`, `constraints`). Output any warnings to stdout and continue — this is advisory only.

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
[ ] Phasing         # full pipeline only
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
  - phasing
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

### Exceptions to the no-silent-defaults rule

- **`verifier_enabled` runtime backfill.** If the field is missing from `config.md` on the first verifier-aware Apply-fix invocation in a resumed run created before the verifier landed, the runtime treats it as `true`, surfaces a one-line stderr warning once per resume (form: `verifier_enabled missing from config.md — backfilling default 'true' for this run`), and writes the field back to `config.md`. This is the only carve-out from the no-silent-defaults rule (`### No silent defaults` above). The carve-out exists because pre-existing run directories on disk pre-date the field's introduction and the alternative — failing the run on a missing field — would prevent users from resuming any in-flight run after upgrading.

### Fields that affect pipeline behavior (must be validated)

| Field | Skills that validate it | Valid values |
|-------|------------------------|--------------|
| `route` | Goals, Plan, Parallelize, Implement, Integrate, using-qrspi | ordered list of skill names (see Route Templates) |
| `pipeline` | Goals, Plan, Parallelize | `full` or `quick` |
| `codex_reviews` | Goals, Plan, Design, Phasing, Structure, Replan, Implement, Integrate, Test | `true` or `false` |
| `review_depth` | Implement | `quick` or `deep` — set by Implement at phase start |
| `review_mode` | Implement | `single` or `loop` — set by Implement at phase start |

- **`verifier_enabled`** (boolean, default `true`) — when `true`, the artifact-level Apply-fix protocol dispatches one `qrspi-finding-verifier` (Haiku) per finding-file in parallel and filters style/clarity/correctness findings at score ≥80 before applying. When `false`, the protocol skips verifier dispatch entirely (no sidecars are written) and keeps all findings via the "no sidecar → keep" branch in step 7. The field is durable across `/compact`, pause, resume, and re-entry within the run directory under `docs/qrspi/<date>-<bundle>/`. Fresh run directories start with `verifier_enabled: true` (set by the `using-qrspi` run-init code at run creation). The §3 menu's `skip` option disables the verifier for the CURRENT round only (it does NOT mutate `config.md`); to disable across the whole run, edit `config.md` directly between rounds. CLI-flag opt-out at `/qrspi` invocation is out of scope for #109 (deferred).

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

### Fix-altitude rule (F-5)

When fixing an "X is under-specified" finding, prefer minimal additions that stay at the artifact's altitude. If the natural fix pulls content from the next pipeline step (Design content into Goals; Plan content into Design; Implementation choices into Plan), that's a signal to defer specification rather than over-specify here. Add a one-line "[X] pinned in <next step>" note instead of pinning X exhaustively now. Reviewers who flag missing detail at the next-step altitude are misapplying their review brief — decline the finding with a one-line explanation in the round notes.

Why: pulling next-step detail upward inflates the artifact, introduces internal contradictions (the natural-language detail at this altitude often contradicts the structured detail at the next altitude), and produces R7-R10-style self-induced review churn — reviewers in subsequent rounds correctly flag the over-specification, the fix removes it, the cycle repeats. Minimal additions converge in 1–2 rounds; maximal additions can take 5+.

Mirrors the skill-refactor design's "decline scope-extension findings" rule, applied to artifact-level reviews.

## Review Output Handling

**Disk-write contract (artifact-level reviews).** Each artifact-level reviewer subagent writes its findings directly to disk and returns only a brief structured summary to main chat. Main chat never receives finding text in subagent return values. This keeps reviewer output out of main chat's conversation history (where it would re-bill as cache reads on every subsequent turn) until main chat explicitly reads the file to apply fixes — at which point the standard `/compact` after fix-apply (see "Compaction at Step Transitions" + per-skill apply-fix recommendations) sheds it.

**Per-reviewer file paths.** Each reviewer writes to its own per-round per-reviewer file under `reviews/{step}/`:

- Claude reviewer subagent → `reviews/{step}/round-NN-claude.md`
- Claude scope-reviewer subagent → `reviews/{step}/round-NN-scope-claude.md` (one per scope-reviewed artifact; dedicated `qrspi-{name}-scope-reviewer` agents per #110)
- Codex reviewer (async) → `reviews/{step}/round-NN-codex.md` (filled by `scripts/codex-companion-bg.sh await --artifact-dir <ABS_ARTIFACT_DIR> <jobId>` stdout redirection — see per-skill Codex dispatch language)
- Codex scope-reviewer (async) → `reviews/{step}/round-NN-scope-codex.md` (when `codex_reviews: true` and the artifact has a dedicated scope-reviewer)
- Main chat fix-apply summary → `reviews/{step}/round-NN-fixes.md`

`{step}` is the canonical step name (e.g. `goals`, `design`, `plan`, `replan`). `NN` is the zero-padded round number. Per-reviewer parallelism is preserved: each reviewer writes its own file, so two reviewers running concurrently never race on the same file.

**Per-reviewer file format** (each Claude-or-scope reviewer authors a file in this shape):

```markdown
---
artifact: {step}
round: NN
reviewer: claude   # or "codex"; the runtime, not the role. Scope-reviewer outputs land in round-NN-scope-{reviewer}.md filenames.
---

# {Step} review — round NN — {reviewer}

## Summary

- Total findings: N
- Severity: high=X, medium=Y, low=Z
- Auto-apply (style/clarity/correctness): A
- Paused (scope/intent): P

## Findings

{Findings emitted as a list, each conforming to the 5-field schema in `skills/reviewer-protocol/SKILL.md` `## Finding Schema`. "No issues found" is a valid body when N=0.}
```

**Subagent return value (brief).** After writing the per-reviewer file, the reviewer subagent returns a single brief summary string to main chat. The summary MUST NOT include the finding text — main chat reads the file when it needs the details. Required summary form:

```
Round NN {reviewer-tag} review complete.
Findings: N (high=X, medium=Y, low=Z)
Auto-apply: A | Paused: P
Written to: reviews/{step}/round-NN-{reviewer-tag}.md
```

This brevity is load-bearing for the optimization: the savings in cache-read accumulation across subsequent main-chat turns depend on the subagent's return text being ~30 tokens, not 3K-30K.

**Subagent guardrail compatibility.** The per-reviewer filename pattern `round-NN-{reviewer}.md` does not match the Claude Code 2.1.x subagent-write blocklist (`^(REPORT|SUMMARY|FINDINGS|ANALYSIS).*\.md$`, case-insensitive at filename stem start). Subagents can `Write` these files directly without hitting the guardrail. (For comparison, the research-step `summary.md` DOES match the blocklist, which is why that file goes through orchestrator-write — see `research/SKILL.md` for the exception.)

**Codex output handling.** Codex reviews run as bash-launched background jobs via `scripts/codex-companion-bg.sh`. The `await` step's stdout is redirected to `reviews/{step}/round-NN-codex.md` directly (see optimization-plan item #8 and per-skill Codex dispatch language) — main chat never paste-backs Codex stdout into its own conversation. Main chat does write a one-line "Codex exit M, see reviews/{step}/round-NN-codex.md" status note when needed, but the bulk findings live on disk only.

**Apply-fix protocol.** When main chat applies fixes after a round:

1. Read each per-reviewer file (Claude, scope, Codex) for that round.
2. Apply auto-apply findings via Edit on the artifact under review.
3. For paused findings, follow the Review-Loop Pause Gate (below) — write `reviews/{artifact}-loop-pause-round-NN.md` and present the BATCH-WITH-OVERRIDES UI.
4. Write a brief `reviews/{step}/round-NN-fixes.md` (main-chat-authored, ≤30 lines) listing what was changed and why.
5. Run `/compact` (per-skill apply-fix compaction recommendation) to shed the per-reviewer file Read content from main chat's transcript.
6. If looping, dispatch round NN+1 reviewers — they start with clean main-chat context.

**Diff handling between rounds (round 2+).** Round NN+1 reviewers see a focused diff — not the full artifact pasted into the prompt — and main chat never reads diff content into its own context. Three steps:

1. **Per-round commit on the artifact.** After step 4 (writing `round-NN-fixes.md`) and before dispatching round NN+1, commit the round-NN fixes when the artifact directory is inside a git repository: `git -C <repo> commit -m "qrspi: {step} round NN fixes"` covering the artifact and `reviews/{step}/round-NN-*.md`. The commit becomes the round's diff anchor (`HEAD~1` after the round-NN+1 fixes commit) and provides a free rollback point. When the artifact directory is not in a git repo, skip the commit step and the diff-file step below — round NN+1 reviewers see the full artifact, the same as round 1 (the per-reviewer file path savings still apply; only the diff-narrowing optimization degrades).

2. **Orchestrator writes the diff to a file via redirect.** Before dispatching round NN+1, run a Bash call that emits no stdout: `git -C <repo> diff <ref> -- <artifact_path> > <ABS_ARTIFACT_DIR>/reviews/{step}/round-NN.diff`. `<ref>` selects scope: typically `HEAD~1` for round NN+1's narrow delta; `<base-branch>` to force a fresh full-scope round (post-backward-loop, user-requested re-broaden). Bash exits 0 with no stdout — the diff content never enters main chat's transcript. Round 1 has no prior round and writes no diff file; round-1 reviewers see the full artifact only.

3. **Reviewer dispatches reference the diff file by path.** Round NN+1 reviewer prompts (Claude reviewer, scope reviewer, Codex prompt-file) carry `<diff_file_path>` as a string parameter pointing at the round-NN.diff written in step 2; reviewers Read the diff file directly. Single git op per round (vs one per reviewer), byte-identical input across Claude and Codex, and main chat sees no diff text on dispatch or return.

This protocol is the canonical statement of the diff-handling policy. Per-skill SKILL.md files defer to it via the Standard Review Loop reference; they do not need to repeat the diff-redirect mechanics inline.

**Per-task review logs differ.** The `implement` skill's per-task review log at `reviews/tasks/task-NN-review.md` follows a different shape (verbatim prompts and responses are captured for diagnostic purposes, and main chat aggregates per-reviewer responses). The disk-write contract above applies only to **artifact-level** reviews (Goals, Questions, Research, Design, Phasing, Structure, Plan, Parallelize, Replan). See `implement/SKILL.md` § Review Log Artifact for the per-task shape.

## Review-Loop Pause Gate

Inside an autonomous review loop (option 2 from the Standard Review Loop), reviewers may surface findings the orchestrating skill cannot safely auto-apply — for example, findings that would rewrite the artifact's contract, contradict an upstream artifact, or require user judgement about scope. When that happens, the loop **pauses** and presents a single consolidated UI message for that round. This is the **Review-Loop Pause Gate**.

### BATCH-WITH-OVERRIDES UI contract

Each pause emits **one consolidated message per round** with three classes of findings:

1. **Auto-applied findings (silent)** — list silently with a count and a one-line summary. Example: `Auto-applied: 7 findings (typos, formatting, cross-reference repair).` Do not enumerate them; the user does not need to act.
2. **Proposed findings (batch approval)** — show as a numbered list, then ask once: `Apply all proposed findings? (y/n)`. A single `y` accepts the whole batch; `n` skips the whole batch. The user does not approve them individually.
3. **Paused findings (per-finding 3-option menu)** — list each one individually. Each paused finding gets the **3-option menu** below.

### 3-option menu (per paused finding)

For each paused finding, present:

```
1) Apply anyway — apply the finding to the current artifact and continue the loop
2) Skip finding — drop the finding, do not modify the artifact, continue the loop
3) Loop back to upstream artifact — cascade the change backward (W2/W3/W4 cascade per Backward Loops)
```

**Loop back to upstream artifact (W2/W3/W4 cascade):** The skill identifies the earliest affected upstream artifact based on the finding's `referenced_files` and the cascade map (W2 = Goals; W3 = Goals + Questions; W4 = Goals + Questions + Research + Design). The skill MUST display the resolved upstream target name in the menu BEFORE the user picks option 3 (e.g., "Loop back to: phasing.md") and MUST request explicit confirmation (`Confirm rewind to {artifact}? (y/n)`) before initiating the cascade. If the finding's `referenced_files` resolves to ambiguous upstreams, the menu lists the candidates and asks the user to pick.

Option 3 then invokes the standard Backward Loops procedure: update the confirmed upstream artifact, re-review, re-approve, and cascade forward to the current step.

### Paused rounds do not decrement the cap

The 10-round review-loop cap (from Standard Review Loop) **does not decrement on a paused round**. A round that triggers the Pause Gate is treated as user-interactive, not autonomous. When the user resolves the pause and the loop resumes, the round counter continues from the same value it had when the pause fired. The cap still terminates the loop at 10 autonomous rounds, but pauses are free.

**Infinite-pause escape hatch:** Although paused rounds do not decrement the 10-round autonomous cap, the skill MUST track total rounds (autonomous + paused) and ABORT after 20 total rounds OR after 5 consecutive pause-only rounds (whichever comes first). On hitting the escape hatch, the skill writes a final summary to `reviews/{artifact}-loop-escape-round-NN.md` listing all unresolved findings and surfaces to the user with the option to manually triage. This prevents pathological reviewers from generating an unbounded round count.

### Pending-findings file

When the Pause Gate fires, the orchestrating skill writes the round's pending findings to:

```
reviews/{artifact}-loop-pause-round-NN.md
```

For example: `reviews/design-loop-pause-round-03.md`. The file captures the auto-applied summary, the proposed batch, and the paused findings (with their 3-option resolutions once the user decides). This preserves an auditable record of every pause and how it was resolved.

**Write timing:** The skill MUST write the round's pending findings to `reviews/{artifact}-loop-pause-round-NN.md` **before** presenting the BATCH-WITH-OVERRIDES UI to the user. The write is a fail-closed precondition: if the file write fails (permission, ENOSPC), the skill ABORTS and surfaces the error — it does NOT advance the round or present the UI without an audit trail on disk.

## Review Time Allocation

When presenting artifacts for human review, guide the user on where to invest review time:

- **Design and Structure** — invest heavy review here. These artifacts set the architecture. Errors here cascade through every downstream step.
- **Plan** — spot-check. Plan is a mechanical decomposition of approved artifacts. Sample a few task specs for correctness; you don't need to read every line.
- **Implementation code** — use task specs as a review guide. Each spec in `tasks/*.md` describes what a task was supposed to do, making code review efficient and traceable. Time saved on Plan review is time available to read the code.

## Compaction at Step Transitions

> **IMPORTANT — Compaction recommended (terminal state).** This block defines the pipeline-wide compaction-recommendation contract. Each skill's terminal state surfaces a compaction recommendation at the per-skill emphasis marker (terminal state), and each cross-skill transition surfaces a second recommendation at the per-skill emphasis marker (cross-skill transition). Skills enforce this by emitting an `IMPORTANT` callout at each anchor; using-qrspi documents the contract here.

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
| "The goals are obvious, skip Goals" | Goals captures the problem framing every downstream artifact traces to. Without it, you can't articulate what success means at the goal level (acceptance criteria themselves are authored downstream in `plan.md` per the strip-from-goals contract, but they trace back to goals). |
| "Let me just start coding" | Code without a plan means rework. Even quick fixes go through Goals → Questions → Research → Plan. |
| "I can design and implement at the same time" | Design and implementation are separate context windows. Mixing them produces underthought architecture. |
| "This fix doesn't need questions" | Questions identify what you need to learn. Skipping them means you'll discover gaps mid-implementation. |
| "The user said to skip ahead" | The user can request mid-pipeline entry with existing artifacts. They cannot skip steps — each produces a contract downstream steps depend on. |
| "I'll come back and do the reviews later" | Reviews catch issues cheaply. Deferring them means expensive rework. |

## Skill Invocation

> **IMPORTANT — Compaction recommended (cross-skill transition).** Before invoking `qrspi:goals` (or any next-skill invocation in any QRSPI skill), run `/compact` if context utilization may exceed ~50%. Every downstream skill reads its declared inputs + every prior approved artifact + reviewer findings; entering it on a saturated context degrades synthesis, review, and gate-decision quality across the pipeline.

When QRSPI applies, invoke the Goals skill to begin:

**REQUIRED SKILL:** Use `qrspi:goals` to start the pipeline.

## Pipeline Iron Laws — Final Reminder

The four invariants that, when violated, produce the most damage:

1. **Each step requires its declared inputs approved.** Artifact gating is not advisory — skills refuse to run without approved prerequisites. Do not "skip ahead." Use mid-pipeline entry only with the existing-artifacts contract.

2. **`status: approved` in YAML frontmatter is the only approval marker.** Pipeline progression is derived from frontmatter — no state cache file gates ordering (the hook layer's `.qrspi/state.json` is separate runtime state, not consulted by skills). The single piece of derived state worth persisting (`phase_start_commit`) lives in `plan.md` frontmatter; see `plan/SKILL.md`.

3. **Backward loops cascade forward — never patch one artifact in isolation.** New learnings at step N require updating the earliest affected artifact, re-reviewing it, and re-approving every step from there to N. Drift between artifacts breaks every downstream contract.

4. **The `Implement → Integrate` segment is per-phase, not per-task.** Implement runs once per phase; main chat itself is the per-task orchestrator, firing implementer + reviewer subagents per task in the wave (flat dispatch — no per-task orchestrator subagent). Integrate runs once per phase. "One task done" does NOT mean "advance to integrate" — verify against `parallelization.md` (every task in the phase) before routing forward. See `implement/SKILL.md` → "Implement Is the Per-Phase Orchestration Loop" for the canonical contract.

<BEHAVIORAL-DIRECTIVES>
D1 — Encourage reviews after changes: After any significant change to an artifact (whether from feedback, a fix round, or a re-run), recommend a review before proceeding. Reviews catch regressions that are invisible during forward-only execution.

D2 — Never suggest skipping steps for speed: Every step in the QRSPI pipeline exists for a reason. Do not offer shortcuts, suggest merging steps, or imply steps can be skipped to save time.

D3 — Resist time-pressure shortcuts: There is no time crunch. LLMs execute orders of magnitude faster than humans. There is no benefit to skipping LLM-driven steps — reviews, synthesis passes, and validation rounds cost seconds. Reassure the user that thoroughness is free. If the user signals urgency ("just move on," "skip the review this time"), acknowledge the constraint and offer the fastest compliant path. Do not use urgency as justification to skip required steps.
</BEHAVIORAL-DIRECTIVES>
