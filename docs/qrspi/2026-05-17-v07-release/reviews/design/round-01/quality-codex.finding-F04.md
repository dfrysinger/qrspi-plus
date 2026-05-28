---
finding_id: R1-F04
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L330-L335, docs/qrspi/2026-05-17-v07-release/design.md:L892-L898, docs/qrspi/2026-05-17-v07-release/design.md:L1048-L1052]
artifact: design
round: 1
reviewer: quality-codex
---

The design's cross-cutting summaries say the G7/G18 hygiene contract has "a CI BATS test as a backstop" and that the BATS backstop catches both internal-ID leaks and evergreen markdown tokens. But the G7 section only specifies an implementer pre-DONE self-check and design-level tests; it does not define a CI BATS backstop for QRSPI internal IDs. G18 defines `tests/unit/test-no-version-tokens-in-prose.bats`, but that only covers release/stale-reference tokens.

Downstream Plan will either omit the G7 CI backstop or invent one from the summary. Fix by making the contract explicit: either add a G7 BATS/CI test that scans non-exempt shipped surfaces for internal IDs, or narrow the Decision 4 and cross-cutting test strategy wording so only G18 has the CI BATS backstop while G7 is enforced by the implementer self-check plus reviewer visibility.
