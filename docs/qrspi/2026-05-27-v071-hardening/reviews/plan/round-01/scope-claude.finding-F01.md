---
finding_id: BD-1
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 1
reviewer: scope-claude
---

## Task 3 Description leaks Implement-layer algorithm pseudocode

> "The new function tracks code-fence state so that heading-shaped lines inside fenced blocks are not treated as section boundaries; it exits at the next out-of-fence section boundary (a same-level heading outside a fence) or at EOF; it includes the anchor line in its output..."

"Tracks code-fence state" describes an internal state-machine design. The exit-condition enumeration reads as algorithm pseudocode. Plan DEFERS algorithm internals to Implement; the observable contract belongs in test expectations (which already pins the behaviors). Replace with behavioral framing such as "a fence-aware extraction function that correctly handles heading-shaped lines inside code fences."
