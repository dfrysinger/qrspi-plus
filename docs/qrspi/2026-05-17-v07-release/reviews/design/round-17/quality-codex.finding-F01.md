---
finding_id: R17-F01
severity: medium
change_type: correctness
referenced_files: [design.md:L46-L53]
artifact: design
round: 17
reviewer: quality-codex
---

G1 defines conditional routing entries under a `condition:` mapping, but the very next paragraph says the schema supports `when:` predicate clauses and later explains behavior in terms of `condition:` again. That leaves the actual field name ambiguous at the design-contract level, so Structure/Plan could implement different shapes and still each think they followed Design. Fix by choosing one canonical key (`condition:` or `when:`) and using that same name consistently in the schema example, prose, and downstream tests.
