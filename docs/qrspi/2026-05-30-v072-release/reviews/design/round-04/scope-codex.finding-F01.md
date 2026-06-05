---
finding_id: R4-F01
severity: medium
change_type: scope
referenced_files:
  - design.md § G15
  - design.md § G18
  - design.md § G19 (and similar per-goal sections using "Plain-language problem" framing)
---

## Issue
Several per-goal sections reintroduce goals-altitude problem framing ("Plain-language problem", contextual incident history, and "Why this matters") inside `design.md`, instead of staying focused on solution definition, decision rationale, dependencies, and acceptance at Design altitude.

## Why it matters
This blurs Goals vs Design boundaries and makes Design carry repeated problem narrative that downstream consumers don't need at this phase, increasing artifact volume/noise and weakening the scope reviewer's ability to detect true altitude drift.

## Proposed change
For each goal block, remove problem-framing prose and keep a short source pointer (goal ID / issue link) plus design-owned content only: outcome, chosen solution, tradeoffs/why, dependencies/edge cases, and acceptance criteria.

## Citation
- design.md:L1528 (`## G15` starts with "Plain-language problem…")
- design.md:L1713 (`## G18` starts with "Plain-language problem…")
- design.md:L1795 (`## G19` starts with "Plain-language problem…")
