# Goals — First-Run Setup (Read on Trigger)

**Trigger:** Read this file on entry to Goals, BEFORE the first user turn of dialogue. One-shot per Goals invocation.

This file owns the run-once setup steps: artifact directory creation, next-phase-restart detection, config validation, and pipeline mode selection. Once this stage is complete, return to SKILL.md for Defining Goals.

## Artifact Gating

**Required inputs:** None (this is the first step.)

**Before starting:**

1. Create the artifact directory: `docs/qrspi/YYYY-MM-DD-{slug}/` (relative to the project root, not the plugin directory).
   - **Slug generation:** Take the user's first description of what they want to build, extract 2–4 key words, convert to lowercase kebab-case. Examples: "I want to add user authentication" → `user-auth`, "Build a search API for products" → `product-search-api`. If ambiguous, ask the user to confirm.
   - If the directory already exists, ask the user if they want to continue an existing run or start fresh.
2. Mark the provisional "Goals" task (created by `using-qrspi`) as `in_progress`.

## Next-Phase Restart Mode

Goals runs in three contexts:

- **Fresh run** — no artifact directory, no `config.md`, no `goals.md`. Run the full Pipeline Mode Selection below, then proceed to Defining Goals.
- **Mid-run resume** — artifact directory exists; `goals.md` may already be `approved`. Validate `config.md` and continue from where the user left off.
- **Next-phase restart (invoked by Replan's minor path)** — a prior phase completed. **Replan auto-populates the draft `goals.md` from `roadmap.md` + `future-goals.md`**: Replan reads `roadmap.md` for the next phase's goal IDs, extracts matching entries from `future-goals.md`, and writes them as the new draft `goals.md` (`status: draft`). `artifact_promote_next_phase` has reset goals/research/design frontmatter to `draft` and deleted phase-scoped files (`structure.md`, `plan.md`, `tasks/`). The `phases/phase-NN/` snapshot exists; `config.md` carries the original route and pipeline.

**Detecting next-phase restart:** all three hold:

- `phases/phase-*/` snapshot directory exists.
- `goals.md` exists with `status: draft`.
- `config.md` exists with valid `route` and `pipeline`.

**Behavior on next-phase restart:**

0. **Fail-closed precondition.** STOP on any failure — do NOT silently dialogue against an empty/partial draft (silent goal loss is the failure mode this guards):
   1. `roadmap.md` exists in the artifact directory.
   2. `future-goals.md` exists.
   3. The auto-populated draft `goals.md` is non-empty and well-formed.
   4. The draft contains ≥1 goal whose ID matches an entry in `roadmap.md`'s next-phase row.

   On failure, surface a concrete diagnostic and ask the user how to proceed (re-run Replan, hand-fix, abort).
1. Skip artifact-directory creation.
2. Skip the Pipeline Mode Selection questions (the existing `config.md` carries `pipeline` and `route`). Still run Config Validation to catch hand-edits.
3. Run a focused Defining Goals dialogue against the auto-populated draft: confirm promoted goals match the user's next-phase expectation; capture new constraints (the Replan feedback file `feedback/replan-phase-NN-round-MM.md` is one input).
4. Re-synthesize `goals.md` per the Defining Goals incremental-persistence path with the auto-populated content + new constraints. Preserve goal IDs from `roadmap.md` so downstream references stay valid.
5. Run After Goals Are Locked (Review Round + Human Gate); on approval, write `status: approved` and let the pipeline cascade.

## Config Validation (when config.md exists)

If `config.md` already exists (resuming a run), apply the **Config Validation Procedure** in `using-qrspi/SKILL.md`. Goals validates `route`, `pipeline`, `second_reviewer`, `verifier_enabled`, `scope_tagger_enabled`, `visual_fidelity_required`, and (when `pipeline: quick`) `question_budget`.

## Pipeline Mode Selection

For full prose on what each `config.md` field means and the format of the file, see `references/config-md-authoring.md` (read alongside this file when authoring `config.md` for the first time).

After intent capture but before synthesizing `goals.md`, ask these questions one at a time:

**Pipeline mode:**
1. Quick fix (goals → questions → research → plan → implement → test)
2. Full pipeline (goals → questions → research → design → structure → plan → parallelize → implement → integrate → test)

**UX step** (only ask if `qrspi:ux` skill exists — glob `~/.claude/plugins/cache/*/qrspi/*/skills/ux/`; skip silently if not found):
1. No UX step
2. Include UX/wireframing step after Design

**Review depth** (only ask when full pipeline is selected):
1. Quick (4 correctness reviewers)
2. Deep (correctness + thoroughness, all 8 reviewers)

**Second-model review** (only ask if a second-reviewer vendor is available — run `bash scripts/second-reviewer-available.sh`; on non-zero exit, skip silently and write `second_reviewer: false`):
1. No second-model reviews
2. Use a second model for second reviews this run

Write `config.md`. The fence below is the **quick-pipeline** writer output. For `pipeline: full`, use the same shape but (a) substitute the full route, (b) substitute `pipeline: full`, and (c) **omit `question_budget` entirely** — that field is `pipeline: quick`-only (caps Research specialist dispatch). Route templates live in `using-qrspi/SKILL.md` → "Route Templates"; UX does not apply to quick-fix. After writing, rewrite the Level 1 pipeline tasks to match.

```yaml
---
created: YYYY-MM-DD
pipeline: quick
second_reviewer: true  # or false
route:
  - goals
  - questions
  - research
  - plan  # quick stops here before implement
  - implement
  - test
verifier_enabled: true  # edit between rounds to disable for the whole run
scope_tagger_enabled: true  # edit between rounds to disable convergence narrowing
visual_fidelity_required: false  # default false unless opted into visual-fidelity binding chain
question_budget: 5
---
```

## HARD-GATE — Synthesis Precondition

<HARD-GATE>
Do NOT begin Defining Goals incremental persistence to `goals.md` until the pipeline mode is selected and `config.md` is written.
The user must explicitly choose quick fix or full pipeline before any per-goal block is written.
</HARD-GATE>

## Return to SKILL.md

When First-Run Setup is complete (`config.md` written, no fail-closed precondition triggered), return to SKILL.md and begin Defining Goals.
