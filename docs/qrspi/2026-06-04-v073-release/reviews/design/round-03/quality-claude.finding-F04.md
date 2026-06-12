---
finding_id: R3-F04
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-06-04-v073-release/design.md]
artifact: design
round: 3
reviewer: quality-claude
---

The design does not include a consolidated test-strategy section naming the test types and explaining what is verified at each level — a requirement of the design-quality checks ("it names the test types (unit, integration, contract, e2e) and explains what's being tested at each level"). The testing approach is embedded in per-goal Acceptance sections using informal terms: "bats coverage", "bats unit test", "bats lint test", "synthetic verifier dispatch", and "meta-acceptance via self-host". These collectively describe four tiers — unit-level bats tests against script fixtures; lint/structural bats tests for artifact-wide properties; synthetic integration-style dispatch tests for end-to-end script chains; and self-host meta-acceptance as the regression backstop — but these tiers are never named, consolidated, or mapped to what each verifies. A reader cannot determine from design.md whether integration tests are considered a distinct test level or how self-host meta-acceptance relates to the regression suite referenced in G9. A one-paragraph design-level test strategy (e.g., under `## Cross-Goal Decisions` or as a standalone `## Test Strategy` section) that names the four tiers and maps each to its subject would satisfy the check without adding scope. No new test commitments are required — the information is present but needs to be surfaced in consolidated, named form.
