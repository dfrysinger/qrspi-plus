---
finding_id: F01
reviewer: silent-failure-claude
round: 2
task: Task 3
category: SILENT_FALLBACK
severity: medium
---

# F01 — Task 3: Missing test expectation for anchor-heading-not-found case

## Location

Task 3 test expectations — specifically the empty-extraction diagnostic bullet.

## What the plan says

The description says: *"emits a named diagnostic to stderr with a non-zero exit code when extraction is empty."*

The corresponding test expectation is:

> When the extraction from anchor to boundary produces no content lines, the function emits a diagnostic message to stderr and exits with a non-zero return code.

## The silent failure

The phrase **"from anchor to boundary"** implies the anchor heading was found. It describes the case where the section exists but contains no content lines between its heading and the next boundary.

There is a second distinct failure mode: **the anchor heading is not present in the input at all**. If a caller passes a section heading string that does not exist in the document, the function will produce zero output. An implementer following the test expectation literally would write:

```
# case 1 (specified): anchor found, no content follows → diagnostic + non-zero
```

but would not necessarily write:

```
# case 2 (not specified): anchor not found → diagnostic + non-zero
```

The resulting implementation could return empty stdout with exit 0 when called with a nonexistent section heading. The caller then cannot distinguish "section exists but is empty" from "section heading typo / wrong document passed." Both produce empty output, but only one gets a diagnostic.

## Why this matters at runtime

The two call sites migrated from the inline `extract_review_round` will call the new shared function with specific heading strings. If those strings ever drift (refactored heading text, wrong argument) and the function silently returns empty with exit 0, the consuming test suite's assertions will fail on the extracted content—with no indication from the helper itself that the heading was never found. The diagnostic path, which should surface the root cause immediately, is never reached.

## Proposed fix

Add one test expectation that explicitly covers the not-found case:

> When the target anchor heading string is not present anywhere in the input, the function emits a diagnostic message to stderr (identifying the missing heading) and exits with a non-zero return code.

The description should also be updated to read: *"emits a named diagnostic to stderr with a non-zero exit code when extraction is empty — both when the anchor heading is absent and when the anchor is present but no content lines follow."*
