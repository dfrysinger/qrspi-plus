---
finding_id: R4-F04
severity: low
change_type: missing
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 4
reviewer: testcov-claude
---

# Task 3 — Whitespace-only extracted region is an unspecified edge case for the empty-extract guard

## Location

Task 3 test expectations, the combined anchor/empty-content bullet:

> "When the target anchor heading is not present, the function emits to stderr `extract_section_fence_aware: anchor heading not found: <heading>` and exits non-zero; when the anchor is found but the extracted region is empty, the function emits to stderr `extract_section_fence_aware: no content found between anchor and next heading: <heading>` and exits non-zero."

## Problem

The plan specifies two error paths: (1) anchor absent, (2) anchor present but region empty. A third boundary condition is absent: **the anchor is present, but the region between it and the next heading contains only blank lines or whitespace-only lines**.

This is a genuine boundary between "empty" (fires the guard) and "has content" (succeeds). The function description says it "exits with non-zero return code when extraction is empty (both when the anchor heading is absent and when the anchor is present but no content lines follow)." The phrase "no content lines" implies whitespace-only lines might not be "content lines," which would put them in the empty-extract error path — but this is not stated explicitly.

A test writer implementing the unit coverage in `tests/unit/test-helpers-skill-markdown.bats` will face this ambiguity: should a document where the anchor heading is followed immediately by blank lines before the next heading trigger the "no content found" diagnostic, or return those blank lines as extracted output?

## Why This Matters

The structure.md interface contract for `extract_section_fence_aware` says it returns 0 on "non-empty extract" — which implies the definition of "empty" is load-bearing. Without an explicit statement for the whitespace-only case, two test writers will make different assumptions, and an implementation that treats blank lines as content will pass one person's test suite but fail another's.

This is especially relevant because the migrated call sites test ("both migrated call sites produce output identical to the prior `extract_review_round` output") may hide this difference if the real input documents happen never to have whitespace-only sections.

## Fix

Add one bullet clarifying the whitespace-only boundary:

> "A section region that contains only blank lines (whitespace-only lines, no non-whitespace content) between the anchor and the next heading boundary triggers the 'no content found' diagnostic and exits non-zero (blank lines are not treated as content lines)"

OR, if blank lines should be returned as content:

> "A section region that contains only blank lines is returned as valid output (exit 0); only a region with literally zero lines triggers the 'no content found' diagnostic"

Either form is testable; the plan just needs to commit to one.
