---
status: draft
question_ids: [20]
research_type: codebase
---

# Q20: What scope or responsibility does `skills/replan/SKILL.md` currently describe for itself relative to `skills/goals/SKILL.md`, and how does `skills/replan/SKILL.md` describe handling new items surfaced during phase completion that are not already formal goals?

## Summary

**TL;DR:** `skills/replan/SKILL.md` scopes Replan to severity classification of phase learnings, minor-path artifact updates (tasks/plan only), major-path feedback authoring + loop-back, and the five-step phase-transition archive-and-populate mechanics; it explicitly DEFERS goal-text expansion and new-goal creation to `skills/goals/SKILL.md`. For new items surfaced during phase completion that are NOT already formal goals, Replan's described handling has two distinct surfaces: (1) the analyzer's **scope-mapping check** classifies any proposed change whose scope is not covered by existing goal text as **Major with loop-back to Goals** (never silently expanded by Replan); (2) `future-goals.md` Ideas (informal suggestions captured by Test/Integrate human gates) are read as input and "presented to user as optional additions" during analysis. The actual Ideas-capture mechanism lives in Test's Phase Learnings Gate, not Replan.

**Key findings:**
- Replan's OWNS list (`skills/replan/owns-defers.md:3-9`) is bounded to: phase-transition execution (minor path), severity classification, minor-path tasks/plan updates, major-path feedback authoring + cascade reset, and marking next-phase drafts `status: draft`.
- Replan's DEFERS list (`skills/replan/owns-defers.md:12-17`) explicitly names "Goal-text expansion or new goal creation → owned by Goals", with the scope-mapping check as the enforcement mechanism (`owns-defers.md:16`).
- The Severity Classification table (`skills/replan/SKILL.md:55-69`) routes "Change project goals or constraints (problem framing, intent, scope, environmental constraints)" and "Fundamental re-evaluation of project direction" to **Major / loop-back target: Goals**.
- The analyzer-responsibility scope-mapping check (`skills/replan/SKILL.md:97`): "when the analyzer ties a proposed change to an existing goal, it verifies the goal's problem framing actually describes the proposal's scope. If the proposal's scope is not covered by the existing goal text, the analyzer classifies the proposal as Major (loop-back to Goals). Goal-text changes are Goals' responsibility on the loop-back, never Replan's."
- Replan reads `future-goals.md` as a required input (`skills/replan/SKILL.md:38`): "contains Formal goals (approved for future phases with IDs) and Ideas (informal suggestions from Test/Integrate human gates). Read before producing analysis. Formal goals inform phase promotion. **Ideas are presented to user as optional additions.**"
- Capture of new ideas/items at phase completion is performed by Test, not Replan. Test's Phase Learnings Gate (`skills/test/SKILL.md:309-322`) splits user input into "Current-phase items" (discussed in conversation) vs "Future work ideas" (appended as bullets under `## Ideas` in `future-goals.md`). Test runs BEFORE Replan in the route; Replan inherits that file.
- The Common Rationalizations table (`skills/replan/SKILL.md:332`) reinforces: "If Test invoked Replan, more phases remain. Review remaining tasks for accuracy even if no changes are needed."
- The Roadmap Usage paragraph (`skills/replan/SKILL.md:101`) clarifies that during phase transitions, Replan promotes goals from the **Formal section** of `future-goals.md` into a fresh `goals.md` — i.e., the Ideas section is NOT auto-promoted into the next-phase draft; only Formal goals with IDs are.

**Surprises:** None.

**Caveats:** Investigation was limited to `skills/replan/SKILL.md`, `skills/replan/owns-defers.md`, `skills/goals/SKILL.md`, `skills/goals/owns-defers.md`, and the relevant Test gate. Agent-body files under `agents/` were not opened (Replan's analyzer and reviewer agent definitions live there); the SKILL.md is described as the authoritative scope contract loaded by scope-reviewers, but agent-body wording could phrase behaviors slightly differently. Phasing's roadmap-authoring rules (where Ideas-vs-Formal lifecycle ultimately resolves) were not inspected.

## Full findings

### 1. Replan's self-described scope relative to Goals

The locked scope contract lives in `skills/replan/owns-defers.md` and is loaded by Replan's scope-reviewer at review time (`skills/replan/SKILL.md:140`). The file opens (`owns-defers.md:1`) with the assertion: "This section is the **single source of truth** for Replan scope boundaries. Phase-transition execution (the minor-path archive-and-populate sequence) is owned here; all phasing decisions and roadmap authoring are deferred to Phasing."

**Replan OWNS** (`owns-defers.md:3-9`):
1. Phase-transition execution (minor path) — the five-step archive-and-populate sequence.
2. Severity classification of phase learnings (Minor / Major / Scope Unknown) and identification of the earliest loop-back target.
3. Minor-path artifact updates — apply approved minor changes to `tasks/*.md` and `plan.md`; status transitions `replan-draft` ↔ `approved`.
4. Major-path feedback authoring — write `feedback/replan-phase-NN-round-MM.md`, reset target + downstream artifacts to `draft`, invoke the loop-back skill.
5. Marking next-phase drafts `status: draft` so the downstream cascade re-reviews.

**Replan DEFERS** (`owns-defers.md:12-17`), in relation to Goals specifically:
- "**Goal-text expansion or new goal creation** → owned by **Goals**. The scope-mapping check (below) makes this explicit: if a proposed change is not covered by existing goal text, classify Major and loop back to Goals — never silently expand." (`owns-defers.md:16`)
- "**Authoring of `future-*.md` artifacts** → owned by **Phasing** (initial pruning) and by the upstream skill on a Major loop-back. Replan READS the future-* artifacts to extract the next-phase entries; it does NOT add new entries to them." (`owns-defers.md:15`)

The Goals counterpart (`skills/goals/owns-defers.md:1-23`) defines Goals OWNS as project purpose, environmental constraints, per-goal entries (with stable IDs, `type` field, the three required subsections), optional Cross-Cutting Notes, and solution-candidates-as-possibilities framing. Goals DEFERS detailed solutions (Design), acceptance criteria (Design Test Strategy + Plan), file/component/interface mapping (Structure), task specs (Plan), phasing/slice/roadmap (Phasing), and implementation logic (Structure/Plan/Implement).

The boundary between the two: Goals authors and amends goal text; Replan never authors or amends goal text. When Replan determines that a phase-completion proposal touches goal text or introduces something not covered by existing goals, the only Replan-side action is to classify it Major and loop back to Goals via the standard cascade-reset mechanism.

### 2. Severity Classification rows that route to Goals

The Severity Classification table (`skills/replan/SKILL.md:55-69`) includes two rows whose loop-back target is **Goals**:

| Change type | Severity | Loop-back target | Examples |
|---|---|---|---|
| "Change project goals or constraints (problem framing, intent, scope, environmental constraints)" | **Major** | Goals | "The MVP scope should include notifications, not just messaging" |
| "Fundamental re-evaluation of project direction" | **Major** | Goals | "We should target mobile-first instead of desktop-first" |

The "Key rule" paragraph (`skills/replan/SKILL.md:73`) restates: "If project goals or constraints change (problem framing, intent, scope), loop back to Goals (which resets all artifacts to draft — the entire pipeline re-runs)."

A loop back to Goals resets the full artifact set (`skills/replan/SKILL.md:273`): "loop to Goals resets all artifacts (`goals.md`, `questions.md`, `research/summary.md`, `design.md`, `phasing.md`, `structure.md`, `plan.md`, all `tasks/task-NN.md`, and `parallelization.md`)".

The Iron-Law / HARD-GATE block (`skills/replan/SKILL.md:22-26, 46-51`) prohibits classifying a major change as minor to skip the backward loop, and prohibits updating approved artifacts without user approval.

### 3. The analyzer's scope-mapping check (the explicit "not already formal goals" mechanism)

The text most directly addressing the second half of the question is the scope-mapping check at `skills/replan/SKILL.md:97`:

> "**Scope-mapping check (analyzer responsibility — restated for orchestrator awareness):** when the analyzer ties a proposed change to an existing goal, it verifies the goal's problem framing actually describes the proposal's scope. If the proposal's scope is not covered by the existing goal text, the analyzer classifies the proposal as Major (loop-back to Goals). Goal-text changes are Goals' responsibility on the loop-back, never Replan's. (Acceptance-criteria changes route to Plan, not Goals — per the strip-from-goals contract.)"

This is the in-prose enforcement that mirrors `owns-defers.md:16`. Operationally:
- Analyzer attempts to map each proposed change to an existing goal.
- If the existing goal's Problem statement does not describe the proposal's scope → classified Major / loop-back: Goals.
- Replan never writes new goal text or expands an existing goal in place. The loop-back hands the work to Goals.

### 4. Handling of `future-goals.md` Ideas (informal items surfaced earlier)

Replan reads `future-goals.md` as a required input (`skills/replan/SKILL.md:38`):

> "`future-goals.md` (if present) — contains Formal goals (approved for future phases with IDs) and Ideas (informal suggestions from Test/Integrate human gates). Read before producing analysis. Formal goals inform phase promotion. Ideas are presented to user as optional additions. If file does not exist, skip silently."

Two parts of `future-goals.md` are distinguished:
- **Formal goals** — already approved for future phases, carry IDs; these drive Replan's phase-promotion (e.g., the five-step archive-and-populate at `skills/replan/SKILL.md:255-263`).
- **Ideas** — informal suggestions. Replan's described action is to "present them to the user as optional additions" during phase-transition analysis. They are not auto-promoted into the next phase's draft `goals.md`.

The Roadmap Usage paragraph (`skills/replan/SKILL.md:101`) reinforces the asymmetry: "Goals for the next phase are promoted from `future-goals.md` (**Formal section**) into a fresh `goals.md`." Only the Formal section feeds the auto-population; Ideas remain informal until a user action elevates them.

### 5. Where Ideas are actually captured (upstream of Replan)

The capture mechanism — the place where "new items surfaced during phase completion that are not already formal goals" enter the system — is **Test's Phase Learnings Gate** (`skills/test/SKILL.md:309-322`), which runs BEFORE Test invokes Replan:

> "Before we proceed to phase routing: do you have any phase learnings or ideas for future phases?
> - **Current-phase items** (things to fix now, constraints found): discuss these in conversation — we'll handle them before moving on.
> - **Future work ideas** (new features, improvements for later phases): these will be appended to `future-goals.md` Ideas section.
> (Press Enter to skip.)"

Behavior (`skills/test/SKILL.md:318-322`):
- Future work ideas → "append as bullet points under `## Ideas` in `future-goals.md` in the artifact directory. If `## Ideas` section does not exist, create it."
- Current-phase items → discussed in conversation, resolved before phase routing.
- No input → skip silently.

Test then writes `replan-pending.md` and invokes `qrspi:replan` (`skills/test/SKILL.md:351`). By the time Replan begins, the Ideas section in `future-goals.md` already contains any phase-completion-surfaced informal items, and Replan's behavior is to read them and "present them to user as optional additions" — but Replan itself does not gather them.

### 6. Net picture of how a non-formal-goal item flows through Replan

Combining the above, the described handling for "new items surfaced during phase completion that are not already formal goals" splits into two cases:

**Case A — Item raises a change the analyzer must classify (a phase-learning proposal).**
- The analyzer applies the scope-mapping check (`skills/replan/SKILL.md:97`).
- If the proposal's scope is covered by an existing goal's Problem statement → classify per the rest of the Severity Classification table (Minor / Major to Design/Phasing/Structure/Plan depending on what's affected).
- If NOT covered → classify Major / loop-back: Goals (`owns-defers.md:16`, `SKILL.md:97`). Replan writes `feedback/replan-phase-NN-round-MM.md`, resets target + downstream artifacts to `draft`, and invokes `qrspi:goals` (`SKILL.md:267-285`). Goals authors the new/expanded goal text on the loop-back; the cascade re-runs.
- Replan never authors goal text itself. The Iron Laws at end (`SKILL.md:462-470`) and the HARD-GATE (`SKILL.md:46-51`) reinforce this with the "DO NOT classify a Major change as Minor" and "DO NOT update approved artifacts before user approval" rules.

**Case B — Item is a future-work idea recorded in `future-goals.md` Ideas by Test before Replan runs.**
- Replan reads `future-goals.md` (`SKILL.md:38`) and considers the Ideas section.
- Replan's described action: "Ideas are presented to user as optional additions."
- Ideas are NOT auto-promoted into the next-phase draft `goals.md` — only Formal goals are (`SKILL.md:101`, `SKILL.md:259`).
- If the user opts to elevate an Idea, the elevation path is to add it to the Formal section of `future-goals.md` so a future phase's auto-population picks it up, OR to invoke a Major loop-back to Goals so Goals can author it as a formal goal. Replan's described scope does not include rewriting `future-goals.md` itself; `owns-defers.md:15` lists "Authoring of `future-*.md` artifacts" as DEFERRED (to Phasing on initial pruning, to the upstream skill on Major loop-back).

### 7. Related guardrails in Replan that reinforce the boundary

- Red Flags (`SKILL.md:316-322`): "Classifying a major change as minor to skip the backward loop", "Updating approved artifacts without presenting proposals to user first", "Skipping the backward loop because 'the change is small'".
- Common Rationalizations (`SKILL.md:327-334`): "'This is just a wording change to design.md' → If you're changing design.md, you're in a major loop-back. The severity table governs, not your judgment."
- Clarifying Amendments table (`SKILL.md:342-348`) explicitly carves goals OUT of the amendment shortcut: "Goals, per-task test expectations, and per-phase acceptance criteria are never amendments. Changes to `goals.md` (purpose, constraints, problem framing, out-of-scope) route to Goals as a Replan Major" — i.e., even the Clarifying/Additive lightweight path is unavailable for goal-text changes.
- Iron Laws — Final Reminder (`SKILL.md:462-470`) re-states: "DO NOT classify a Major change as Minor to skip the backward loop. Severity classification is the entire point of Replan."
