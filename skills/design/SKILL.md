---
name: design
description: Use when research/summary.md is approved and the QRSPI pipeline needs an architecture — proposes approaches, defines vertical slices, phases, and test strategy through interactive design discussion
---

# Design (QRSPI Step 4)

**PRECONDITION:** Invoke `qrspi:using-qrspi` skill to ensure global pipeline rules are in context. (Idempotent on session re-entry. Subagents are exempt — SUBAGENT-STOP in using-qrspi handles that.)

**Announce at start:** "I'm using the QRSPI Design skill to explore approaches and define the architecture."

## Overview

Translate research findings into an architecture through interactive discussion. Propose approaches with trade-offs, define vertical slices, establish phases with replan gates, and include a test strategy. The discussion happens conversationally; a subagent synthesizes `design.md` per round.

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

## Phase-Scoped Content Rules

design.md contains ONLY current-phase design entries. Each entry is keyed by `### {GOAL_ID} — {name}`. Entries for goals not in the current phase (per roadmap.md) belong in `future-design.md`, not design.md. When the Design skill creates or updates design.md, it must: (1) verify every goal ID in the document exists in goals.md, (2) move entries for out-of-scope goals to future-design.md, (3) check future-design.md for existing entries on current-phase goals and pull them into design.md.

### Roadmap Maintenance

When the Design skill creates or updates roadmap.md: (1) every goal ID must exist in either `goals.md` (current phase) or `future-goals.md` (Formal section), (2) the table contains ONLY goal ID, phase, and slice columns — no notes, no design content, (3) flag any goal IDs in roadmap.md that don't exist in either file as orphans for user review.

## Process

### Interactive Design Discussion

1. Propose 2-3 design approaches with trade-offs, lead with recommendation
2. Include test strategy: what types of tests (unit, integration, E2E), what layers get tested, what frameworks
3. Include high-level Mermaid system diagram showing major components, relationships, and data flow
4. Enforce vertical slice decomposition with explicit anti-pattern examples:
   - BAD: "DB layer, then API layer, then service layer, then frontend"
   - GOOD: "User registration (DB + API + service + frontend), then user profile (DB + API + service + frontend)"
5. Define phases with replan gates. Phase 1 is always the PoC — it must prove the full stack works end-to-end. Ask user which slices go in the PoC phase and where replan checkpoints belong.
6. If no CI pipeline exists, note CI setup as the first task in Phase 1, blocking all other tasks. For greenfield projects, this task should also include creating project convention files (CLAUDE.md, linting config, etc.) so later reviewers have rules to enforce.
7. When handling amendments, remember: Amendment items that introduce distinct new work (new functions, new behavior, new files) must receive their own goal ID. Only items that genuinely refine or detail an existing goal's described work may be compressed into that goal. Never use bare-number compression (e.g., '5/8/10 -> U1') when the goal text doesn't cover all mapped items.

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

## Vertical Slices
{Slice definitions with layers each touches}

## Phases
### Phase 1: PoC
{Slices in PoC, what it proves}

### Phase 2: {name}
{Slices and replan gate criteria}
```

### Review Round

Apply the **Standard Review Loop** from `using-qrspi/SKILL.md`. Design-specific reviewer instructions:

- **Claude review subagent** — inputs: `design.md`, `goals.md`, `research/summary.md`. Checks: design addresses all goals and acceptance criteria; trade-offs clearly stated; no internal contradictions; test strategy appropriate; YAGNI (no unnecessary complexity); slices are vertical (end-to-end), not horizontal layers; phase boundaries reasonable and Phase 1 PoC proves full stack. Findings written to `reviews/design-review.md`.
- **Codex review** (if `codex_reviews: true`) — `codex:rescue` with `design.md` + `goals.md` + `research/summary.md` for cross-reference, same criteria. Findings appended to `reviews/design-review.md`.

### Human Gate

Present `design.md` to the user — "hammer on it" review point. **Always state the review status** when presenting: either "Reviews passed clean in round N" or "Reviews found issues in round N which were fixed but not re-verified."

On approval, if reviews have not passed clean, note this and ask if they'd like a review loop before finalizing. Then write `status: approved` in frontmatter.

On rejection, write the user's feedback to `feedback/design-round-{NN}.md` (using the standard feedback file format from `using-qrspi`), then continue the conversation and re-synthesize with a new subagent that receives: `goals.md`, `research/summary.md`, the latest design-discussion summary, and **all** prior feedback files (not just the latest round). After re-generation, the review cycle restarts.

### Artifact

`design.md` — approach, key decisions, trade-offs considered, test strategy, vertical slice definitions, phase groupings with replan gates, Mermaid system diagram

### Terminal State

Commit the approved `design.md` and `reviews/design-review.md` to git **if the artifact directory is inside a git repository** (see `using-qrspi` → "Commit after approval (conditional)"). If not, skip the commit silently.

Recommend compaction: "Design approved. This is a good point to compact context before the next step (`/compact`)."

**REQUIRED:** Invoke the next skill in the `config.md` route after `design`.

## Red Flags — STOP

- Slices are horizontal layers ("database layer, then API layer, then frontend") instead of vertical ("user registration end-to-end, then user profile end-to-end")
- No test strategy section, or test strategy is just "add tests"
- Phase 1 (PoC) doesn't prove the full stack end-to-end
- YAGNI violation: features, abstractions, or extensibility not required by goals
- Design contradicts research findings without acknowledging the deviation
- No Mermaid system diagram, or diagram is just boxes without relationships
- Missing phase boundaries or replan gates for multi-phase work
- "We might need X later" as justification for including X now

## Common Rationalizations — STOP

| Rationalization | Reality |
|----------------|---------|
| "Horizontal layers are cleaner for this project" | Vertical slices are the invariant. If you think horizontal is better, present the case to the user — don't default to it. |
| "The test strategy is implied by the stack" | Write it explicitly. The Plan skill needs it to generate test expectations. |
| "We should add X for future extensibility" | YAGNI. If it's not in goals, it's not in the design. |
| "Phase 1 can just be the backend" | Phase 1 must prove the full stack. Backend-only PoC delays integration risk. |
| "The design is simple enough, skip the diagram" | Diagrams catch misunderstandings. A "simple" design still needs one. |

## Worked Example

**Good vertical slice decomposition:**

> ## Vertical Slices
>
> ### Slice 1: Client rate check (middleware → Redis → response)
> Touches: Express middleware, Redis client, HTTP response headers
> Proves: Full request lifecycle with rate limiting
>
> ### Slice 2: Rate limit metrics (middleware → metrics → dashboard)
> Touches: Express middleware, metrics collector, Grafana config
> Proves: Observability of rate limiting behavior

**Bad horizontal decomposition:**

> ## Layers
>
> ### Layer 1: Redis rate limit storage
> ### Layer 2: Middleware logic
> ### Layer 3: HTTP response formatting
> ### Layer 4: Metrics collection

The bad example splits by technical layer. Each "layer" can't be tested or demonstrated independently — they only work together.

## Iron Laws — Final Reminder

The two override-critical rules for Design, restated at end:

1. **Vertical slices, not horizontal layers.** Each slice must be end-to-end demonstrable on its own (DB + service + API + frontend together). "DB layer first, API layer second" defers integration risk and breaks Phase 1 PoC's job of proving the full stack works.

2. **Phase 1 is always the PoC and must prove the full stack end-to-end.** Backend-only Phase 1 hides cross-layer issues until Phase 2+, when they're more expensive to surface.

Behavioral directives D1-D3 apply — see `using-qrspi/SKILL.md` → "BEHAVIORAL-DIRECTIVES".
