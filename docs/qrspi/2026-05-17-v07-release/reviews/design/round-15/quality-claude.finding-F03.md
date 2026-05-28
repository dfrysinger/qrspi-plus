---
finding_id: R15-F03
severity: medium
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L607-L611]
artifact: design
round: 15
reviewer: quality-claude
---

G12's design states its first architectural invariant as: "staging runs BEFORE the scratch commit-message file is written to disk, so that within a single commit cycle the scratch file does not exist when staging executes and therefore cannot be accidentally included."

This invariant requires a specific commit sequence: `git add -A` → write scratch file → `git commit -F scratch` → rm scratch file. However, research (Q17, research summary lines 241–256) documents the current commit procedure as a compound step 3: "`git -C <worktree> add -A && git -C <worktree> commit -F .qrspi-commit-msg.txt`" — staging and commit are run as one shell compound command, with the scratch file necessarily already written before step 3 begins (it's written in step 2).

The design calls this invariant an "architectural contract" but does not explain that realizing it requires splitting step 3 of the current procedure into two separate commands: `git add -A` (before scratch file exists), then write scratch file, then `git commit -F scratch`, then rm scratch. Without this explanation, an implementer reading the design and the existing `implementer-protocol/SKILL.md` side-by-side will see a contradiction: the design says stage before writing the file, but the existing step 3 writes the file first and stages+commits in one operation.

The fix is to add a clarifying note under the first invariant explaining the required reordering of the current protocol steps: staging must become a separate step that runs before the Write-tool call that creates the scratch file, and the `git commit -F` call must run as a subsequent step. This makes the implementation change explicit for Plan/Implement rather than leaving the conflict with the existing protocol as an ambiguity.
