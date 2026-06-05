---
finding_id: R1-F03
reviewer_tag: silent-failure-codex
artifact: plan.md
round: 1
severity: medium
change_type: correctness
location: "Task 19 (G27) Scope — second_reviewer probe fallback"
---

## Issue

T19 Scope describes `second_reviewer: false on probe failure` — probe failure is converted into a config fallback that disables the second review.

## Why silent

Loses review coverage while appearing like a normal configured single-reviewer run. The orchestrator cannot distinguish "user intentionally chose single reviewer" from "second reviewer was silently disabled because probe failed."

## Fix

Treat probe failure as fatal (halt with operator-actionable diagnostic). If the user wants single-reviewer mode, they should configure it explicitly, not get it as a probe-failure side effect.
