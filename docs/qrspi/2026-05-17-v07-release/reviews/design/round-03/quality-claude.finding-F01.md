---
finding_id: R3-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L1061]
artifact: design
round: 3
reviewer: quality-claude
---

The Cross-cutting test strategy → "Hygiene contract (G7 + G18)" subsection contains an internal cross-reference error. The line reads:

> G7 has no CI BATS backstop; G7 enforcement is implementer self-check plus reviewer visibility per Decision 9.

The rationale "G7 has no CI BATS backstop because the carve-outs are too path-shaped to mechanize cheaply" actually lives in Decision 4 ("G7 and G18 share one hygiene contract"), which states explicitly: "A CI BATS test as a backstop (G18 only — G7 is enforced by the implementer self-check plus reviewer visibility, since G7 carve-outs are too path-shaped to mechanize cheaply)."

Decision 9 is "Reviewer agents are not added to the pipeline unless deterministic checks are not enough" — about whether to introduce new reviewer agents, not about G7's enforcement mechanism. A downstream reader who follows the "per Decision 9" pointer to validate the claim will find Decision 9 says nothing about G7's BATS-backstop absence.

Fix: change "per Decision 9" to "per Decision 4" so the cross-reference resolves to the section that actually justifies the claim. Low downstream risk if missed (the claim is still true), but the broken pointer will confuse Phasing/Plan readers who walk the cross-references when deciding which tasks ship together.
