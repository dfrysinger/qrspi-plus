---
finding_id: R1-F01
reviewer_tag: test-coverage-codex
artifact: plan.md
round: 1
severity: medium
change_type: correctness
location: "Task 27 (~lines 1687-1692 out-of-scope; ~1695-1710 DoD/Test expectations)"
---

## Issue

Design CD-2 requires two additional acceptance surfaces: (1) reviewer-protocol enforcement for antagonist-pattern findings, and (2) a `using-qrspi/SKILL.md` one-line pointer to `_shared/evergreen-output-rule.md`. T27 explicitly excludes these and no other task test expectations cover them.

## Why

CD-2 design scenarios are not testable from any plan task. The plan-to-design coverage check passes (T27 maps to CD-2) but the test-level coverage check fails (CD-2's two acceptance surfaces have no test home).

## Fix

Either (a) extend T27 to include the two CD-2 acceptance surfaces and their test expectations, or (b) add a new task (T27b) that owns them. Reference design.md ~285-289 for the canonical acceptance text.
