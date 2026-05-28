---
finding_id: R2-F02
severity: low
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/phasing.md:L37, docs/qrspi/2026-05-17-v07-release/phasing.md:L98-L99]
artifact: phasing
round: 2
reviewer: scope-claude
---

Slice 7's description and gate criteria name an implementation mechanism ("marker-insertion," "prefix shape and marker placement decision") that belongs to Implement, not Phasing.

The Slice 7 description (line 37) states: "the dispatch layer (prefix shape and marker placement decision)" and the gate criterion (lines 98–99) reads: "If Path B is taken, marker-insertion lands before measurement so subsequent dispatches reflect the marker behavior."

"Prefix shape," "marker placement decision," and "marker-insertion" are implementation-mechanism language — they describe how caching is implemented in the dispatcher, not what the Phasing step needs to demonstrate as a delivery unit. The DEFERS list calls out "Implementation prose, code, hook syntax, subagent dispatch verbs → owned by Implement and downstream skills. Skill-implementation jargon is a boundary-drift signal in phasing.md."

Phasing should describe Slice 7 in terms of what is observably true at the slice boundary: a spike report with measured data and a recorded branch decision. Whether that decision is implemented via marker insertion, prefix shaping, or another mechanism is an Implement concern. The gate criterion's conditional "If Path B is taken, marker-insertion lands before measurement" prescribes an implementation ordering that Plan/Implement own.

Proposed fix: restate the Slice 7 gate criterion as outcome-observable: e.g. "If Path B is taken, the marker behavior is observable in the spike's measurement data" — removing the implementation ordering constraint ("lands before measurement") which is a Plan/Implement scheduling concern, not a Phasing gate criterion.
