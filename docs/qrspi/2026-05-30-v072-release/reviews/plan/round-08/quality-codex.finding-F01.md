---
reviewer: codex
role: plan-reviewer
round: 8
artifact: plan.md
severity: high
change_type: correctness
finding_id: F01
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

# Finding F01 — T25 includes an unfulfillable repo-wide stale-reference assertion

## Location

- `plan.md` Task 25 DoD, **L1400**
- `plan.md` Task 25 Test Expectations, **L1408** (the round-07 E1 fix)

## What's wrong

Task 25's DoD/Test Expectations require a repo-wide grep to find zero
`docs/prompt-design-guide.md` references (outside CHANGELOG), but this
repository intentionally contains many non-CHANGELOG historical/release
artifacts that still reference that path. As written, the acceptance
check can fail even when implementation is correct.

## Evidence

- Plan requirement: line 1400 (`No stale ... remain in the repo`) and
  line 1408 (repo-wide grep audit).
- Actual repo state (excluding CHANGELOG) still contains many matches
  in release artifacts, e.g. `docs/qrspi/2026-05-30-v072-release/structure.md:118`,
  `:2416`, plus other release/history files
  (`grep -R -n "docs/prompt-design-guide.md" . --exclude='*CHANGELOG*'`).

Orchestrator verification: 43 total non-CHANGELOG matches across
`docs/qrspi/` (release artifacts), `.restructure-v2/` (intermediate
structure work), `plan.md.bak-pre-merge` (planning backup), and the
v0.4 bundle's research files.

## Suggested fix

Narrow the audit scope to runtime/source surfaces that should be clean
(e.g., `skills/`, `agents/`, `scripts/`, active templates), or
explicitly exclude historical/release artifact directories and backups.
The intent of the audit is to catch live consumers still pointing at
the deleted path, not to penalize planning documents that describe the
migration.
