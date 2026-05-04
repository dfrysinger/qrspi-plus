---
name: design
description: Use when research/summary.md is approved and the QRSPI pipeline needs an architecture — proposes approaches, surfaces key architectural decisions with rationale, and defines a design-level test strategy through interactive design discussion
---

# Design (QRSPI Step 4)

**PRECONDITION:** Invoke `qrspi:using-qrspi` skill to ensure global pipeline rules are in context. (Idempotent on session re-entry. Subagents are exempt — SUBAGENT-STOP in using-qrspi handles that.)

**Announce at start:** "I'm using the QRSPI Design skill to explore approaches and define the architecture."

## Overview

Translate research findings into an architecture through interactive discussion. Propose approaches with trade-offs, surface key architectural decisions with rationale, and include a test strategy at the design level. The discussion happens conversationally; a subagent synthesizes `design.md` per round.

<!-- Soft length target: 200–400 lines for this SKILL.md. The marker is a guidance signal — long enough to carry per-section template guidance + OWNS/DEFERS contract + reviewer wiring, short enough to keep the prompt scannable in a single context window. -->

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

1. Propose 2-3 design approaches with trade-offs, lead with recommendation
2. Include test strategy at the design level: what types of tests (unit, integration, E2E), what layers get tested, what frameworks. Assertion text and test file layout are deferred (see DEFERS).
3. Include high-level Mermaid system diagram showing major components, relationships, and data flow
4. Surface key architectural decisions with rationale (approach selection, technical trade-offs, data-flow boundaries). Phasing concerns — vertical slice authoring, phase boundaries, replan-gate criteria, PoC scoping — are owned by `qrspi:phasing` and not authored here.
5. When handling amendments, remember: Amendment items that introduce distinct new work (new functions, new behavior, new files) must receive their own goal ID. Only items that genuinely refine or detail an existing goal's described work may be compressed into that goal. Never use bare-number compression (e.g., '5/8/10 -> U1') when the goal text doesn't cover all mapped items.

### Design Synthesis Subagent

Once the discussion settles, launch a **subagent** to synthesize `design.md`.

**Subagent inputs:**
- `goals.md`
- `research/summary.md`
- A summary of the design discussion (key decisions, user preferences, chosen approach)
- Any prior feedback files
- **On-demand:** `research/q*.md` files per the read-on-demand permission in `## Artifact Gating` (single source of truth for the trigger condition, citation requirement, and anti-prophylactic guard — not restated here). The orchestrator surfaces available `q*.md` filenames in the subagent prompt; the subagent decides which (if any) to load.

**Output format for `design.md`:**

> **Per-section template guidance is embedded inline as HTML comments below.** Each section block carries a one-line guidance comment and a conformance reminder so future design.md content can be linted for boundary-drift signals (the scope-reviewer's boundary-drift sub-check looks for downstream-stage jargon — DDL keywords, full TypeScript signatures, literal `expect(...)` assertions, phase-split language — leaking into design.md; design.md owns approach/rationale/trade-offs/test-strategy/system-diagram, not Plan/Implement-layer surfaces or Phasing-layer slice authoring).
>
> **Conformance applies to every section of design.md.** Claim-before-evidence (lead each subsection with its decision sentence; supporting detail follows). Paragraph density: ≤150 words / ≤8 lines per paragraph; if longer, split. Scannability: bullets in any section longer than ~12 lines. Required-section heading match: the headings below (`## Approach`, `## Key Decisions`, `## Trade-offs Considered`, `## Test Strategy`, `## System Diagram`) are the canonical set; do not silently rename. No-brevity prohibition: do NOT add "be concise", "brief summary", "≤ N lines" framing; the soft length target lives in this SKILL.md, not in the artifact.

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

## Test Strategy

<!-- Per-section guidance: design-level test strategy only — types (unit / integration / E2E), layers covered, frameworks chosen. Bullets for type/layer/framework triples. Do NOT include assertion text, do NOT include per-test-file layout — those are DEFERS (Implement / TDD). -->

{Test types, layers, frameworks}

## System Diagram

<!-- Per-section guidance: high-level Mermaid diagram of major components and data flow. The diagram is written into design.md (NOT pasted into terminal). Lead with a one-sentence claim describing the diagram's organizing axis (e.g., "Components grouped by trust boundary; arrows are runtime data flow") so a scanning reader does not have to infer the convention. NO file/module-layout detail — that's Structure's diagram. -->

{Mermaid diagram}
````

### Review Round

> **IMPORTANT — Compaction recommended (pre-review-loop).** The Design synthesis subagent has just returned a full design.md with rationale, trade-offs, test strategy, and a Mermaid diagram. Before dispatching the Claude reviewer, scope-reviewer, and Codex reviewer in parallel, run `/compact` if context utilization may exceed ~50%. Reviewer prompts each load `design.md` + `goals.md` + `research/summary.md` + the agent-embedded reviewer protocol; running them on a saturated context produces shallow findings.

Apply the **Standard Review Loop** from `using-qrspi/SKILL.md`. Two parallel reviewer dispatches per artifact per round (quality + scope). Design-specific reviewer instructions:

**On-demand inputs apply to reviewers.** Both the Claude quality-reviewer subagent and the Claude scope-reviewer subagent inherit the read-on-demand permission for `research/q*.md` defined in `## Artifact Gating`. When `design.md` cites a specific `q*.md` file (e.g., "per `research/q07-codebase.md`") to justify a decision, the reviewer needs to be able to verify that citation against its source — without on-demand permission the audit loop cannot close. The required reviewer inputs remain `design.md` + `goals.md` + `research/summary.md`; `research/q*.md` is permissive (read only when verifying a synthesis citation or checking a decision against compressed source detail), not required, and does not enter the untrusted-data wrapper list unless actually loaded. Same anti-prophylactic discipline applies: do NOT load `q*.md` files prophylactically.

- **Claude quality-reviewer subagent** — dispatch `Agent({ subagent_type: "qrspi-design-reviewer", model: "sonnet" })` with a prompt containing only:
  - `artifact_body`: `design.md` content wrapped between `<<<UNTRUSTED-ARTIFACT-START id=design.md>>>` and `<<<UNTRUSTED-ARTIFACT-END id=design.md>>>` markers
  - `companion_goals`: `goals.md` content wrapped between `<<<UNTRUSTED-ARTIFACT-START id=goals.md>>>` and `<<<UNTRUSTED-ARTIFACT-END id=goals.md>>>` markers
  - `companion_research`: `research/summary.md` content wrapped between `<<<UNTRUSTED-ARTIFACT-START id=research/summary.md>>>` and `<<<UNTRUSTED-ARTIFACT-END id=research/summary.md>>>` markers
  - `output`: `<ABS_ARTIFACT_DIR>/reviews/design/round-NN-claude.md` (interpolate absolute path and round number)
  - `round`: NN
  - `reviewer_tag`: `claude`

  The reviewer protocol (5-field schema, change-type classifier, disk-write contract, untrusted-data handling per `skills/reviewer-protocol/SKILL.md`) arrives via the agent file's `skills:` preload — do NOT embed reviewer-protocol content in the dispatch prompt. The Design-specific checks (addresses all goals, trade-offs, YAGNI, diagram, no phasing checks) arrive via the agent body auto-loaded by the runtime. Zero rules content in main chat for this dispatch.

- **Claude scope-reviewer subagent** — dispatch `Agent({ subagent_type: "qrspi-design-scope-reviewer", model: "sonnet" })` in parallel with the quality reviewer, with a prompt containing only:
  - `artifact_body`: same untrusted-data-wrapped `design.md` body
  - `output`: `<ABS_ARTIFACT_DIR>/reviews/design/round-NN-scope-claude.md` (interpolate absolute path and round number)
  - `round`: NN
  - `reviewer_tag`: `claude`

  The scope-reviewer's Step-1 Read of `skills/design/owns-defers.md` delivers the Design OWNS/DEFERS contract at runtime. Do NOT embed the OWNS/DEFERS rule set or reviewer-protocol content in the dispatch prompt.

- **Codex reviews** (if `codex_reviews: true`) — dispatch TWO non-blocking Codex reviews in parallel (quality + scope) via shell pipelines:

  ```sh
  # Quality reviewer (Codex)
  { awk '/^---$/{n++; next} n>=2{print}' skills/reviewer-protocol/SKILL.md;
    printf '\n\n---\n\n';
    awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-design-reviewer.md;
    printf '\n\n## Dispatch parameters\n\nartifact_body: %s\ncompanion_goals: %s\ncompanion_research: %s\noutput: <ABS_ARTIFACT_DIR>/reviews/design/round-%s-codex.md\nround: %s\nreviewer_tag: codex\n' \
      "<untrusted-data-wrapped design.md body>" "<untrusted-data-wrapped goals.md body>" "<untrusted-data-wrapped research/summary.md body>" "$ROUND" "$ROUND";
  } | scripts/codex-companion-bg.sh launch

  # Scope-reviewer (Codex)
  { awk '/^---$/{n++; next} n>=2{print}' skills/reviewer-protocol/SKILL.md;
    printf '\n\n---\n\n';
    awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-design-scope-reviewer.md;
    printf '\n\n## Dispatch parameters\n\nartifact_body: %s\noutput: <ABS_ARTIFACT_DIR>/reviews/design/round-%s-scope-codex.md\nround: %s\nreviewer_tag: codex\n' \
      "<untrusted-data-wrapped design.md body>" "$ROUND" "$ROUND";
  } | scripts/codex-companion-bg.sh launch
  ```

  The awk strips YAML frontmatter (everything up through the second `---` line). Main chat sees only the jobIds Codex prints.

### Human Gate

Present `design.md` to the user — "hammer on it" review point. **Always state the review status** when presenting: either "Reviews passed clean in round N" or "Reviews found issues in round N which were fixed but not re-verified."

On approval, if reviews have not passed clean, note this and ask if they'd like a review loop before finalizing. Then write `status: approved` in frontmatter.

On rejection, write the user's feedback to `feedback/design-round-{NN}.md` (using the standard feedback file format from `using-qrspi`), then continue the conversation and re-synthesize with a new subagent that receives: `goals.md`, `research/summary.md`, the latest design-discussion summary, and **all** prior feedback files (not just the latest round). The on-demand read permission for `research/q*.md` carries forward — re-synthesis subagents may also reach for individual `q*.md` files per the §Artifact Gating contract (same trigger, citation requirement, and anti-prophylactic guard apply). After re-generation, the review cycle restarts.

### Artifact

`design.md` — approach, key decisions, trade-offs considered, test strategy at the design level, Mermaid system diagram. Vertical slice authoring and phase groupings live in `phasing.md` (owned by `qrspi:phasing`).

### Terminal State

If the artifact directory is inside a git repository, commit the approved `design.md` and the `reviews/design/` directory (per-round per-reviewer files; see `using-qrspi` → "Commit after approval (when applicable)").

> **IMPORTANT — Compaction recommended (terminal state).** Design approved. This is a good point to compact context before the next step. Recommend the user run `/compact` if context utilization may exceed ~50%.

**REQUIRED:** Invoke the next skill in the `config.md` route after `design`.

> **IMPORTANT — Compaction recommended (cross-skill transition).** Before invoking the next skill, run `/compact` if context utilization may exceed ~50%. The next skill (typically Phasing, per the Full route) reads `design.md` + every prior approved artifact + reviewer findings; entering it on a saturated context degrades the slice-authoring and phase-split quality.

## Red Flags — STOP

- No test strategy section, or test strategy is just "add tests"
- YAGNI violation: features, abstractions, or extensibility not required by goals
- Design contradicts research findings without acknowledging the deviation
- No Mermaid system diagram, or diagram is just boxes without relationships
- Approach rationale missing — chosen approach stated but trade-offs not explained
- "We might need X later" as justification for including X now
- Design embeds DEFERS-list content (full DDL, full function signatures, full assertion text, line-by-line logic) — this content is owned downstream by Plan / Implement

## Common Rationalizations — STOP

| Rationalization | Reality |
|----------------|---------|
| "The test strategy is implied by the stack" | Write it explicitly. Downstream skills (Plan, Test) need the design-level strategy to generate task expectations. |
| "We should add X for future extensibility" | YAGNI. If it's not in goals, it's not in the design. |
| "The design is simple enough, skip the diagram" | Diagrams catch misunderstandings. A "simple" design still needs one. |
| "I'll just paste the DDL/full signatures here so Plan has them" | Those belong to Plan / Implement. Pasting them in design.md is boundary-drift the scope-reviewer flags as a DEFERS violation. |
| "Phasing decisions feel architectural — I'll handle them here" | Phasing is the next skill in the route. Authoring slices or phase boundaries here is boundary-drift; pass the architecture forward and let `qrspi:phasing` author the slice/phase split. |

Behavioral directives D1-D3 apply — see `using-qrspi/SKILL.md` → "BEHAVIORAL-DIRECTIVES".
