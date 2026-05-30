---
artifact: design
reviewer: scope-claude
round: 1
finding_id: scope-claude-F03
severity: low
change_type: scope
file: design.md
section: "DKR4"
lines: 43
---

# F03: DKR4 Reasoning contains an implementation directive

## Evidence

DKR4 Reasoning says: "The parallelize-reviewer agent's linting must be updated to walk Wave sub-sections rather than a single table."

## Rule violated

This is a task spec ("update the linting logic to traverse the new structure") embedded in an architectural-decision record. Design OWNS the impact statement (downstream consumers are affected) but not the directive to implement a specific traversal change.

## Required fix

Rephrase as an impact consequence: e.g., "Downstream linting that walks the flat Branch Map structure will need to accommodate the new Wave sub-section shape (a Plan / Implement concern)."
