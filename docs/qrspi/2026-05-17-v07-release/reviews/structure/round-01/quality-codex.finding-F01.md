---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L16-L18, docs/qrspi/2026-05-17-v07-release/structure.md:L141-L157, docs/qrspi/2026-05-17-v07-release/design.md:L94-L105]
artifact: structure
round: 1
reviewer: quality-codex
---

The Slice 1 file map tells `scripts/run-codex-review.sh` to delegate with `run-third-party-llm.sh --provider codex --transport-type codex-broker`, but the interface section and approved design make `transport_type:` a provider-config field resolved from `config.md`, not a CLI flag. If implemented from the file map, the shim will either pass an unsupported flag or create a second transport-selection surface that contradicts the universal dispatcher contract. Fix: remove `--transport-type codex-broker` from the shim responsibility and state that the `codex` provider entry carries `transport_type: codex-broker`.

