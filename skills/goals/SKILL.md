---
name: goals
description: Use when starting a new QRSPI pipeline run — captures user intent, constraints, and acceptance criteria through interactive dialogue, then synthesizes goals.md
---

# Goals (QRSPI Step 1)

**PRECONDITION:** Invoke `qrspi:using-qrspi` skill to ensure global pipeline rules are in context. (Idempotent on session re-entry. Subagents are exempt — SUBAGENT-STOP in using-qrspi handles that.)

**Announce at start:** "I'm using the QRSPI Goals skill to capture what you want to build."

## Overview

Capture what the user wants — intent, constraints, success criteria, acceptance criteria. This is the "ticket" equivalent but doesn't require a ticket system. Runs as an interactive conversation in the main session, then launches a subagent to synthesize the artifact.

## Artifact Gating

**Required inputs:** None (this is the first step)

**State bootstrap:** If `.qrspi/state.json` does not exist or `state_read` returns non-zero, call `state_init_or_reconcile <artifact_dir>`.

**Before starting:**
1. Create the artifact directory: `docs/qrspi/YYYY-MM-DD-{slug}/` (relative to the project root, not the plugin directory)
   - **Slug generation:** Take the user's first description of what they want to build, extract 2-4 key words, convert to lowercase kebab-case. Examples: "I want to add user authentication" → `user-auth`, "Build a search API for products" → `product-search-api`. If ambiguous, ask the user to confirm.
   - If the directory already exists, ask the user if they want to continue an existing run or start fresh
2. Mark the provisional "Goals" task (created by `using-qrspi`) as `in_progress`.

### Next-Phase Restart Mode

Goals is invoked in three distinct contexts:

- **Fresh run** — first invocation for a project. No artifact directory, no `config.md`, no `goals.md`. Run the full Interactive Dialogue + Pipeline Mode Selection.
- **Mid-run resume** — user re-enters a paused run. Artifact directory exists; `goals.md` may already be `approved`. Validate `config.md` (Config Validation Procedure below) and either continue or restart from where the user left off.
- **Next-phase restart (invoked by Replan's minor path)** — a prior phase has completed; `artifact_promote_next_phase` has reset goals/research/design frontmatter to `draft` and deleted phase-scoped files (`structure.md`, `plan.md`, `tasks/`). The `phases/phase-NN/` snapshot from the completed phase exists; `config.md` exists with the original route and pipeline mode; `goals.md` exists with `status: draft` containing the next phase's promoted goals (per Replan's roadmap-driven promotion).

**Detecting next-phase restart:** All three of these conditions hold:
- `phases/phase-*/` snapshot directory exists (one or more completed phases)
- `goals.md` exists with `status: draft`
- `config.md` exists with valid `route` and `pipeline` fields

**Behavior on next-phase restart:**

1. Skip artifact-directory creation (it exists).
2. Skip the Pipeline Mode Selection *questions* (use the existing `config.md`'s `pipeline` and `route` — these are locked at run start and do not change between phases). Still run the standard Config Validation Procedure on the existing `config.md` to catch hand-edits that may have invalidated it between phases.
3. Run a focused Interactive Dialogue: confirm the promoted goals match the user's expectation for this next phase, capture any phase-specific constraints discovered during the prior phase (the Replan feedback file at `feedback/replan-phase-NN-round-MM.md` is one input; ask the user whether they want anything in addition).
4. Re-synthesize `goals.md` (subagent) with the promoted content + any new constraints.
5. Run the standard Review Round + Human Gate; on approval, write `status: approved` and let the standard pipeline cascade (Questions → Research → ... → Parallelize → Implement).

**State reconciliation on next-phase restart.** Replan calls `state_init_or_reconcile <artifact_dir>` before invoking Goals, so Goals does not call it again on next-phase restart. The fresh-run bootstrap above still applies when state is genuinely missing.

<HARD-GATE>
Do NOT synthesize goals.md until the pipeline mode is selected and config.md is written.
The user must explicitly choose quick fix or full pipeline before synthesis begins.
</HARD-GATE>

### Config Validation (when config.md exists)

If `config.md` already exists (resuming a run), apply the **Config Validation Procedure** in `using-qrspi/SKILL.md`. Goals validates `route`, `pipeline`, and `codex_reviews`.

## Process

### Interactive Dialogue

- **One question at a time** — don't overwhelm with multiple questions
- **Prefer multiple choice** when possible, open-ended is fine too
- Focus on understanding: purpose, constraints, success criteria
- **Scope check:** If the request describes multiple independent subsystems, flag immediately. Help decompose into sub-projects — each gets its own QRSPI run.

Questions to cover (not necessarily in order — follow the conversation):
1. **What are you building?** What is the core purpose?
2. **Who is it for?** End users, internal team, API consumers?
3. **What constraints exist?** Tech stack, timeline, compatibility, performance?
4. **What does success look like?** Specific, testable acceptance criteria.
5. **What's out of scope?** Explicitly exclude to prevent scope creep.
6. **Is this greenfield or modifying existing code?**

### Pipeline Mode Selection

After intent capture (the interactive dialogue above) but before synthesizing `goals.md`, determine the pipeline configuration. Ask these questions — one at a time, using numbered choices:

**Pipeline mode:**
1. Quick fix (goals → questions → research → plan → implement → test)
2. Full pipeline (goals → questions → research → design → structure → plan → parallelize → implement → integrate → test)

**UX step** (only ask if `qrspi:ux` skill exists — glob for `~/.claude/plugins/cache/*/qrspi/*/skills/ux/` — skip silently if not found):
1. No UX step
2. Include UX/wireframing step after Design

**Review depth** (only ask when full pipeline is selected):
1. Quick (4 correctness reviewers)
2. Deep (correctness + thoroughness, all 8 reviewers)

**Codex reviews** (only ask if `codex:rescue` is available — glob for `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs` — skip silently if not found):
1. No Codex reviews
2. Use Codex for second reviews this run

Once you have answers, write `config.md` in the artifact directory:

```yaml
---
created: YYYY-MM-DD
pipeline: quick  # or full
codex_reviews: true  # or false
route:
  - goals
  - questions
  - research
  - plan  # quick stops here before implement
  - implement
  - test
---
```

Route templates live in `using-qrspi/SKILL.md` → "Route Templates" (Quick / Full / Full + UX). Use the template that matches the user's selection. UX is not applicable to quick-fix routes.

After writing `config.md`, rewrite the Level 1 pipeline tasks to match the route (add or remove steps as needed).

### Artifact Synthesis

Once the conversation settles, launch a **subagent** to synthesize `goals.md`:

**Subagent inputs:**
- The conversation content (user's answers to the dialogue questions)

**Subagent task:**
Produce `goals.md` with this structure:

```markdown
---
status: draft
---

# Goals: {Project/Feature Name}

## Purpose
{1-2 sentences: what is being built and why}

## Constraints
- {constraint 1}
- {constraint 2}
- ...

## Success Criteria
- [ ] {testable criterion 1}
- [ ] {testable criterion 2}
- ...

## Out of Scope
- {exclusion 1}
- {exclusion 2}

## Context
- Greenfield / Existing codebase
- {Any other relevant context from the conversation}
```

### Review Round

Apply the **Standard Review Loop** from `using-qrspi/SKILL.md`. Goals-specific reviewer instructions:

- **Claude review subagent** — launched with `goals.md`. Checks: completeness; testable acceptance criteria; missing constraints/assumptions; scope appropriate for a single implementation. Findings written to `reviews/goals-review.md`.
- **Codex review** (if `codex_reviews: true`) — `codex:rescue` with `goals.md`; no predecessor artifacts to cross-reference. Findings appended to `reviews/goals-review.md`.

### Human Gate

Present the synthesized `goals.md` to the user. **Always state the review status** when presenting: either "Reviews passed clean in round N" or "Reviews found issues in round N which were fixed but not re-verified."

They can:
- **Approve** → if reviews have not passed clean, note this and ask if they'd like a review loop before finalizing. Then write `status: approved` in frontmatter.
- **Request changes** → write the user's feedback to `feedback/goals-round-{NN}.md` (see using-qrspi Feedback File Format), then continue the conversation and re-synthesize with a new subagent that receives the original inputs + **all** prior feedback files (not just the latest round). After re-generation and the review cycle completes, present:

  > Feedback applied. How would you like to proceed?
  > 1. More feedback (I have additional changes)
  > 2. Single review round (run Claude + Codex once, see findings)
  > 3. Loop until clean (autonomous review cycles)
  > 4. Approve (I'm satisfied, skip reviews)

  Omit option 2 if Codex is disabled in config.md. Omit the "fix issues" options (options 2 and 3) if there are no issues to fix.

### Terminal State

If the artifact directory is inside a git repository, commit the approved `goals.md`, `config.md`, and `reviews/goals-review.md` (see `using-qrspi` → "Commit after approval (when applicable)" for the detection rule). Otherwise, skip the commit — the approved frontmatter on disk is the durable record.

Recommend compaction: "Goals approved. This is a good point to compact context before the next step (`/compact`)."

**REQUIRED:** Invoke the next skill in the `config.md` route after `goals`.

## Red Flags — STOP

- User describes multiple independent subsystems but you're proceeding without decomposition
- Acceptance criteria are subjective ("it should feel fast") instead of testable ("response time < 200ms")
- Constraints section is empty — every project has constraints (tech stack, timeline, compatibility)
- Out of scope section is empty — scope creep happens when boundaries aren't explicit
- "Similar to what we did before" without specifying what exactly
- Pipeline mode selected without discussing the work's scope (quick fix for something that needs design, or full pipeline for a one-line change)
- Synthesizing goals.md before asking about constraints or success criteria

## Common Rationalizations — STOP

| Rationalization | Reality |
|----------------|---------|
| "The user already described what they want clearly" | Clear description ≠ complete goals. Acceptance criteria, constraints, and out-of-scope still need explicit capture. |
| "This is a quick fix, goals are overkill" | Quick-fix mode exists — use it. But even quick fixes need captured intent and acceptance criteria. |
| "I can infer the acceptance criteria" | Inferred criteria lead to "that's not what I meant." Make them explicit and get approval. |
| "The scope is obvious" | Obvious scope is where scope creep hides. Write it down. |
| "Let me just start the research first" | Research without approved goals means you don't know what you're looking for. |

## Goal Specificity

**Goal specificity rule:** Each goal must be independently scopeable — it can be moved between phases without surgery on other goals. A goal that bundles multiple distinct deliverables should be split into separate goals with their own IDs.

**Late splitting:** When a goal proves too coarse during downstream work (Design, Structure, Plan), it can be split. Classify per the standard amendment severity classes (Minor / Major / Scope Unknown) — see `replan/SKILL.md` for the canonical classification. Present each split as a before/after diff; the skill recommends a class, the user decides. After the split, update `roadmap.md` with new goal IDs.

**Red flag:** A goal whose acceptance criterion text describes 3+ distinct deliverables that could be independently phased.

**Common rationalization:** "These items are related so they should be one goal" — Related ≠ coupled. If they can be independently scoped and phased, they should be separate goals.

## Worked Example

### Good goals.md — "Rate Limiter for Public API"

```markdown
---
status: draft
---

# Goals: Rate Limiter for Public API

## Purpose
Add per-client rate limiting to the public REST API to prevent abuse and ensure
fair resource usage across all API consumers.

## Constraints
- Must use Redis for shared state (already in the stack)
- Must not exceed 5ms p99 overhead on rate-limited paths
- Must respect X-Forwarded-For headers for clients behind proxies
- Must be deployable without downtime (rolling deploy)
- Timeline: complete within current sprint (5 days)

## Success Criteria
- [ ] Clients exceeding 100 requests/min receive 429 Too Many Requests
- [ ] Response includes Retry-After header with seconds until reset
- [ ] Limits are enforced consistently across all API nodes (Redis-backed)
- [ ] Rate limit headers (X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset) present on every response
- [ ] Existing test suite passes with no regressions
- [ ] p99 latency overhead measured at < 5ms under load test

## Out of Scope
- Per-endpoint rate limits (uniform limit only)
- Admin UI for configuring limits
- Billing-tier differentiation
- IP allowlisting / blocklisting

## Context
- Existing codebase (Express + Redis already deployed)
- Rate limit key: API key from Authorization header; fallback to IP
```

### Bad goals.md — "Rate Limiting"

```markdown
---
status: draft
---

# Goals: Rate Limiting

## Purpose
Add rate limiting so the API doesn't get abused.

## Constraints
- Use existing tech stack

## Success Criteria
- [ ] Rate limiting works
- [ ] API is still fast

## Out of Scope
- (none specified)

## Context
- Existing codebase
```

### Why the bad one fails

- **"Rate limiting works"** is not testable. Works at what threshold? For which clients? Verified how?
- **"API is still fast"** is subjective. Fast compared to what baseline? Measured how?
- **Constraints section** says "existing tech stack" — this doesn't tell a downstream agent which technology to use. Redis? In-memory? A third-party service?
- **Out of scope is empty** — without explicit exclusions, downstream agents will make assumptions. One agent might scope in per-endpoint limits, another might add an admin UI. Scope creep enters here.
- **No X-Forwarded-For mention** — a real production requirement that will be discovered mid-implementation and trigger a backward loop.
- The bad goals.md will cause Questions to ask vague questions, Research to gather irrelevant material, and Design to propose an architecture the user didn't want.

## Iron Laws — Final Reminder

The two override-critical rules for Goals, restated at end:

1. **Do NOT synthesize `goals.md` until pipeline mode is selected and `config.md` is written.** The user must explicitly choose `quick` or `full`. Synthesis without an explicit choice locks the run into a default the user never agreed to.

2. **Each goal must be independently scopeable.** A goal that bundles multiple distinct deliverables must be split into separate goals with their own IDs (see "Goal Specificity"). Bundled goals cannot be moved between phases without surgery on adjacent goals — they break Replan's roadmap-driven phase promotion.

Behavioral directives D1-D3 (encourage reviews after changes, no shortcuts for speed, no time-pressure skips) apply — see `using-qrspi/SKILL.md` → "BEHAVIORAL-DIRECTIVES".
