---
finding_id: R3-F02
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L367-L368, docs/qrspi/2026-05-17-v07-release/design.md:L415-L416, docs/qrspi/2026-05-17-v07-release/design.md:L552-L552, docs/qrspi/2026-05-17-v07-release/design.md:L684-L684, docs/qrspi/2026-05-17-v07-release/design.md:L749-L749, docs/qrspi/2026-05-17-v07-release/design.md:L815-L815]
artifact: design
round: 3
reviewer: scope-codex
---

The design repeatedly names exact BATS test file paths to be created, such as `tests/unit/test-parallelize-owns-defers-contains-setup-validation.bats`, `tests/unit/test-implementer-commit-no-scratch.bats`, and `tests/unit/test-ci-workflow-shape.bats`. Design owns the design-level test strategy and the behavior that must be pinned, but per-test-file layout is deferred. Resolve by describing the required BATS pins and their behavioral assertions without committing to exact test filenames; Plan / Implement can choose the file layout.
