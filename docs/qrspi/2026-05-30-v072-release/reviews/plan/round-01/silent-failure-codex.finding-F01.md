---
finding_id: R1-F01
reviewer_tag: silent-failure-codex
artifact: plan.md
round: 1
severity: high
change_type: correctness
location: "Task 16 (G22) — _resolve-lib.sh precedence Scope / Test expectations"
---

## Issue

T16's resolver chain ends in "hardcoded medium with loud warning" — a log-and-continue fallback. Warning-on-stderr + exit 0 does not surface in LLM-orchestrator context.

## Why silent

Caller gets continued execution instead of a required failure signal. The orchestrator cannot branch on a warning it cannot see, so misconfiguration silently ships.

## Fix

Replace step 4 of the precedence chain with a non-zero exit + named diagnostic, consistent with the `none`-tier halt the same task already requires.

## Disposition note (orchestrator)

Concurs with sf-claude F01 (Codex escalates to high, Claude rated low). Also concurs with security-codex F01. Verifier should consolidate.
