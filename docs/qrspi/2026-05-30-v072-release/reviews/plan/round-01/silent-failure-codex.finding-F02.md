---
finding_id: R1-F02
reviewer_tag: silent-failure-codex
artifact: plan.md
round: 1
severity: medium
change_type: correctness
location: "Task 12 (G4) DoD / Test expectations — backward-loop flag delete"
---

## Issue

T12's backward-loop flag DoD describes "delete when possible" with "on delete failure only surface a diagnostic". State-mutation failure is treated as log-and-continue, not fatal.

## Why silent

Failure to delete a consume-once flag leaves sticky state. The next round's ref-selection step reads the flag and broadens regardless of convergence — non-deterministic future routing behavior with no fail-loud signal.

## Fix

Treat flag-delete failure as fatal (non-zero exit, halt the loop). Surface the failure as a Review-Loop Pause Gate that requires user action, not a continue-and-log path.
