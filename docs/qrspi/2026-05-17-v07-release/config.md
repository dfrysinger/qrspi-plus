---
created: 2026-05-17
pipeline: full
codex_reviews: false  # Implement-phase override: user cost guidance ("sonnet for reviewers"); Claude reviewers cover the 4 correctness gates per task. Original value: true (kept for upstream phases via git history).
route:
  - goals
  - questions
  - research
  - design
  - phasing
  - structure
  - plan
  - parallelize
  - implement
  - integrate
  - test
verifier_enabled: true
scope_tagger_enabled: true
phase: 1
review_depth: quick
review_mode: loop_until_clean
worktree_mode: serialized  # Pragmatic override (non-canonical field, documented): no .worktrees/, sequential per-wave dispatch on feature branch. Justified for markdown/script repo with 18/43 lightweight tasks.
---
