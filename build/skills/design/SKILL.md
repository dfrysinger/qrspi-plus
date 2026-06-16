---
name: design
description: Use when research/summary.md is approved and the QRSPI pipeline needs an architecture — proposes approaches, surfaces key architectural decisions with rationale, and defines per-goal acceptance through interactive design discussion
---

# Design (QRSPI Step 4)

<!-- Soft length target: 200–400 lines for this SKILL.md. The marker is a guidance signal — long enough to carry per-section template guidance + OWNS/DEFERS contract + reviewer wiring, short enough to keep the prompt scannable in a single context window. -->

**PRECONDITION:** Invoke `qrspi:using-qrspi` skill to ensure global pipeline rules are in context. (Idempotent on session re-entry. Subagents are exempt — SUBAGENT-STOP in using-qrspi handles that.)

**Announce at start:** "I'm using the QRSPI Design skill to explore approaches and define the architecture."

**If auto-mode is detected** (`## Auto Mode Active` system-reminder present), surface before the first interactive step: "This skill is collaborative — turn-by-turn dialogue produces better Design quality than autonomous execution. Recommend exiting auto-mode (`Shift+Tab`). I'll proceed in either mode if you prefer." Do not force the user out; respect their choice.

## Overview

Translate research findings into per-goal solution definitions through interactive discussion. Propose approaches with trade-offs, surface key architectural decisions with rationale, and lock decisions at outcome altitude. Discussion is conversational; a subagent synthesizes `design.md` per round.

## What Design produces

A per-goal solution definition at outcome altitude — the end-state, the practical solution at the altitude defined by the Altitude Sub-Rules below, and the reasoning. Per-goal acceptance criteria are inline in each goal block. Design MAY include zero or more per-solution diagrams. Unified system architecture, file maps, module boundaries, and the unified test architecture are Structure's job (see Structure's owns/defers contract); per-assertion test code is Plan's job.

## Per-goal block template

- **Outcome** — end-state being targeted
- **Solution** — practical solution at the altitude defined by the Altitude Sub-Rules
- **Why this approach** — tradeoffs and alternatives considered
- **Dependencies + edge cases** — what the solution depends on and which corner cases it handles
- **Acceptance** — high-level "done" signal at the outcome level

**Optional per-goal Mermaid diagram** when the flow benefits from visualization. **Cross-Goal Decisions** section above the per-goal blocks for decisions that span multiple goals.

## Dialogue Conduct

When working a goal with the user, follow these rules.

1. **Open with questions.** Surface open questions for the goal; work through them one decision at a time.

2. **One question at a time, with a recommended answer.** The user confirms, amends, or rejects.

3. **Ground first, ask second.** Consult, in order: the research summary, the codebase, then the web. When a question touches industry best practice or external patterns, search the web for cited evidence rather than speculating or punting back. Escalate to the user only when no source surfaces a defensible answer.

4. **When the user asks for your call, provide one.** Give a grounded recommendation (sources per Rule 3) with named tradeoffs. Do not deflect or punt. If grounding leaves the call indeterminate, say so and name what additional evidence would resolve it.

5. **Use simple language and provide context when presenting ideas.** Ground proposals in concrete scenarios before naming them abstractly. When introducing a technical term that has not appeared in this dialog recently, give one sentence of grounding context. Trade-off framings ("here are 3 candidates: A is X, B is Y...") should explain what each candidate concretely does in plain prose before naming the abstract architectural shape.

6. **Sharpen fuzzy language.** When the user uses imprecise vocabulary, propose the canonical term and ask for confirmation.

7. **Walk every branch of the decision tree, including flow gaps.** Resolve dependencies one-by-one. Do not move to the next goal until every surfaced branch is decided, explicitly deferred with a written reason, or split out as a separate goal. Branch completeness includes the end-to-end flow between multi-actor decisions — actors named, operations sequenced, per-step inputs/outputs traced to producer and consumer, loud-failure paths named, context-cost call-out present (per Sub-Rule C). A flow with implicit hand-offs is an open branch; close it.

8. **Lock decisions as they settle.** Write each decision into the goal block under `status: draft` as it is confirmed. Do not accumulate decisions in chat across multiple goals.

## Altitude Sub-Rule A — Naming-vs-Layout

**Altitude Sub-Rule A — Naming-vs-Layout** (applies to code, scripts, and data-contract artifacts).

Design names artifacts when naming IS the decision. Filenames, script names, contract artifact
names, and renames are in scope when they establish cross-skill vocabulary or commit to a
public-interface identity.

Design does NOT specify:
- Directory trees or where files live within the repo
- Inter-file wiring (what sources / imports / requires what)
- Function or method signatures
- Field-level schema layouts (JSON keys, table columns, struct fields)
- Code, pseudocode, or implementation outlines

**Altitude test.** After reading the design block for a goal, can Structure still author its
file map AND Plan still author its per-task API surface without contradiction? If yes → right
altitude. If no → back off.

**Worked examples.** See `references/altitude-sub-rules.md` § Sub-Rule A.

## Altitude Sub-Rule B — Prose-as-Decision

**Altitude Sub-Rule B — Prose-as-Decision** (applies to prompt prose, reviewer rubrics, skill text, agent frontmatter, dispatch payloads).

When the artifact being designed IS prompt prose, the prose-level wording IS the design. Specifying exact words is not over-reach; it is the unit of architectural commitment. LLM behavior is acutely sensitive to wording, and generic paraphrase is not equivalent to a specified rule.

**Altitude test.** Ask: "if a future agent re-implemented this from my description using different wording, would they produce equivalent LLM behavior?"
- If the artifact is code: generally YES — Sub-Rule A governs; specify what, not how.
- If the artifact is prompt prose: generally NO — Sub-Rule B governs; specify the wording verbatim to the extent scope allows.

**Scope proportionality, operational rule, worked examples.** See `references/altitude-sub-rules.md` § Sub-Rule B for the full proportionality rule, the verbatim-vs-deferred operational block shapes, and the per-artifact worked-example table.

## Altitude Sub-Rule C — End-to-End Flow

**Altitude Sub-Rule C — End-to-End Flow** (applies whenever a design decision introduces or modifies an interaction across two or more actors — orchestrator, script, subagent, file, manifest, external service, user).

When a decision involves multiple actors that hand off to each other, the design block MUST specify the end-to-end flow between them, not just enumerate the components in isolation. "We'll have script X and agent Y and manifest Z" is component enumeration; the design also has to say what calls what, in what order, with what inputs, producing what outputs, consumed by whom.

**Required flow elements** (for any multi-actor decision):
- **Actor inventory** — name every actor (orchestrator, script, subagent, file, external service, user).
- **Sequence of operations** — ordered list of who-does-what. If parallelism matters, name the parallelism boundary (e.g., "M Task tool calls in parallel in one orchestrator response").
- **Per-step inputs and outputs** — what each actor receives and produces. Cite where outputs are written (stdout, file path, manifest entry, Task tool return value).
- **Consumer identification** — name who reads each output next. An output with no named consumer is dead and must be removed or its consumer surfaced.
- **Loud-failure paths** — what happens when each step fails. "Silent fallback" is never the answer — name the diagnostic.
- **Context-cost call-out** — for any flow crossing the orchestrator/subagent boundary, state what enters orchestrator context vs. what stays in subagent context or on disk.

**Altitude test.** Ask: "Can Structure / Plan / Implement enumerate the per-round orchestrator actions in order, naming inputs and outputs for each step, without inventing sequencing decisions the design failed to commit?" If no → back off and add the missing steps. The most common gap is the orchestrator-side instruction work: "the script returns N specs" without saying how the orchestrator parses them and what it does with each one.

**Worked examples, Mermaid-diagram rule, scope clarification.** See `references/altitude-sub-rules.md` § Sub-Rule C.

## Sub-Rule D — External-Knowledge Completeness

**Sub-Rule D — External-Knowledge Completeness** (applies whenever a design decision references behavior, contracts, or signals from external systems — host CLIs, vendor APIs, platform runtime injections, library protocols, third-party file formats).

Design is the LAST research-bearing phase in the QRSPI pipeline. After Design, no skill runs research or external-source verification — Structure, Plan, Parallelize, Implement, Integrate, Test all consume what Design committed. Any external-knowledge question Design defers (a "TBD per vendor docs at implementation time" footnote, a "to be verified by implementer" placeholder) becomes a downstream blocker that resolves to either a guess (silently wrong) or a halt the user has to unblock. Either outcome is a design defect.

The only external-to-codebase knowledge downstream skills are expected to bring is: (a) how existing project code works (they Read it), (b) how to write code in the relevant language (model weights), (c) how to use ordinary development tools (model weights). Everything else — platform behaviors, vendor contracts, host runtime injections, third-party protocols, file-format specifics — MUST be answered in the design block, with citations.

**Required completeness elements** (for any decision that references external behavior):

- **External-claim inventory** — every external-system claim is enumerated explicitly. Implicit references ("the platform handles it", "see vendor docs") are forbidden — name the platform, name the mechanism, write the answer.
- **Verified answer** — each claim has the concrete answer in the design block, not deferred.
- **Source citation** — each claim cites its source: docs URL + fetch date, CLI command + output snapshot, direct runtime observation + observation method + observed value.
- **Verification method label** — note whether the answer was verified by docs-only, docs + direct observation, or direct observation only. **For claims about host runtime injections, direct observation is required** (doc-only is unreliable — host CLIs frequently inject undocumented signals; verified case: Copilot CLI v1.0.57 injects an autopilot-state context tag with no mention in `copilot help environment` or official autopilot docs — see `scripts/detect-interaction-mode.sh` for the exact tag and sentinel literals). <!-- evergreen-exempt -->
- **Unknown branches** — when verification yields "unknown" or "host-not-yet-supported", the design block MUST name the unknown AND specify the safe-default downstream code applies AND the verification procedure the implementer follows when the host is added. "Unknown — safe default X — verify via procedure Y" is valid; "TBD figure out later" is not.

**Completeness test.** Ask: "If a fresh implementer reads only this design block plus the existing project code, can they implement the decision without consulting any external source the design didn't already cite?" If no → name the missing external answer, research it, write the answer + citation. If genuinely unknown, add an explicit `unknown` branch with safe-default + verification procedure.

**Worked examples and scope clarification.** See `references/altitude-sub-rules.md` § Sub-Rule D.

## Incremental Persistence (Direct-to-Artifact Drafting)

Per Dialogue Conduct Rule 8, after each per-decision lock signal (user says "approved" for a goal block or cross-goal decision), write the block **directly to `design.md`** with `status: draft`. The draft on disk is the durable record; the chat transcript is not.

Per-goal blocks use the five-field template (Outcome, Solution, Why this approach, Dependencies + edge cases, Acceptance). Cross-goal decisions live in `## Cross-Goal Decisions` at the top of `design.md`.

**Presence ≡ locked.** The draft is a keyed map. A decision is locked iff its block appears. Tentative bodies, `to be filled` markers, TODO markers, "placeholder for synthesis" markers NEVER enter the draft. If a decision is not fully formed (missing one of the five per-goal fields, or cross-goal entry missing rationale/scope), it does not appear. Evergreen-Output Rule applies — dialogue exhaust never enters the artifact.

**Keyed in-place overwrite on re-lock.** Blocks are keyed by ID (`### G3 — ...`, `### CD-1 — ...`). On re-lock, overwrite in place — do NOT append a duplicate.

**Resume after compaction.** If `/compact` fires mid-phase, on resume:

1. Read the draft `design.md` and enumerate locked decisions.
2. Compute remaining = `goals.md` goals minus per-goal blocks already locked. The upstream inventory is the approved `goals.md` goal list — every goal requires one per-goal block. Cross-Goal Decisions are additive and not pre-enumerable; they do not contribute to `K remaining`.
3. Surface the recovery diagnostic verbatim:

   `"Resumed after compaction — last locked decision: GNN (M decisions locked, K remaining). Continuing from G(NN+1)."`

4. Continue from the next unlocked decision.

**End-of-phase finalize pass.** After walkthrough:

- Validate that every goal in `goals.md` has a corresponding per-goal block in `design.md` with all five fields populated (Outcome, Solution, Why this approach, Dependencies + edge cases, Acceptance).
- Validate the `## Cross-Goal Decisions` section is well-formed (each entry keyed by ID, each entry carries rationale + scope).
- Optionally append a top-level summary if absent.
- **Only flip status if all validations pass.** On failure, halt, surface, re-enter dialogue.
- Flip frontmatter `status: draft` to `status: approved-pending-review`. Hand-edits flipping status mid-phase (before the finalize pass) are forbidden — only the finalize pass writes the next-gate status.

**Simulated-compaction durability contract.** A simulated compaction at a mid-phase decision (e.g., G15) followed by resume MUST produce a final artifact identical to a no-compaction run. The on-disk draft is the single source of truth for locked decisions; nothing about the chat transcript or in-session working memory is load-bearing across the compaction boundary.

## Design OWNS / Design DEFERS

**Analogy.** design.md is the **architecture brief** for the project: it states the chosen approach, the trade-offs that were weighed, the key technical decisions and their rationale, the per-goal `Acceptance` blocks (and a `## Visual-Fidelity Binding` H2 when `config.md` sets `visual_fidelity_required: true`), and a high-level system diagram. It does NOT enumerate concrete implementation surfaces (DDL, full signatures, assertion text), and it does NOT author phasing decisions (which slices belong in which phase). Implementation surfaces are owned downstream by Plan / Implement; phasing concerns — vertical slice authoring, phase boundaries, Iron Law 1, the Phase 1 PoC guideline, replan-gate criteria — are owned by `qrspi:phasing` (see `skills/phasing/SKILL.md`).

The OWNS/DEFERS contract below is the locked rule set the scope-reviewer dispatch loads at review time (Read by the `qrspi-design-scope-reviewer` agent at runtime per its rules-loading procedure). Boundary-drift detection runs against the DEFERS list; scope-compliance runs against the OWNS list.

## Design Altitude Boundary

### Design OWNS

Design OWNS:
- Per-goal outcome statements (the end-state being targeted)
- Per-goal solution definitions at outcome altitude including: detailed descriptions of the solutions with full edge cases, end-to-end flows specifying actor sequence and per-step inputs/outputs, prompt-writing specifics (the actual prose a SKILL or agent file will carry, paraphrased or verbatim when load-bearing), acceptance criteria including concrete examples and rough test-pairing shapes (e.g., "one bats file per script under `scripts/`"; naming the shape is acceptance-criteria-altitude — authoring the test code is Plan/Implement's job)
- Cross-Goal Decisions (CDs) that establish vocabulary, named architectural components by purpose, and cross-cutting invariants
- Per-solution diagrams (zero or more per goal block or per cross-cutting CD block) when they aid comprehension of that specific solution — Mermaid sequence diagrams for per-solution end-to-end flows, or Mermaid flowcharts for branch-heavy per-solution control flow. NOT a unified system-wide architecture diagram across goals/CDs (Structure's job).
- Per-goal Acceptance at the per-solution altitude: each goal/CD block carries its own Acceptance subsection with concrete examples and rough test-pairing shapes; design.md does NOT stitch acceptance criteria across goals into a unified release-level test architecture (Structure's job — see `## Test Architecture` in structure.md).
- `## Visual-Fidelity Binding` (top-level H2 in design.md) — authored ONLY when `config.md` carries `visual_fidelity_required: true`; lists the concrete wireframe artifacts (Figma URLs, embedded PNG paths) that downstream visual-fidelity reviews bind to. Phasing reads this H2 by name. When `visual_fidelity_required` is false or absent, the H2 MUST NOT appear.
- Naming and renames that establish cross-skill vocabulary (rename inventory blocks)
- Phasing/release-assignment phrases that name which goal/CD ships in which release (operator-authoritative; phasing.md is the canonical artifact but design.md may carry the labels inline for self-host reasoning)

### Design DEFERS

Design DEFERS:
- Function bodies (procedural code blocks with executable logic — full implementations belong in Implement)
- Full unit-test code (specific assertion text, fixture file contents, test scaffolding — belongs in Plan/Implement; Design names the test type and rough shape only)
- Executable shell beyond a few illustrative lines (a 2-3 line block illustrating shape is fine; a 20-line script body is not)
- File architecture (which file holds which component, directory layout, module boundary lines — Structure's job)
- Unified system-wide architecture diagrams that stitch components across goals/CDs into a single architectural overview (Structure's job; per-solution diagrams inside a single goal/CD block remain in Design's OWNS)
- Unified `## Test Architecture` section that stitches per-solution acceptance criteria from individual goal/CD blocks into a release-wide test plan, names cross-cutting test invariants by type, or enumerates the release's test taxonomy (Structure's job; per-solution Acceptance subsections inside individual goal/CD blocks remain in Design's OWNS)
- Task carving (per-task LOC budgets, per-task dependency graphs, per-task test-case enumeration — Plan's job)

**Phasing pointer.** Phasing concerns (vertical slices, phase boundaries, Iron Law 1, the Phase 1 PoC guideline) are owned by `qrspi:phasing` — see `skills/phasing/SKILL.md`.

A finding citing design.md prose that asserts any DEFERS item from the included contract above is a boundary-drift finding emitted by the scope-reviewer with `change_type: scope` (per the schema in `skills/reviewer-protocol/SKILL.md`).

## Artifact Gating

**Required inputs:**
- `goals.md` with `status: approved`
- `research/summary.md` with `status: approved`

If either artifact is missing or not approved, refuse to run and tell the user which artifact is needed.

**On-demand inputs — research read-on-demand:** the per-question research files at `research/q*.md` are available to Design as **on-demand reads**, not required inputs. `research/summary.md` carries each question's structured `## Summary` block (TL;DR / Key findings / Surprises / Caveats) verbatim and is the primary input; reach for the corresponding `research/q*.md` when an architectural decision depends on detail the summary block deliberately compressed away (specific `file:line` references, full source URLs, methodology notes, alternatives the researcher considered but did not surface). Cite the file you reached for in the design discussion (e.g., "per `research/q07-codebase.md`") so the rationale chain stays auditable. Do NOT load `research/q*.md` files prophylactically — they exist behind `summary.md` precisely to keep the default input set lean.

Read `config.md` from the artifact directory to determine whether second-model reviews are enabled. Apply the **Config Validation Procedure** in `using-qrspi/SKILL.md`. Design validates `second_reviewer`.

<HARD-GATE>
Do NOT synthesize design.md without approved goals.md AND research/summary.md.
Do NOT proceed to Structure without user approval of the design.
</HARD-GATE>

## Execution Model

**Interactive in main conversation** (like Goals). User and Claude discuss approaches. Subagent synthesizes `design.md` per round. Each rejection round launches a new subagent with original inputs + all prior feedback files.

## Process

### Interactive Design Discussion

**Phase 1 — per-goal:**

1. **For each goal in `goals.md`, in order:**
   1. Surface the relevant research findings from `research/summary.md` (and on-demand from `research/q*.md` if a decision depends on details).
   2. Propose 2–3 candidate approaches; lead with recommendation; explain trade-offs.
   3. Open Q&A — user asks back, you ask back, until the goal's design is settled.
   4. Move to the next goal. Do **not** dump multiple goals' designs in one turn.

**Phase 2 — cross-cutting (after all goals settled):**

2. Surface key architectural decisions with rationale (approach selection, technical trade-offs, data-flow boundaries). Phasing concerns — vertical slice authoring, phase boundaries, replan-gate criteria, PoC scoping — are owned by `qrspi:phasing` and not authored here.
3. When handling amendments, remember: Amendment items that introduce distinct new work (new functions, new behavior, new files) must receive their own goal ID. Only items that genuinely refine or detail an existing goal's described work may be compressed into that goal. Never use bare-number compression (e.g., '5/8/10 -> U1') when the goal text doesn't cover all mapped items.

### Design Synthesis Subagent

Once the discussion settles, launch a **subagent** to synthesize `design.md`.

**Subagent inputs:**
- The existing incremental draft `design.md` on disk (REQUIRED — the draft is the source of truth for pre-compaction locked decisions; the subagent MUST merge this draft with new conversation content rather than re-synthesizing from conversation alone)
- `goals.md`
- `research/summary.md`
- A summary of the design discussion (key decisions, user preferences, chosen approach)
- The resolved value of `visual_fidelity_required` from `config.md` (REQUIRED — when true, the subagent MUST author a top-level `## Visual-Fidelity Binding` H2 listing at least one concrete wireframe artifact; when false or absent, the subagent MUST NOT author that H2)
- Any prior feedback files
- **On-demand:** `research/q*.md` files per the read-on-demand permission in `## Artifact Gating` (single source of truth for the trigger condition, citation requirement, and anti-prophylactic guard — not restated here). The orchestrator surfaces available `q*.md` filenames in the subagent prompt; the subagent decides which (if any) to load.

**Prompt-prose authoring step.** When the subagent authors `<!-- prose-design: target -->` blocks (verbatim prompt-prose destined for an LLM-consumable file), apply detection + writer rules. **PRECONDITION:** `skills/_shared/prompt-prose-detection.md` and `skills/_shared/prompt-prose-writer-addition.md` MUST exist on disk; halt the subagent with a named diagnostic if any required shared file is missing.

**Prompt prose** is text authored to be loaded into an LLM's context as instructions, system prompts, agent definitions, skill definitions, reviewer rubrics, MCP tool descriptions, RAG instructions, or any equivalent LLM-consumable directive content.

**Detection rule (universal).** Use content semantics, not just file path or extension, as the determining signal. Ask: is the text intended to be loaded into an LLM's context at runtime as instructions? If yes, it is prompt prose, regardless of where it lives in the repo.

**Path and extension as secondary signals (fast-path shortcut for qrspi-plus-internal authoring).** When ALL target files match one of these globs, classify as prompt prose without further inspection:

- `skills/**/SKILL.md`
- `skills/**/*.md` (snippet files under a skill directory)
- `agents/*.md`
- `AGENTS.md`
- `CLAUDE.md`

Files outside these globs require the content-semantic test above. Other projects may carry prompts in `prompts/`, `src/llm-instructions/`, or custom layouts — the content-semantic test is universal; the glob list is qrspi-plus-internal convenience only.

**Examples of prompt prose:**

- A SKILL.md body that instructs an orchestrator.
- An `agents/*.md` file defining a subagent (role, task, constraints, tools).
- A `.md` file under a project's `prompts/` directory whose frontmatter `description:` indicates LLM consumption.
- A verbatim system prompt embedded in any markdown file (e.g., "You are...", "Your role is...", `<HARD-GATE>` blocks).
- A `.txt` or `.json` file whose content is plainly an LLM instruction payload.

**Examples of NOT prompt prose:**

- Code documentation, README files describing features.
- Design decisions in prose form (unless a `<!-- prose-design: ... -->` marker indicates a verbatim prompt-prose block within).
- Research notes ABOUT prompts (this file itself is a meta-document — it IS subject to the rules per meta-acceptance, but ordinary research/explanatory content about prompts is not).
- Configuration files, test fixtures, shell scripts.

**Rules file.** When prompt-prose authoring or review applies, the rules live at `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention).

**Writer-side application.** When authoring or planning a deliverable, apply the detection above to the planned target content (or sub-block, for blocks within larger documents like `design.md`). If the target IS prompt prose, Read `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention) and apply R1-R7 + cross-cutting principles BEFORE drafting, not as post-write polish. The rules shape what to write; patching after the fact is a known anti-pattern. If the Read fails, do NOT proceed with authoring. Surface the error and stop.

**If the target is NOT prompt prose** (ordinary documentation, configuration, code, non-prompt prose), do NOT Read the rules file. Reading-without-applying is the verbosity-bias anti-pattern the rules themselves warn against — loading them into context for a deliverable they don't apply to wastes context and risks misapplication.

**Output format for `design.md`:** the synthesis subagent produces `design.md` per the conformance template in `skills/design/references/design-md-template.md` (template + per-section guidance + conformance reminder). Pass the template path to the subagent. The three per-section guidance markers (one per H2 inside the template) are:

<!-- Per-section guidance — Approach: one claim sentence first ("Chosen approach: {X}"), then 1–2 short paragraphs of rationale grounded in research findings. Claim-before-evidence; length-target ≤8 lines per paragraph. NO DDL, NO full function signatures, NO assertion text — those are DEFERS. -->

<!-- Per-section guidance — Key Decisions: bulleted list of major decisions, each with one-line decision + one-line reasoning. Decisions are at the architecture-boundary level (data-flow, transport, persistence model, security posture) — NOT line-by-line logic, NOT column-level DDL. Bullets for scannability; lead each bullet with the decision noun. -->

<!-- Per-section guidance — Trade-offs Considered: the 2–3 rejected alternatives, each with what it traded off and why it lost. Claim-before-evidence — lead each subsection with the alternative name; rationale follows. Keep at the approach level — do NOT enumerate per-column trade-offs (DEFERS). -->

## Evergreen-Output Rule

Any artifact in the QRSPI run directory governed by `status: draft → approved` frontmatter promotion (goals, design, structure, phasing, plan, parallelization, roadmap, future-goals, and any future artifact adopting this lifecycle) describes the **current state** of decisions. The reader is a downstream agent or future maintainer.

*(Excludes by design: `SKILL.md` files — skills carry rule rationale legitimately; `feedback/*.md` — the designated home for dialogue exhaust; `reviews/**/*.md` — finding rationale; `config.md` — non-narrative.)*

**Litmus test (apply to every paragraph before write).** Two filters, in order:

1. Is the subject the **decision** (the thing being designed / planned / scoped)? → keep.
2. Is the subject the **document itself** — its drafts, its history, the dialogue that produced it, "us"? → cut.

A sentence that only makes sense as a delta from a prior state is **dialogue exhaust** — strip it.

**Permitted substantive content** (do NOT confuse with dialogue exhaust):

- Chosen approach and its rationale (inline)
- Rejected alternatives and tradeoffs, where the artifact template asks for them (e.g., design.md's `## Trade-offs Considered` — substantive content about the decision space, not about the document's history)
- Rationale embedded inline as one parenthetical when a downstream reader needs it

**Named antagonist patterns — strip on sight, substitute as shown:**

| Antagonist pattern | Recognize by | Replace with |
|---|---|---|
| Session / drafting notes | "Rule X drafting note," "this collapsed from 3 to 1 because…" | Nothing — delete. If a fact matters, embed inline in the decision. |
| Version-history narration | "earlier draft said X," "previously," "originally," "pre-cleanup" | Nothing — git history holds versions. |
| Inside baseball | text addressed to "us" / "the author," meta-explanation of the document's own structure ("this section is split into A and B because…") | The decision the structure expresses — without the structural explanation. |
| Compaction-loss recovery notes | "this nuance was almost lost during…" | Nothing — if the nuance is needed, the rule itself carries it. |
| Failure-modes-prevented lists | bullets that justify why a rule exists rather than state what to do | Strengthen the rule's wording; delete the justification list. |

Decision-process history (drafts, review rounds, feedback applied, compaction recovery) lives in feedback files, review findings, PR descriptions, and git history — never in the artifact.

### Precondition Checks

Run AFTER the synthesis subagent emits `design.md` and BEFORE `### Review Round` (before the pre-fanout compaction checkpoint, reviewer diff-file emission, and any reviewer dispatch). The gate is structural — on failure it short-circuits the cycle so reviewers do not consume context against an artifact that must be regenerated.

**Visual-fidelity binding precondition.** When `config.md` carries `visual_fidelity_required: true`, verify both:

1. A top-level `## Visual-Fidelity Binding` H2 is present in `design.md`.
2. The H2 body names at least one concrete wireframe artifact — a Figma URL, an embedded PNG path under the run-local artifact directory, or both. An empty / whitespace-only / comment-only / placeholder-only body (e.g., `{Wireframe artifacts}`) FAILS the gate — structural presence without concrete content fails the same way absence does.

On failure: do NOT emit the reviewer diff file, run the pre-fanout compaction checkpoint, or dispatch reviewers. Surface: "design.md is missing the required `## Visual-Fidelity Binding` H2 (or the H2 is present but names zero concrete wireframe artifacts). Add at least one Figma URL or embedded PNG path before approval." Loop back to re-synthesis; do not proceed until the gate passes. When `visual_fidelity_required: false` (or absent), skipped entirely.

**Reference-gate checklist item.** When the design introduces a reviewer whose verdict depends on an external reference artifact (prototype screenshot, golden output, contract fixture, lifted prototype), confirm before `### Review Round`:

1. The producing task is flagged `reference_gate: true` in the Plan task spec (per T24 frontmatter contract in `skills/plan/SKILL.md` § Refuse-to-Write Contract).
2. `design.md` records the **lift-verbatim-vs-re-derive decision**: state explicitly whether the implementer should copy the artifact verbatim or derive the behavior independently, and name the reference artifact path or URL.

On failure: surface `"design.md introduces a reference-dependent reviewer but does not record the lift-verbatim-vs-re-derive decision — add a decision statement under the relevant Key Decisions entry naming the reference artifact and the chosen decision (lift-verbatim or re-derive) before proceeding."` Loop back to re-synthesis.

### Review Round

**Compaction checkpoint: pre-fanout.** Quality + scope reviewer fan-out reads `design.md` + `goals.md` + `research/summary.md` + the agent-embedded reviewer protocol. See using-qrspi `## Compaction Checkpoints`.

Call `TaskCreate({ subject: "Recommend /compact (pre-fanout) — design", description: "pre-fanout: parallel reviewer dispatch reads design.md + goals.md + research/summary.md. User decides whether to /compact." })`.

Apply the **Standard Review Loop** from `using-qrspi/SKILL.md`. Two parallel reviewer dispatches per artifact per round (quality + scope).

**Dispatch the round through dispatch-agent's high-level entry.** Run `scripts/dispatch-agent.sh --step design --round ${ROUND} --artifact-dir <ABS_ARTIFACT_DIR>` (plus the per-skill `--output-dir`/`--artifact`/`--agents` flags below). High-level mode invokes `scripts/review-prep.sh` to emit `<ABS_ARTIFACT_DIR>/reviews/design/round-${ROUND}.diff` (and the design absorption-map TSV) and threads `diff_file_path:` and `absorption_map_path:` into each reviewer prompt; the orchestrator runs no `git diff` Bash redirect of its own. When the artifact directory is not inside a git repository, review-prep skips diff emission and `diff_file_path:` is omitted. When using-qrspi step 12 narrows the base ref, pass `--base-ref "$(cat reviews/design/round-$((ROUND-1))-commit.txt)"` so review-prep narrows against the prior round's per-round commit SHA (using-qrspi step 12 owns the SHA-format validation and the `anchor-file-missing:`/`sha-format-invalid:` halt directions before the SHA reaches `git diff`). Scope-tag narrowing (when active) reaches reviewers as `scope_hint:` wrapped between `<<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>` / `<<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>` markers per the reviewer-protocol Reviewer Dispatch Contract.

**On-demand inputs apply to the quality reviewer only.** Only `qrspi-design-reviewer` (Claude quality-reviewer) inherits the read-on-demand permission for `research/q*.md` — NOT the scope-reviewer. When `design.md` cites a specific `q*.md` (e.g., "per `research/q07-codebase.md`") to justify a decision, the quality reviewer must be able to verify that citation. Scope-reviewers evaluate boundary/scope only against OWNS/DEFERS; granting them the permission would dilute the "scope-reviewers only Read OWNS/DEFERS" invariant. `research/q*.md` is permissive for the quality reviewer alone, not required, and does not enter the untrusted-data wrapper list unless actually loaded. Anti-prophylactic discipline applies.

Set the per-skill dispatch parameters below, then include the shared reviewer-dispatch prose. Include `*-codex` peer tags in `REVIEW_AGENTS` only when `second_reviewer: true`.

```sh
REVIEW_STEP="design"
REVIEW_ROUND="${ROUND}"                                  # current review round (NN)
REVIEW_OUTPUT_DIR="<ABS_ARTIFACT_DIR>/reviews/design/round-${ROUND}/"
REVIEW_ARTIFACT="design.md"
REVIEW_AGENTS="quality-claude=qrspi-design-reviewer,scope-claude=qrspi-design-scope-reviewer,quality-codex=qrspi-design-reviewer,scope-codex=qrspi-design-scope-reviewer"
```

# Reviewer Dispatch (shared)

With `$REVIEW_STEP`, `$REVIEW_ROUND`, `$REVIEW_OUTPUT_DIR`, `$REVIEW_ARTIFACT`, and `$REVIEW_AGENTS` set by the per-skill preamble above, run:

```sh
scripts/dispatch-agent.sh --step "$REVIEW_STEP" --round "$REVIEW_ROUND" \
  --output-dir "$REVIEW_OUTPUT_DIR" --artifact "$REVIEW_ARTIFACT" \
  --agents "$REVIEW_AGENTS"
```

`dispatch-agent` emits M lines on stdout (one per first-party reviewer; zero lines for a third-party-only batch). Each line has the form:

```
MODE=first_party TAG=<tag> SUBAGENT_TYPE=<agent-name> MODEL=<resolved-model> PROMPT_FILE=<absolute-path>
```

**For every emitted spec line, invoke the Task tool with these arguments (parse the line as space-separated `KEY=VALUE` pairs; values contain no spaces):**

- `subagent_type` = the `SUBAGENT_TYPE` value, verbatim
- `model` = the `MODEL` value, verbatim
- `prompt` = the literal string `"DISPATCH_FILE=<PROMPT_FILE-value>"` — a single-line env-var-style reference; the prompt argument has no other content

**Invoke all M Task tool calls in parallel in one orchestrator response** (one Task call per spec line). The reviewer agent body's first instruction is to `Read` its `DISPATCH_FILE` — do not pre-Read the file yourself; the dispatch context belongs in the subagent's window, not the orchestrator's.

**Iron law (orchestrator-side dispatch contract):** invoke the Task tool exactly once per emitted spec line, with `SUBAGENT_TYPE`, `MODEL`, and `PROMPT_FILE` copied verbatim. Skipping a line, deduplicating across lines, modifying any value, or substituting a different subagent_type is a contract violation. The dispatch manifest (`$REVIEW_OUTPUT_DIR/.dispatch-manifest.json`) records expected dispatches; the apply-fix step's "expected tag produced no output" diagnostic catches missed or mis-routed Task invocations.

**Capture each Task return value to disk before draining.** After each Task call returns, write the subagent's reply text (the full Task return string) to `$REVIEW_OUTPUT_DIR/.dispatch/<TAG>.raw` using the `create` tool, where `<TAG>` is the `TAG` value from the corresponding spec line. This is mandatory regardless of whether the subagent appeared to write per-finding files itself. Rationale: when a subagent cannot use the Write tool (read-only sandbox; missing `allowed-tools` entry; tool denial at runtime) it emits findings via the `<<<FINDING-BOUNDARY>>>` stdout contract instead. `await-round.sh` recovers those findings via a universal stdout-fallback that reads `.dispatch/<TAG>.raw` and pipes it through `third-party-finding-splitter.sh`; without the captured `.raw` file the fallback has nothing to work with and the round looks (incorrectly) clean.

After all Task tool calls return AND all `.raw` captures are written (Task tool is synchronous; first-party subagents with working Write tools have already written their per-finding files by this point), drain any third-party background dispatches and finalize the round:

```sh
scripts/await-round.sh --round-dir "$REVIEW_OUTPUT_DIR"
```

`await-round` is no-op-safe — first-party-only rounds still call it; it returns immediately after reading the manifest. It writes a small `$REVIEW_OUTPUT_DIR/.round-complete.json` summary and (for third-party dispatches OR any entry that produced no per-finding files but has a `.dispatch/<TAG>.raw` capture) materializes per-finding files via `third-party-finding-splitter.sh`. It does NOT echo captured subagent payloads (CD-1 #4 output-bound contract).

Then read `$REVIEW_OUTPUT_DIR/.round-complete.json` and the per-finding files as needed for apply-fix. The raw per-reviewer prompt content (assembled by dispatch-agent into `PROMPT_FILE`) never enters the orchestrator's context — only the small spec lines + the small `DISPATCH_FILE` references passed to Task.

### Human Gate

**Visual-fidelity binding precondition (defense-in-depth re-check).** When `config.md` carries `visual_fidelity_required: true`, re-assert the same gate as `### Precondition Checks` before presenting `design.md`. On failure, **do not present** — loop back to re-synthesis (the upstream check should have caught this; reaching it here means a step was skipped). Skipped entirely when `visual_fidelity_required: false`.

Present `design.md` to the user — "hammer on it" review point. **Always state the review status:** "Reviews passed clean in round N" or "Reviews found issues in round N which were fixed but not re-verified."

On approval, if reviews have not passed clean, note this and ask if they'd like a review loop before finalizing. Then write `status: approved`.

On rejection, write feedback to `feedback/design-round-{NN}.md` (using-qrspi Feedback File Format), continue the conversation, and re-synthesize with a new subagent receiving: `goals.md`, `research/summary.md`, the latest design-discussion summary, and **all** prior feedback files. The on-demand read permission for `research/q*.md` carries forward per §Artifact Gating.

### Artifact

`design.md` — per-goal solution definitions (outcome, solution, why this approach, dependencies + edge cases, acceptance), cross-goal decisions, approach rationale and trade-offs. Vertical slice authoring and phase groupings live in `phasing.md` (owned by `qrspi:phasing`).

### Terminal State

If the artifact directory is inside a git repository, commit the approved `design.md` and the `reviews/design/` directory (per-round per-reviewer files; see `using-qrspi` → "Commit after approval (when applicable)").

**Compaction checkpoint: pre-handoff.** Design approved; the next skill (typically Phasing) reads `design.md` + every prior approved artifact + reviewer findings on a fresh context. See using-qrspi `## Compaction Checkpoints` for the iron-rule contract.

Call `TaskCreate({ subject: "Recommend /compact (pre-handoff) — design", description: "pre-handoff: next skill reads design.md + prior artifacts + reviewer findings. User decides whether to /compact." })`.

**REQUIRED:** Invoke the next skill in the `config.md` route after `design`.

## Red Flags — STOP

- YAGNI violation: features, abstractions, or extensibility not required by goals
- Design contradicts research findings without acknowledging the deviation
- Approach rationale missing — chosen approach stated but trade-offs not explained
- "We might need X later" as justification for including X now
- Design embeds DEFERS-list content (full DDL, full function signatures, full assertion text, line-by-line logic) — this content is owned downstream by Plan / Implement
- Batch-presenting designs for multiple goals in one turn — pace the discussion goal-by-goal.

## Common Rationalizations — STOP

| Rationalization | Reality |
|----------------|---------|
| "We should add X for future extensibility" | YAGNI. If it's not in goals, it's not in the design. |
| "I'll just paste the DDL/full signatures here so Plan has them" | Those belong to Plan / Implement. Pasting them in design.md is boundary-drift the scope-reviewer flags as a DEFERS violation. |
| "Phasing decisions feel architectural — I'll handle them here" | Phasing is the next skill in the route. Authoring slices or phase boundaries here is boundary-drift; pass the architecture forward and let `qrspi:phasing` author the slice/phase split. |

Behavioral directives D1-D4 apply — see `using-qrspi/SKILL.md` → "BEHAVIORAL-DIRECTIVES".
