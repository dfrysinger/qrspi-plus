---
finding_id: R9-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L338-L348, docs/qrspi/2026-05-17-v07-release/design.md:L984-L994]
artifact: design
round: 9
reviewer: quality-claude
---

G7's `id_hygiene_exempt:` per-task frontmatter field is introduced but its enforcement mechanism is inconsistent with G7's own "advisory, not blocking" design.

G7 (lines 338–344) introduces a path-shaped carve-out mechanism with three layers:

> - `docs/qrspi/**` — the artifact directory IS QRSPI's internal addressing.
> - Reviewer agent files (`agents/qrspi-*-reviewer.md`) — these document the finding-ID schema.
> - Test fixtures and BATS tests that explicitly pin the ID format, opted in via per-task frontmatter `id_hygiene_exempt: [<paths>]`.

Decision 10 (lines 984–994) lists `id_hygiene_exempt: [<paths>]` as one of the new task-spec fields with safe defaults.

But the rest of the G7 design says the self-check is **advisory** and "the implementer either removes the token (most cases) or explicitly acknowledges the hit in the DONE report with reasoning" (line 336). The carve-out test (line 362) only covers the path-prefix carve-out (`docs/qrspi/**`), not the per-task frontmatter exempt list. And the rejected "Pre-commit Git hook" option is rejected partly because "Blocking creates an escape-hatch arms race in spec frontmatter" (line 348) — which is exactly what `id_hygiene_exempt: [<paths>]` is.

The inconsistency: if the check is advisory and uses DONE-report acknowledgment to handle false positives, the per-task frontmatter exempt field is unnecessary (and is precisely the "escape-hatch arms race in spec frontmatter" the design rejected for the blocking option). If the check is blocking enough to need a frontmatter exempt list, then "advisory" is the wrong framing.

This matters for Plan because Decision 10 commits Plan to treating `id_hygiene_exempt: [<paths>]` as an additive task-spec field, and Plan will then need to wire its absence-as-default semantics into the implementer self-check — but the self-check is advisory and consumes the field only to know "this path is allowed to acknowledge silently rather than acknowledge explicitly," which is a difficult contract for Implement to enforce.

Suggested fix: pick one resolution. Either (a) drop the `id_hygiene_exempt:` frontmatter field from Decision 10 and rely entirely on path-shaped carve-outs plus DONE-report acknowledgment (consistent with "advisory"); or (b) acknowledge that frontmatter exemption is a blocking-style mechanism and reframe G7 as blocking-with-exempt-list (and revisit the rejection rationale for the pre-commit Git hook). The current text wants both.
