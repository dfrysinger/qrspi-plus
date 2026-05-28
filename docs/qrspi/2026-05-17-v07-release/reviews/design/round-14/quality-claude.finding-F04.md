---
finding_id: R14-F04
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L192-L198]
artifact: design
round: 14
reviewer: quality-claude
---

The G4 Mechanism A section describes "a Plan-time spike" to resolve whether Claude Code Agent-tool dispatches already auto-cache stable prefixes, but the spike's scope and outputs are underspecified for an implementer. Specifically:

- "A Plan-time spike resolves the hypothesis" — this implies a spike task is needed in the plan, but the design does not say who authors the spike, what its acceptance criteria are, or what happens to the G4 design if the spike finds caching is NOT happening (it says "G4 scope expands accordingly" but does not define the expansion boundary).

The branching behavior (cache already works → verification only; cache not working → also add cache-control markers at the SDK boundary) is documented, but the spike is presented as a Plan concern without giving Plan enough contract to author the spike task. A downstream Plan author reading this section does not know: what does the spike do, what does success or failure look like, and which tasks are blocked on the spike result?

Proposed fix: add a sentence clarifying the spike's deliverable — for example: "The spike task reads response-level usage metadata from a representative Agent dispatch and checks for `cache_read_input_tokens > 0`. Success (cache hits confirmed) means Mechanism A on this surface is verification-only. Failure (no cache hits) means the G4 scope for this surface expands to include adding `cache_control` breakpoints at the SDK boundary before the measurement step."
