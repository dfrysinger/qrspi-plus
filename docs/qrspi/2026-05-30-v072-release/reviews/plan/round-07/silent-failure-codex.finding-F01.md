---
reviewer: codex
role: plan-silent-failure-hunter
round: 7
artifact: plan.md
severity: high
change_type: correctness
finding_id: F01
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

# Finding F01 — `_resolve-lib.sh` `hardcoded medium` warning-only fallback (fail-open)

## Location

- `plan.md` Task 16, **L986** and **L1013**

## What's wrong

The plan explicitly preserves a log-and-continue routing path:
`--tier-override → tier → default_tier → hardcoded medium with loud warning`,
and test expectations require that precedence. That means resolver
behavior can continue on an implicit fallback instead of halting when
routing inputs are incomplete or broken.

## Why this matters

This is a fail-open/log-and-continue behavior in the dispatch control
plane; it can route work to unintended models while still "succeeding,"
masking configuration defects rather than forcing correction.

## Suggested fix

Replace the final `hardcoded medium` fallback with a hard failure
(non-zero exit + diagnostic), and update test expectations to require
halt-on-missing-effective-tier rather than warning-and-continue.

## Counter-context (round-07 sf-claude disposition)

Round-07 sf-claude clean explicitly addressed this same surface: "T16 L986
resolver precedence (`… → default_tier: → hardcoded medium with loud
warning`) was not flagged in round-06 by silent-failure-claude
(**goals-permitted operator-facing fallback per CD-1**) and is untouched
in round-07; no regression." The fallback is a deliberate goal/design
decision in CD-1 (operator gets the warning, dispatch proceeds with
documented default), not a plan-altitude defect. Changing it would
require backward-looping into design.md ## CD-1 and goals.md G22.
