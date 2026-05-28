---
finding_id: R18-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L270-L272, docs/qrspi/2026-05-17-v07-release/design.md:L295]
artifact: design
round: 18
reviewer: quality-claude
---

G5's routing matrix designates `qrspi-research-specialist` as "Cheap-model eligible (with post-output citation-density validation)." The recommendation at line 271 states: "on a below-threshold result, re-runs the same prompt on the trusted model." The test at line 295 refers to "the configured floor." Neither the G1 schema design nor any other part of this design document specifies:

- Which config block carries the citation-density floor value (it is not in `model_routing:`, `providers:`, or any defined `config.md` block).
- What the default floor value is.
- What "citation density" means computationally (citations-per-paragraph ratio? total citation count? presence of at least one citation per finding?).
- Which dispatch site runs the post-output validator and how it invokes the re-run.

Plan authors writing the G5 task must invent a new config key, a default, and a computational definition to implement the post-output validator. These are design-level decisions that affect the config.md schema (which G1 owns) and the dispatch-site contract (which G2 + G5 own). Leaving them undefined in the design creates avoidable ambiguity that will either block Plan or produce an ad-hoc schema extension inconsistent with G1's schema.

To fix: add a subsection to G5 (or a note in G1's provider-configuration block) that specifies (a) the config key name and location for the citation-density floor, (b) the default value, and (c) the computational definition the dispatch-site adapter uses to score the specialist's output. If the exact formula is not yet decided, state the decision point explicitly so Plan authors know they need to resolve it and approve it before implementation.
