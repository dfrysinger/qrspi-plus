---
finding_id: R2-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-30-v072-release/design.md:2195-2203, docs/qrspi/2026-05-30-v072-release/design.md:2221-2223, docs/qrspi/2026-05-30-v072-release/design.md:46-54]
artifact: design
round: 2
reviewer: quality-codex
---
G27 D2 defines probe success as "second reviewer vendor is distinct from the primary reviewer vendor," but the probe inputs are host+matrix only, while primary vendor is tier/config-dependent via `model_routing` (CD-1). That makes D2's stated predicate under-specified and inconsistent with D4's runtime fallback-halt behavior. The acceptance text also hardcodes "distinct from the Anthropic-vendor primary," which conflicts with configurable primary-vendor routing. Either (a) define D2 explicitly as host-default-only (not primary-distinct), or (b) pass enough inputs (resolved primary vendor/tier) so D2 can actually enforce the stated predicate, then align D4 + acceptance wording.
