---
finding_id: R1-F03
reviewer_tag: security-codex
artifact: plan.md
round: 1
severity: medium
change_type: correctness
location: "Task 20 (~lines 1243-1262, 1269-1276)"
---

## Issue

T20 writes files using `<tag>`-derived paths (`.dispatch/<tag>.raw`, prompt files, finding materialization) but no explicit validation or tests reject `../`, slashes, or unsafe tag chars.

## Why (security gap)

Path traversal / overwrite outside the intended round directory via a crafted `<tag>` value. The reviewer-tag string flows from configuration into a filesystem path — exactly the class of trust-boundary that needs explicit validation.

## Fix

Add a canonical tag regex (e.g. `^[a-z0-9][a-z0-9-]*$`), reject unsafe tags fail-closed at the dispatch boundary, and add traversal regression tests (`../`, `foo/bar`, absolute paths, NULL bytes).
