---
finding_id: R2-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L37-L39]
artifact: design
round: 2
reviewer: quality-codex
---

The G1 routing schema defines conditional predicates as `condition: <predicate-key>: <value>`, which is not a valid YAML shape for `config.md`. A downstream Plan/Structure task following this literally would author malformed configuration even though the same design requires `config.md` to parse valid `model_routing:` and `providers:` blocks. Fix by specifying a concrete parseable shape, for example `condition: {predicate: citation_density_floor, value: 3}` or a nested mapping such as `condition:\n  citation_density_floor: 3`, and state how multiple predicates are represented or forbidden.
