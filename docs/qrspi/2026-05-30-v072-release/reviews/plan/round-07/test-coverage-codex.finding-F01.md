---
reviewer: codex
role: plan-test-coverage-reviewer
round: 7
artifact: plan.md
severity: medium
change_type: correctness
finding_id: F01
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

# Finding F01 — T39 reproducibility DoD lacks build-twice determinism test

## Location

- `plan.md` Task 39 DoD, **L2242**
- `plan.md` Task 39 Test Expectations, **L2257–L2269**

## What's wrong

The DoD requires a *reproducible* build tree (L2242), but Test
Expectations only require a single successful build plus artifact audits.
There is no explicit "build twice and compare bytes/diff" check.

## Why this matters

Nondeterministic build behavior (ordering/timestamp/path traversal side
effects) can slip through and only appear as flaky CI or intermittent
build-sync failures.

## Needed coverage

Add an explicit determinism check (e.g., run `node tools/build-plugin.mjs`
twice from clean state and assert zero diff/hash change in `build/` +
relevant metadata outputs).
