---
finding_id: quality-codex-F01
severity: medium
change_type: coherence
referenced_files:
  - docs/qrspi/2026-05-27-v071-hardening/structure.md
  - docs/qrspi/2026-05-27-v071-hardening/design.md
artifact: structure
round: 1
reviewer: quality-codex
status: applied
---

`structure.md` claims `detect_host()` is the shared mechanism for both G6 and G7b (Interfaces section + diagram), but the File Map only includes `detect_host()` work in `scripts/run-codex-review.sh` (Slice 6) and, for Slice 8, only `agents/*.md`, `config.md`, and a lint test. There is no mapped file/component that actually consumes `detect_host()` at config-load/model-routing selection time as required by design DKR10.

**Resolution:** added Slice 8 row for `skills/using-qrspi/SKILL.md` (G7b focus) documenting how dispatcher prose resolves tier vocabulary against `config.md` `model_routing` using `detect_host()` output. This wires the shared probe to a concrete G7b consumer file.
