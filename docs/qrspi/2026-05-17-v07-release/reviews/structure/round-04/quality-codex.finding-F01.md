---
finding_id: R4-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L101-L108, docs/qrspi/2026-05-17-v07-release/design.md:L211-L238]
artifact: structure
round: 4
reviewer: quality-codex
---

The G4 structure turns the accepted narrow-Reads mechanism into a placeholder-only follow-up. Design requires Structure/Plan to define the section-anchor index details: a JSON-shaped index per stable artifact, refresh behavior when the source changes, consumers that use line ranges, and a verification that fetched slices are byte-identical to source slices. In the file map, Slice 7 only creates the cache probe, the probe script, a `skills/structure/SKILL.md` placeholder for a future Path-B follow-up, and a no-summary-shim test. That leaves no concrete file/module for index generation or refresh, no storage path for the index artifacts, and no consumer/test mapping for the byte-identical narrow-Read contract.

This misrepresents the approved design: the design accepts "Both A and B" and explicitly says the detailed site-by-site mechanism is deferred to Structure and Plan, not to a future release. Fix by adding the concrete Structure-level components for the section-anchor index surface (for example, index file location/format, generator or refresh owner, consumer update points, and tests that verify line-range Reads are byte-identical), or by changing the upstream Design/Phasing artifacts to explicitly defer Mechanism B out of the current release.
