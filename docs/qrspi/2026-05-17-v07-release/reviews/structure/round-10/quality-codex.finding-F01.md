---
finding_id: R10-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L165-L195, docs/qrspi/2026-05-17-v07-release/design.md:L92-L109]
artifact: structure
round: 10
reviewer: quality-codex
---

The `scripts/run-third-party-llm.sh` interface is incomplete: it says `--provider` matches a provider entry in the per-run `config.md`, and Design requires provider configuration to resolve from `config.md` at call time, but the call surface has no `--config`, `--artifact-dir`, or equivalent parameter that tells the script which run's `config.md` to read. Since QRSPI can have multiple artifact directories and resumed runs, implementers cannot reliably locate the intended configuration from `--provider`, `--model`, stdin, and `--output-file` alone.

Fix: add an explicit config-location input to the interface and file map, such as `--config-file <path>` or `--artifact-dir <path>`, then update the related tests to cover provider resolution against that path.
