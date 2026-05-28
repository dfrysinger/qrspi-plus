---
finding_id: R10-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L61-L62, docs/qrspi/2026-05-17-v07-release/design.md:L866-L877, docs/qrspi/2026-05-17-v07-release/phasing.md:L70-L74]
artifact: structure
round: 10
reviewer: quality-codex
---

The Structure file weakens the G17 bash-3.2 backstop test below the approved Design and Phasing contract. Design explicitly requires an Option-A'-load-bearing test with a bash-4+ construct not enumerated by the Option B ban-list, proving the docker `bash32` job catches compatibility failures that the grep list misses. Phasing repeats that the docker job must surface new bash-4 constructs not enumerated by the ban-list. Structure instead defines `test-bash32-runtime-coverage.bats` only around constructs already on the ban-list, which no longer proves that Option A' is the true backstop when Option B misses something.

Fix: restore a Structure-owned test entry for the non-enumerated-construct case, or expand `test-bash32-runtime-coverage.bats` so it includes both ban-list currency checks and the Design-required Option-A'-load-bearing fixture.
