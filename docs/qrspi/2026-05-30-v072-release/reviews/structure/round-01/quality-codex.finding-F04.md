---
finding_id: R1-F04
severity: high
change_type: correctness
artifact: structure
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md, docs/qrspi/2026-05-30-v072-release/design.md]
round: 1
reviewer: quality-codex
---

The fan-in audit interface in `structure.md` conflicts with `design.md`: structure
defines `fan-in-audit.json` (Interface 11 in the Interfaces section), while CD-4
locks the filename as `.verifier-fan-in-audit.json` (dotfile prefix + full name).
This filename contract mismatch can break downstream consumers and tests that
verify the locked path.

Originally hand-persisted from chat-only Codex dispatch (per qrspi-plus issue #288).
