---
artifact: design
reviewer_tag: quality-codex
finding_id: quality-codex-F01
change_type: correctness
---

# G6 Outcome contradicts updated full-parent validation rule

## Location

design.md L391 (G6 Outcome) vs L396 (capture procedure) and L405 (edge case).

## Finding

G6 Outcome still says actual merge parents are "validated to equal the named task-tip SHA set at creation time", but the updated Solution captures and compares the full parent set (integration base + task tips). An implementer following only the Outcome could compare task-tips-only and trigger every valid merge to halt.

## Expected fix

Rewrite Outcome to reflect full-set comparison: "actual git merge parents are validated to equal the expected full parent set captured at wave-dispatch time (integration-base SHA + named task-tip SHAs)".
