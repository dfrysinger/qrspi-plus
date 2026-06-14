---
name: design
description: Use when research/summary.md is approved and the QRSPI pipeline needs an architecture — proposes approaches, surfaces key architectural decisions with rationale, and defines a design-level test strategy through interactive design discussion
---

# Design (QRSPI Step 4)

**PRECONDITION:** Invoke `qrspi:using-qrspi` skill to ensure global pipeline rules are in context. (Idempotent on session re-entry. Subagents are exempt — SUBAGENT-STOP in using-qrspi handles that.)

**Announce at start:** "I'm using the QRSPI Design skill to explore approaches and define the architecture."

**If auto-mode is detected** (presence of `## Auto Mode Active` system-reminder in current context), surface to the user before the first interactive step: "This skill is collaborative — turn-by-turn dialogue produces better Design quality than autonomous execution. Recommend exiting auto-mode (`Shift+Tab` to cycle modes) for this phase. I'll proceed in either mode if you prefer."

Do not force the user out of auto-mode; respect their choice. Surface the recommendation explicitly at start.

## Overview

Translate research findings into per-goal solution definitions through interactive discussion. Propose approaches with trade-offs, surface key architectural decisions with rationale, and lock decisions at outcome altitude. The discussion happens conversationally; a subagent synthesizes `design.md` per round.

<!-- Soft length target: 200–400 lines for this SKILL.md. The marker is a guidance signal — long enough to carry per-section template guidance + OWNS/DEFERS contract + reviewer wiring, short enough to keep the prompt scannable in a single context window. -->

## What Design produces

Design produces a per-goal solution definition at outcome altitude — the end-state
being targeted, the practical solution at the altitude defined by the Altitude Sub-Rules below,
and the reasoning behind it. Per-goal acceptance criteria are inline in each goal block.
Design may include zero or more per-solution diagrams (per goal block or per cross-cutting CD)
when they aid comprehension of that specific solution. Unified system architecture, file maps,
module boundaries, and the unified test architecture that stitches per-solution acceptance
criteria into a coherent test plan are Structure's job (see Structure's owns/defers contract); per-test specification
(per-assertion test code) is Plan's job.

## Per-goal block template

- **Outcome** — the end-state being targeted
- **Solution** — the practical solution at the altitude defined by the Altitude Sub-Rules
- **Why this approach** — tradeoffs and alternatives considered
- **Dependencies + edge cases** — what the solution depends on and which corner cases it handles
- **Acceptance** — a high-level "done" signal at the outcome level

**Optional per-goal Mermaid diagram** when the solution involves flow that benefits from visualization.

**Cross-Goal Decisions section** above the per-goal blocks for decisions that span multiple goals.

## Dialogue Conduct

When working a goal with the user, follow these rules:

1. **Open with questions.** Surface your list of open questions for the goal in chat. Work
   through them with the user one decision at a time.

2. **One question at a time, with a recommended answer.** Each question carries your proposed
   answer; the user confirms, amends, or rejects.

3. **Ground first, ask second.** Before asking the user any question — your own or one the
   user has asked back — consult, in order: the research summary, the codebase, then the web.
   When a question touches industry best practice, conventions, or external patterns, search
   the web liberally for cited evidence rather than speculating or punting the question back.
   Only escalate to the user when no source surfaces a defensible answer.

4. **When the user asks for your call, provide one.** When the user solicits your opinion,
   asks which option is best, or asks what you would recommend, give a grounded recommendation
   (sources per Rule 3) with named tradeoffs. Do not deflect with more questions or punt the
   choice back. If grounding genuinely leaves the call indeterminate, say so explicitly and
   name what additional evidence would resolve it.

5. **Use simple language and provide context when presenting ideas.** Ground proposals in
   concrete scenarios before naming them abstractly. Assume the user may not have the
   project's internal vocabulary (component names, jargon, structural conventions, identifiers
   specific to this codebase or domain) fresh in working memory — when introducing a technical
   term that has not appeared in this dialog within the recent turns, provide one sentence
   of grounding context. Trade-off framings ("here are 3 candidates: A is X, B is Y...")
   should explain what each candidate concretely does in plain prose before naming the
   abstract architectural shape.

6. **Sharpen fuzzy language.** When the user uses imprecise vocabulary, propose the canonical
   term and ask for confirmation before moving on.

7. **Walk every branch of the decision tree, including flow gaps.** For each goal, resolve
   dependencies between decisions one-by-one. Do not move to the next goal until every branch
   surfaced for the current one is either decided, explicitly deferred with a written reason,
   or split out as a separate goal. Branch completeness explicitly includes the end-to-end
   flow between any multi-actor decisions — actors named, operations sequenced, per-step
   inputs/outputs traced to producer and consumer, loud-failure paths named, context-cost
   call-out present (per Sub-Rule C). A flow with implicit hand-offs is an open branch; close
   it before moving on.

8. **Lock decisions as they settle.** Write each decision into the goal block under
   `status: draft` as it is confirmed. Do not accumulate decisions in chat across multiple
   goals before persisting.

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

**Worked examples:**

| Permitted (identity) | Not permitted (layout / wiring / signatures) |
|---|---|
| "Rename `foo.sh` → `bar.sh`" | "`bar.sh` lives at `scripts/bar.sh` and sources `lib/baz.sh`" |
| "`prep.sh` is auto-invoked by `bar.sh` when its outputs are absent" | "`bar.sh` calls `prep_if_needed(step, round)` returning `{ref, narrowed}`" |
| "The per-round manifest is `manifest.json`, one entry per dispatched job" | "Manifest schema: `{jobs: [{id: str, tier: str, started_at: int}]}`" |
| "Resolver and host-detect are shared infrastructure" | "`detect_host()` returns one of `claude-code\|codex-cli\|copilot-cli`" |

## Altitude Sub-Rule B — Prose-as-Decision

**Altitude Sub-Rule B — Prose-as-Decision** (applies to prompt prose, reviewer rubrics, skill
text, agent frontmatter, dispatch payloads).

When the artifact being designed IS prompt prose, the prose-level wording IS the design.
Specifying exact words is not over-reach; it is the unit of architectural commitment. LLM
behavior is acutely sensitive to wording, and generic paraphrase is not equivalent to a
specified rule.

**Altitude test.** Ask: "if a future agent re-implemented this from my description using
different wording, would they produce equivalent LLM behavior?"
- If the artifact is code: generally YES — Sub-Rule A governs; specify what, not how.
- If the artifact is prompt prose: generally NO — Sub-Rule B governs; specify the wording
  verbatim to the extent scope allows (see Scope proportionality below).

**Scope proportionality.** Verbatim authoring is the default when the prose artifact is small
enough for design.md to carry cleanly — paragraph-scale items such as a SKILL.md rule, a
frontmatter description, a reviewer directive, or a short rubric. For larger prose artifacts
(multi-section skill bodies, multi-page reviewer protocols, lengthy agent instructions),
design.md specifies (a) the intent and required behaviors, (b) the structural skeleton, and
(c) any **anchor phrases** that MUST be exact — sentences whose wording is load-bearing for
LLM behavior (RED FLAG / STOP directives, Iron Rules, "do NOT X" prohibitions, named
antagonist behaviors). The full body is authored at Implement against that spec (Plan
packages the deferred spec into a task with test expectations that assert intent, skeleton,
and anchor-phrase presence). Err toward verbatim when in doubt — small artifacts deserve
verbatim treatment; defer only when full inclusion would balloon design.md and lose altitude.

**Default when in doubt.** If the artifact is text an LLM will read as instructions, treat
the wording as binding. For paragraph-scale items, author the literal sentence. For multi-
section bodies, author the intent + skeleton + anchor phrases per Scope proportionality
above. "The rule should say X in spirit" is insufficient at any scale — even when deferring
the body to Implement, the design.md spec must be precise enough that paraphrase risk is
constrained.

**Operational rule for design.md.** When locking a prose-design decision, write the content
inside a fenced block or blockquote, marked with a comment naming the target artifact. For
verbatim (paragraph-scale) decisions:

```
<!-- prose-design: <target file> § <section> -->
<verbatim text here>
```

For deferred (multi-section) decisions, mark the spec block with the deferral note:

```
<!-- prose-design (deferred to Implement): <target file> § <section> -->
Intent: <one-paragraph behavioral spec>
Skeleton: <ordered list of required subsections>
Anchor phrases (MUST be exact):
  - "<load-bearing sentence 1>"
  - "<load-bearing sentence 2>"
```

Downstream readers handle both:
- Verbatim blocks → exact-copy contracts; Implement copies them through without paraphrase.
- Deferred blocks → intent + skeleton + anchor-phrase contracts; Plan packages the spec
  into a task with test expectations (anchor phrases present verbatim, skeleton structure
  matches, intent satisfied); Implement authors the full body against the spec.

In both cases anchor phrases are exact-copy.

**Worked examples:**

| Artifact | Altitude content | Sub-rule | Form |
|---|---|---|---|
| Shell script identity (rename + behavior) | Name + purpose + behavior; no function signatures | A | — |
| Skill prose rule (e.g., a Dialogue Conduct rule) | Verbatim wording inside a marked block | B | Verbatim |
| Reviewer protocol rubric (e.g., change-type classifier) | Verbatim rubric text | B | Verbatim |
| Data-contract artifact identity (e.g., JSON manifest) | Name + purpose + necessary fields; no schema layout | A | — |
| Subagent frontmatter description | Verbatim description text | B | Verbatim |
| Routing matrix / lookup table | Verbatim table | B | Verbatim |
| Multi-section SKILL.md body (e.g., a new skill's full body) | Intent + section skeleton + anchor phrases | B | Deferred → Implement |
| Lengthy reviewer-protocol body (multi-section) | Intent + skeleton + anchor phrases | B | Deferred → Implement |

## Altitude Sub-Rule C — End-to-End Flow

**Altitude Sub-Rule C — End-to-End Flow** (applies whenever a design decision introduces or modifies an interaction across two or more actors — orchestrator, script, subagent, file, manifest, external service, user).

When a decision involves multiple actors that hand off to each other, the design block MUST specify the end-to-end flow between them, not just enumerate the components in isolation. "We'll have script X and agent Y and manifest Z" is component enumeration; the design has to also say what calls what, in what order, with what inputs, producing what outputs, consumed by whom.

**Required flow elements** (for any multi-actor decision):
- **Actor inventory** — name every actor that participates in the flow (orchestrator, script, subagent, file, external service, user).
- **Sequence of operations** — ordered list of who-does-what. If parallelism matters, name the parallelism boundary (e.g., "M Task tool calls in parallel in one orchestrator response").
- **Per-step inputs and outputs** — what each actor receives at each step and what it produces. Cite where outputs are written (stdout, file path, manifest entry, Task tool return value).
- **Consumer identification** — for every output, name who reads it next. An output with no named consumer is dead and must be removed or its consumer surfaced.
- **Loud-failure paths** — what happens when each step fails (the step's failure mode, where the failure surfaces, which actor catches it). "Silent fallback" is never the answer — name the diagnostic.
- **Context-cost call-out** — for any flow that crosses the orchestrator/subagent boundary, explicitly state what enters the orchestrator's context vs. what stays in subagent context or on disk. This is the substrate for orchestrator-context-budget concerns; flows that bloat the orchestrator window without saying so leak prompt content silently.

**Altitude test.** Ask: "Can Structure / Plan / Implement enumerate the per-round (or per-cycle) orchestrator actions in order, naming inputs and outputs for each step, without inventing sequencing decisions the design failed to commit?"
- If yes → flow is specified at the right altitude.
- If no → back off and add the missing steps. The most common gap is the orchestrator-side instruction work: "the script returns N specs" without saying how the orchestrator parses them and what it does with each one.

**Worked example — failure pattern (components without flow).** A design names three actors — a controller, several worker subagents, a shared output directory — and a goal: collect results from all workers. The design specifies the actors and the goal but not the choreography: how the controller invokes each worker, what each worker is told about where to write, how the controller knows all workers are done, what happens if one worker writes nothing. The result is downstream guessing — Structure invents an invocation contract that doesn't match Plan's task ordering, Implement ships a polling loop the design never authorized, and a worker silently producing no output is missed entirely until Test.

**Worked example — same decision after applying Sub-Rule C.** The design specifies the choreography. The controller writes per-worker inputs to deterministic paths under the shared directory. It invokes the N workers in parallel in a single batched call, passing each worker the path it should read and the path it should write. Each worker reads its input, processes, writes its output to its assigned path. The controller waits for all worker calls to return, then enumerates the shared directory; any expected output that is missing or empty triggers a loud failure citing the missing worker by name. Every actor named, every step ordered, every input and output traced to its producer and consumer, the controller-context-cost call-out present (worker outputs stay on disk; only the consolidated summary enters the controller's window).

**Mermaid flow diagrams.** When the end-to-end flow involves three or more actors with non-trivial sequencing, the per-goal block SHOULD include a Mermaid sequence diagram (or flowchart for branch-heavy flows). The diagram is a load-bearing artifact, not decoration — readers (Structure, Plan, Implement) inspect it before reading the prose. Diagrams are mandatory when the flow:
- crosses the orchestrator/subagent boundary (LLM tool-call boundary)
- involves parallel fan-out followed by wait-all (or other non-linear control flow)
- has loud-failure paths whose detection is across-actor

Per-goal blocks with single-actor or two-actor flows MAY omit the diagram if the prose specification is unambiguous.

**Scope clarification.** Sub-Rule C does NOT push Design into pseudocode (Sub-Rule A still forbids function signatures) or into specifying the per-actor implementation (each actor's internals are owned by Structure for code or Plan for tasks). C specifies the **inter-actor contract**: the shape of each hand-off, the order of operations, the trace from input to output to consumer. Structure and Plan author the internals; Design owns the choreography.

## Sub-Rule D — External-Knowledge Completeness

**Sub-Rule D — External-Knowledge Completeness** (applies whenever a design decision references behavior, contracts, or signals from external systems — host CLIs, vendor APIs, platform runtime injections, library protocols, third-party file formats).

Design is the LAST research-bearing phase in the QRSPI pipeline. After Design, no skill runs research or external-source verification — Structure, Plan, Parallelize, Implement, Integrate, Test all consume what Design committed. Any external-knowledge question Design defers (a "TBD per vendor docs at implementation time" footnote, a "to be verified by implementer" placeholder) becomes a downstream blocker that resolves to either a guess (silently wrong) or a halt the user has to unblock. Either outcome is a design defect.

The only external-to-codebase knowledge downstream skills are expected to bring is: (a) how existing project code works (they Read it), (b) how to generally write code in the relevant language (model weights), (c) how to use ordinary development tools (model weights). Everything else — platform behaviors, vendor contracts, host runtime injections, third-party protocols, file-format specifics — MUST be answered in the design block, with citations.

**Required completeness elements** (for any decision that references external behavior):

- **External-claim inventory** — every external-system claim the design relies on is enumerated explicitly. "We detect autopilot via a host signal" is one claim. "We dispatch with parameter Y on vendor API Z" is another. Implicit references ("the platform handles it", "see vendor docs") are forbidden — name the platform, name the mechanism, write the answer.
- **Verified answer** — each claim has the concrete answer in the design block, not deferred. "Claude Code injects `## Auto Mode Active`" is an answer. "TBD per Claude docs" is not.
- **Source citation** — each claim cites its source: docs URL + fetch date, CLI command + output snapshot, direct runtime observation + observation method + observed value. Citations are durable; the design block is the audit trail downstream skills consult.
- **Verification method label** — note whether the answer was verified by docs-only, by docs + direct observation, or by direct observation only. Docs-only is acceptable when the source is authoritative and stable. Docs + observation is preferred when feasible. **For claims about host runtime injections, direct observation is required** (doc-only is unreliable — host CLIs frequently inject undocumented signals; verified case: Copilot CLI v1.0.57 injects an autopilot-state context tag with no mention in `copilot help environment` or official autopilot docs — see `scripts/detect-interaction-mode.sh` for the exact tag and sentinel literals). <!-- evergreen-exempt -->
- **Unknown branches** — when verification yields "unknown" or "host-not-yet-supported", the design block MUST name the unknown explicitly AND specify the safe-default behavior downstream code applies AND specify the verification procedure the implementer follows when the host is added. "Unknown — safe default X — verify via procedure Y" is a valid design answer; "TBD figure out later" is not.

**Completeness test.** Ask: "If a fresh implementer reads only this design block plus the existing project code, can they implement the decision without consulting any external source the design didn't already cite?"
- If yes → external-knowledge completeness satisfied.
- If no → name the missing external answer, research it, write the answer + citation into the design block. If the answer is genuinely unknown at design time, add it as an explicit `unknown` branch with safe-default + verification procedure.

**Worked example — failure pattern (deferred external knowledge).** A design decision says "the orchestrator detects auto-mode via a host-specific signal (see vendor docs for the exact mechanism)." Structure maps the work to a script. Plan authors tasks that consume the detection. The implementer reads the design, finds no concrete signal name, guesses (env var name, system-reminder string), and ships a script that fails to detect anything on real sessions. The bug surfaces at Test or in production. The root cause is design-time external-knowledge deferral.

**Worked example — same decision after applying Sub-Rule D.** The design enumerates supported hosts as locked claims. For each host, the design block names the exact detection signal with citation and verification method. Example: for host A: "`## Auto Mode Active` system-reminder block; verified via plugin skill citation X (docs-only, stable source)". For host B: "the host's autopilot-state context tag and its body sentinel sentence (exact literals captured in `scripts/detect-interaction-mode.sh` — kept out of this prose so the regression-grep in `tests/unit/test-detect-interaction-mode.bats` can fence them to the script and its fixture); verified via direct toggle-and-observe on CLI version Z dated 2026-05-31 (docs would have produced the wrong answer)". Unsupported hosts get an explicit unknown branch: "host not yet supported — safe default `interactive` — verification procedure: at host-addition time, toggle the host's auto-mode CLI affordance and observe context for any new tag/marker/sentence; document observation in script header." The implementer reads the block, writes the script branches, and ships working detection on day one. No external research, no guessing, no Test-time surprises.

**Scope clarification.** Sub-Rule D does NOT require Design to restate common-knowledge programming patterns or ordinary tool usage. It targets specifically **claims about external systems whose behavior the implementer cannot verify by reading project code or relying on general programming knowledge**. "We use `git diff` to compare commits" is not a Sub-Rule D claim (basic tool usage). "Vendor X's webhook fires on event Y with payload shape Z" is a Sub-Rule D claim (external-contract specifics). When in doubt, ask: "could a competent implementer answer this from project code + their own knowledge?" If no, Sub-Rule D applies.

## Incremental Persistence (Direct-to-Artifact Drafting)

Per Dialogue Conduct Rule 8 above, after each per-decision lock signal (the user says "approved" or equivalent for a goal block or a cross-goal decision), write the resulting block **directly to `design.md`** with `status: draft` in the frontmatter — no separate staging file, no end-of-phase synthesis-from-scratch transformation step. The draft `design.md` on disk is the durable record of locked decisions; the chat transcript is not.

Per-goal blocks use the five-field template defined in `## Per-goal block template` above (Outcome, Solution, Why this approach, Dependencies + edge cases, Acceptance). Cross-goal decisions live in a dedicated **`## Cross-Goal Decisions`** section at the top of `design.md` (above the per-goal blocks). Goals SKILL has no equivalent cross-decision section — its template is purely per-goal.

**Presence ≡ locked.** The draft `design.md` is a keyed map of locked decisions. A decision is locked if and only if its block appears in the file. Tentative bodies, placeholder bodies, `to be filled` markers, TODO markers, "placeholder for synthesis" markers, or any other not-yet-formed content NEVER enter the draft artifact. If a decision is not fully formed (per-goal block missing one of the five fields, cross-goal decision missing rationale or scope), it does not appear in the file. This is the Evergreen-Output Rule applied to incremental persistence — dialogue exhaust never enters the artifact.

**Keyed in-place overwrite on re-lock.** Per-goal and cross-goal decision blocks are keyed by decision ID (`### G3 — ...`, `### CD-1 — ...`). If the user re-opens a previously-locked decision (e.g., revises G3 after walking G15), overwrite that decision's block in place — do NOT append a duplicate. The artifact is a keyed map persisted as ordered markdown, not an append-only log.

**Resume after compaction.** If `/compact` fires mid-phase, on resume:

1. Read the draft `design.md` from disk and enumerate the decisions already locked.
2. Compute remaining work as `goals.md` goals minus per-goal blocks already locked in `design.md`. The upstream inventory is the approved `goals.md` goal list — every goal in `goals.md` requires one per-goal solution definition in `design.md`. Cross-Goal Decisions are additive (they emerge during walkthrough) and are not pre-enumerable from the upstream inventory; they do not contribute to `K remaining`.
3. Surface the recovery diagnostic to the user, verbatim:

   `"Resumed after compaction — last locked decision: GNN (M decisions locked, K remaining). Continuing from G(NN+1)."`

4. Continue dialogue from the next unlocked decision.

**Simulated-compaction durability contract.** A simulated compaction at a mid-phase decision (e.g., G15) followed by resume MUST produce a final artifact identical to a no-compaction run. The on-disk draft is the single source of truth for locked decisions; nothing about the chat transcript or in-session working memory is load-bearing across the compaction boundary.

**End-of-phase finalize pass.** After the per-goal walkthrough completes, run a lightweight finalize pass:

- Validate that every goal in `goals.md` has a corresponding per-goal block in `design.md` with all five fields populated (Outcome, Solution, Why this approach, Dependencies + edge cases, Acceptance).
- Validate the `## Cross-Goal Decisions` section is well-formed (each entry keyed by ID, each entry carries rationale + scope).
- Optionally append a top-level summary if absent.
- **Only flip status if all validations pass.** If any validation step fails, halt immediately before the status flip, surface the specific failure to the user, and re-enter dialogue to resolve the invariant violation before re-attempting the finalize pass. Do NOT advance the gate with a failing artifact.
- Flip frontmatter `status: draft` to `status: approved-pending-review`.

Hand-edits that flip `status: draft` to `status: approved-pending-review` (or directly to `approved`) mid-phase, before the finalize pass, are forbidden — only the finalize pass writes the next-gate status.

## Design OWNS / Design DEFERS

!cat skills/design/owns-defers.md

## Artifact Gating

**Required inputs:**
- `goals.md` with `status: approved`
- `research/summary.md` with `status: approved`

If either artifact is missing or not approved, refuse to run and tell the user which artifact is needed.

**On-demand inputs — research read-on-demand:** the per-question research files at `research/q*.md` are available to Design as **on-demand reads**, not required inputs. `research/summary.md` carries each question's structured `## Summary` block (TL;DR / Key findings / Surprises / Caveats) verbatim and is the primary input; reach for the corresponding `research/q*.md` when an architectural decision depends on detail the summary block deliberately compressed away (specific `file:line` references, full source URLs, methodology notes, alternatives the researcher considered but did not surface). Cite the file you reached for in the design discussion (e.g., "per `research/q07-codebase.md`") so the rationale chain stays auditable. Do NOT load `research/q*.md` files prophylactically — they exist behind `summary.md` precisely to keep the default input set lean.

Read `config.md` from the artifact directory to determine whether Codex reviews are enabled. Apply the **Config Validation Procedure** in `using-qrspi/SKILL.md`. Design validates `codex_reviews`.

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
- Any prior feedback files
- **On-demand:** `research/q*.md` files per the read-on-demand permission in `## Artifact Gating` (single source of truth for the trigger condition, citation requirement, and anti-prophylactic guard — not restated here). The orchestrator surfaces available `q*.md` filenames in the subagent prompt; the subagent decides which (if any) to load.

**Prompt-prose authoring step.** When the synthesis subagent authors `<!-- prose-design: target -->` blocks (verbatim prompt-prose destined for an LLM-consumable file), apply the detection and writer rules:

**PRECONDITION:** `skills/_shared/prompt-prose-detection.md` and `skills/_shared/prompt-prose-writer-addition.md` MUST exist on disk; halt the subagent with a named diagnostic if any required shared file is missing rather than proceeding with empty include content.

!cat skills/_shared/prompt-prose-detection.md

!cat skills/_shared/prompt-prose-writer-addition.md

**Output format for `design.md`:**

!cat skills/_shared/evergreen-output-rule.md

> **Per-section template guidance is embedded inline as HTML comments below.** Each section block carries a one-line guidance comment and a conformance reminder so future design.md content can be linted for boundary-drift signals (the scope-reviewer's boundary-drift sub-check looks for downstream-stage jargon — DDL keywords, full TypeScript signatures, literal `expect(...)` assertions, phase-split language — leaking into design.md; design.md owns approach/rationale/trade-offs and per-goal solution definitions, not Plan/Implement-layer surfaces or Phasing-layer slice authoring).
>
> **Conformance applies to every section of design.md.** Claim-before-evidence (lead each subsection with its decision sentence; supporting detail follows). Paragraph density: ≤150 words / ≤8 lines per paragraph; if longer, split. Scannability: bullets in any section longer than ~12 lines. No-brevity prohibition: do NOT add "be concise", "brief summary", "≤ N lines" framing; the soft length target lives in this SKILL.md, not in the artifact.

````markdown
---
status: draft
---

# Design: {Project/Feature Name}

<!-- Lead with one claim sentence describing the architecture's organizing axis (e.g., "Event-sourced write side, projection-based read side"); do NOT restate goals.md. -->

## Approach

<!-- Per-section guidance: one claim sentence first ("Chosen approach: {X}"), then 1–2 short paragraphs of rationale grounded in research findings. Claim-before-evidence; length-target ≤8 lines per paragraph. NO DDL, NO full function signatures, NO assertion text — those are DEFERS. -->

{Chosen approach and rationale}

## Key Decisions

<!-- Per-section guidance: bulleted list of major decisions, each with one-line decision + one-line reasoning. Decisions are at the architecture-boundary level (data-flow, transport, persistence model, security posture) — NOT line-by-line logic, NOT column-level DDL. Bullets for scannability; lead each bullet with the decision noun. -->

{Decisions made during discussion with reasoning}

## Trade-offs Considered

<!-- Per-section guidance: the 2–3 rejected alternatives, each with what it traded off and why it lost. Claim-before-evidence — lead each subsection with the alternative name; rationale follows. Keep at the approach level — do NOT enumerate per-column trade-offs (DEFERS). -->

{Alternatives that were rejected and why}

````

### Precondition Checks

Run this gate AFTER the synthesis subagent emits `design.md` and BEFORE the `### Review Round` block (i.e., before the pre-fanout compaction checkpoint, before the reviewer diff-file emission, and before any reviewer subagent dispatch). The gate is structural — it asserts properties the artifact must hold for downstream review to be meaningful, and on failure it short-circuits the cycle so reviewers do not consume context against an artifact that must be regenerated.

**Visual-fidelity binding precondition.** When `config.md` carries `visual_fidelity_required: true`, verify both of the following against `design.md`:

1. `## Test Strategy` contains a `### Visual-Fidelity Binding` subsection.
2. That subsection names at least one concrete wireframe artifact — a Figma URL, an embedded PNG path under the run-local artifact directory, or both. A subsection whose body is empty, contains only whitespace, contains only an HTML comment, or contains only template-placeholder text (e.g., `{Wireframe artifacts}`) does NOT satisfy this check; structural presence without concrete content fails the gate the same way absence does.

If either condition fails, do **not** emit the reviewer diff file, do **not** run the pre-fanout compaction checkpoint, and do **not** dispatch any reviewer subagent. Surface the error to the user: "design.md is missing the required `### Visual-Fidelity Binding` subsection under `## Test Strategy` (or the subsection is present but names zero concrete wireframe artifacts). Add at least one Figma URL or embedded PNG path before approval." Then loop back to `### Interactive Design Discussion` / `### Design Synthesis Subagent` to regenerate; do not proceed to `### Review Round` until the gate passes.

When `visual_fidelity_required: false` (or the field is absent), this check is skipped entirely and the binding subsection is not required.

**Reference-gate checklist item.** When the design introduces a reviewer whose verdict depends on an external reference artifact — a prototype screenshot, a golden output file, a contract fixture, or a lifted prototype — the Design synthesis subagent and the orchestrator must confirm the following before proceeding to `### Review Round`:

1. The producing task (the task that will implement the behavior the reference-dependent reviewer evaluates) is flagged `reference_gate: true` in the Plan task spec (per the T24 frontmatter contract in `skills/plan/SKILL.md` § Refuse-to-Write Contract).
2. `design.md` records the **lift-verbatim-vs-re-derive decision** for the reference artifact: state explicitly whether the implementer should copy the artifact verbatim (lift-verbatim) or derive the output behavior independently (re-derive), and name the reference artifact path or URL. This decision is the structural input downstream Structure (T25) and the visual-fidelity reviewer (T28) consume to ground their judgments.

Failure mode: if the design introduces a reference-dependent reviewer but `design.md` does not record the lift-verbatim-vs-re-derive decision, the precondition check fails. Surface the error to the user: `"design.md introduces a reference-dependent reviewer but does not record the lift-verbatim-vs-re-derive decision — add a decision statement under the relevant Key Decisions entry naming the reference artifact and the chosen decision (lift-verbatim or re-derive) before proceeding."` Then loop back to `### Design Synthesis Subagent` to update `design.md`; do not proceed to `### Review Round` until the check passes.

### Review Round

**Compaction checkpoint: pre-fanout.** Quality + scope reviewer fan-out reads `design.md` + `goals.md` + `research/summary.md` + the agent-embedded reviewer protocol; saturated context produces shallow findings. See using-qrspi `## Compaction Checkpoints` for the iron-rule contract.

Call `TaskCreate({ subject: "Recommend /compact (pre-fanout) — design", description: "pre-fanout: parallel reviewer dispatch reads design.md + goals.md + research/summary.md. User decides whether to /compact." })`.

Apply the **Standard Review Loop** from `using-qrspi/SKILL.md`. Two parallel reviewer dispatches per artifact per round (quality + scope). Design-specific reviewer instructions:

**Dispatch the round through dispatch-agent's high-level entry.** Run `scripts/dispatch-agent.sh --step design --round ${ROUND} --artifact-dir <ABS_ARTIFACT_DIR>` (plus the per-skill `--output-dir`/`--artifact`/`--agents` flags below). High-level mode invokes `scripts/review-prep.sh` to emit `<ABS_ARTIFACT_DIR>/reviews/design/round-${ROUND}.diff` (and the design absorption-map TSV) and threads `diff_file_path:` and `absorption_map_path:` into each reviewer prompt; the orchestrator runs no `git diff` Bash redirect of its own. When the artifact directory is not inside a git repository, review-prep skips diff emission and `diff_file_path:` is omitted. When using-qrspi step 12 narrows the base ref, pass `--base-ref HEAD~1`. Scope-tag narrowing (when active) reaches reviewers as `scope_hint:` wrapped between `<<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>` / `<<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>` markers per the reviewer-protocol Reviewer Dispatch Contract.

**On-demand inputs apply to the quality reviewer only.** Only the Claude quality-reviewer subagent (`qrspi-design-reviewer`) inherits the read-on-demand permission for `research/q*.md` defined in `## Artifact Gating` — NOT the scope-reviewer. When `design.md` cites a specific `q*.md` file (e.g., "per `research/q07-codebase.md`") to justify a decision, the quality reviewer needs to be able to verify that citation against its source — without on-demand permission the audit loop cannot close. Scope-reviewers evaluate boundary/scope only against the OWNS/DEFERS rule and have no citation-verification need; granting them the same permission would dilute the "scope-reviewers only Read OWNS/DEFERS" invariant. The required quality-reviewer inputs remain `design.md` + `goals.md` + `research/summary.md`; `research/q*.md` is permissive for the quality reviewer alone (read only when verifying a synthesis citation or checking a decision against compressed source detail), not required, and does not enter the untrusted-data wrapper list unless actually loaded. Same anti-prophylactic discipline applies: do NOT load `q*.md` files prophylactically.

The round's reviewers dispatch through the universal dispatch chain (`scripts/dispatch-agent.sh` → Task fan-out → `scripts/await-round.sh`). Set the per-skill dispatch parameters below, then include the shared reviewer-dispatch prose. Include the `*-codex` peer tags in `REVIEW_AGENTS` only when `second_reviewer: true`; otherwise list only the `*-claude` tags.

```sh
REVIEW_STEP="design"
REVIEW_ROUND="${ROUND}"                                  # current review round (NN)
REVIEW_OUTPUT_DIR="<ABS_ARTIFACT_DIR>/reviews/design/round-${ROUND}/"
REVIEW_ARTIFACT="design.md"
REVIEW_AGENTS="quality-claude=qrspi-design-reviewer,scope-claude=qrspi-design-scope-reviewer,quality-codex=qrspi-design-reviewer,scope-codex=qrspi-design-scope-reviewer"
```

!cat skills/_shared/reviewer-dispatch-prose.md

### Human Gate

**Visual-fidelity binding precondition (re-check before presenting).** The structural gate for the `### Visual-Fidelity Binding` subsection is the upstream `### Precondition Checks` block, which runs before reviewer dispatch and is the load-bearing enforcement point. Re-assert the same gate here as a defense-in-depth check before presenting `design.md` to the user: when `config.md` carries `visual_fidelity_required: true`, verify the subsection is present under `## Test Strategy` AND names at least one concrete wireframe artifact (Figma URL, embedded PNG under a run-local artifact path, or both); a structurally-present subsection with empty / whitespace-only / comment-only / placeholder-only body fails the check the same way absence does. If the check fails here, **do not present `design.md` to the user** — this is a precondition failure, not a reviewer finding. Surface the error: "design.md is missing the required `### Visual-Fidelity Binding` subsection under `## Test Strategy` (or the subsection is present but names zero concrete wireframe artifacts). Add at least one Figma URL or embedded PNG path before approval." Then loop back to re-synthesis (the upstream `### Precondition Checks` should have caught this; reaching it here means an earlier step was skipped). When `visual_fidelity_required: false` (or the field is absent), this check is skipped entirely and the binding subsection is not required.

Present `design.md` to the user — "hammer on it" review point. **Always state the review status** when presenting: either "Reviews passed clean in round N" or "Reviews found issues in round N which were fixed but not re-verified."

On approval, if reviews have not passed clean, note this and ask if they'd like a review loop before finalizing. Then write `status: approved` in frontmatter.

On rejection, write the user's feedback to `feedback/design-round-{NN}.md` (using the standard feedback file format from `using-qrspi`), then continue the conversation and re-synthesize with a new subagent that receives: `goals.md`, `research/summary.md`, the latest design-discussion summary, and **all** prior feedback files (not just the latest round). The on-demand read permission for `research/q*.md` carries forward — re-synthesis subagents may also reach for individual `q*.md` files per the §Artifact Gating contract (same trigger, citation requirement, and anti-prophylactic guard apply). After re-generation, the review cycle restarts.

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
