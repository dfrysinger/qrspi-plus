---
finding_id: R5-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L31-L47, docs/qrspi/2026-05-17-v07-release/design.md:L327-L337]
artifact: structure
round: 5
reviewer: quality-codex
---

Slice 2 wires the new Implement-phase test-writer dispatch in `skills/implement/SKILL.md` and updates `agents/qrspi-test-writer.md`, but it never updates `agents/qrspi-implementer.md` for the split-mode contract. The approved design requires the implementer, when dispatched after the test-writer, to treat the prewritten failing tests as the RED input and not author duplicate RED tests. Without a corresponding implementer-agent change, the existing implementer body can still follow its old RED cycle and write its own failing tests, which breaks the intended separation between test authoring and production-code authoring.

Fix: add `agents/qrspi-implementer.md` to Slice 2 with responsibility to recognize split-mode/prewritten RED tests and skip authoring duplicate RED tests, or otherwise define the exact dispatch signal the implementer uses to enter that behavior.
