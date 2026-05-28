---
finding_id: R8-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L756-L759, docs/qrspi/2026-05-17-v07-release/design.md:L796-L801]
artifact: design
round: 8
reviewer: quality-codex
---

The Bash 3.2 compatibility surface incorrectly lists `[[`-only constructs as bash-4/5-only syntax. `[[ ... ]]` is supported by Bash 3.2, so this would mislead Plan/Implement into treating valid Bash 3.2 scripts as incompatible and could produce a CI check that rejects acceptable code. Fix: keep the examples to actual bash-4/5-only constructs, such as associative arrays, `mapfile/readarray`, `globstar`, `${var,,}` case conversion, or other features not available in Bash 3.2.
