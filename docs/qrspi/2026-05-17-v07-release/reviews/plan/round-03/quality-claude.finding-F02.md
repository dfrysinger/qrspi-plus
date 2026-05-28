---
finding_id: R3-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L1043-L1050]
artifact: plan
round: 3
reviewer: quality-claude
---

T34's Description mentions a "structure.md amendment tracked separately — see `reviews/plan/structure-amendment-needed.md`" when noting that `scripts/g4-section-anchor-manifest.json` is not enumerated in structure.md's Slice 7 file map. However, structure.md is already approved and the Slice 7 Mechanism B table in structure.md does NOT include the manifest file. This is a real gap: structure.md Slice 7 lists the three `.anchors.json` files and the refresh script but not the manifest (`scripts/g4-section-anchor-manifest.json`), yet T34 creates this file and T35 depends on it. The reference to a "structure-amendment-needed.md" side file is not a valid mechanism in the QRSPI pipeline — structure.md amendments go through the structure skill's review loop, not via a sidecar note. Either (a) the manifest file needs to be added to structure.md's Slice 7 table and a structure.md fix should be tracked through the normal mechanism, or (b) the task description should acknowledge this as a known gap without implying the fix is tracked in a non-existent sidecar. The sidecar reference as written is a dangling pointer that an implementer cannot follow.
