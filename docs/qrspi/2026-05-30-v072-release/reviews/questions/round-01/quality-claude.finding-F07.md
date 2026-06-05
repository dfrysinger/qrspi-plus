---
finding_id: F07
severity: low
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/questions.md
artifact: questions
---

# Objectivity Defect — Q7 Telegraphs the Desired State via "Bidirectionally Referenced"

## Location

Question 7, closing sentence:

> "Are the fail-loud paragraphs at L470 and L526 (dispatcher-scoped and missing-block backfill) **bidirectionally referenced** from the validation table, or do they stand independently?"

## Problem

"Bidirectionally referenced" is a specific structural outcome — one in which the validation table links forward to the fail-loud paragraphs AND the fail-loud paragraphs link back to the table. A neutral characterization question would not name the desired relationship and ask whether it exists; it would simply ask the researcher to characterize the relationship.

As written, a researcher who reads "bidirectionally referenced" as the first alternative in a binary will understand the project wants bidirectional cross-referencing and will frame their findings accordingly. The question tells the researcher what counts as the "correct" state before research establishes what the current state is.

This is a mild but real objectivity issue. The goals text for G23 phrases the same investigation neutrally: the problem is "fail-loud paragraphs sit in the file but are not cross-referenced from the validation table" — noting unidirectional absence, not asserting bidirectional presence as the target.

## Suggested Rewrite

Replace:

> "Are the fail-loud paragraphs at L470 and L526 (dispatcher-scoped and missing-block backfill) bidirectionally referenced from the validation table, or do they stand independently?"

With:

> "How are the fail-loud paragraphs at L470 and L526 (dispatcher-scoped and missing-block backfill) related to the validation table — do they cross-reference each other, does one reference the other unidirectionally, or do they stand independently?"

This asks the researcher to characterize the actual relationship without implying that bidirectional referencing is the expected or desired state.
