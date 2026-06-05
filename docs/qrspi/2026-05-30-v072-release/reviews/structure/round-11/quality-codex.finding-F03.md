---
finding_id: quality-codex-F03
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md:40-47
  - docs/qrspi/2026-05-30-v072-release/design.md:2194-2198
  - docs/qrspi/2026-05-30-v072-release/structure.md:918-924
  - docs/qrspi/2026-05-30-v072-release/structure.md:1066-1080
  - docs/qrspi/2026-05-30-v072-release/structure.md:2990-3022
artifact: structure
round: 11
reviewer: quality-codex
---

The Dispatch Manifest schema example uses vendor IDs `anthropic` and `openai`, but the rest of the design/structure contracts use `claude` and `openai-codex` as the concrete routing identifiers. `dispatch-companion.sh` also names `openai-codex` as the current third-party branch. This makes the manifest schema ambiguous at the routing boundary. Normalize the manifest example and surrounding schema language to the same vendor identifiers used by `model_routing`, `_resolve-lib.sh`, and `dispatch-companion.sh`.

(Persisted by orchestrator from Codex chat-only return.)
