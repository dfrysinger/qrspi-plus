---
finding_id: R2-F10
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L1226-L1234]
artifact: plan
round: 2
reviewer: test-coverage-claude
---

T41 test expectations are entirely documentation-shape assertions with no behavioral test and no error-condition test. All eight T41 bullets check that `skills/replan/SKILL.md` "contains a section," "states" promotion rules, "states" skip rules, "states" authoring restrictions, "declares the hand-off report shape," and that `skills/replan/owns-defers.md` "OWNS list contains" and "DEFERS list contains" specific entries.

The behavioral test — "Replan invocation against a mixed-shape future-goals fixture promotes only the fully Formal entry" — is entirely assigned to T42's BATS pin. This is analogous to T31/T32 and T38/T39 above, but in T41's case there is also a missing error-condition test: what happens when T41's section documentation is consulted by the Replan skill for a `future-goals.md` that has NO entries at all (empty file)? The Replan boundary contract says Replan promotes only Formal entries and skips partial-Formal and prose-only Ideas — but the empty-file boundary case is not covered by T42's fixture (which has exactly three entries) and is not mentioned in T41's test expectations.

Additionally, T41's test expectations do not cover the case where a partial-Formal entry has `id:` and `type:` set but is missing `## Problem` specifically (as opposed to missing `## What we know so far` which T42 covers). The T42 fixture exercises one specific missing-subsection variant; the T41 documentation should state that ALL three missing-subsection variants (missing `## Problem`, missing `## Why we care`, missing `## What we know so far`) are individually described as partial-Formal with skip reason naming the specific missing subsection — this is a testable property of the hand-off report shape that T41 declares but T42's single-fixture cannot fully cover.

Add to T41's test expectations: (1) a cross-reference to T42's pin as behavioral coverage, AND (2) a statement that the hand-off report shape described in T41 names the specific missing required subsection for each distinct partial-Formal entry type (missing `## Problem`, missing `## Why we care`, missing `## What we know so far` each produce distinguishable skip reasons).
