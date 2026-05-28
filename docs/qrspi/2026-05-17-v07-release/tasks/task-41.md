---
task: 41
status: approved
pipeline: full
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G15]
dependencies: []
loc_estimate: 100
---

# Task 41: Replan boundary-with-Goals section in skills/replan/SKILL.md and OWNS update in skills/replan/owns-defers.md

- **Phase:** 1
- **Target files:**
  - `skills/replan/SKILL.md` (Modify) — append a new `## Boundary with Goals` H2 section that codifies the Replan-side promotion contract for `future-goals.md`. The section declares: Replan promotes ONLY fully-Formal future-goals entries (entries whose frontmatter carries `id:` and `type:` AND whose body contains all three required Goals subsections `## Problem`, `## Why we care`, `## What we know so far`) into the next phase's `goals.md`; partial-Formal entries (frontmatter `id:` present but missing `type:` or missing any of the three required subsections) are SKIPPED; prose-only Idea entries are SKIPPED; Replan does NOT mint IDs, does NOT author acceptance criteria, and does NOT convert Ideas into Formal goals. The section also declares the hand-off report shape: Replan emits a per-run hand-off report that enumerates (a) each promoted Formal entry by `id:` and `title:` and (b) each skipped entry (partial-Formal or Idea) with the explicit reason for the skip (which required field or subsection was missing for partial-Formal, or "prose-only Idea" for fully informal entries). Goals retains sole authority to formalize skipped entries on a subsequent user-invoked Goals run.
  - `skills/replan/owns-defers.md` (Modify) — extend the OWNS list with an explicit "Boundary with Goals: Formal-vs-Idea schema check on `future-goals.md` entries during phase-boundary promotion, plus the hand-off report shape (promoted Formal entries enumerated; skipped partial-Formal and Idea entries enumerated with skip reason)" entry; extend the DEFERS list with an explicit "Idea formalization (minting new `id:`, assigning `type:`, authoring `## Problem` / `## Why we care` / `## What we know so far` subsections) — DEFERS to Goals on a subsequent user-invoked run" entry. The OWNS update declares this responsibility belongs to Replan (not Goals), so the Replan reviewer enforces the boundary contract via the standard SKILL ↔ owns-defers consistency check.
- **Dependencies:** none
- **LOC estimate:** ~100
- **Description:** Codifies the Replan ↔ Goals boundary contract for v0.7 by adding a `## Boundary with Goals` section to `skills/replan/SKILL.md` and a matching OWNS/DEFERS update to `skills/replan/owns-defers.md` so the Replan reviewer enforces it. Replan promotes ONLY fully-Formal future-goals entries (entries with complete Formal-shape frontmatter — `id:`, `type:` — AND all three required Goals subsections `## Problem`, `## Why we care`, `## What we know so far`) to current-phase `goals.md`. Partial-Formal entries (entries that carry an `id:` but are missing `type:` or are missing one of the three required subsections) and prose-only Idea entries are SKIPPED with explicit acknowledgment in the hand-off report. The hand-off report enumerates both promoted Formal entries (by `id:` and `title:`) and skipped entries (with the explicit reason for the skip — which required field or subsection was missing for partial-Formal entries, or "prose-only Idea" for fully informal entries) so users can manually promote partial-Formal entries to Formal via a subsequent Goals invocation. The OWNS update declares this responsibility belongs to Replan (the Formal-vs-Idea schema check, the promotion decision, and the hand-off report shape), and the DEFERS update declares that Idea formalization (minting IDs, assigning types, authoring required subsections) belongs to Goals — keeping deliberate user-intent capture in Goals where it belongs and preventing silent scope expansion at phase boundaries. Source authority is `skills/replan/SKILL.md` (the section is the canonical boundary statement); `skills/replan/owns-defers.md` mirrors the OWNS/DEFERS so the Replan reviewer's source-of-truth pin enforces the boundary on every Replan run.
- **Test expectations:**
  - `skills/replan/SKILL.md` contains a `## Boundary with Goals` H2 section.
  - The section states Replan promotes ONLY fully-Formal `future-goals.md` entries (frontmatter `id:` + `type:` AND all three required subsections `## Problem`, `## Why we care`, `## What we know so far`) to current-phase `goals.md`.
  - The section states partial-Formal entries (have `id:` but missing `type:` or missing any of the three required subsections) are SKIPPED, not promoted.
  - The section states prose-only Idea entries are SKIPPED, not promoted.
  - The section states Replan does NOT mint IDs, does NOT author acceptance criteria, and does NOT convert Ideas into Formal goals.
  - The section declares the hand-off report shape: enumerates promoted Formal entries (by `id:` and `title:`) AND skipped entries (partial-Formal and Idea) with the explicit reason for the skip.
  - `skills/replan/owns-defers.md` OWNS list contains the Boundary-with-Goals responsibility entry (Formal-vs-Idea schema check on `future-goals.md` entries plus the hand-off report shape).
  - `skills/replan/owns-defers.md` DEFERS list contains the Idea-formalization deferral entry (minting IDs, assigning types, authoring required subsections — DEFERS to Goals).
