---
finding_id: R15-F04
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L1192-L1212]
artifact: design
round: 15
reviewer: quality-claude
---

The per-goal test expectations summary table (lines 1192–1212) lists test types using only "acceptance", "acceptance, boundary", and "acceptance, integration" — no "unit" test type appears anywhere. Yet multiple goals explicitly call for BATS unit tests in their design-level test strategy sections:

- G8: "BATS-pin presence test" and "Owns-defers content test" (line 444–447) — these are BATS unit tests
- G9: "Vocabulary-presence test" BATS pin (line 486)
- G13: slug-extraction path test (line 666–668) — BATS unit test
- G14: "Helper-self test" (line 713) — BATS unit test
- G15: "Promotion test" with fixture (line 766–770) — BATS unit test
- G17: "Workflow-presence test" and "Job-shape test" (lines 837–843)
- G18: "Markdown-positive test" (line 921–926) — BATS unit test

The summary table conflates unit tests with acceptance tests or omits the unit category entirely. An implementer using this table for test-planning will miss the signal that several goals require fast unit-level BATS tests as distinct from acceptance tests that exercise the pipeline end-to-end.

The fix is to add "unit" as a test type in the table where applicable. The goals listed above should show "acceptance, unit" or "unit" rather than "acceptance" alone. The cross-cutting test strategy section heading "The Test phase should verify the following end-to-end behaviors" should also note that design-level unit BATS pins are a separate tier from the phase-level acceptance tests described in that section.
