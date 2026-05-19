# future-goals.md — mixed-shape fixture (T42)

This fixture carries exactly three entries that exercise all three branches
of the Replan ↔ Goals boundary classifier authored in T41:

1. One **fully-Formal** entry — frontmatter `id:` + `type:` + all three
   required subsections (`## Problem`, `## Why we care`,
   `## What we know so far`). Expected outcome: **promoted**.
2. One **partial-Formal** entry — frontmatter `id:` present, body contains
   `## Problem` and `## Why we care` but is **missing** the required
   `## What we know so far` subsection. Expected outcome: **skipped** with
   the missing subsection named in the hand-off report.
3. One **prose-only Idea** entry — a single prose paragraph with no
   frontmatter and no `##` subsections. Expected outcome: **skipped** with
   the reason `prose-only Idea`.

Each entry is labeled so the BATS pin can address it by name and the
hand-off report can be matched against expected per-entry outcomes.

---

## Entry 1: fully-Formal (PROMOTE)

```yaml
---
id: G5
type: known-fix
title: Add support for async task queues
---
```

### ## Problem

Long-running tasks block the request handler and cause timeouts under
moderate load. Users report 504 errors when uploading large batches.

### ## Why we care

Timeout failures degrade trust in the bulk-import surface, which is the
highest-revenue path for enterprise customers. Pager noise from 504 alerts
has consumed an estimated 12 hours of on-call time over the last quarter.

### ## What we know so far

The handler is synchronous and pinned to a single worker. A prior spike
(see `research/q03-async.md`) identified Redis-backed Sidekiq as the
lowest-risk introduction path; the migration footprint is bounded to the
`/api/v1/bulk-import` endpoint family.

---

## Entry 2: partial-Formal (SKIP — missing `## What we know so far`)

```yaml
---
id: G6
type: exploratory
title: Investigate caching layer for read-heavy endpoints
---
```

### ## Problem

Several read-heavy endpoints hit the database directly with no caching
layer, inflating p95 latency on cache-friendly queries.

### ## Why we care

Latency directly affects perceived product responsiveness on the
dashboard surface. A 200ms p95 reduction would be observable to users.

(Note: the required `## What we know so far` subsection is intentionally
absent — this entry has been started but not completed to the Formal
shape, so Replan must SKIP it and name the missing subsection in the
hand-off report.)

---

## Entry 3: prose-only Idea (SKIP — no frontmatter, no subsections)

We should probably look into improving the onboarding flow at some point.
A few users have mentioned in feedback that the first-run experience
feels disjointed, but we haven't had a chance to dig into it yet.
