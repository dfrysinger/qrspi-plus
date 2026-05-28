---
finding_id: R2-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/phasing.md:L29, docs/qrspi/2026-05-17-v07-release/phasing.md:L89]
artifact: phasing
round: 2
reviewer: scope-claude
---

Slice 5's description and replan-gate criterion prescribe wave-boundary behavior, which is DEFERS to Parallelize.

In the Slice 5 description (line 29), the artifact states: "the parallelize layer (wave-boundary treatment of gated tasks)." Naming that Parallelize is involved is within scope — but the corresponding replan-gate criterion (line 89) goes further: "A reference-gated wave-1 task pauses Implement before any wave-2 dependent dispatches, and the approval decision is recorded as a per-task review artifact."

This sentence specifies a concrete wave-sequencing outcome: wave-1 tasks gate wave-2 dispatch. Wave decisions, dependency graphs, and wave-boundary rules are owned by Parallelize per the DEFERS list ("Dependency graph, Wave decisions, branch maps → owned by Parallelize"). Phasing may name the Parallelize layer as a touched layer, but the gate criterion should not dictate the specific wave-boundary behavior — that is Parallelize's call to make when it consumes the Phasing output.

Proposed fix: trim the gate criterion to the observable outcome visible at the Phasing level (e.g. "A reference-gated UI task is demonstrably blocked until a human-gate approval is recorded") and remove the wave-numbering prescription ("wave-1 task pauses Implement before any wave-2 dependent dispatches"). The wave-boundary enforcement mechanism is a Parallelize implementation detail; the gate criterion need only confirm that blocking happens, not specify via which wave number.
