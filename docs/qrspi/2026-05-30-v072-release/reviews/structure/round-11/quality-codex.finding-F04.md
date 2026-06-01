---
finding_id: quality-codex-F04
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md:1058-1085
  - docs/qrspi/2026-05-30-v072-release/design.md:1091-1097
  - docs/qrspi/2026-05-30-v072-release/design.md:1350-1352
  - docs/qrspi/2026-05-30-v072-release/structure.md:961-968
  - docs/qrspi/2026-05-30-v072-release/structure.md:977-1002
artifact: structure
round: 11
reviewer: quality-codex
---

The `scripts/round-prepare.sh` interface block contradicts both design.md and the later verbatim block in structure.md. The interface says exit 10 means "SHA already matches (idempotent skip)" and that success writes `<output-dir>/round-NN-commit.txt`; design says exit 10 is missing `--implementer-commit`, exit 12 is "passed SHA equals prior anchor," and the anchor write is `<output-dir>/../round-NN-commit.txt`. Align the interface block with the design recovery table and anchor path so Plan/Implement have one concrete contract.

(Persisted by orchestrator from Codex chat-only return.)
