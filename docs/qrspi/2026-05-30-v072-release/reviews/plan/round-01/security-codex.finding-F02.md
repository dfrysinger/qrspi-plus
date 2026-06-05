---
finding_id: R1-F02
reviewer_tag: security-codex
artifact: plan.md
round: 1
severity: medium
change_type: correctness
location: "Task 14/15 (~lines 880, 941-963) and Task 33 (~line 2043)"
---

## Issue

T14/T15 require rerunning author-supplied search commands (e.g. `grep ...`) from repo root. T33 requires the reviewer to execute a `structural_lint:` command from the spec. No requirement or test constrains these to a safe allowlist or rejects shell-metachar/injection payloads.

## Why (security gap)

The plan content itself is an untrusted-data surface (sub-subagent-authored, codex-co-authored). A malicious or accidentally adversarial plan field can trigger arbitrary command execution during review or implementation.

## Fix

Enforce a strict command schema/allowlist (e.g. structured fields with a canonical command/arg JSON, not free-form shell strings), and add negative tests for injection/metachar cases (`; rm -rf`, backticks, dollar-paren substitution, redirects).
