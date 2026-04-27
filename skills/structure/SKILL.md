---
name: structure
description: Use when design.md is approved and the QRSPI pipeline needs file/component mapping — maps vertical slices to specific files, interfaces, and component boundaries
---

# Structure (QRSPI Step 5)

**PRECONDITION:** Invoke `qrspi:using-qrspi` skill to ensure global pipeline rules are in context. (Idempotent on session re-entry. Subagents are exempt — SUBAGENT-STOP in using-qrspi handles that.)

**Announce at start:** "I'm using the QRSPI Structure skill to map the design to files and interfaces."

## Overview

Map the design's vertical slices to specific files, components, and interfaces. Define what gets created vs modified, show how slices map to the stack, and produce a detailed architectural diagram. This is the bridge between abstract design and concrete implementation.

## Artifact Gating

**Required inputs:**
- `goals.md` with `status: approved`
- `research/summary.md` with `status: approved`
- `design.md` with `status: approved`

If any artifact is missing or not approved, refuse to run and tell the user which artifact is needed.

Read `config.md` from the artifact directory to determine whether Codex reviews are enabled. If `config.md` doesn't exist, default to `codex_reviews: false`.

<HARD-GATE>
Do NOT produce structure.md without approved goals.md, research/summary.md, AND design.md.
Do NOT proceed to Plan without user approval of the structure.
</HARD-GATE>

## Execution Model

**Subagent per round** (iterative with human feedback). Each round is a fresh subagent with declared inputs + any feedback from prior rounds.

## Phase-Scoped Content Rules

structure.md contains ONLY current-phase file maps and interfaces. Entries must be tagged with goal IDs. File maps for goals not in the current phase (per roadmap.md) must not appear. When the Structure skill generates structure.md, it must verify every goal ID in the file map exists in goals.md.

## Process

### Structure Subagent

**Inputs:**
- `goals.md`
- `research/summary.md`
- `design.md`
- Any prior feedback files

**Task:** Map the design to concrete files and interfaces.

1. Map each vertical slice from `design.md` to specific files and components
2. For each slice, show which layers of the stack it touches and what files are involved
3. Define interfaces between components (function/class signatures, not implementations)
4. Identify create vs modify for each file
5. Detailed Mermaid architectural diagram: file/module layout, API endpoints, data flow, interface boundaries
6. If CI setup noted in Design, define pipeline structure (workflow file, test commands, lint config) and project convention files (CLAUDE.md, linting config, etc.) for greenfield projects

**Output format for `structure.md`:**

````markdown
---
status: draft
---

# Structure: {Project/Feature Name}

## File Map

### Slice 1: {name}
| File | Action | Responsibility |
|------|--------|---------------|
| `path/to/file.ts` | Create | {what it does} |
| `path/to/existing.ts` | Modify | {what changes} |

### Slice 2: {name}
...

## Interfaces

### {Component A} → {Component B}
```typescript
// path/to/interface.ts
interface FooService {
  bar(input: BarInput): Promise<BarOutput>;
}
```

## Architectural Diagram
{Detailed Mermaid diagram}

## CI Pipeline (if needed)
{Workflow file structure, test commands, lint config}
````

### Review Round

Apply the **Standard Review Loop** from `using-qrspi/SKILL.md`. Structure-specific reviewer instructions:

- **Claude review subagent** — inputs: `structure.md`, `goals.md`, `research/summary.md`, `design.md`. Checks: structure matches the design; each vertical slice maps cleanly to files/components; no missing or unnecessary components (YAGNI); interfaces well-defined; modifications don't conflict with existing codebase patterns. Findings written to `reviews/structure-review.md`.
- **Codex review** (if `codex_reviews: true`) — `codex:rescue` with `structure.md` + `goals.md` + `research/summary.md` + `design.md`, same criteria. Findings appended.

### Human Gate

Present `structure.md` to the user — "hammer on it" review point alongside Design. **Always state the review status** when presenting: either "Reviews passed clean in round N" or "Reviews found issues in round N which were fixed but not re-verified."

When presenting Mermaid diagrams (dependency graphs, architectural diagrams, parallelization plans), write the diagram to the artifact file (e.g., `structure.md` for architecture diagrams, `parallelization.md` for dependency graphs) and direct the user to open the file. Do not paste raw Mermaid syntax into terminal output — it renders as unreadable text in the terminal. Tell the user: "The architecture diagram is in `structure.md` — open it to view the rendered diagram."

On approval, if reviews have not passed clean, note this and ask if they'd like a review loop before finalizing. Then write `status: approved` in frontmatter.

On rejection, write the user's feedback and the rejected artifact snapshot to `feedback/structure-round-{NN}.md` (using the standard feedback file format from `using-qrspi`), then launch a new subagent with original inputs + **all** prior feedback files (not just the latest round). After re-generation, the review cycle restarts.

### Artifact

`structure.md` — file-level and function-level breakdown organized by vertical slice, with interface definitions, Mermaid architectural diagram, CI pipeline structure if needed

### Terminal State

If the artifact directory is inside a git repository, commit the approved `structure.md` and `reviews/structure-review.md` (see `using-qrspi` → "Commit after approval (when applicable)").

Recommend compaction: "Structure approved. This is a good point to compact context before the next step (`/compact`)."

**REQUIRED:** Invoke the next skill in the `config.md` route after `structure`.

## Red Flags — STOP

- A file mentioned in the design has no entry in the file map
- An interface definition doesn't match between caller and callee
- A file is marked "Modify" but doesn't exist in the codebase
- A file is marked "Create" but already exists in the codebase
- Slices in the file map don't match slices in the design
- Missing Mermaid architectural diagram
- CI pipeline structure is needed (greenfield or no existing CI) but not defined
- Interfaces use placeholder types ("any", "object", "TBD")
- Pasting Mermaid diagram syntax directly into terminal output (user cannot read it)

## Common Rationalizations — STOP

| Rationalization | Reality |
|----------------|---------|
| "The interfaces are obvious from the file names" | Write them explicitly. The Plan skill uses interfaces to define task boundaries. |
| "I'll figure out the exact files during implementation" | Structure IS the file decision. Deferring to implementation means the plan will be wrong. |
| "This file is too small to list" | If it's in the design, it's in the structure. Every file needs an entry. |
| "The existing codebase doesn't have clear interfaces" | Then define them. Structure is the opportunity to introduce clarity. |
| "CI can be set up later" | CI is Task 1 of Phase 1 (per Design). It blocks everything else. |

## Worked Example

**Good file map entry:**

> ### Slice 1: Client rate check
> | File | Action | Responsibility |
> |------|--------|---------------|
> | `src/middleware/rate-limiter.ts` | Create | Express middleware that checks Redis for client rate, returns 429 if exceeded |
> | `src/services/redis-client.ts` | Modify | Add rate limit increment/check methods to existing Redis wrapper |
> | `src/types/rate-limit.ts` | Create | RateLimitConfig, RateLimitResult interfaces |
> | `tests/middleware/rate-limiter.test.ts` | Create | Unit tests for rate limiting middleware |

**Bad file map entry (vague):**

> ### Rate Limiting
> | File | Action | Responsibility |
> |------|--------|---------------|
> | `src/middleware/` | Create | Rate limiting stuff |
> | Various | Modify | Update as needed |

The bad example uses directory paths instead of files, and "various" is not an action plan.

## Iron Laws — Final Reminder

The two override-critical rules for Structure, restated at end:

1. **Every file in the design has an entry; every entry has a real path.** No directory placeholders, no "various", no "TBD". Structure IS the file decision — Plan reads from it directly to write task specs.

2. **Interfaces are explicit, with concrete types.** No `any`, no `object`, no placeholder types. Plan uses interface signatures to define task boundaries; vague interfaces produce vague tasks.

Behavioral directives D1-D3 apply — see `using-qrspi/SKILL.md` → "BEHAVIORAL-DIRECTIVES".
