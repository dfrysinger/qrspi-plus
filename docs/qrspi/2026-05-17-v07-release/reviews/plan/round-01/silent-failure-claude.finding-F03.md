---
finding_id: R1-F03
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L519-L526]
artifact: plan
round: 1
reviewer: silent-failure-claude
---

T15's pre-DONE self-check is explicitly advisory: "The pre-DONE self-check subsection states the scan is advisory, runs one combined pass, applies the internal-ID rules to all edited files and the evergreen-markdown rules to edited markdown only, and requires explicit DONE-report acknowledgment for any retained hit." The test expectation at line 597–598 confirms: "A retained hit with no acknowledgment still proceeds to commit (advisory contract holds) and the unacknowledged hit is surfaced to the reviewer through the DONE-report channel."

The critical gap is that "surfaced to the reviewer through the DONE-report channel" is undefined in terms of how reviewers are guaranteed to see it. The plan describes the DONE-report as the surfacing mechanism but does not specify: (a) whether the reviewer is dispatched with the DONE-report as a companion parameter, or (b) whether the reviewer reads the DONE-report independently, or (c) whether this "surfacing" is merely that the report exists somewhere on disk.

If the DONE-report channel is not structurally connected to the reviewer dispatch (i.e., if the reviewer is not given the DONE-report as a companion), then an unacknowledged hygiene hit is "surfaced" only in the sense that a file exists on disk — the reviewer will not see it unless the reviewer explicitly reads that file. This is a silent failure by design: the spec says the reviewer has visibility, but the mechanism for that visibility is not defined, so the reviewer may complete without seeing the unacknowledged hit.

Test expectations for T18 also do not specify that the reviewer dispatch for the next round will include the DONE-report body as a companion parameter. There is no test expectation asserting "the DONE-report is passed to the reviewer dispatch so the reviewer can observe unacknowledged hits."

The fix is to add a test expectation that specifies the concrete mechanism: either (a) the DONE-report body is passed as a companion parameter in the per-task reviewer dispatch, or (b) the reviewer's dispatch site explicitly lists the DONE-report path in the dispatch so the reviewer reads it as part of its pre-flight. Without this specification, "reviewer visibility" is a nominal guarantee, not an enforced one.
