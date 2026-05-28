---
finding_id: R4-F02
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L272-L282, docs/qrspi/2026-05-17-v07-release/design.md:L297-L302, docs/qrspi/2026-05-17-v07-release/research/summary.md:L163-L168]
artifact: design
round: 4
reviewer: quality-codex
---

The G6 dispatch design splits test authoring into `qrspi-test-writer` first, then says the existing implementer's TDD cycle runs against the now-existing failing tests, but it does not define the changed protocol boundary needed to make that work. The research summary states the current implementer TDD cycle itself writes and verifies failing tests, while the current `qrspi-test-writer` is Test-phase-only and explicitly does not run tests. The design therefore leaves two incompatible behaviors active: the test-writer is asked to produce failing tests for Implement phase, while the implementer may still try to write its own RED tests under the old cycle, and no component is clearly responsible for verifying the prewritten tests fail before implementation.

Fix: add an explicit Implement-phase contract for both agents. For example: in split mode, `qrspi-test-writer` writes task-spec tests and either the orchestrator or implementer verifies they fail before production code; `qrspi-implementer` skips authoring duplicate RED tests and instead treats the prewritten failing tests as the RED input. Also name the dispatch parameters and protocol edits required for `qrspi-test-writer` to distinguish Implement-phase test generation from Test-phase acceptance-test generation.
