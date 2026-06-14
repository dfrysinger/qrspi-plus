## Boundary with Goals

This section codifies the Replan ↔ Goals boundary contract for `future-goals.md` promotion at phase boundaries. Replan consumes `future-goals.md` entries and promotes a subset to the next phase's `goals.md`; Goals retains sole authority to formalize entries Replan must skip.

### Formal-vs-Idea promotion gate

Replan promotes **ONLY fully-Formal entries** from `future-goals.md` into the next phase's `goals.md`. A fully-Formal entry is an entry that satisfies ALL of the following:

**Frontmatter requirements:**
- Has a frontmatter `id:` field (e.g., `id: G5`)
- Has a frontmatter `type:` field with a valid Goals type value (`known-fix` or `exploratory`)

**Required body subsections:**
- Contains `## Problem` subsection
- Contains `## Why we care` subsection
- Contains `## What we know so far` subsection

An entry that satisfies all five requirements above is promoted to the next phase's `goals.md`.

### Skip conditions

The following entry types are **SKIPPED** (not promoted to `goals.md`):

**Partial-Formal entries** — entries that carry a frontmatter `id:` but are missing any of the following: `type:` field, `## Problem` subsection, `## Why we care` subsection, or `## What we know so far` subsection. These entries have been started but not completed to the Formal shape. Replan skips them and records the specific missing field or subsection in the hand-off report.

**Prose-only Idea entries** — entries that carry no frontmatter `id:` field. These are informal ideas captured without commitment to a goal ID. Replan skips them and records "prose-only Idea" as the skip reason in the hand-off report.

### Replan does NOT

Replan enforces the promotion gate but does NOT perform any of the following:
- Mint new `id:` values for Idea entries
- Assign `type:` fields to entries missing them
- Author `## Problem`, `## Why we care`, or `## What we know so far` subsections
- Convert Ideas into Formal goals
- Author acceptance criteria for promoted or skipped entries

All of the above belong to a subsequent user-invoked Goals run.

### Hand-off report shape

After applying the promotion gate, Replan emits a per-run hand-off report enumerating both promoted and skipped entries:

**Promoted Formal entries:** listed by `id:` and `title:` (one line per entry). Example:
```
Promoted: id=G5 title="Add support for async task queues"
```

**Skipped entries:** listed with the explicit reason for the skip:
- Partial-Formal: `Skipped (partial-Formal): id=G6 missing: type:, ## Why we care`
- Prose-only Idea: `Skipped (prose-only Idea): "Improve onboarding flow" (no id:)`

The hand-off report is presented to the user before the next Goals run begins, so users can manually formalize skipped entries via a subsequent Goals invocation if desired.
