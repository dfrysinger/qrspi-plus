# Finding F04: Task 3 — EOF-terminated extraction case is missing from test expectations

**Artifact:** plan.md
**Task:** Task 3 (G3 — fence-aware section extractor promoted to shared library)
**Category:** Edge Cases
**Severity:** advisory

## Problem

The description explicitly states:

> "exits at the next out-of-fence section boundary (a same-level heading outside a fence) **or at EOF**"

The function's structure.md interface contract likewise lists EOF as a valid termination condition. However, all test expectations for `extract_section_fence_aware` describe termination at a section-boundary heading. There is no test expectation covering the case where the section runs to the end of the file with no subsequent heading.

The EOF path is a distinct code path: the extraction loop must correctly return the accumulated content (non-empty) and exit 0, rather than falling into the empty-extract error branch. Without a pinned expectation, an implementation that emits the empty-extract diagnostic and non-zero return code on EOF-termination would pass all stated expectations while breaking the documented contract.

## Recommendation

Add one expectation:

- "When the anchor pattern matches a section that extends to EOF with no subsequent section heading and no closing fence, the function returns the section content (non-empty) to stdout and exits with return code 0."

This guards the EOF-termination branch independently of the heading-termination branch.
