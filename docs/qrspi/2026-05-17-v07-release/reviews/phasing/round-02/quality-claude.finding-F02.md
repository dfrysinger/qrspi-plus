---
finding_id: R2-F02
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/phasing.md:L112-L114, docs/qrspi/2026-05-17-v07-release/roadmap.md:L27]
artifact: phasing
round: 2
reviewer: quality-claude
---

The `## Goal-ID Consistency` section of phasing.md (lines 112–114) states: "Every goal ID listed in `roadmap.md` is accounted for above." This claim is factually inaccurate for G16. The roadmap.md lists G16 with `phase: future` and `slice: —` (line 27), meaning G16 is in the roadmap but not assigned to any slice or phase in phasing.md. The slices and phases sections ("above" in the document) contain no mention of G16.

The `## Orphan IDs` section then states "No orphan IDs," which is technically defensible since G16 is deferred rather than orphaned, but the preceding claim that all roadmap IDs are "accounted for above" remains inaccurate — G16 is not accounted for in the slices or phases content above.

A downstream reader consulting phasing.md's consistency claim to verify that all roadmap IDs are traceable through the document would find G16 missing and conclude the claim is wrong. The actual accounting for G16 lives in `future-goals.md`, not in phasing.md.

Resolution: amend the `## Goal-ID Consistency` section to distinguish current-phase IDs from future-deferred IDs. A minimal fix: "Every in-scope goal ID listed in `roadmap.md` is accounted for above. G16 is listed in `roadmap.md` as `future` and is accounted for in `future-goals.md`, not in the slices above." Alternatively, add a brief note in the `## Orphan IDs` section explaining that G16 is deferred (not orphaned) so the "No orphan IDs" statement is clear in context.
