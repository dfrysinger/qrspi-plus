---
name: goals
description: Use when starting a new QRSPI pipeline run — captures user intent and constraints through interactive dialogue, then synthesizes a problem-framed goals.md
---

# Goals (QRSPI Step 1)

!cat skills/_shared/precondition-block.md

**Announce at start:** "I'm using the QRSPI Goals skill to capture what you want to build."

**If auto-mode is detected** (presence of `## Auto Mode Active` system-reminder), surface before the first interactive step: "This skill is collaborative — turn-by-turn dialogue produces better Goals quality than autonomous execution. Recommend exiting auto-mode (`Shift+Tab` to cycle modes). I'll proceed in either mode if you prefer." Do not force the user out; respect their choice.

## Overview

Capture purpose, environmental constraints (when known), and the per-goal problem frames that downstream skills work against. Runs as an interactive conversation in the main session, persisting each locked decision directly to `goals.md` on disk.

Goals is **problem-framed**, not solution-prescribing. Each goal states a problem, why it matters, and what is known. Solution candidates surface in "What we know so far" as **possibilities for Design to weigh** — NOT commitments.

**Prohibition.** Goals does NOT author file maps, phasing decisions, or detailed solution definitions; those are owned by downstream artifacts.

## Goals OWNS / Goals DEFERS

!cat skills/goals/owns-defers.md

## The Three Stages

Goals runs three stages per invocation. First-Run Setup and After Goals Are Locked live in dedicated reference files and are read on trigger; the Defining Goals stage (the user-facing dialogue) lives below in this file.

- **First-Run Setup** (run-once on entry). Artifact directory creation, next-phase-restart detection, config validation, pipeline mode selection, `config.md` HARD-GATE. **Trigger:** Read `references/setup.md` on entry to Goals, BEFORE the first user turn of dialogue.
- **Defining Goals** (the bulk of the skill — captured below). What to ask, how to engage, what to write per goal, incremental persistence to disk, final coverage review.
- **After Goals Are Locked**. Review Round, Human Gate, Terminal State / next-skill handoff. **Trigger:** Read `references/post-lock.md` AFTER all goals are locked on disk and the user has signaled the dialogue is complete.

# Defining Goals

This stage covers everything between First-Run Setup (`config.md` written) and After Goals Are Locked (all goals locked; entering review). All rules in this stage apply per-goal during the conversation.

## What to Ask

- **One question at a time** — don't overwhelm.
- **Prefer multiple choice** when possible — but only for goal-articulation questions (see Dialogue Conduct Rule 5).
- Focus on the users, their needs, and any environmental constraints that are already committed to.

Question coverage (order follows the conversation; phrasing is a guide — adapt the voice but keep the intent):

1. **Who is this for?** Name the users concretely — end users, internal teams, API consumers, admins, ops, any stakeholder this work serves. **Are there secondary or tertiary users we should also consider?** (e.g., the primary user is a customer, but admins configure their experience, support staff handle their escalations, ops maintain the system serving them.) Capture every user the work touches — those secondary and tertiary users become angles for the Rule 9 stakeholder probe and the Final Coverage Review.
2. **What do we know about what those users want, need, or struggle with today?** Capture as user-need statements — outcomes the user is trying to reach ("users need to [verb]") not features we'd build ("we should build [noun]"). Classic trap: "users need a dashboard" → they need to digest varied information in one place; the dashboard is one possible solution.
3. **For each need, why does the user have it?** Probe root motivation by asking "why" 1–3 times. Stop when the answer is a durable user outcome rather than a process complaint, or when further probing turns philosophical. Goal: surface the underlying job-to-be-done, not interrogate.
4. **Do we have any concrete evidence for those needs?** Direct user feedback, support tickets, analytics, observed behavior, prior incidents — or is the need inferred or assumed? Mark each need's evidence basis (observed / inferred / assumed) so Research knows where to dig and Design knows what's verified vs hypothesis.
5. **Does the user have a workaround today?** The current journey — even if painful — signals problem magnitude and surfaces assumptions to overturn.
6. **Has this need been attempted to be solved before, here or elsewhere, that we should know about?** Prior internal attempts to avoid repeating; competing or adjacent products worth studying for inspiration; specific patterns to avoid (and why). Feeds Research and Design.
7. **For each goal, does it feel like `known-fix` (risk — solution space bounded) or `exploratory` (uncertainty — success criteria emerge through investigation)?** Default `exploratory` when uncertain; flag the ambiguity. Exploratory goals are protected from cost-benefit reasoning that would defer them.
8. **Are there any constraints already committed to?** Tech stack, timeline, compatibility, performance, deployment — *only if known*. A greenfield project may have none yet; do not invent or pressure for constraints that haven't been decided.
9. **Is this a new project or building on existing work?**

Do NOT ask for per-goal acceptance criteria, file maps, phasing, or "what's out of scope" — those are owned by downstream artifacts.

## Dialogue Conduct

When working a goal with the user, follow these rules.

1. **Open with questions.** Surface your list of open questions for the goal in chat. Work through them with the user one decision at a time.

2. **One question at a time, with a recommended answer.** Each question carries your proposed answer; the user confirms, amends, or rejects.

3. **Ground first, ask second.** Before asking the user any question — your own or one the user has asked back — consult the codebase, then the web. When a question touches industry best practice or external patterns, search the web for cited evidence rather than speculating or punting back. Escalate to the user only when no source surfaces a defensible answer.

4. **When the user asks for your call, provide one — at Goals altitude.** Give a grounded recommendation (sources per Rule 3) with named tradeoffs. Do not deflect with more questions. If grounding leaves the call indeterminate, say so and name what additional evidence would resolve it. If the question is solution-approach (methodology, algorithm, scoring rubric, architecture, "how to compute X"), the recommendation is *capture candidates in "What we know so far" and defer to Design* — not a pick between A/B/C/D. See Rule 5.

5. **Altitude check before every question.** Before asking the user any question, classify it: is the answer a *goal-articulation* fact (what is the problem, who is affected, why does it matter, what is currently known) or a *solution-approach* decision (how to compute, how to measure, which methodology, which algorithm, which architecture, which scoring rubric)? Only goal-articulation questions belong in this dialogue. If a question is solution-approach, do NOT ask it — capture it as an open question Design will weigh, list any candidates the conversation has surfaced under "What we know so far," and move on. The dialogue's job is to surface the problem; Design's job is to choose how to solve it.

6. **Sharpen fuzzy language.** When the user uses imprecise vocabulary, propose the canonical term and ask for confirmation before moving on.

7. **Walk every goal-articulation branch of the decision tree.** For each goal, resolve open questions one-by-one. Do not move to the next goal until every branch surfaced is decided, explicitly deferred with a written reason, or split out as a separate goal. "Branch" here means a goal-articulation branch (whose problem is this, what signal tells us it's a problem, what's the blast radius, who is affected) — NOT a solution-approach branch (which methodology, algorithm, architecture, multi-actor flow). Solution-approach branches are closed per Rule 5: list candidates in "What we know so far" for Design to weigh; do NOT force a user pick.

8. **Lock decisions as they settle.** Write each decision into the goal block under `status: draft` as it is confirmed (see § Incremental Persistence below). Do not accumulate decisions in chat across multiple goals before persisting.

9. **Probe for unstated goals before declaring the set complete.** User-volunteered goals are a *starting set*, not the complete set. Before treating the goal list as final, drive 1–2 probing passes by widening the stakeholder lens. Walk **every** user named in Question 1 — primary, secondary, tertiary — as a separate angle: for each, what do they need that hasn't been captured yet? Add operators, security or compliance reviewers, downstream consumers, future maintainers, and support staff to the list if they weren't named already. Each may have a legitimate user-need (e.g., "an operator needs to roll back a release without data loss") that the primary-user focus missed. Useful probes: "What does success look like for [user X]?", "What would make this fail for [user Y] even if every stated goal lands?", "Is there anything [user Z] needs that we haven't named?" Capture any new stakeholder needs the user confirms as additional goals; then run the Final Coverage Review below.

## Final Coverage Review (before declaring goals locked)

After the user signals they're done articulating goals — and after the Rule 9 in-flow stakeholder probing — pause for a deliberate **set-level review** of the locked goals before handing off to After Goals Are Locked.

Read the on-disk draft as a whole, with each user named in Question 1 (primary, secondary, tertiary) and their stated needs / evidence / workarounds in mind. Ask: does this set tell a complete story for *every* named user? Are there obvious goals nobody has named — implied by the evidence, the workarounds, or the stakeholders mentioned — that would round out the picture?

The number of candidates is **zero to many**. Propose every reasonable gap you spot, batched in one turn so the user can weigh them together:

> "Looking at the set together against the named users, I see [N] potential gaps:
>
> 1. **[name]** — given [evidence anchor], a goal like `[one-line problem]` would cover [user X].
> 2. **[name]** — [evidence anchor] suggests `[one-line problem]` for [user Y].
> 3. … etc.
>
> For each: add, defer, or skip?"

**Don't be shy.** If a candidate is reasonable, propose it. The cost of one user veto is small; the cost of shipping a goal set with an obvious gap is real work in the next QRSPI cycle.

**Zero candidates is also fine.** If nothing jumped out, say so explicitly ("set looks coverage-complete to me — nothing else jumped out") and hand off. Do not invent candidates to fill the slot.

## Goal Specificity

**Rule:** Each goal must be independently scopeable — moveable between phases without surgery. Bundled goals must be split with their own IDs. **Red flag:** a goal whose **Problem** bundles 3+ distinct problems that could be independently phased. **Late splitting:** classify per amendment severity (Minor / Major / Scope Unknown) — see `replan/SKILL.md`. Present each split as a before/after diff; user decides; update `roadmap.md` with new IDs. **Common rationalization:** "These items are related so they should be one goal" — Related ≠ coupled.

## What to Write — Per-Goal Block

When a goal is locked, the block written to `goals.md` MUST conform to the conformance template at `skills/goals/references/goals-md-template.md` (read it the first time you author a per-goal block). The rules below are the load-bearing constraints; the template is the formatting reference.

!cat skills/_shared/evergreen-output-rule.md

**The three required subsections.** Every goal MUST carry exactly the three subsections `Problem`, `Why we care`, `What we know so far`. Omitting one is a defect. If the user did not articulate one during dialogue, re-enter dialogue to obtain it — do NOT write a placeholder, partial, or tentative body (presence ≡ locked, see Incremental Persistence below). Do NOT add a fourth subsection — additional content belongs in `What we know so far` or in a Constraint.

**The `type` field — concrete value.** Every goal MUST carry a `type` field with exactly one concrete value: `known-fix` OR `exploratory`. Grounded in **Knight risk-vs-uncertainty**:

- **`known-fix`** — *risk*. Well-characterized problem; bounded solution space. Cost-benefit reasoning applies normally.
- **`exploratory`** — *uncertainty*. The problem is partly uncharted; success criteria emerge through investigation. Exploratory goals are **protected from cost-benefit reasoning that would defer them**.

NEVER emit the alternation literal `known-fix | exploratory` (template placeholder, not valid output). If neither fits, default to `exploratory` and flag the ambiguity under "What we know so far". Do NOT invent a third value.

**Solutions-as-possibilities framing.** When the user mentions a candidate fix during dialogue, transcribe it under "What we know so far" with explicit framing ("candidate Design should weigh" / "possibility for Design to evaluate"). Do NOT promote it to Purpose, Constraints, or a `Solution` subsection.

**No `Out of Scope`, `Success Criteria`, or `Acceptance Criteria` section** — top-level or per-goal. What isn't a goal isn't in scope; acceptance is owned by Design's per-goal `Acceptance` blocks and Plan's per-task expectations. Capture user-volunteered exclusions as constraints (when they shape the solution space) or omit them.

## Incremental Persistence (Direct-to-Artifact Drafting)

Per Dialogue Conduct Rule 8, write each locked goal **directly to `goals.md`** with `status: draft` as confirmed. The draft on disk is the durable record; the chat transcript is not. There is no separate "synthesis subagent" pass — the dialogue *is* the synthesis.

**Presence ≡ locked.** The draft is a keyed map. A goal is locked iff its block appears. Tentative bodies, placeholder bodies, `to be filled` markers, TODO markers NEVER enter the draft. If a goal is not fully formed (Problem, Why we care, What we know so far all populated; concrete `type` value), it does not appear. This is the Evergreen-Output Rule applied to incremental persistence.

**Keyed in-place overwrite on re-lock.** Per-goal blocks are keyed by ID (`### G1 — ...`). On re-lock, overwrite in place — do NOT append a duplicate. <!-- id-hygiene-exempt -->

**Resume after compaction.** If `/compact` fires mid-phase, on resume:

1. Read the draft `goals.md` from disk and enumerate locked goals.
2. Ask the user whether all desired goals have been articulated. Goals runs before Research and has no upstream inventory to diff against — the user is the only authority on what work remains (the remaining-work computation is a user-driven question at Goals stage, not an inventory diff).
3. Surface the recovery diagnostic verbatim:

   `"Resumed after compaction — last locked decision: GNN (M decisions locked, K remaining). Continuing from G(NN+1)."`

4. Continue from the next unlocked goal.

## Red Flags — STOP

- A goal is missing the `type` field, or carries a value other than `known-fix` / `exploratory`.
- A goal carries fewer or more than the three required subsections (Problem / Why we care / What we know so far).
- The draft is being shaped to include a top-level `Out of Scope` or `Success Criteria` / `Acceptance Criteria` section — those concerns are deferred (see Goals OWNS / Goals DEFERS).
- A solution candidate has been promoted from "What we know so far" into Purpose or Constraints (commitment leakage).
- "Similar to what we did before" without specifying what exactly.
- Pipeline mode selected without discussing the work's scope (quick fix for something that needs design, or full pipeline for a one-line change).
- Locking goal blocks before `config.md` is written (First-Run Setup HARD-GATE).
- Asking the user to pick between solution-approach options during dialogue (measurement methodologies, computation approaches, scoring rubrics, ranking algorithms, architectural patterns, "how to compute X" framings) — that's solutioning-via-question. Capture candidates in "What we know so far" and move on (see Dialogue Conduct Rule 5).
- Declaring the goal set complete after only capturing user-volunteered goals — no stakeholder-widening probe run, no Final Coverage Review (see Dialogue Conduct Rule 9 + Final Coverage Review).

## Common Rationalizations — STOP

| Rationalization | Reality |
|----------------|---------|
| "The user already described what they want clearly" | Clear description ≠ complete goals. The per-goal Problem / Why we care / What we know so far frames still need explicit capture. |
| "This is a quick fix, goals are overkill" | Quick-fix mode exists — use it. Even quick fixes need a captured Problem and Why we care. |
| "I should add acceptance criteria so downstream knows when it's done" | Goals does NOT own acceptance criteria — Design's per-goal `Acceptance` blocks and Plan's per-task expectations do. Adding them here pre-commits Design. |
| "I should add an Out of Scope section to prevent creep" | Goals does NOT own out-of-scope decisions. What isn't a goal isn't in scope; project-level scope clarifications belong in Design's Approach. |
| "The scope is obvious" | Obvious scope is where scope creep hides. Write the per-goal Problem clearly so Design can scope its solution against it. |
| "This goal feels exploratory but I can't justify the cost so I'll mark it known-fix" | Cost-benefit reasoning is exactly what the `exploratory` tag protects against. Mark it `exploratory` honestly. |
| "Let me just start the research first" | Research without approved goals means you don't know what you're looking for. |
| "I'll let the user pick between methodology / measurement / approach options A/B/C/D" | Methodology choice is Design altitude. Capture all candidates in "What we know so far" and let Design weigh them with research. Forcing the choice now pre-commits Design and bypasses the research step. |
| "The user gave me their goals; the list is complete" | User-volunteered goals are a starting set, not the complete set. Run the Rule 9 stakeholder-widening probe (operators, security/compliance, downstream consumers, future maintainers) and the Final Coverage Review before declaring complete — Goals' job is to surface what the user *hasn't* articulated yet, not just transcribe what they have. |

## Worked Example

See `references/worked-example.md` for a good `goals.md` (Rate Limiter for Public API), a contrastive bad `goals.md` with failure-mode analysis, and a BAD/GOOD dialogue contrast pair on solutioning-via-question.

## Iron Laws — Final Reminder

The override-critical rules for Goals, restated at end:

1. **Stage order is fixed.** First-Run Setup → Defining Goals → After Goals Are Locked. Do NOT begin Defining Goals incremental persistence until `config.md` is written (First-Run Setup HARD-GATE). Do NOT hand off to After Goals Are Locked until every locked goal carries the three required subsections + a concrete `type` value AND the Rule 9 stakeholder probe + Final Coverage Review have both run.

2. **Each goal must be independently scopeable.** Bundled goals must be split into separate goals with their own IDs — they break Replan's roadmap-driven phase promotion.

3. **Goals is problem-framed, not solution-prescribing.** Each goal carries `type` (`known-fix` OR `exploratory` — concrete value, not the alternation) and exactly the three subsections — Problem, Why we care, What we know so far. No top-level `Out of Scope` or acceptance-criteria sections. Solution candidates are framed as **possibilities for Design to weigh**. The "Goals OWNS / Goals DEFERS" section is the locked scope contract.

!cat skills/_shared/behavioral-directives.md
