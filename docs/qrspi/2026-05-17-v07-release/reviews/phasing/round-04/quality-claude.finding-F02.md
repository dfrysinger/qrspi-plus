---
finding_id: R4-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/phasing.md:L35-L37]
artifact: phasing
round: 4
reviewer: quality-claude
---

Slice 7 (Caching spike + verify, goal G4) departs from Iron Law 1 — the requirement that every slice is vertical and demonstrable end-to-end — but the departure is not named in the slice description or the Phase 1 PoC justification.

The Iron Law states: "each slice must be demonstrable on its own across every layer it touches." Slice 7's deliverable is "a written deliverable that records the hit-rate behavior" and "a recorded decision," with any follow-up implementation being explicitly conditional ("downstream implementation work is either green-lit-by-measurement or scoped against the gap"). The replan-gate criteria for Slice 7 confirm this: both criteria require only documents (a written deliverable and a recorded decision), not working software spanning multiple layers.

This makes Slice 7 a measurement/spike slice rather than a vertical feature slice. It does not exercise a multi-layer working feature end-to-end the way Slices 1–6 and 8–10 do. The design for G4 itself calls this a "Plan-time spike" to resolve a hypothesis — so the Phasing is correctly representing the design intent. But Iron Law 1 applies to all slices, and departures must be explicitly named with a stated reason.

The Phase 1 PoC justification explains many design decisions (why there is no backend-only Phase 1, why the entire release is a single PoC) but does not name the Slice 7 Iron Law 1 departure. The fix is to add an explicit named departure for Slice 7 in either the Slice 7 description or the Phase 1 PoC justification section — for example: "Slice 7 departs from Iron Law 1: G4 is a measurement spike whose design-phase deliverable is a decision document rather than a working feature. The spike's output gates any implementation work; shipping the spike as its own slice is the correct decomposition for an exploratory goal with a conditional implementation path."
