---
finding_id: R7-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L689-L701]
artifact: design
round: 7
reviewer: quality-codex
---

The Replan boundary defines a “Formal goal” as requiring `id:`, `type:`, and acceptance criteria, then says Replan promotes only those Formal goals into the next phase’s `goals.md`. That conflicts with the Goals artifact shape used by this pipeline, where goals are problem-framed and downstream verifiability criteria are authored later in Plan. If Structure/Plan follows this design literally, Replan will either refuse to promote otherwise-valid future goals that lack acceptance criteria or will push plan-style acceptance criteria back into `goals.md`.

Fix: replace “acceptance criteria” with the fields that actually make a future goal promotable under the current Goals contract, or explicitly say acceptance criteria live outside `goals.md` and are only used as a future-goals staging signal if that is intentional.
