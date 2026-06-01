---
finding_id: quality-codex-F01
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md:2178-2182
  - docs/qrspi/2026-05-30-v072-release/design.md:2206-2208
  - docs/qrspi/2026-05-30-v072-release/structure.md:57-68
  - docs/qrspi/2026-05-30-v072-release/structure.md:1052-1058
artifact: structure
round: 11
reviewer: quality-codex
---

`structure.md` omits a per-file specification for `scripts/second-reviewer-available.sh`, even though design.md makes it a required new probe script and acceptance requires it to exist and be executable. The File Index lists the surrounding dispatch scripts but not this script, while `_resolve-lib.sh` is described as consumed by it. Add a dedicated per-file block and File Index row for `scripts/second-reviewer-available.sh` with its interface, responsibility, tests, and slice/goal mapping.

(Persisted by orchestrator from Codex chat-only return.)
