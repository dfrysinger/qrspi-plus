---
finding_id: R9-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L61-L62, docs/qrspi/2026-05-17-v07-release/design.md:L824-L829, docs/qrspi/2026-05-17-v07-release/design.md:L873-L877]
artifact: structure
round: 9
reviewer: quality-codex
---

The structure artifact assigns `tests/unit/test-bash32-runtime-coverage.bats` to a `declare -A` fixture and says the "ban-list-only scan misses it." That contradicts the approved CI design: `declare -A` is explicitly included in Option B's supplemental ban-list, while the load-bearing Option A' test must use a bash-4+ construct that is **not** enumerated by that ban-list (the design gives `${!array[@]}` as the example). As written, the file map would lead Plan/Implement to build a test that proves only that the bash 3.2 lane rejects a known banned construct, not that the runtime lane catches constructs the grep layer misses.

Fix: change the structure entry or add a separate test entry so the load-bearing runtime-coverage pin uses a non-ban-listed bash-4+ construct for the Option-A' assertion, while keeping ban-listed constructs such as `declare -A` under the supplemental Option-B coverage.
