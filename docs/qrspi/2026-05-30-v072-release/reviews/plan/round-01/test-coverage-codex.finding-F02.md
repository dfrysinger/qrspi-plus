---
finding_id: R1-F02
reviewer_tag: test-coverage-codex
artifact: plan.md
round: 1
severity: medium
change_type: correctness
location: "Task 11 DoD (~line 714) vs Test expectations (~lines 721-727)"
---

## Issue

T11 DoD claims "atomic and append-safe" but the Test expectations cover only repeated invocations and "well-formed JSON with expected entries" — no concurrent/overlap writes or interruption/race scenarios.

## Why

A non-atomic implementation can still pass the current expectations. The atomicity claim is unverifiable from the test surface; concurrent dispatchers writing to the same audit log could interleave or lose entries.

## Fix

Add explicit concurrency fixtures: two parallel dispatchers writing to the same log file, with an assertion that all N entries are present and well-formed. Add an interruption fixture: terminate the writer mid-write and assert no torn entry. Concurs with tc-claude F05's broader "concurrency invariants are unverifiable" finding.
