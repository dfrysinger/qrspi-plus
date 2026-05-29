---
finding_id: quality-claude-F02
severity: minor
change_type: style
referenced_files:
  - scripts/run-codex-review.sh:617
  - scripts/run-codex-review.sh:626
artifact: task-07
round: 1
reviewer: quality-claude
---

# F02 — QRSPI task-ID `T7` leaked into production-code comments in `run-codex-review.sh`

Two new comment markers in `scripts/run-codex-review.sh` reference the run-internal task ID:

- Line 617: `# Decoupled from the short-circuit below (T7):`
- Line 626: `# check_codex_available short-circuit (T7):`

Per the ID-hygiene rule, `T`-prefixed numeric tokens are forbidden in code comments outside `docs/qrspi/`, regardless of scope. The tokens couple production-code narrative to a specific QRSPI run that will go stale post-merge. The surrounding prose already explains the behavioral rationale (decoupling reason, propagate-exit-unchanged contract); the `(T7)` tags add no signal a future reader would benefit from.

(Note: the pre-existing `T04` reference at line 4 is outside this diff's scope and is not flagged.)

**Recommendation:** Strike `(T7)` from both comments. The rationale remains intact: `# Decoupled from the short-circuit below:` and `# check_codex_available short-circuit:`. If a "why was this added" pointer is needed, point at the durable design artifact (`docs/qrspi/2026-05-27-v071-hardening/design.md`) rather than the per-run task ID.
