---
artifact: design
reviewer: scope-claude
round: 1
finding_id: scope-claude-F02
severity: medium
change_type: scope
file: design.md
section: "DKR5"
lines: 47-48
---

# F02: DKR5 Reasoning embeds a per-line treatment priority procedure

## Evidence

DKR5 Reasoning contains an ordered procedure: "(1) rewrite to forward-functional framing, (2) delete as historical noise, (3) inline `<!-- evergreen-exempt -->` marker (last resort, only for load-bearing example content)."

## Rule violated

This is an ordered, content-type-specific treatment algorithm — the kind of line-classification recipe that belongs in Plan's task specification, not in Design's architectural decisions section. Design OWNS the decision to drop all path-shaped carve-outs but DEFERS the per-line decision procedure to Plan.

## Required fix

Replace the ordered treatment list with a single architecture-level statement of intent (e.g., "Plan classifies each line for forward-functional rewrite, deletion, or inline-marker fallback before editing").
