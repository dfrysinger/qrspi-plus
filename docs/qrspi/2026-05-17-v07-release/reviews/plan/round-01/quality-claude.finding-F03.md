---
finding_id: R1-F03
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L994-L1013, docs/qrspi/2026-05-17-v07-release/structure.md:L119-L130]
artifact: plan
round: 1
reviewer: quality-claude
---

Task 34 creates `scripts/g4-section-anchor-manifest.json` as a required output — the manifest JSON that enumerates the three indexed artifact pairs and serves as the single registry the refresh script (T35) reads. The task description explicitly states "The refresh script in T35 reads this manifest to know which artifacts to regenerate." The manifest file is therefore a load-bearing runtime artifact that T35 depends on.

However, `scripts/g4-section-anchor-manifest.json` does not appear in `structure.md`'s Slice 7 file map. The Slice 7 Mechanism B table lists `skills/reviewer-protocol/SKILL.anchors.json`, `skills/using-qrspi/SKILL.anchors.json`, `skills/plan/SKILL.anchors.json`, `scripts/g4-section-anchor-refresh.sh`, `skills/structure/SKILL.md`, and the three test pins — but not the manifest file that underpins T35's discovery mechanism.

This is a design/structure traceability gap. The structure.md file map is the canonical inventory of files the release creates or modifies; a consumer or auditor reading structure.md to understand the G4 Mechanism B surface would not know the manifest exists. Implementers following structure.md as their authoritative source could omit the manifest, leaving T35 with no discovery input and silently broken.

Resolution: add `scripts/g4-section-anchor-manifest.json` to the Slice 7 Mechanism B table in `structure.md` with action "Create" and a responsibility entry describing its role as the single registry of indexed artifact pairs consumed by `scripts/g4-section-anchor-refresh.sh`.
