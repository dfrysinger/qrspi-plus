---
finding_id: R2-F08
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L27]
artifact: questions
round: 2
reviewer: quality-claude
---

Q18's "worktree-safe way" phrasing reveals the G13 problem framing.

The question reads: "How does `tests/unit/test-u14-lint.bats` construct its file-path scan and excluded-skill substring check, and how do other BATS tests in `tests/unit/` derive skill identity from paths in a worktree-safe way?" The qualifier "in a worktree-safe way" presupposes the G13 problem: "When BATS runs from a QRSPI integrate worktree, the checkout path itself legitimately contains `/integrate/`, so the test fails even though the in-scope file set is correct." It also presupposes the candidate fix ("scope by skill-name basename extracted from the path under `skills/`, not by substring matching the absolute path").

A researcher reading only Q18 would correctly infer the project has identified a worktree-path collision in u14-lint and is looking for safer path-derivation patterns to copy. That is the G13 fix space.

Recommend neutralizing: "How does `tests/unit/test-u14-lint.bats` construct its file-path scan and excluded-skill substring check, and how do other BATS tests in `tests/unit/` derive skill identity from file paths?" Drop "worktree-safe." The researcher will report the patterns; the safety analysis (under worktree execution, do any of these collide?) becomes the Design step's job.
