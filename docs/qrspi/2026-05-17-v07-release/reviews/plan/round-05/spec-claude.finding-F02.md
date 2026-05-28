---
finding_id: R5-F02
severity: low
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L1283
  - docs/qrspi/2026-05-17-v07-release/plan.md:L1252
artifact: plan
round: 5
reviewer: spec-claude
---

T42's description (plan.md line 1283) contains a vocabulary contradiction relative to T41. The T42 description states the partial-Formal fixture entry "is NOT promoted (classified as Idea because it is missing a required subsection)." However, T41 (the contract T42 is testing) explicitly treats partial-Formal entries and prose-only Idea entries as two distinct categories with distinct skip reasons: partial-Formal entries are "SKIPPED" with the reason naming the missing required field or subsection, while prose-only Idea entries are "SKIPPED" with the reason "prose-only Idea" (plan.md line 1252).

The T41 target-file bullet (line 1252) is unambiguous: "Replan emits a per-run hand-off report that enumerates ... (b) each skipped entry (partial-Formal or Idea) with the explicit reason for the skip (which required field or subsection was missing for partial-Formal, or 'prose-only Idea' for fully informal entries)." The two skip categories have separate reasons precisely because they are separate categories, not because a partial-Formal entry is reclassified as an Idea.

When an implementer reads T42's description before implementing the promotion classifier — which is the normal TDD read order — the phrase "classified as Idea because it is missing a required subsection" suggests the implementation should treat partial-Formal entries as a sub-type of the Idea category, using the Idea classification branch. This would produce a classifier that conflates the two categories, potentially losing the partial-Formal-specific skip reason that T41 requires in the hand-off report.

T42's own test expectations (lines 1284–1289) are correctly aligned with T41's taxonomy — the fixture carries a "one partial-Formal" entry and assertions (b), (c), (d), (e), (f) correctly treat partial-Formal and prose-only Idea as separate categories. The contradiction is in the description text only (line 1283), not in the test expectations.

**Fix:** Replace "is NOT promoted (classified as Idea because it is missing a required subsection)" with "is NOT promoted (skipped as a partial-Formal entry; the hand-off report names the missing required subsection as the skip reason)" to align with T41's two-category taxonomy. The replacement correctly identifies the entry as partial-Formal (not reclassified as Idea), explains the skip reason in the T41-consistent vocabulary, and removes the misleading "classified as Idea" framing.
