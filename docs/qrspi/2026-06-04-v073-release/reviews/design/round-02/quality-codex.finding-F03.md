---
finding_id: R2-F03
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-06-04-v073-release/design.md]
artifact: design
round: 2
reviewer: quality-codex
---

The design does not provide a design-level test strategy that explicitly names and scopes unit, integration, contract, and end-to-end testing. Current acceptance bullets are mostly implementation checks (e.g., bats/grep fixtures) but do not map test layers to architectural risks. Add a dedicated testing strategy section that states what each test type validates for this design.
