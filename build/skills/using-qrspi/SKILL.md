---
name: using-qrspi
description: Use when starting any conversation — establishes the QRSPI pipeline for agentic software development, requiring structured progression through Goals, Questions, Research, Design, Phasing, Structure, Plan, Parallelize, Implement, Integrate, Test, with Replan firing between phases
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill entirely. Do not start a new QRSPI pipeline — just do your assigned work.
</SUBAGENT-STOP>

# Using QRSPI

## Recommended Workspace Layout

Read `skills/using-qrspi/references/workspace-layout.md` when setting up a new run's on-disk layout or auditing an existing one — artifact/code separation (`docs/qrspi/{slug}/` vs target repo) and the greenfield bootstrap note.

## The Pipeline

Read `skills/using-qrspi/references/pipeline-overview.md` when you need the full pipeline shape — both diagrams (full + quick-fix) and the per-step what/why/artifact table.

## Route Templates

Read `skills/using-qrspi/references/route-templates.md` when Goals is seeding `config.md.route` at run start, or when the user requests a mid-pipeline route change — quick / full / full-plus-UX templates plus the route-change rules.

## Artifact Directory

Read `skills/using-qrspi/references/artifact-directory.md` when creating the artifact directory for a new run, or when resolving the slug for an existing run — full per-run on-disk tree (`docs/qrspi/YYYY-MM-DD-{slug}/...`) and slug-generation rule.

## Approval Markers

Read `skills/using-qrspi/references/approval-markers.md` when transitioning a step to `status: approved` (or `replan-draft`), or before the post-approval git commit — semantics and commit rule.

## State and Pipeline Ordering

Pipeline state is derived from artifact frontmatter; the only piece of derived state worth persisting is `phase_start_commit` (lives in `plan.md` frontmatter, scoped by Replan and Test).

Read `skills/using-qrspi/references/state-and-pipeline-ordering.md` before dispatching a downstream step when checking predecessor-approval gating — predecessor rules and the Implement batch trap. Orchestration-boundary enforcement lives in each phase SKILL (`implement/`, `integrate/`, `test/`).

## Rejection Behavior

When the user rejects an artifact at a human gate, the current step re-runs with feedback until approved — never skips backward. For subagent-dispatching steps (Plan, Parallelize, Structure), the orchestrator launches a new subagent round with the original inputs plus a feedback file (see Feedback File Format below). For conversational steps (Goals, Design), the rejection iterates in-conversation without writing a feedback file.

## Backward Loops (New Learnings)

Read `skills/using-qrspi/references/backward-loops.md` when a downstream step surfaces new learnings about an upstream artifact — cascade-forward rule.

## Mid-Pipeline Entry

Users can enter mid-pipeline when required input artifacts already exist with `status: approved`; mid-pipeline resume also detects `replan-pending.md` to resume Replan when set.

Read `skills/using-qrspi/references/mid-pipeline-entry.md` when resuming a run partway through the pipeline (artifact directory already exists, some steps already approved) — full resume contract and existing-artifacts handshake.

## Pipeline Progress

Read `skills/using-qrspi/references/pipeline-progress.md` when unsure where the run currently sits in the pipeline — diagnostic for resolving ambiguous status.

## Artifact Gating Check (Standard Pattern)


Every skill uses this standard pattern to verify its prerequisites:

1. Read the required artifact file
2. Parse YAML frontmatter (content between first two `---` markers)
3. Check that `status` field equals `approved`
4. If file missing: "Cannot proceed — {artifact} not found. Complete the {previous step} step first."
5. If file exists but not approved: "Cannot proceed — {artifact} exists but hasn't been approved yet. Review and approve it first."

## Config File (`config.md`)

Read `skills/using-qrspi/references/config-runtime-contract.md` when validating any `config.md` field, dispatching an agent, resolving a `model_routing:` tier, or handling a runtime-backfill write — dispatch routing blocks (`providers:`, `model_routing:`, `trusted_path:`, `validators:`), Precedence chain, Config Validation Procedure, no-silent-defaults rule, runtime-backfill carve-outs + hard-stop on write-back failure, field-validation-by-skill table. The authoring side (format, field definitions, writing procedure, `pipeline: quick` semantics) lives at `skills/goals/references/config-md-authoring.md` and is `!cat`-included into Goals — read it directly only when auditing Goals' config-writing behavior.

## Standard Review Loop

Every artifact-producing step runs the Standard Review Loop. Read `skills/_shared/review-loop.md` when dispatching reviewers, computing kept findings, or deciding fix-loop convergence — canonical SSoT (checklist + reviewer dispatch shape + convergence rule). Sweep-task findings ride the existing Plan re-spec loop (no new gate, no new runner behavior).

## Apply-Fix Protocol

After each review round, the orchestrator invokes `scripts/review-prep.sh` (per-round diff emission with anchor-SHA narrow-ref, atomic temp+rename) then `scripts/verifier-fan-in.sh` (SSoT for verifier dispatch, change_type-keyed score filters, `round-NN-verified.md` assembly). Read `skills/using-qrspi/references/apply-fix-protocol.md` after `verifier-fan-in.sh` emits `round-NN-verified.md`, when applying fixes for the round — the full post-fan-in procedure (partition by change_type, scope-tagger dispatch, dispositions.md, per-round commit, convergence rule, backward-loop reset, reviewer-model audit-field, verifier-round failure menu). Read `skills/using-qrspi/references/fix-altitude-rule.md` when a finding contains the phrase "X is under-specified" — the F-5 altitude rule.


## Review-Loop Pause Gate

Inside an autonomous review loop (option 2 from the Standard Review Loop), the loop **pauses** when reviewers surface findings the orchestrating skill cannot safely auto-apply. The 10-round review-loop cap **does not decrement on a paused round** — paused rounds are user-interactive, not autonomous.

Read `skills/using-qrspi/references/review-loop-pause-gate.md` when the review loop hits the pause gate (review-round kept-findings non-zero, or a sub-threshold rescue is being surfaced) — full BATCH-WITH-OVERRIDES UI contract, 3-option menu (apply / skip / loop-back to upstream), infinite-pause escape hatch, and pending-findings audit-file shape.

## Compaction Checkpoints

QRSPI skills mark transition points where main-chat context bloat degrades downstream quality. At every checkpoint and at every user-input pause, the orchestrator follows the Iron Rule below — regardless of perceived utilization, regardless of auto-mode.

**Iron Rule.** Pause and recommend `/compact` to the user before continuing. The user can decline; do not skip the recommendation.

Read `skills/using-qrspi/references/compaction-checkpoints-detail.md` when approaching a context-saturation checkpoint and unsure which trigger applies for the current step — full list of checkpoint trigger points per pipeline step.

## Feedback File Format

Read `skills/using-qrspi/references/feedback-file-format.md` when writing or consuming a feedback file after a rejection round in Plan, Parallelize, or Structure — `{artifact-dir}/feedback/{step}-round-{NN}.md` YAML+markdown schema. Goals/Design rejection flows interactively and does not produce feedback files.

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

## Pipeline Rules

1. **Each step requires its declared inputs approved.** Artifact gating is not advisory — skills refuse to run without approved prerequisites. Do not "skip ahead." Use mid-pipeline entry only with the existing-artifacts contract.

2. **`status: approved` in YAML frontmatter is the only approval marker.** Pipeline progression is derived from frontmatter — no state cache file gates ordering. The single piece of derived state worth persisting (`phase_start_commit`) lives in `plan.md` frontmatter; see `plan/SKILL.md`.

3. **Backward loops cascade forward — never patch one artifact in isolation.** New learnings at step N require updating the earliest affected artifact, re-reviewing it, and re-approving every step from there to N. Drift between artifacts breaks every downstream contract.

4. **The `Implement → Integrate` segment is per-phase, not per-task.** Implement runs once per phase; main chat itself is the per-task orchestrator, firing implementer + reviewer subagents per task in the wave (flat dispatch — no per-task orchestrator subagent). Integrate runs once per phase. "One task done" does NOT mean "advance to integrate" — verify against `parallelization.md` (every task in the phase) before routing forward. See `implement/SKILL.md` → "Implement Is the Per-Phase Orchestration Loop" for the canonical contract.

## Conversation Rules

1. **Recommend a review after any significant change to an artifact** (from feedback, a fix round, or a re-run). Reviews catch regressions that are invisible during forward-only execution.

2. **Never suggest skipping steps for speed.** Every step exists for a reason. Do not offer shortcuts, suggest merging steps, or imply steps can be skipped to save time.

3. **Resist time-pressure shortcuts.** LLMs execute orders of magnitude faster than humans — reviews, synthesis passes, and validation rounds cost seconds. Reassure the user that thoroughness is free. If the user signals urgency ("just move on," "skip the review this time"), acknowledge the constraint and offer the fastest compliant path. Do not use urgency as justification to skip required steps.

4. **Use jargon-free language with the user.** In user-facing text (questions, status updates, design proposals, summaries), do not use issue numbers, ticket IDs, goal IDs (G1/G2/…), agent file names, skill names, `change_type` values (the per-finding routing categories: style/clarity/correctness/scope/intent), file paths, or other internal terminology without grounding them in plain English on first reference per response. Subagent dispatch prompts and structured artifacts may use full vocabulary — those are read by agents that already have the context loaded; the rule applies only to text the user reads directly.

   Example: instead of "the qrspi-finding-verifier from #109 was added with verifier_enabled: true default," write "the verifier — a small fast model that scores each finding 0–100 — was turned on by default in a recent change." Orchestrators tend to lean on jargon under context pressure, exactly when this guidance matters most.
