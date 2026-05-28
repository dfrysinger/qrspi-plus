---
finding_id: R5-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/phasing.md
  - docs/qrspi/2026-05-17-v07-release/research/summary.md
  - docs/qrspi/2026-05-17-v07-release/future-research-summary.md
artifact: phasing
round: 5
reviewer: quality-codex
---

`phasing.md` overstates the pruning result for research artifacts. The file says both that `research/summary.md` is "kept intact as full corpus" and that there is "no future content leaked into current-phase artifacts," but those two claims conflict once Q21/G16 is deferred: the current `research/summary.md` still contains the combined `Q13, Q14, Q21` section, and `future-research-summary.md` points back to that same deferred-Q21 content. As written, downstream readers cannot tell whether the exception is intentional corpus-retention or a failed pruning boundary. Fix by making the exception explicit in `phasing.md` (for example: research corpus is intentionally retained in the current artifact, with future-only pointers duplicated in `future-research-summary.md`) instead of claiming a clean no-future-content split across current artifacts.
