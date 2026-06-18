---
name: phasing
description: Use when design.md is approved and the QRSPI pipeline needs vertical slice authoring, phase boundary decisions, roadmap.md authoring, current-phase pruning, and goal-ID consistency validation — sits between Design and Structure
---

# Phasing (QRSPI Step 5)

**PRECONDITION:** Invoke `qrspi:using-qrspi` skill to ensure global pipeline rules are in context. (Idempotent on session re-entry. Subagents are exempt — SUBAGENT-STOP in using-qrspi handles that.)

**Announce at start:** "I'm using the QRSPI Phasing skill to author vertical slices, phase boundaries, and the roadmap."

## Overview

Translate the approved architecture into delivery units. Phasing owns vertical-slice authoring (Iron Law 1), phase boundary decisions (Phase 1 PoC guideline), `roadmap.md` authoring, current-phase pruning of the four synthesizing artifacts (goals.md, questions.md, research/summary.md, design.md), future-* artifact maintenance, and goal-ID consistency validation across nine target files. Discussion is conversational; a subagent synthesizes the artifact set per round.

Pipeline position: Goals → Questions → Research → Design → **Phasing** → Structure → Plan → Parallelize → Implement → Integrate → Test → Replan. Quick-fix routes skip Phasing entirely.

## Artifact Gating

**Required inputs:**
- `goals.md` with `status: approved`
- `questions.md` with `status: approved`
- `research/summary.md` with `status: approved`
- `design.md` with `status: approved`
- `config.md` (read to determine whether Codex reviews are enabled — see `### Config Validation` below)

If any required artifact is missing or not approved, refuse to run and tell the user which artifact is needed.

### Config Validation

Apply the **Config Validation Procedure** in `using-qrspi/SKILL.md`. Phasing validates `second_reviewer` (expected `true` or `false`). If `config.md` is missing or `second_reviewer` is missing/invalid, halt and present the field-specific menu from the Procedure — do NOT silently default `second_reviewer` to false.

<HARD-GATE>
Do NOT synthesize phasing.md, roadmap.md, or any future-* artifact without all five required inputs approved.
Do NOT prune goals.md, questions.md, research/summary.md, or design.md until phasing.md is reviewed and approved by the user.
Do NOT proceed to Structure without user approval of the Phasing artifact set.
</HARD-GATE>

## Phasing OWNS / Phasing DEFERS

!cat skills/phasing/owns-defers.md

## Iron Law 1 — Vertical slices, not horizontal layers

Every slice in `phasing.md` `## Slices` must be **end-to-end demonstrable on its own** (DB + service + API + frontend together, where applicable). Horizontal decomposition ("DB layer first, API layer second, frontend third") defers integration risk and breaks Phase 1 PoC's job of proving the full stack works. If a slice cannot be demonstrated independently, it is not a slice — re-decompose.

- BAD: "DB layer, then API layer, then service layer, then frontend"
- GOOD: "User registration (DB + API + service + frontend), then user profile (DB + API + service + frontend)"

## Phase 1 PoC Guideline — prove the full stack end-to-end when possible

**Phase 1 is the PoC**, and it should prove the full stack works end-to-end across every layer the project touches whenever possible. A backend-only Phase 1 tends to hide cross-layer issues until Phase 2+, where they are more expensive to surface — so the default is to pull at least one full-stack slice forward into Phase 1. Departures are fine when there's a real reason (e.g., the frontend depends on a backend contract that genuinely cannot be stubbed for Phase 1, or the project is single-layer by nature). When Phase 1 does not exercise every layer named in design.md, the discussion should name the reason explicitly so reviewers can confirm it's a deliberate choice rather than horizontal layering by accident.

## Process

**Interactive in main conversation** (Goals/Design-style). The user and Claude discuss slice decomposition, phase boundaries, and the Phase 1 PoC scope. A subagent synthesizes `phasing.md`, `roadmap.md`, and the four pruned + four future-* artifacts per round. Each rejection round launches a new subagent with original inputs + all prior feedback files.

### Interactive Phasing Discussion

1. Read `goals.md`, `questions.md`, `research/summary.md`, `design.md` and present a proposed slice decomposition derived from the Design's vertical slices (if any) plus a proposed Phase 1 PoC scope.
2. Discuss with the user: which slices belong in Phase 1 (should satisfy the Phase 1 PoC guideline when possible; departures need an explicit reason), where the replan checkpoints belong, and what gate criteria each phase carries.
3. Collect amendment items from the user: any new slices introduced here must receive their own goal IDs in roadmap.md (do not bare-number-compress amendment items into existing goals when the goal text doesn't cover them — see Goals "Amendment handling").
4. Once the slice set and phase grouping settle, hand off to the synthesis subagent.

### Phasing Synthesis Subagent

Once the discussion settles, launch a **subagent** to synthesize the artifact set.

**Subagent inputs:**
- `goals.md`
- `questions.md`
- `research/summary.md`
- `design.md`
- A summary of the phasing discussion (proposed slices, phase grouping, Phase 1 PoC justification, replan gates, amendment items)
- Any prior feedback files

**Subagent outputs (single round, all artifacts together — atomic emission):**
- `phasing.md` (draft) — see Outputs section below
- `roadmap.md` — canonical phase → slice → goal-ID mapping table
- Pruned `goals.md` — current-phase entries only
- `future-goals.md` — deferred entries
- Pruned `questions.md` — current-phase entries only
- `future-questions.md` — deferred entries
- Pruned `research/summary.md` — current-phase entries only
- `future-research-summary.md` — deferred entries
- Pruned `design.md` — current-phase entries only
- `future-design.md` — deferred entries

**Atomicity (fail-closed).** The synthesis subagent MUST emit all 10 artifacts (phasing.md + roadmap.md + 4 pruned + 4 future-*) in a single return. Partial returns — any missing file, or any pruned/future-* pair imbalanced — invalidate the round. Reviewers MUST reject any synthesis output that omits any of the ten artifacts.

### Four-Artifact Pruning Procedure

For each of `goals.md`, `questions.md`, `research/summary.md`, `design.md`:

1. Identify entries by goal ID. Entries whose goal ID maps (per `roadmap.md`) to the **current phase** stay in the artifact in place.
2. Entries whose goal ID maps to a **future phase** are moved to the corresponding `future-*.md` (`future-goals.md`, `future-questions.md`, `future-research-summary.md`, `future-design.md`).
3. Existing entries already in the `future-*.md` for goal IDs that have moved into the current phase are pulled forward into the current artifact.
4. **Individual research/q numbered files do NOT split** — each research/q file is kept intact as full-corpus reference and remains in the research directory (the file pattern is research/q*.md), so the summary's Q-attribution links continue to resolve.

**Atomicity (fail-closed).** Pruning produces 8 files (4 pruned + 4 future-*). Any missing file or imbalanced pruned/future-* pair invalidates the round; the synthesis subagent MUST emit all 8 in a single return. Reviewers MUST reject any phasing.md emission not accompanied by the complete 8-file pruning set.

### Review Round

Apply the **Standard Review Loop** from `using-qrspi/SKILL.md`. Two parallel reviewer dispatches per artifact per round (quality + scope). Phasing-specific reviewer instructions:

**Dispatch the round through dispatch-agent's high-level entry.** Run `scripts/dispatch-agent.sh --step phasing --round ${ROUND} --artifact-dir <ABS_ARTIFACT_DIR>` (plus the per-skill `--output-dir`/`--artifact`/`--agents` flags below). High-level mode invokes `scripts/review-prep.sh` to emit `<ABS_ARTIFACT_DIR>/reviews/phasing/round-${ROUND}.diff` and threads `diff_file_path:` into each reviewer prompt; the orchestrator runs no `git diff` Bash redirect of its own. When the artifact directory is not inside a git repository, review-prep skips diff emission and `diff_file_path:` is omitted. For round 01 pass `--base-ref <base-branch>`; on round >= 2 review-prep auto-narrows by reading `reviews/phasing/round-$((ROUND-1))-commit.txt` (named diagnostics `anchor-file-missing:` / `sha-format-invalid:` halt before the SHA reaches `git diff`). Scope-tag narrowing (when active) reaches reviewers as `scope_hint:` wrapped between `<<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>` / `<<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>` markers per the reviewer-protocol Reviewer Dispatch Contract.

**Compaction checkpoint: pre-fanout.** Parallel reviewer dispatch reads the full ten-artifact set (phasing.md + roadmap + 4 pruned + 4 future-* + snapshots); saturated context produces shallow findings on this large input set. See using-qrspi `## Compaction Checkpoints` for the iron-rule contract.

Surface a todo: title `Recommend /compact (pre-fanout) — phasing`, description `pre-fanout: parallel reviewer dispatch reads ten-artifact set. User decides whether to /compact.`.

The round's reviewers dispatch through the universal dispatch chain (`scripts/dispatch-agent.sh` → subagent fan-out → `scripts/await-round.sh`). Set the per-skill dispatch parameters below, then include the shared reviewer-dispatch prose. Include the `*-codex` peer tags in `REVIEW_AGENTS` only when `second_reviewer: true`; otherwise list only the `*-claude` tags.

```sh
REVIEW_STEP="phasing"
REVIEW_ROUND="${ROUND}"                                  # current review round (NN)
REVIEW_OUTPUT_DIR="<ABS_ARTIFACT_DIR>/reviews/phasing/round-${ROUND}/"
REVIEW_ARTIFACT="phasing.md"
REVIEW_AGENTS="quality-claude=qrspi-phasing-reviewer,scope-claude=qrspi-phasing-scope-reviewer,quality-codex=qrspi-phasing-reviewer,scope-codex=qrspi-phasing-scope-reviewer"
```

!cat skills/_shared/reviewer-dispatch-prose.md

### Human Gate

Present `phasing.md` and `roadmap.md` to the user — "hammer on it" review point. **Always state the review status** when presenting: either "Reviews passed clean in round N" or "Reviews found issues in round N which were fixed but not re-verified."

When presenting any Mermaid diagram (slice/phase visualization, if generated), write it to the artifact file and direct the user to open the file. Do not paste raw Mermaid syntax into terminal output.

On approval, if reviews have not passed clean, note this and ask if they'd like a review loop before finalizing. Once the user has indicated approval, run the **Visual-Fidelity Precondition Assertion** (next subsection) before writing any `status: approved` field. Only after that assertion passes do you write `status: approved` in the frontmatter of `phasing.md`, `roadmap.md`, the four pruned artifacts, and the four `future-*.md` artifacts. If the assertion halts, do NOT write `status: approved` to any artifact — surface the diagnostic to the user and await their action (they will update the offending design or phasing artifacts and re-trigger approval).

On rejection, write the user's feedback to `feedback/phasing-round-{NN}.md` (using the standard feedback file format from `using-qrspi`), then continue the conversation and re-synthesize with a new subagent that receives: `goals.md`, `questions.md`, `research/summary.md`, `design.md`, the latest phasing-discussion summary, and **all** prior feedback files (not just the latest round). After re-generation, the review cycle restarts.

### Visual-Fidelity Precondition Assertion

The visual-fidelity precondition assertion runs **after the user has indicated approval at the Human Gate and immediately before the orchestrator writes `status: approved`** to any phasing artifact. It fires only when `config.md` carries `visual_fidelity_required: true`; otherwise it is inert. Every UI-producing phase must cite at least one wireframe artifact (named in `design.md`'s top-level `## Visual-Fidelity Binding` H2) in its replan gate criteria; halts produce diagnostic-bearing fail-closed approval refusal. This assertion is enforced as part of the orchestrator's approval control flow — it is NOT delegated to a reviewer, downstream skill, or subagent.

**Full procedure, scope rules, UI-classification vocabulary, halt diagnostics, and pass-sentinel contract:** see `skills/phasing/references/visual-fidelity-precondition.md`.

### Terminal State

Commit the approved `phasing.md`, `roadmap.md`, the four pruned artifacts, the four `future-*.md` artifacts, and the `reviews/phasing/` directory (per-round per-reviewer files) to git.

**Compaction checkpoint: pre-handoff.** Phasing approval is a high-water mark for context size — the conversation has carried Goals + Questions + Research + Design + Phasing artifacts; the next skill (typically Structure) reads phasing.md + roadmap.md + pruned design.md on a fresh context. See using-qrspi `## Compaction Checkpoints` for the iron-rule contract.

Surface a todo: title `Recommend /compact (pre-handoff) — phasing`, description `pre-handoff: next skill reads phasing.md + roadmap.md + pruned design.md after a 5-artifact build-up. User decides whether to /compact.`.

**REQUIRED:** Invoke the next skill in the `config.md` route after `phasing` (typically `structure`).

## Outputs

The Phasing skill emits the following artifacts on a successful run:

- `phasing.md` — vertical slice enumeration (with Iron Law 1) and phasing decisions (with Phase 1 PoC justification + replan-gate criteria per phase).
- `roadmap.md` — canonical phase → slice → goal-ID mapping table.
- Pruned `goals.md` + new/updated `future-goals.md`.
- Pruned `questions.md` + new/updated `future-questions.md`.
- Pruned `research/summary.md` + new/updated `future-research-summary.md`.
- Pruned `design.md` + new/updated `future-design.md`.
- Individual `research/q*.md` files are NOT pruned and remain as full-corpus reference.

The synthesis subagent MUST emit all 8 pruning files (4 pruned + 4 future-*) atomically alongside `phasing.md` and `roadmap.md`. Partial emission is fail-closed (see Phasing Synthesis Subagent and Four-Artifact Pruning Procedure).

### `phasing.md` Output Template

The synthesis subagent writes `phasing.md` in the following shape. **Each section's first sentence is the load-bearing claim** (claim-before-evidence; Nielsen inverted pyramid). Paragraphs stay ≤150 words; sections >300 words use bullets or numbered lists. No "be concise"-style instructions appear in the output.

!cat skills/_shared/evergreen-output-rule.md

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

Phase grouping with replan-gate criteria. The Phase 1 PoC guideline applies: Phase 1 should prove the full stack end-to-end whenever possible, with any departure named explicitly.

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

## Goal-ID Consistency Validation

Run this procedure during synthesis and again during the review round. The canonical set is `roadmap.md` once it exists; until then, fall back to `goals.md` + `future-goals.md` union.

1. Collect goal IDs from each of the nine target files: `goals.md`, `questions.md`, `research/summary.md`, `design.md`, `future-goals.md`, `future-questions.md`, `future-research-summary.md`, `future-design.md`, `roadmap.md`. (`phasing.md` is also scanned as a sanity check; it should not introduce IDs absent from `roadmap.md`.)
2. **Orphan-ID flag — direction A.** An orphan in direction A is any goal ID that appears in one of the nine files yet is missing from the canonical roadmap set; surface every such orphan under `phasing.md` `## Orphan IDs` for user review.
3. **Orphan-ID flag — direction B.** An orphan in direction B is any goal ID that appears in the canonical roadmap set yet is missing from the file expected to contain it under current-phase scope: a current-phase ID must appear in the current-phase artifacts (goals, questions, research summary, design) and a deferred ID must appear in the corresponding future-* artifact.
4. The orphan list is presented to the user; resolution is a user decision (rename ID, move entry, or accept as orphan with justification).

**Fail-closed semantics.** If orphan IDs are detected, the synthesis subagent MUST emit them in the `phasing.md` `## Orphan IDs` section AND the round is invalid until the user resolves them. Reviewers MUST reject any phasing.md emission that omits the `## Orphan IDs` section (even when the section content reads "No orphan IDs." — the section header itself is required so reviewers can confirm the validation procedure ran). Silent orphan suppression is a fail-closed condition: any reviewer that detects an orphan ID present in one of the nine files but missing from `## Orphan IDs` MUST emit a finding with `severity: high` and `change_type: correctness` (per the schema in `skills/reviewer-protocol/SKILL.md`, which only permits severity ∈ {low, medium, high}) and the round is invalid.

## Phase-2+ Behavior

When `roadmap.md` already exists at Phasing entry — i.e., this is not the first Phasing run — Phasing acts as a **light validation/refinement step** rather than re-authoring the roadmap from scratch.

1. Read existing `roadmap.md`. Confirm with the user whether the slice set and phase boundaries still hold given any new amendments accumulated since the previous Phasing run.
2. If the user opts to update the roadmap (new slice, re-grouped phase, deferred goal pulled forward, etc.), run a normal synthesis round on the updated subset; otherwise re-run only the goal-ID consistency validation and the four-artifact pruning procedure against the existing roadmap.
3. Re-run the goal-ID consistency validation across the nine files; surface any new orphans for user resolution.
4. Re-run the four-artifact pruning procedure to reflect any goals that have moved between current and future scope.
5. Replan, not Phasing, owns the recurring between-phase transition (archive completed phase, populate next-phase drafts from `future-*.md`). Phasing does NOT execute transitions.

## Red Flags — STOP

- A "slice" is actually a horizontal layer ("database setup", "API scaffolding", "frontend shell") — Iron Law 1 violated.
- Phase 1 does not exercise every layer named in design.md AND the phasing discussion does not name an explicit reason — Phase 1 PoC guideline departure without justification.
- A goal ID appears in `goals.md` but not in `roadmap.md` (or vice versa) and is not surfaced under `## Orphan IDs`.
- `future-*.md` contains entries for current-phase goal IDs (pruning procedure not applied).
- Current-phase artifact (`goals.md`, `questions.md`, `research/summary.md`, `design.md`) contains entries for deferred goal IDs (pruning procedure not applied).
- Synthesis subagent returns partial output (any of the 8 pruning files missing, or any pruned/future-* pair imbalanced) — atomicity violated, round is fail-closed.
- Individual `research/q*.md` files have been split or moved (they must remain in `research/` as full-corpus reference).
- `phasing.md` re-litigates architecture, names files, or writes task specs — boundary drift into Design / Structure / Plan ownership.
- Replan-gate criteria are vague ("everything works") instead of concrete and checkable.
- `roadmap.md` carries notes, design content, or any column beyond goal ID + phase + slice.
- `## Phasing OWNS / Phasing DEFERS` section malformed/missing — scope-reviewer fail-closed (emits `severity: high` per the schema).
- Pasting Mermaid diagram syntax directly into terminal output (user cannot read it).
- `visual_fidelity_required: true` is set but the visual-fidelity precondition assertion was not run before writing `status: approved` — approval of a phasing artifact without the per-phase wireframe citation check when the flag is active is a precondition violation, not a reviewer-finding-level concern.
- A UI-producing phase's replan gate criteria (the section labeled `**Replan gate criteria.**` in the phasing.md template, i.e. the phase's acceptance criteria) do not cite any wireframe artifact from design's top-level `## Visual-Fidelity Binding` H2 when `visual_fidelity_required: true` — pushing this finding into a reviewer instead of enforcing it as an orchestrator-side precondition assertion is a boundary violation; the assertion must halt approval, not surface as a suggestion.
- Phasing approval written (`status: approved`) despite the visual-fidelity precondition assertion halting — the assertion's halt is a hard stop on the approval flow; approval must not proceed while offending phases remain unresolved or while design's top-level `## Visual-Fidelity Binding` H2 is missing or empty.

## Common Rationalizations — STOP

| Rationalization | Reality |
|----------------|---------|
| "We'll figure out vertical slicing later in Structure" | Phasing IS the slicing decision. Structure reads from `phasing.md`. |
| "Phase 1 can just be the backend so we can move fast" | Phase 1 must prove the full stack. Backend-only PoC defers integration risk to a more expensive phase. |
| "The roadmap can include design notes for context" | No. roadmap.md is mechanical: goal ID, phase, slice. Notes belong in `phasing.md`. |
| "We can skip pruning — the artifacts are short enough" | Pruning is the contract Replan reads from during transitions. Skipping it breaks Phase 2+ flow. |
| "An orphan ID is fine, the user will notice" | Surface orphans explicitly under `## Orphan IDs`. Silent orphans are fail-closed: the round is invalid until resolved. |
| "We can emit phasing.md and finish pruning next round" | Atomicity is mandatory: the synthesis subagent MUST emit all 8 pruning files in a single return. Partial returns are fail-closed. |

## Iron Law and Guidelines — Final Reminder

The override-critical rule plus the strong recommendation for Phasing, restated at end:

1. **Iron Law — Vertical slices, not horizontal layers.** Each slice must be end-to-end demonstrable on its own. "DB layer first, API layer second" defers integration risk and breaks Phase 1 PoC's job of proving the full stack works. Phasing is the natural home of slice authoring.

2. **Phase 1 PoC guideline — prove the full stack end-to-end when possible.** Phase 1 is the PoC; it should exercise every layer the project touches whenever practical. Backend-only Phase 1 tends to hide cross-layer issues until Phase 2+, where they are more expensive to surface — so the default is full-stack. Departures are fine when the phasing discussion names a real reason; the goal is deliberate scoping, not horizontal layering by accident. Phasing owns phase boundaries.

!cat skills/_shared/behavioral-directives.md
