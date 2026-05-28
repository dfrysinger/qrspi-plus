---
artifact: design
reviewer: quality-claude
round: 1
finding_id: F02
severity: low
check: trade-offs-clearly-stated
---

# F02 — "Trade-offs Considered" section has no entry for G5 (evergreen-lint carve-out removal)

## Location

`design.md` § **Trade-offs Considered** — missing G5 subsection.

## Observation

The "Trade-offs Considered" section documents rejected alternatives for G1, G2, G3, G4, G6, and G7b. **G5 has no entry.** This is the only goal with a named Key Decision (DKR5) that is absent from the Trade-offs section.

DKR5 explains the chosen *per-line treatment priority* (rewrite → delete → inline marker), but nowhere in the design is the primary architectural choice made explicit as a stated-and-rejected alternative: **keep the path carve-outs in place** vs. **remove all path carve-outs unconditionally**.

`goals.md` G5 lists three per-line treatment options (a, b, c) — all of which are internal to DKR5's priority ordering. The more load-bearing choice that could benefit from a Trade-offs entry is the status-quo alternative: *leave the 5 path-shaped exemption groups in `_is_path_exempt()` untouched*, which costs nothing short-term but leaves the lint blind to an entire file class. That alternative is never named and rejected with explicit reasoning in the design.

## Why it matters

The "Trade-offs Considered" section exists so reviewers and implementers can see that the author actively considered staying with the status quo before committing to the change. An absent G5 entry creates the impression that the carve-out removal was treated as obvious, when in fact there is a legitimate cost side (Plan still has to enumerate and classify each violation before any per-line treatment decision is safe to execute). An implementer could interpret DKR5's deferred-to-Plan enumerate-and-classify step as signaling the design is less confident than the other decisions.

## Recommended fix

Add a brief G5 subsection to "Trade-offs Considered":

```
### G5: Keep path carve-outs in place (rejected)

Leaves the lint blind to the carve-out file class indefinitely; every future
prose touch in a carved-out path silently bypasses the rule. Per
`research/q07-codebase.md`, with carve-outs disabled and inline markers
active the violation count drops to zero, so the structural cost of removal
is paid entirely at Plan-time enumeration, not at a runtime enforcement
regression. Status quo rejected.
```

(Exact wording at the author's discretion; the key is that the alternative is named and disposed of.)
