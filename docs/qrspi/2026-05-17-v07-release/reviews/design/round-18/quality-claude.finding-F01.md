---
finding_id: R18-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L45-L52, docs/qrspi/2026-05-17-v07-release/design.md:L86]
artifact: design
round: 18
reviewer: quality-claude
---

The G1 routing-schema design includes a `condition:` predicate clause in the schema shape with a test that verifies it parses, yet the design explicitly states "The v0.7 conditional-routing vocabulary is empty; the schema supports `condition:` predicate clauses but no concrete predicate is in scope." No v0.7 goal produces a dispatch site that evaluates a `condition:` predicate. The schema-parse test (line 86) exercises functionality with zero behavioral consumers in this release.

The design's self-aware framing ("Predicates may be added by future goals alongside dispatch-site consumers, so that each new key arrives with a concrete consumer rather than a YAGNI-flavored placeholder") acknowledges the YAGNI concern but misapplies it: the argument is that FUTURE predicate KEYS should arrive with concrete consumers, but the `condition:` SCHEMA SLOT ITSELF is being implemented — with parsing logic and a test — before any concrete predicate or consumer exists in v0.7.

A clean YAGNI-respecting approach would instead state: "Routing entries MAY carry a `condition:` block in a future release; the schema extension point is reserved but not implemented in v0.7." This removes the conditional-routing schema implementation and its parse test from v0.7 scope entirely, leaving only a prose reservation in the schema description. No dispatch site needs to parse a `condition:` key that has no defined behavior.

The scope of the fix: remove the `condition:` schema block definition and its corresponding test (the "Conditional-resolution schema test" at line 86) from v0.7. Add a single prose sentence under the G1 routing schema description noting that conditional predicates are reserved for future goals that introduce both a concrete predicate key and its dispatch-site consumer.
