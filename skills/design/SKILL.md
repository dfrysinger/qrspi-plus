---
name: design
description: Use when research/summary.md is approved and the QRSPI pipeline needs an architecture — proposes approaches, surfaces key architectural decisions with rationale, and defines a design-level test strategy through interactive design discussion
---

# Design (QRSPI Step 4)

**Announce at start:** "I'm using the QRSPI Design skill to explore approaches and define the architecture."

## Overview

Translate research findings into an architecture through interactive discussion. Propose approaches with trade-offs, surface key architectural decisions with rationale, and include a test strategy at the design level. The discussion happens conversationally; a subagent synthesizes `design.md` per round.

## Artifact Gating

**Required inputs:**
- `goals.md` with `status: approved`
- `research/summary.md` with `status: approved`

If either artifact is missing or not approved, refuse to run and tell the user which artifact is needed.

Read `config.md` from the artifact directory to determine whether Codex reviews are enabled. If `config.md` doesn't exist, default to `codex_reviews: false`.

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

**Output format for `design.md`:**

```markdown
---
status: draft
---

# Design: {Project/Feature Name}

## Approach
{Chosen approach and rationale}

## Key Decisions
{Decisions made during discussion with reasoning}

## Trade-offs Considered
{Alternatives that were rejected and why}

## Test Strategy
{Test types, layers, frameworks}

## System Diagram
{Mermaid diagram}
```

### Review Round

Apply the **Standard Review Loop** from `using-qrspi/SKILL.md`. Design-specific reviewer instructions:

- **Claude review subagent** — inputs: `design.md`, `goals.md`, `research/summary.md`. Checks: design addresses all goals and acceptance criteria; trade-offs clearly stated; no internal contradictions; test strategy appropriate at the design level; YAGNI (no unnecessary complexity); approach rationale present and grounded in research findings. Phasing/slice decomposition checks are owned by the Phasing reviewer and not run here. Findings written to `reviews/design-review.md`.
- **Codex review** (if `codex_reviews: true`) — same inputs and criteria as the Claude reviewer. Findings appended to `reviews/design-review.md`.

### Human Gate

Present `design.md` to the user — "hammer on it" review point. **Always state the review status** when presenting: either "Reviews passed clean in round N" or "Reviews found issues in round N which were fixed but not re-verified."

On approval, if reviews have not passed clean, note this and ask if they'd like a review loop before finalizing. Then write `status: approved` in frontmatter.

On rejection, write the user's feedback to `feedback/design-round-{NN}.md` (using the standard feedback file format from `using-qrspi`), then continue the conversation and re-synthesize with a new subagent that receives: `goals.md`, `research/summary.md`, the latest design-discussion summary, and **all** prior feedback files (not just the latest round). After re-generation, the review cycle restarts.

### Artifact

`design.md` — approach, key decisions, trade-offs considered, test strategy at the design level, Mermaid system diagram. Vertical slice authoring and phase groupings live in `phasing.md` (owned by `qrspi:phasing`).

### Terminal State

Commit the approved `design.md` and `reviews/design-review.md` to git.

Recommend compaction: "Design approved. This is a good point to compact context before the next step (`/compact`)."

**REQUIRED:** Invoke the next skill in the `config.md` route after `design`.

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
