---
finding_id: R1-F02
reviewer_tag: scope-codex
artifact: plan.md
round: 1
severity: medium
change_type: scope
location: "Many tasks — exact file operations, command sequences, exit-code branches"
---

## Issue

Many task specs descend to implementation-contract level: exact byte-for-byte file operations, exact command sequences, exit-code branches in Test expectations. Per owns-defers, that altitude is owned by structure.md (interfaces) and the implementer (line-level).

## Why

Plan's altitude is "what each task accepts as input, produces as output, and proves in test." When plan pins exit codes and command sequences, it removes the implementer's ability to refactor without re-opening plan; it also re-authors structure-owned interface contracts.

## Fix

Sweep each task's DoD and Test expectations: replace literal command sequences with behavioral assertions ("rejects symlink that resolves outside repo root"), replace exit-code pins with pass/fail outcome descriptions, and cross-reference structure.md for the interface contract.

## Disposition note (orchestrator)

Counter-evidence: this verdict opposes scope-claude's "no boundary drift" finding. The specificity in test expectations is part of the new template's value proposition (T25 pilot deliberately pins exact behavior). Surfaced here for verifier triage.
