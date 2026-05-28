---
finding_id: R1-F02
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/goals.md:L276, docs/qrspi/2026-05-17-v07-release/goals.md:L266]
artifact: goals
round: 1
reviewer: quality-claude
---

Two goal titles use opaque internal cross-reference tokens that are never expanded in the goal body or anywhere in goals.md: G15 "F-23 wave nesting" (title token `F-23`; body references `F-22` in passing) and G16 "K3 CI" (title token `K3` never appears in the body at all).

A downstream Design reader who does not have the source-issue tracker open cannot tell what F-23, F-22, or K3 refer to. The goal bodies are themselves self-contained and reasonably clear about the work, which makes the title tokens vestigial — they identify the source issue without informing the reader about the goal itself. For G16 in particular, "K3 CI" tells the reader nothing about scope until they read the Problem paragraph.

Two reasonable resolutions: (a) drop the bare tokens from titles and rely on descriptive titles alone (e.g. "Wave nesting in parallelization.md", "GitHub Actions CI for qrspi-plus"), keeping any source-issue cross-reference inside a "What we know so far" bullet that names what F-22/F-23/K3 actually are; or (b) keep the tokens but add a one-line gloss at first mention. Either approach removes the unexplained-token surface.

This is a clarity finding because the artifact's content is correct — the references are accurate within their original tracker context — but readers without that tracker context will misread or skim past the titles.
