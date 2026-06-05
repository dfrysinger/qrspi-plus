---
reviewer: codex
role: plan-test-coverage-reviewer
round: 7
artifact: plan.md
severity: medium
change_type: correctness
finding_id: F02
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

# Finding F02 — T25 DoD requires zero stale refs but lacks repo-wide grep assertion

## Location

- `plan.md` Task 25 DoD, **L1400**
- `plan.md` Task 25 Test Expectations, **L1407–L1413**

## What's wrong

DoD requires zero stale references to `docs/prompt-design-guide.md`
(L1400), but Test Expectations do not include a repo-wide assertion for
that removal.

## Why this matters

The migration can be partially complete while stale references remain,
causing drift and pointing contributors to a deleted source-of-truth path.

## Needed coverage

Add a grep assertion that `docs/prompt-design-guide.md` has no remaining
live references (with any intended explicit exclusions documented).
