---
artifact: design
reviewer: quality-codex
round: 1
finding_id: quality-codex-F01
severity: medium
change_type: correctness
file: design.md
section: "DKR2"
---

# F01: DKR2 rationale cites the wrong research source

## Evidence

design.md DKR2 Reasoning says the `.git/info/exclude` reliance is "Per `research/q04-codebase.md`". The `q04-codebase.md` file documents current `.gitignore` entries; it does not establish the commit-procedure `.git/info/exclude` dependency. That dependency is established in `research/q03-codebase.md` (commit procedure / invariants).

## Impact

Research traceability is incorrect for a key design decision, weakening rationale verifiability.

## Required fix

Update DKR2 citation to the correct source (`research/q03-codebase.md`) or cite both q03 and q04 precisely (q03 for the exclude reliance, q04 for the absence of a `.gitignore` entry).

## Convergence note

Same finding raised by quality-claude as F01. Dedup target.
