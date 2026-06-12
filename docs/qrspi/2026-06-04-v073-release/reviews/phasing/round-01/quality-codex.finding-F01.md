---
artifact: phasing
reviewer: quality-codex
finding_id: quality-codex-F01
change_type: correctness
---

## Finding: `future-goals.md` leaks current-phase goal IDs despite the "no deferred content / no goal IDs in future artifacts" contract

`phasing.md` says the `future-*` files "carry no goal IDs because v0.7.3 defers no content":

- `phasing.md:37`

But `future-goals.md` explicitly includes the current-phase goal range:

- `future-goals.md:7` — "all goals (G1–G9) are in the current phase"

This violates the pruning-quality check that no current-phase content leaks into `future-*.md`, and makes the phasing artifact's Goal-ID consistency statement false.

### Required fix

Remove the current-phase goal IDs from `future-goals.md`, e.g. change it to:

> No goals deferred. v0.7.3 is a single-phase release; all goals remain in the current-phase goals artifact. This file exists to satisfy the Phasing atomicity contract and will be repopulated by Replan if a future phase is opened.
