---
finding_id: R16-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L45-L53]
artifact: design
round: 16
reviewer: quality-claude
---

The `citation_density_floor` conditional predicate in G1's routing schema cannot be evaluated at dispatch time as designed, because citation density is a property of the research specialist's output rather than an available input before the dispatch decision is made.

The design states (G1, "Conditional predicates" section): "The v0.7 vocabulary defines exactly one legal predicate key: `citation_density_floor` (consumed by G5's research-specialist routing)." G5's matrix entry reads: "qrspi-research-specialist — Cheap-model eligible with citation-density floor — Bounded factual research with explicit citation requirements. A minimum number of citations per claim makes the cheap-model output testable."

The design also says (G1): "When the predicate evaluates true at dispatch time, the routing entry applies; when it evaluates false, the dispatch falls through to the next layer in the precedence chain." The phrase "at dispatch time" is the contradiction. Citation density is a measurement of how many citations appear in a research-specialist's completed output. That output does not exist at the moment the orchestrator must decide which model to route to — the routing decision is made before the dispatch, and the research specialist produces its output after. There is no available citation-density signal to evaluate before the dispatch.

The conditional-resolution test in G1 says: "a routing entry with a `citation_density_floor` predicate dispatches to the cheap path when the predicate is satisfied and falls through to the next precedence layer when not." This test cannot be run unless the predicate has a defined input. Without a mechanism for evaluating the predicate before dispatch, `citation_density_floor` is an unimplemented routing gate that Plan and Implement would need to invent.

To resolve this, the design should specify one of:

1. What the predicate's input is at dispatch time — for example, a static property of the question type or a configurable floor declared in `config.md` (e.g., "route to cheap model only when task spec declares `min_citations: N`"), making it a pre-dispatch routing rule rather than an output-quality check.

2. That `citation_density_floor` is actually a post-dispatch validation step (an output checker that triggers a fallback retry on the trusted path if the specialist's output has too few citations), not a routing predicate. This reframes the mechanism as a result-validator rather than a pre-dispatch router, which would require changing the schema description in G1.

Without this clarification, the `condition.citation_density_floor` schema field is underspecified in a way that blocks implementation.
