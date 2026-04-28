---
status: draft
---

# Replan: Out-of-Scope Seed (replan proposals)

This fixture deliberately seeds content that violates `## Replan OWNS / Replan DEFERS`. The scope-reviewer dispatch with `{ARTIFACT_TYPE}=replan` MUST emit boundary-drift findings tagged `change_type: scope` (or `intent`) for the DEFERS-list violations below. The in-scope examples (under `## In-Scope Examples`) trace to OWNS rules and must NOT be flagged — they exist so a regression that nukes the replan parameterization is caught by the test (the rendered prompt should still surface the OWNS/DEFERS rule set verbatim from the locked rules file).

## In-Scope Examples (Replan OWNS — must NOT be flagged)

### Severity classifications (OWNS — Replan-owned)

- Proposal: "Task 7 needs an extra edge-case test for empty-input handling." → **Minor** (task spec wording).
- Proposal: "Task 9 LOC estimate should be ~400 not ~250." → **Minor** (LOC estimate).
- Proposal: "Split Task 8 into 8a and 8b." → **Minor** (add/split within existing slice).

### Minor-path artifact updates (OWNS — Replan-owned)

- Apply approved minor changes to `tasks/task-07.md` and `plan.md`; transition status to `replan-draft` and back to `approved` after re-approval.

### Phase-transition execution (OWNS — Replan-owned, minor path)

- Five-step archive-and-populate sequence: archive `goals.md`/`questions.md`/`research/summary.md`/`design.md` to `docs/qrspi/{slug}/phases/phase-NN/`; read `roadmap.md` to identify next-phase goal IDs; extract entries for those goal IDs from `future-*.md`; write next-phase drafts with `status: draft`; invoke `qrspi:goals` Restart Mode.

## Out-of-Scope Examples (Replan DEFERS — MUST be flagged)

### DEFERS violation — Phasing decision (slice decomposition)

- Proposal: "Move Notifications out of the social slice into its own vertical slice." — DEFERS violation: vertical slice decomposition is owned by **Phasing** (and Design re-litigation), not Replan. This must classify Major and loop back; Replan MUST NOT silently re-author phase boundaries.

### DEFERS violation — `roadmap.md` authoring

- Proposal: "Amend `roadmap.md` to add a new phase between Phase 2 and Phase 3 for caching work." — DEFERS violation: `roadmap.md` authoring is owned by **Phasing**. Replan READS the roadmap; it MUST NOT write or amend it.

### DEFERS violation — `future-*.md` authoring

- Proposal: "Add three new entries to `future-goals.md` covering observability work the team noticed mid-phase." — DEFERS violation: `future-*.md` authoring is owned by **Phasing** (and the upstream skill on Major loop-back). Replan READS the future-* artifacts; it MUST NOT add new entries.

### DEFERS violation — Architecture re-litigation (Design-owned)

- Proposal: "Switch from polling to WebSockets for the real-time feed; this is a small wording change to the existing tasks." — DEFERS violation: architecture choice belongs to **Design**. Replan must classify Major and loop back to Design — not silently re-author task wording to mask an architecture pivot.

### DEFERS violation — File-map authoring (Structure-owned)

- Proposal: "Add `src/middleware/rate-limiter.ts` to the structure for Phase 2 — Replan can update `structure.md` directly to add this entry." — DEFERS violation: file maps are owned by **Structure**. Replan must classify Major and loop back; Replan MUST NOT author entries in `structure.md`.

### DEFERS violation — Task spec authoring beyond LOC/wording (Plan-owned)

- Proposal: "Author a brand-new task spec `tasks/task-25.md` describing the migration runner from scratch, including its full test expectations and dependencies graph." — DEFERS violation: full task spec authoring (vs. LOC/wording tweaks within an existing task) belongs to **Plan**.

### DEFERS violation — Goal-text expansion / new goal creation

- Proposal: "Expand goal G3's acceptance criteria to also cover SMS notifications — Replan can add this acceptance criterion inline." — DEFERS violation: goal-text expansion or new goal creation is owned by **Goals**. The scope-mapping check requires Replan to classify this Major and loop back to Goals, NEVER silently expand goal text.

### DEFERS violation — Phase boundary edit (Phasing-owned)

- Proposal: "Move Task 8 from Phase 2 to Phase 3 because the integration window slipped." — DEFERS violation: phase boundaries / phase membership decisions are owned by **Phasing** (with Design re-litigation if the slice splits). Replan must classify Major.
