---
name: goals
description: Use when starting a new QRSPI pipeline run — captures user intent and constraints through interactive dialogue, then synthesizes a problem-framed goals.md
---

# Goals (QRSPI Step 1)

!`cat ${CLAUDE_SKILL_DIR}/../_shared/precondition-block.md`

**Announce at start:** "I'm using the QRSPI Goals skill to capture what you want to build."

## Overview

Capture what the user wants — purpose, environmental constraints, and the per-goal problem frames that downstream skills will work against. Runs as an interactive conversation in the main session, then launches a subagent to synthesize the artifact.

Goals is **problem-framed**, not solution-prescribing. Each goal entry states a problem, why it matters, and what is currently known. Solution candidates may surface in "What we know so far" as **possibilities for Design to weigh** — they are NOT commitments.

**Prohibition.** Goals does NOT author file maps, phasing decisions, or detailed solution definitions; those concerns are owned by downstream artifacts (see "Goals OWNS / Goals DEFERS" below for the locked scope contract).

## Goals OWNS / Goals DEFERS

!cat skills/goals/owns-defers.md

## Goal Type Field

Every goal entry MUST carry a `type` field with value `known-fix` or `exploratory`. The field is grounded in **Knight risk-vs-uncertainty**:

- **`known-fix`** — *risk*. The problem is well-characterized and the solution space is bounded. A reasonable engineer could enumerate the candidate fixes. Cost-benefit reasoning applies normally.
- **`exploratory`** — *uncertainty*. The problem itself is partly uncharted; success criteria emerge through investigation. Exploratory goals are explicitly **protected from cost-benefit reasoning that would defer them** — their value comes from learning that hasn't happened yet, so naive ROI math under-weights them. Do NOT drop or down-rank an exploratory goal because it "isn't shovel-ready" or "has unclear payoff."

If neither value fits cleanly, default to `exploratory` and flag the ambiguity in the goal's "What we know so far" section. Do NOT invent a third value.

## Artifact Gating

**Required inputs:** None (this is the first step)

**Before starting:**
1. Create the artifact directory: `docs/qrspi/YYYY-MM-DD-{slug}/` (relative to the project root, not the plugin directory)
   - **Slug generation:** Take the user's first description of what they want to build, extract 2-4 key words, convert to lowercase kebab-case. Examples: "I want to add user authentication" → `user-auth`, "Build a search API for products" → `product-search-api`. If ambiguous, ask the user to confirm.
   - If the directory already exists, ask the user if they want to continue an existing run or start fresh
2. Mark the provisional "Goals" task (created by `using-qrspi`) as `in_progress`.

### Next-Phase Restart Mode

Goals is invoked in three distinct contexts:

- **Fresh run** — first invocation for a project. No artifact directory, no `config.md`, no `goals.md`. Run the full Interactive Dialogue + Pipeline Mode Selection.
- **Mid-run resume** — user re-enters a paused run. Artifact directory exists; `goals.md` may already be `approved`. Validate `config.md` (Config Validation Procedure below) and either continue or restart from where the user left off.
- **Next-phase restart (invoked by Replan's minor path)** — a prior phase has completed. Per the cascade, **the draft `goals.md` is auto-populated by Replan from `roadmap.md` + `future-goals.md`**: Replan reads `roadmap.md` to identify the next phase's goal IDs, extracts the matching entries from `future-goals.md`, and writes them as the new draft `goals.md` with `status: draft`. `artifact_promote_next_phase` has reset goals/research/design frontmatter to `draft` and deleted phase-scoped files (`structure.md`, `plan.md`, `tasks/`). The `phases/phase-NN/` snapshot from the completed phase exists; `config.md` exists with the original route and pipeline mode.

**Detecting next-phase restart:** All three of these conditions hold:
- `phases/phase-*/` snapshot directory exists (one or more completed phases)
- `goals.md` exists with `status: draft`
- `config.md` exists with valid `route` and `pipeline` fields

**Behavior on next-phase restart:**

0. **Fail-closed precondition (assert before dialogue).** Before running the focused dialogue, assert ALL of the following. On any failure, STOP and surface the failure to the user — do NOT silently dialogue against an empty or partial draft (silent goal loss is the failure mode this guards against):
   1. `roadmap.md` exists in the artifact directory.
   2. `future-goals.md` exists in the artifact directory.
   3. The auto-populated draft `goals.md` is non-empty and well-formed (parses as the goals.md template above).
   4. The draft contains ≥1 goal whose ID matches an entry in `roadmap.md`'s next-phase row.

   If any condition fails, surface a concrete diagnostic (which file is missing, or which IDs failed to match) and ask the user how to proceed (re-run Replan, hand-fix the draft, or abort) before any further work.
1. Skip artifact-directory creation (it exists).
2. Skip the Pipeline Mode Selection *questions* (use the existing `config.md`'s `pipeline` and `route` — these are locked at run start and do not change between phases). Still run the standard Config Validation Procedure on the existing `config.md` to catch hand-edits that may have invalidated it between phases.
3. Run a focused Interactive Dialogue against the auto-populated draft: confirm the promoted goals (Replan-populated from `roadmap.md` + `future-goals.md`) match the user's expectation for this next phase, capture any phase-specific constraints discovered during the prior phase (the Replan feedback file at `feedback/replan-phase-NN-round-MM.md` is one input; ask the user whether they want anything in addition).
4. Re-synthesize `goals.md` (subagent) with the auto-populated content + any new constraints. Preserve goal IDs from `roadmap.md` so downstream artifact references remain valid.
5. Run the standard Review Round + Human Gate; on approval, write `status: approved` and let the standard pipeline cascade (Questions → Research → ... → Parallelize → Implement).

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
- Focus on understanding: purpose, constraints, the per-goal problem frames
- **Scope check:** If the request describes multiple independent subsystems, flag immediately. Help decompose into sub-projects — each gets its own QRSPI run.

Questions to cover (not necessarily in order — follow the conversation):
1. **What are you building?** What is the core purpose / problem space?
2. **Who is it for?** End users, internal team, API consumers?
3. **What constraints exist?** Tech stack, timeline, compatibility, performance.
4. **What problems are in play, and why do they matter?** Probe each goal's **Problem** and **Why we care** — capture the pain, not the proposed fix.
5. **What is currently known?** Prior attempts, partial diagnoses, candidate solutions to weigh — these populate "What we know so far" as **possibilities Design will evaluate**, not commitments.
6. **For each goal, is the problem a `known-fix` (risk — solution space bounded) or `exploratory` (uncertainty — investigation reveals success)?** Default `exploratory` when uncertain; flag the ambiguity in "What we know so far".
7. **Is this greenfield or modifying existing code?**

Do NOT ask the user for per-goal acceptance criteria, file maps, phasing, or "what's out of scope" at this step — those concerns are owned by downstream artifacts (see "Goals OWNS / Goals DEFERS").

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

**Codex reviews** (only ask if the Codex companion is available — glob for `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs` — skip silently if not found):
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
- This skill's "Goals OWNS / Goals DEFERS" section (the locked scope contract)

**Subagent task:**
Produce `goals.md` with this structure. The template is the **conformance contract** for goals.md: required sections and per-goal subsections are enumerated here, claim-before-evidence ordering is mandated, scannable bullets are required, and "be concise" instructions are forbidden (synthesize the substance, do not truncate it).

```markdown
---
status: draft
---

# Goals: {Project/Feature Name}

## Purpose

{1-2 sentences leading with the claim — what is being built and the problem space it addresses. First sentence ≤250 chars, ends with a period.}

## Constraints

- {Environmental constraint 1 — tech stack, compatibility, performance budget, deployment, timeline}
- {Environmental constraint 2}
- ...

## Goals

### G1 — {Short goal name}

- **type:** `known-fix` | `exploratory`

#### Problem

{The problem this goal addresses, framed as a problem (not a solution). One paragraph; lead with the claim. ≤150 words, ≤8 rendered lines per paragraph.}

#### Why we care

{Why this problem matters now — impact, blast radius, who is affected, what breaks if it stays. One paragraph.}

#### What we know so far

{Prior attempts, partial diagnoses, observed signals, and any solution **candidates Design should weigh** (framed as possibilities, not commitments). Use bullets when enumerating candidates so Design can see them at a glance.}

- {Candidate A — Design should weigh}
- {Candidate B — Design should weigh}
- ...

### G2 — {Short goal name}

- **type:** `known-fix` | `exploratory`

#### Problem

{...}

#### Why we care

{...}

#### What we know so far

{...}

{Repeat per goal. Each goal has exactly these three subsections — Problem / Why we care / What we know so far — no others. No per-goal `Acceptance Criteria` subsection. No per-goal `Out of Scope` subsection. No per-goal solution-definition subsection.}

## Cross-Cutting Notes

{OPTIONAL — include only when relationships between goals genuinely cross-cut. Omit the entire section otherwise. Do NOT use this section as a back door for acceptance criteria, file maps, or phasing.}
```

**Iron Rule (template):** the goals.md output has NO top-level `Out of Scope` section and NO top-level `Success Criteria` / `Acceptance Criteria` section. What isn't a goal isn't in scope; acceptance is owned by Design's Test Strategy and Plan's per-task expectations. If the user volunteers exclusions during dialogue, capture them as constraints (when they shape the solution space) or simply omit them — do NOT reintroduce an `Out of Scope` heading.

**Iron Rule (three subsections — emit all three).** Every goal MUST carry exactly the three subsections `Problem`, `Why we care`, `What we know so far`. Emitting only some of them (e.g. omitting `Why we care` because the answer feels obvious) is a synthesis defect, not a permitted shortcut. If the user did not articulate one of the three during dialogue, write a one-sentence honest placeholder under that subsection (e.g. under `Why we care`: "Impact not yet articulated — Design should probe before committing solution work.") rather than dropping the heading. Likewise, do NOT add a fourth subsection under any goal — additional content belongs in `What we know so far` or in a Constraint, not a new heading.

**Iron Rule (type field — concrete value).** Emit ONE concrete value for each goal's `type` field — either `known-fix` OR `exploratory`. NEVER emit the alternation literal `known-fix | exploratory` (that string appears in the template as a placeholder showing the allowed values; it is not a valid output). If uncertain which applies, default to `exploratory` and explain the uncertainty under that goal's `What we know so far` subsection.

**Solutions-as-possibilities framing.** When the user mentions a candidate fix, transcribe it under "What we know so far" with explicit framing such as "candidate Design should weigh" or "possibility for Design to evaluate." Do NOT promote the candidate to a Purpose-line commitment, do NOT enumerate it under Constraints, and do NOT add a `Solution` subsection.

### Review Round

**IMPORTANT:** the synthesis subagent has just returned `goals.md` and three reviewer dispatches are about to run in parallel. If context utilization is high, recommend `/compact` BEFORE dispatching reviewers — once dispatched, each reviewer inherits the current context and any bloat is multiplied across the parallel set.

Apply the **Standard Review Loop** from `using-qrspi/SKILL.md`. Four reviewer dispatches run in parallel on Goals (two Claude + two Codex when `codex_reviews: true`; two Claude when Codex is disabled):

- **Claude quality-reviewer subagent** — dispatch `Agent({ subagent_type: "qrspi-goals-reviewer", model: "sonnet" })` with a prompt containing only:
  - `artifact_body`: `goals.md` content wrapped between `<<<UNTRUSTED-ARTIFACT-START id=goals.md>>>` and `<<<UNTRUSTED-ARTIFACT-END id=goals.md>>>` markers
  - `output`: `<ABS_ARTIFACT_DIR>/reviews/goals/round-NN-claude.md` (interpolate absolute path and round number)
  - `round`: NN
  - `reviewer_tag`: `claude`

  The reviewer protocol (5-field schema, change-type classifier, disk-write contract, untrusted-data handling) arrives via the agent file's `skills:` preload — do NOT embed reviewer-protocol content in the dispatch prompt. The Goals-specific checks (required subsections, no-others, type field, no Out-of-Scope section, etc.) arrive via the agent body auto-loaded by the runtime. Zero rules content in main chat for this dispatch.

- **Claude scope-reviewer subagent** — dispatch `Agent({ subagent_type: "qrspi-goals-scope-reviewer", model: "sonnet" })` in parallel with the quality reviewer, with a prompt containing only:
  - `artifact_body`: same untrusted-data-wrapped `goals.md` body
  - `output`: `<ABS_ARTIFACT_DIR>/reviews/goals/round-NN-scope-claude.md` (interpolate absolute path and round number)
  - `round`: NN
  - `reviewer_tag`: `claude`

  The scope-reviewer's Step-1 Read of `skills/goals/owns-defers.md` delivers the Goals OWNS/DEFERS contract at runtime. Do NOT embed the OWNS/DEFERS rule set or reviewer-protocol content in the dispatch prompt.

- **Codex reviews** (if `codex_reviews: true`) — dispatch TWO non-blocking Codex reviews in parallel (quality + scope) via shell pipelines. The `/tmp/codex-prompt-goals.md` temp-file pattern is retired; protocol and agent body flow via stdin:

  ```sh
  # Quality reviewer (Codex)
  { awk '/^---$/{n++; next} n>=2{print}' skills/reviewer-protocol/SKILL.md;
    printf '\n\n---\n\n';
    awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-goals-reviewer.md;
    printf '\n\n## Dispatch parameters\n\nartifact_body: %s\noutput: <ABS_ARTIFACT_DIR>/reviews/goals/round-%s-codex.md\nround: %s\nreviewer_tag: codex\n' \
      "<untrusted-data-wrapped goals.md body>" "$ROUND" "$ROUND";
  } | scripts/codex-companion-bg.sh launch

  # Scope-reviewer (Codex)
  { awk '/^---$/{n++; next} n>=2{print}' skills/reviewer-protocol/SKILL.md;
    printf '\n\n---\n\n';
    awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-goals-scope-reviewer.md;
    printf '\n\n## Dispatch parameters\n\nartifact_body: %s\noutput: <ABS_ARTIFACT_DIR>/reviews/goals/round-%s-scope-codex.md\nround: %s\nreviewer_tag: codex\n' \
      "<untrusted-data-wrapped goals.md body>" "$ROUND" "$ROUND";
  } | scripts/codex-companion-bg.sh launch
  ```

  The awk strips YAML frontmatter (everything up through the second `---` line). Main chat sees only the jobIds Codex prints.

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

If the artifact directory is inside a git repository, commit the approved `goals.md`, `config.md`, and the `reviews/goals/` directory (per-round per-reviewer files; see `using-qrspi` → "Commit after approval (when applicable)" for the detection rule). Otherwise, skip the commit — the approved frontmatter on disk is the durable record.

**IMPORTANT:** Goals is approved. This is a high-value compaction moment — the dialogue transcript and review-loop context are no longer needed downstream. Recommend `/compact` to the user: "Goals approved. This is a good point to compact context before the next step (`/compact`)."

**IRON RULE — REQUIRED:** Invoke the next skill in the `config.md` route after `goals` (typically `qrspi:questions`). Do NOT skip the route handoff or invoke a different skill out of order. The route is locked at run start and the cross-skill transition is the salience point where downstream isolation begins (Questions must not see this conversation's content beyond `goals.md`).

## Red Flags — STOP

- User describes multiple independent subsystems but you're proceeding without decomposition
- Constraints section is empty — every project has environmental constraints (tech stack, timeline, compatibility)
- A goal is missing the `type` field, or carries a value other than `known-fix` / `exploratory`
- A goal carries fewer or more than the three required subsections (Problem / Why we care / What we know so far)
- The draft is being shaped to include a top-level `Out of Scope` or `Success Criteria` / `Acceptance Criteria` section — those concerns are deferred (see Goals OWNS / Goals DEFERS)
- A solution candidate has been promoted from "What we know so far" into Purpose or Constraints (commitment leakage)
- "Similar to what we did before" without specifying what exactly
- Pipeline mode selected without discussing the work's scope (quick fix for something that needs design, or full pipeline for a one-line change)
- Synthesizing goals.md before capturing the per-goal Problem / Why we care / What we know so far frames

## Common Rationalizations — STOP

| Rationalization | Reality |
|----------------|---------|
| "The user already described what they want clearly" | Clear description ≠ complete goals. The per-goal Problem / Why we care / What we know so far frames still need explicit capture. |
| "This is a quick fix, goals are overkill" | Quick-fix mode exists — use it. Even quick fixes need a captured Problem and Why we care. |
| "I should add acceptance criteria so downstream knows when it's done" | Goals does NOT own acceptance criteria — Design's Test Strategy and Plan's per-task expectations do. Adding them here pre-commits Design. |
| "I should add an Out of Scope section to prevent creep" | Goals does NOT own out-of-scope decisions. What isn't a goal isn't in scope; project-level scope clarifications belong in Design's Approach. |
| "The scope is obvious" | Obvious scope is where scope creep hides. Write the per-goal Problem clearly so Design can scope its solution against it. |
| "This goal feels exploratory but I can't justify the cost so I'll mark it known-fix" | Cost-benefit reasoning is exactly what the `exploratory` tag protects against. Mark it `exploratory` honestly. |
| "Let me just start the research first" | Research without approved goals means you don't know what you're looking for. |

## Goal Specificity

**Goal specificity rule:** Each goal must be independently scopeable — it can be moved between phases without surgery on other goals. A goal that bundles multiple distinct deliverables should be split into separate goals with their own IDs.

**Late splitting:** When a goal proves too coarse during downstream work (Design, Structure, Plan), it can be split. Classify per the standard amendment severity classes (Minor / Major / Scope Unknown) — see `replan/SKILL.md` for the canonical classification. Present each split as a before/after diff; the skill recommends a class, the user decides. After the split, update `roadmap.md` with new goal IDs.

**Red flag:** A goal whose **Problem** statement bundles 3+ distinct problems that could be independently phased. (Goals does NOT enumerate acceptance criteria — boundary-detection runs against the Problem statement.)

**Common rationalization:** "These items are related so they should be one goal" — Related ≠ coupled. If they can be independently scoped and phased, they should be separate goals.

## Worked Example

### Good goals.md — "Rate Limiter for Public API"

```markdown
---
status: draft
---

# Goals: Rate Limiter for Public API

## Purpose

The public REST API has no per-client rate limiting; abusive callers are degrading service for legitimate consumers. This run captures the problem space and known signals so Design can propose a fair-resource-usage architecture.

## Constraints

- Redis is already in the stack and is the only shared-state store available
- Rate-limited paths cannot exceed 5ms p99 overhead (existing latency budget)
- Clients sit behind proxies — X-Forwarded-For must be respected
- Must be deployable without downtime (rolling deploy)
- Timeline: complete within current sprint (5 days)

## Goals

### G1 — Per-client request limiting

- **type:** `known-fix`

#### Problem

A small number of clients are issuing burst traffic that crowds out other consumers. The API has no mechanism to throttle a single client's request rate; every request is served until downstream resources saturate.

#### Why we care

Service quality for legitimate consumers degrades during abuse events. Support load increases as customers report intermittent failures. Without enforcement, a single misbehaving client can effectively DoS the public API.

#### What we know so far

- The abuse pattern is per-API-key; clients without an API key fall back to source IP.
- Industry pattern is token-bucket or sliding-window counters — both are **candidates Design should weigh**.
- Redis-backed counters are a **possibility for Design to evaluate** given the existing Redis dependency; in-memory per-node counters are an alternative Design may also weigh.

### G2 — Rate-limit response headers

- **type:** `known-fix`

#### Problem

When a client is rate-limited it has no way to know when to retry, and even un-throttled clients have no visibility into how close they are to a limit.

#### Why we care

Without retry-guidance headers, polite clients cannot back off correctly and become indistinguishable from abusive ones. SDK authors have requested limit-introspection headers repeatedly.

#### What we know so far

- Common-practice headers include `Retry-After`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` — **candidates Design should weigh** for the response contract.
- IETF `RateLimit-*` draft headers exist as an alternative Design may also weigh.
```

Note what is NOT in this example: no `Success Criteria` or `Acceptance Criteria` section (Design's Test Strategy + Plan's per-task expectations own that), no `Out of Scope` section (what isn't a goal isn't in scope), no per-goal solution definition (candidates are framed as possibilities for Design to weigh).

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

## Goals

### G1 — Rate limiting

#### Problem

Rate limiting needed.

#### What we ship

- 429 responses
- An admin UI to configure limits
- Implementation in Redis with a token bucket
```

### Why the bad one fails

- **No `type` field** on G1 — required.
- **"Rate limiting needed"** is not a problem statement; it's a solution-shaped placeholder. The Problem subsection should describe what is failing and for whom.
- **Missing "Why we care" subsection** entirely — and the goal carries a `What we ship` subsection that is NOT one of the three permitted (Problem / Why we care / What we know so far).
- **Solution commitments leaked** — "Implementation in Redis with a token bucket" pre-commits Design. Such candidates belong in "What we know so far" framed as possibilities Design should weigh.
- **Admin UI smuggled in** — that's a separate goal, not a sub-bullet of "rate limiting." Bundled goals break Replan's per-phase promotion (Goal Specificity rule).
- **"Use existing tech stack"** as a constraint doesn't tell a downstream agent which technology applies — Redis? In-memory? A third-party service? Constraints must be concrete environmental conditions.
- The bad goals.md will cause Questions to ask vague questions, Research to gather irrelevant material, and Design to inherit pre-committed solutions instead of weighing alternatives.

## Iron Laws — Final Reminder

The override-critical rules for Goals, restated at end:

1. **Do NOT synthesize `goals.md` until pipeline mode is selected and `config.md` is written.** The user must explicitly choose `quick` or `full`. Synthesis without an explicit choice locks the run into a default the user never agreed to.

2. **Each goal must be independently scopeable.** A goal that bundles multiple distinct deliverables must be split into separate goals with their own IDs (see "Goal Specificity"). Bundled goals cannot be moved between phases without surgery on adjacent goals — they break Replan's roadmap-driven phase promotion.

3. **Goals is problem-framed, not solution-prescribing.** Each goal carries the `type` field (`known-fix | exploratory`) and exactly the three subsections — Problem, Why we care, What we know so far. No top-level `Out of Scope` or acceptance-criteria sections exist. Solution candidates are framed as **possibilities for Design to weigh**, never as commitments. The "Goals OWNS / Goals DEFERS" section is the locked scope contract; the scope-reviewer dispatches against it.

Behavioral directives D1-D3 (encourage reviews after changes, no shortcuts for speed, no time-pressure skips) apply — see `using-qrspi/SKILL.md` → "BEHAVIORAL-DIRECTIVES".
