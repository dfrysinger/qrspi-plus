---
verifier_status: passed
score: 75
actual_model: unknown
defect_class: internal-inconsistency
---
Verified L396, L404, L405 in design.md. Solution step 2 explicitly states the
wave-dispatch step writes the **full {integration-base, task-tips...} set** to
the sidecar and that validation compares the **full parent set, with no
parent[0]-stripping normalization**. The dependencies bullet at L404 matches.

The edge-case bullet at L405 quoted in the finding is present verbatim and does
assert `expected = {task-tip}` and frames the integration-base-inclusion
question as an open "Either … or … Choose the latter" deliberation. Both
statements are stale under the now-locked solution: the expected set per the
sidecar contract is `{integration-base, task-tip}`, not `{task-tip}`, and the
deliberation has already been resolved upstream in the same section.

This is a real internal inconsistency within a single design subsection, with a
plausible implementer-confusion path (reading L405 in isolation and coding
`expected = {task-tip}` produces a guaranteed mismatch on every single-task
wave). The bullet's own follow-on clause partially self-corrects via prose, but
not via a directive — so a reader cannot tell whether the assertion or the
solution body governs. Worth fixing; not catastrophic since the solution body
is the load-bearing statement.
