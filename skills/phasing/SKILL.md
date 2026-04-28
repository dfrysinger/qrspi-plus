---
name: phasing
description: Use when design.md is approved and the QRSPI pipeline needs vertical slice authoring, phase boundary decisions, roadmap.md authoring, current-phase pruning, and goal-ID consistency validation — sits between Design and Structure
---

# Phasing (QRSPI Step 5)

**Announce at start:** "I'm using the QRSPI Phasing skill to author vertical slices, phase boundaries, and the roadmap."

## Overview

Translate the approved architecture into delivery units. Phasing is a dedicated step between Design and Structure that owns vertical-slice authoring (Iron Law 1), phase boundary decisions (Iron Law 2), roadmap.md authoring, current-phase pruning of the four synthesizing artifacts (goals.md, questions.md, research/summary.md, design.md), future-* artifact maintenance, and goal-ID consistency validation across the nine target artifact files. The discussion happens conversationally; a subagent synthesizes the artifact set per round.

Pipeline position: Goals → Questions → Research → Design → **Phasing** → Structure → Plan → Parallelize → Implement → Integrate → Test → Replan. Quick-fix routes skip Phasing entirely.

## Artifact Gating

**Required inputs:**
- `goals.md` with `status: approved`
- `questions.md` with `status: approved`
- `research/summary.md` with `status: approved`
- `design.md` with `status: approved`
- `config.md` (read to determine whether Codex reviews are enabled; default `codex_reviews: false` if absent)

If any required artifact is missing or not approved, refuse to run and tell the user which artifact is needed.

<HARD-GATE>
Do NOT synthesize phasing.md, roadmap.md, or any future-* artifact without all five required inputs approved.
Do NOT prune goals.md, questions.md, research/summary.md, or design.md until phasing.md is reviewed and approved by the user.
Do NOT proceed to Structure without user approval of the Phasing artifact set.
</HARD-GATE>

## Execution Model

**Interactive in main conversation** (Goals/Design-style). The user and Claude discuss slice decomposition, phase boundaries, and the Phase 1 PoC scope. A subagent synthesizes `phasing.md`, `roadmap.md`, and the four pruned + four future-* artifacts per round. Each rejection round launches a new subagent with original inputs + all prior feedback files.

## Phasing OWNS / Phasing DEFERS

### OWNS

- **Vertical-slice authoring** — enumerate end-to-end demonstrable delivery units in `phasing.md` `## Slices`. **Iron Law 1 applies** (see below).
- **Phase boundaries** — group slices into phases with explicit replan-gate criteria per phase, captured in `phasing.md` `## Phases`. **Iron Law 2 applies** (see below).
- **roadmap.md authoring** — canonical phase → slice → goal-ID mapping table. Roadmap is the source of truth for which goals belong to which phase via which slice; downstream skills (Structure, Plan, Replan) read from it.
- **Current-phase pruning of four synthesizing artifacts** — split `goals.md`, `questions.md`, `research/summary.md`, and `design.md` into current-phase content (kept in place) and deferred content (moved to `future-goals.md`, `future-questions.md`, `future-research-summary.md`, `future-design.md`). Individual `research/q*.md` files are NOT split — they remain as full-corpus reference so the summary's Q-attribution links continue to resolve.
- **Future-* artifact maintenance** — `future-goals.md`, `future-questions.md`, `future-research-summary.md`, `future-design.md` are created and updated each Phasing run; consumed by Replan during between-phase transitions.
- **Goal-ID consistency validation** — every goal ID appearing in any of the nine target files (goals.md, questions.md, research/summary.md, design.md, future-goals.md, future-questions.md, future-research-summary.md, future-design.md, roadmap.md) must trace to the canonical roadmap.md set. Orphan IDs flagged for user review.

### DEFERS

- **Architecture, key decisions, system diagram, test strategy** → owned by Design. Phasing consumes design.md; it does NOT re-litigate architectural choices.
- **File paths, module boundaries, interface contracts, file maps** → owned by Structure. Phasing names slices and phases; it does NOT enumerate files or function signatures.
- **Task specs, LOC estimates, ordered task lists, per-task test expectations** → owned by Plan. Phasing produces the input Plan reads from (slice list + phase grouping); it does NOT write task specs.
- **Dependency graph, parallel-group decisions, branch maps** → owned by Parallelize.
- **Implementation prose, code, hook syntax, subagent dispatch verbs** → owned by Implement and downstream skills. Skill-implementation jargon is a U14 boundary-drift signal in phasing.md.

## Iron Law 1 — Vertical slices, not horizontal layers

Every slice in `phasing.md` `## Slices` must be **end-to-end demonstrable on its own** (DB + service + API + frontend together, where applicable). Horizontal decomposition ("DB layer first, API layer second, frontend third") defers integration risk and breaks Phase 1 PoC's job of proving the full stack works. If a slice cannot be demonstrated independently, it is not a slice — re-decompose.

- BAD: "DB layer, then API layer, then service layer, then frontend"
- GOOD: "User registration (DB + API + service + frontend), then user profile (DB + API + service + frontend)"

## Iron Law 2 — Phase 1 PoC must prove the full stack end-to-end

**Phase 1 is always the PoC** and it must prove the full stack works end-to-end across every layer the project touches. A backend-only Phase 1 hides cross-layer issues until Phase 2+, when they are more expensive to surface. If a proposed Phase 1 does not exercise every layer named in design.md, it is not a valid PoC — pull at least one full-stack slice forward into Phase 1.

## Process

### Interactive Phasing Discussion

1. Read `goals.md`, `questions.md`, `research/summary.md`, `design.md` and present a proposed slice decomposition derived from the Design's vertical slices (if any) plus a proposed Phase 1 PoC scope.
2. Discuss with the user: which slices belong in Phase 1 (must satisfy Iron Law 2), where the replan checkpoints belong, and what gate criteria each phase carries.
3. Collect amendment items from the user: any new slices introduced here must receive their own goal IDs in roadmap.md (do not bare-number-compress amendment items into existing goals when the goal text doesn't cover them — see Goals "Amendment handling").
4. Once the slice set and phase grouping settle, hand off to the synthesis subagent.

> **IMPORTANT — Compaction recommended.** The synthesis subagent below is dispatched after the discussion settles and before the review loop runs. If context utilization may exceed ~50% at this point, run `/compact` before dispatching the subagent. Subagents inherit context from the main conversation and a bloated context degrades synthesis quality.

### Phasing Synthesis Subagent

Once the discussion settles, launch a **subagent** to synthesize the artifact set.

**Subagent inputs:**
- `goals.md`
- `questions.md`
- `research/summary.md`
- `design.md`
- A summary of the phasing discussion (proposed slices, phase grouping, Phase 1 PoC justification, replan gates, amendment items)
- Any prior feedback files

**Subagent outputs (single round, all artifacts together):**
- `phasing.md` (draft) — see Output Template below
- `roadmap.md` — canonical phase → slice → goal-ID mapping table
- Pruned `goals.md` — current-phase entries only
- `future-goals.md` — deferred entries
- Pruned `questions.md` — current-phase entries only
- `future-questions.md` — deferred entries
- Pruned `research/summary.md` — current-phase entries only
- `future-research-summary.md` — deferred entries
- Pruned `design.md` — current-phase entries only
- `future-design.md` — deferred entries

> **IMPORTANT — Compaction recommended.** Synthesis output spans ten files and may be large. After the subagent returns, before the review loop dispatches, run `/compact` if context utilization may exceed ~50%. Reviewer subagents launched below also inherit context.

### `phasing.md` Output Template

The synthesis subagent writes `phasing.md` in the following shape. **Each section's first sentence is the load-bearing claim** (claim-before-evidence; Nielsen inverted pyramid). Paragraphs stay ≤150 words; sections >300 words use bullets or numbered lists. No "be concise"-style instructions appear in the output.

```markdown
---
status: draft
---

# Phasing: {Project/Feature Name}

## Slices

Vertical, end-to-end demonstrable delivery units. Iron Law 1 applies: each slice must be demonstrable on its own across every layer it touches.

### Slice 1: {name} (goal IDs: {G1, G2, ...})
{One-paragraph claim-before-evidence description: what this slice proves end-to-end, which layers it touches, why it is a vertical slice and not a horizontal layer.}

### Slice 2: {name} (goal IDs: {...})
{...}

## Phases

Phase grouping with replan-gate criteria. Iron Law 2 applies: Phase 1 must prove the full stack end-to-end.

### Phase 1: PoC — {name} (slices: {Slice 1, Slice N})
**Phase 1 PoC justification.** {Claim-before-evidence: which layers are exercised, why this proves the full stack, what cross-layer risk is surfaced.}
**Replan gate criteria.** {Bulleted list of conditions that must be true at end of Phase 1 to enter Phase 2.}

### Phase 2: {name} (slices: {Slice X, Slice Y})
{...}
**Replan gate criteria.** {...}

## Goal-ID Consistency

Every goal ID listed in `roadmap.md` is accounted for above. Orphan IDs (if any) are surfaced in `## Orphan IDs` for user resolution; otherwise the section reads "No orphan IDs."

## Orphan IDs

{Either "No orphan IDs." or a bulleted list per the Goal-ID Consistency Validation procedure below.}
```

### `roadmap.md` Output Template

The roadmap is mechanical: goal ID, phase, slice. No notes, no design content, no prose — Replan reads it programmatically during between-phase transitions.

```markdown
---
status: draft
---

# Roadmap

| Goal ID | Phase | Slice |
|---------|-------|-------|
| G1      | 1     | Slice 1 |
| G2      | 1     | Slice 1 |
| G3      | 2     | Slice 3 |
| ...     | ...   | ...     |
```

### Goal-ID Consistency Validation

Run this procedure during synthesis and again during the review round. The canonical set is `roadmap.md` once it exists; until then, fall back to `goals.md` + `future-goals.md` union.

1. Collect goal IDs from each of the nine target files: `goals.md`, `questions.md`, `research/summary.md`, `design.md`, `future-goals.md`, `future-questions.md`, `future-research-summary.md`, `future-design.md`, `roadmap.md`. (`phasing.md` is also scanned as a sanity check; it should not introduce IDs absent from `roadmap.md`.)
2. **Orphan-ID flag — direction A.** An orphan in direction A is any goal ID that appears in one of the nine files yet is missing from the canonical roadmap set; surface every such orphan under `phasing.md` `## Orphan IDs` for user review.
3. **Orphan-ID flag — direction B.** An orphan in direction B is any goal ID that appears in the canonical roadmap set yet is missing from the file expected to contain it under current-phase scope: a current-phase ID must appear in the current-phase artifacts (goals, questions, research summary, design) and a deferred ID must appear in the corresponding future-* artifact.
4. The orphan list is presented to the user; resolution is a user decision (rename ID, move entry, or accept as orphan with justification).

### Four-Artifact Pruning Procedure

For each of `goals.md`, `questions.md`, `research/summary.md`, `design.md`:

1. Identify entries by goal ID. Entries whose goal ID maps (per `roadmap.md`) to the **current phase** stay in the artifact in place.
2. Entries whose goal ID maps to a **future phase** are moved to the corresponding `future-*.md` (`future-goals.md`, `future-questions.md`, `future-research-summary.md`, `future-design.md`).
3. Existing entries already in the `future-*.md` for goal IDs that have moved into the current phase are pulled forward into the current artifact.
4. **Individual research/q numbered files do NOT split** — each research/q file is kept intact as full-corpus reference and remains in the research directory (the file pattern is research/q*.md), so the summary's Q-attribution links continue to resolve.

### Review Round

Apply the **Standard Review Loop** from `using-qrspi/SKILL.md`. Phasing-specific reviewer instructions:

> **IMPORTANT — Compaction recommended.** Reviewers run in parallel and emit findings against the full ten-artifact set. If context utilization may exceed ~50% before this dispatch, run `/compact` first.

- **Claude review subagent** — inputs: `phasing.md`, `roadmap.md`, both pruned + future-* sets for all four artifacts, `goals.md` (pre-prune snapshot if available), `design.md` (pre-prune snapshot if available). Checks: every goal in scope has at least one slice; every slice has at least one phase; **Iron Law 1** holds for every slice (vertical, not horizontal); **Iron Law 2** holds for Phase 1 (full-stack end-to-end); replan-gate criteria are concrete and checkable; the four-artifact pruning procedure was applied (no current-phase content in `future-*.md`, no future content in current artifacts); goal-ID consistency holds across all nine files (no orphans, or orphans surfaced for user resolution); `## Phasing OWNS / Phasing DEFERS` boundary respected (no architecture re-litigation, no file paths, no task specs). Findings written to `reviews/phasing-review.md`.

- **scope-reviewer subagent dispatch** — invoke `skills/_shared/templates/scope-reviewer.md` with `{ARTIFACT_TYPE}=phasing`. The dispatched reviewer loads `skills/phasing/SKILL.md` `## Phasing OWNS / Phasing DEFERS` as the locked rule set, runs boundary-drift detection (content matching a DEFERS entry → finding), scope-compliance per OWNS, and the U14 boundary-drift signal (skill-implementation jargon, file-path leakage, task-spec leakage). Findings emitted per the M48 5-field schema in `skills/_shared/reviewer-boilerplate.md` `## Finding Schema`. Append to `reviews/phasing-review.md`.

- **Reviewer prompt block — embedded boilerplate.** The Claude reviewer prompt and the scope-reviewer dispatch BOTH embed `skills/_shared/reviewer-boilerplate.md` verbatim at dispatch time so the reviewer sees the finding schema, change-type classifier, and disagreement-valid framing inline. (Embed by reference: the file path is stable across edits; the dispatch concatenates the file's contents into the rendered prompt.)

- **Codex review** (if `codex_reviews: true`) — dispatch a non-blocking Codex review via the wrapper:
  1. Write the review prompt (`phasing.md` + `roadmap.md` + the four pruned + four future-* artifacts + the same Phasing-specific criteria + the embedded `skills/_shared/reviewer-boilerplate.md` content) to a temporary file (e.g., `/tmp/codex-prompt-phasing.md`).
  2. Launch the job early (in parallel with the Claude reviewers above) by running `scripts/codex-companion-bg.sh launch --prompt-file /tmp/codex-prompt-phasing.md` as a foreground Bash-tool call. The wrapper prints the jobId to stdout as a single line and exits 0 within ~5 seconds. The orchestrator (this skill's caller — the Claude Code agent driving the Bash tool) records that printed jobId text from the Bash tool's stdout output and pastes it as the literal `<jobId>` argument in the matching await Bash call below; there is no shell variable assignment in this flow, and shell command substitution (`$()` / backticks) is forbidden per Daniel's CLAUDE.md. If launch exits non-zero, abort this Codex review and append a launch-failure note to `reviews/phasing-review.md`.
  3. After the Claude reviewers return, await the result: `scripts/codex-companion-bg.sh await <jobId>`. Exit codes: **0** = success, append the markdown stdout to `reviews/phasing-review.md` under `#### Codex`; **10** = 20-min ceiling hit (no stdout produced) — append an explicit ceiling note (e.g., `Codex review: 20-min ceiling hit, no findings produced`), do NOT append empty stdout, do NOT silently retry; **11** = companion crash mid-job (job-not-found) — append a crash note and surface to the user before proceeding; **12** = audit-write fail (e.g., row > 4096 bytes) — append an infrastructure-failure note and surface to the user, do NOT retry blindly. **Only append stdout to the review log on exit 0.**

### Human Gate

Present `phasing.md` and `roadmap.md` to the user — "hammer on it" review point. **Always state the review status** when presenting: either "Reviews passed clean in round N" or "Reviews found issues in round N which were fixed but not re-verified."

When presenting any Mermaid diagram (slice/phase visualization, if generated), write it to the artifact file and direct the user to open the file. Do not paste raw Mermaid syntax into terminal output.

On approval, if reviews have not passed clean, note this and ask if they'd like a review loop before finalizing. Then write `status: approved` in the frontmatter of `phasing.md`, `roadmap.md`, the four pruned artifacts, and the four `future-*.md` artifacts.

On rejection, write the user's feedback to `feedback/phasing-round-{NN}.md` (using the standard feedback file format from `using-qrspi`), then continue the conversation and re-synthesize with a new subagent that receives: `goals.md`, `questions.md`, `research/summary.md`, `design.md`, the latest phasing-discussion summary, and **all** prior feedback files (not just the latest round). After re-generation, the review cycle restarts.

### Outputs

The Phasing skill emits the following artifacts on a successful run:

- `phasing.md` — vertical slice enumeration (with Iron Law 1) and phasing decisions (with Iron Law 2 Phase 1 PoC justification + replan-gate criteria per phase).
- `roadmap.md` — canonical phase → slice → goal-ID mapping table.
- Pruned `goals.md` + new/updated `future-goals.md`.
- Pruned `questions.md` + new/updated `future-questions.md`.
- Pruned `research/summary.md` + new/updated `future-research-summary.md`.
- Pruned `design.md` + new/updated `future-design.md`.
- Individual `research/q*.md` files are NOT pruned and remain as full-corpus reference.

### Terminal State

> **IMPORTANT — Compaction recommended.** Phasing approval is a high-water mark for context size: the conversation has carried Goals + Questions + Research + Design + Phasing artifacts. Run `/compact` before invoking Structure if context utilization may exceed ~50%. Cross-skill transitions are a known compaction pressure moment.

Commit the approved `phasing.md`, `roadmap.md`, the four pruned artifacts, the four `future-*.md` artifacts, and `reviews/phasing-review.md` to git.

Recommend compaction: "Phasing approved. This is a good point to compact context before the next step (`/compact`)."

> **IMPORTANT — Cross-skill transition.** The next step (Structure) consumes `phasing.md` + `roadmap.md` for phase scoping and the pruned `design.md` for architecture. Confirm both artifacts are approved and committed before invoking Structure. Compaction at this transition is strongly recommended.

**REQUIRED:** Invoke the next skill in the `config.md` route after `phasing` (typically `structure`).

## Phase-2+ Behavior

When `roadmap.md` already exists at Phasing entry — i.e., this is not the first Phasing run — Phasing acts as a **light validation/refinement step** rather than re-authoring the roadmap from scratch.

1. Read existing `roadmap.md`. Confirm with the user whether the slice set and phase boundaries still hold given any new amendments accumulated since the previous Phasing run.
2. If the user opts to update the roadmap (new slice, re-grouped phase, deferred goal pulled forward, etc.), run a normal synthesis round on the updated subset; otherwise re-run only the goal-ID consistency validation and the four-artifact pruning procedure against the existing roadmap.
3. Re-run the goal-ID consistency validation across the nine files; surface any new orphans for user resolution.
4. Re-run the four-artifact pruning procedure to reflect any goals that have moved between current and future scope.
5. Replan, not Phasing, owns the recurring between-phase transition (archive completed phase, populate next-phase drafts from `future-*.md`). Phasing does NOT execute transitions.

## Red Flags — STOP

- A "slice" is actually a horizontal layer ("database setup", "API scaffolding", "frontend shell") — Iron Law 1 violated.
- Phase 1 does not exercise every layer named in design.md — Iron Law 2 violated.
- A goal ID appears in `goals.md` but not in `roadmap.md` (or vice versa) and is not surfaced under `## Orphan IDs`.
- `future-*.md` contains entries for current-phase goal IDs (pruning procedure not applied).
- Current-phase artifact (`goals.md`, `questions.md`, `research/summary.md`, `design.md`) contains entries for deferred goal IDs (pruning procedure not applied).
- Individual `research/q*.md` files have been split or moved (they must remain in `research/` as full-corpus reference).
- `phasing.md` re-litigates architecture, names files, or writes task specs — boundary drift into Design / Structure / Plan ownership.
- Replan-gate criteria are vague ("everything works") instead of concrete and checkable.
- `roadmap.md` carries notes, design content, or any column beyond goal ID + phase + slice.
- Pasting Mermaid diagram syntax directly into terminal output (user cannot read it).

## Common Rationalizations — STOP

| Rationalization | Reality |
|----------------|---------|
| "We'll figure out vertical slicing later in Structure" | Phasing IS the slicing decision. Structure reads from `phasing.md`. |
| "Phase 1 can just be the backend so we can move fast" | Phase 1 must prove the full stack. Backend-only PoC defers integration risk to a more expensive phase. |
| "The roadmap can include design notes for context" | No. roadmap.md is mechanical: goal ID, phase, slice. Notes belong in `phasing.md`. |
| "We can skip pruning — the artifacts are short enough" | Pruning is the contract Replan reads from during transitions. Skipping it breaks Phase 2+ flow. |
| "An orphan ID is fine, the user will notice" | Surface orphans explicitly. Silent orphans propagate into Structure/Plan and break goal traceability. |

## Iron Laws — Final Reminder

The two override-critical rules for Phasing, restated at end:

1. **Vertical slices, not horizontal layers.** Each slice must be end-to-end demonstrable on its own. "DB layer first, API layer second" defers integration risk and breaks Phase 1 PoC's job of proving the full stack works. Iron Law 1 was previously stated in Design; under M54 it moves to Phasing as the natural home of slice authoring.

2. **Phase 1 is always the PoC and must prove the full stack end-to-end.** Backend-only Phase 1 hides cross-layer issues until Phase 2+, when they're more expensive to surface. Iron Law 2 was previously stated in Design; under M54 it moves to Phasing alongside phase boundary ownership.

Behavioral directives D1-D3 apply — see `using-qrspi/SKILL.md` → "BEHAVIORAL-DIRECTIVES".
