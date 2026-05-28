---
task: 39
status: approved
pipeline: full
task_type: code
model: opus
phase: 1
goal_ids: [G12]
dependencies: [T13, T38]
loc_estimate: 120
---

# Task 39: Implement-skill worktree-setup appends scratch path to worktree-local exclude and a BATS pin asserts the three commit-hygiene invariants hold across a representative implementer commit cycle

- **Phase:** 1
- **Target files:**
  - `skills/implement/SKILL.md` (Modify) — extend the per-task worktree-setup step so that during worktree creation it appends `.qrspi-commit-msg.txt` to `<worktree>/.git/info/exclude`, independent of any per-commit ordering, satisfying the worktree-local-exclude invariant declared in Task 38's `skills/implementer-protocol/SKILL.md` section.
  - `tests/unit/test-commit-hygiene-invariants.bats` (Create) — author the BATS pin that simulates a representative implementer commit cycle against a fixture worktree and asserts the three commit-hygiene invariants from Task 38 observably hold (scratch file absent from any committed tree, `.git/info/exclude` carries the entry after worktree setup, scratch file absent from the worktree after the cycle completes, file-based commit-message mechanism used rather than heredoc, and the cleanup invariant still holds when the worktree-local exclude is artificially emptied).
- **Dependencies:** T13, T38
- **LOC estimate:** ~120
- **Description:** Realizes the worktree-local-exclude invariant from Task 38 inside `skills/implement/SKILL.md`'s worktree-setup step and pins all three commit-hygiene invariants with a BATS test that exercises a representative implementer commit cycle end-to-end. The `skills/implement/SKILL.md` edit extends the existing worktree-setup step so that, during per-task worktree creation, the orchestrator appends the line `.qrspi-commit-msg.txt` to the new worktree's `<worktree>/.git/info/exclude` file (creating the file if it does not exist). This append is independent of any per-commit ordering — it happens once at worktree creation time and is the structural defense that satisfies the worktree-local-exclude invariant for every commit cycle the implementer runs in that worktree, including the first one. The edit preserves the file-based commit-message convention (`git commit -F <scratch>`) unchanged and does not reorder existing per-commit steps; the staging-before-scratch and cleanup-after-commit invariants are realized by the existing commit procedure prose, which Task 38 already declared as the load-bearing surface. The BATS pin at `tests/unit/test-commit-hygiene-invariants.bats` constructs a fixture git worktree set up the same way Implement sets up implementer worktrees, runs a representative implementer commit cycle against it (write scratch file, `git add -A`, `git commit -F <scratch>`, cleanup), and asserts five observable properties that together prove the three invariants hold. The pin asserts that no committed tree in the cycle contains the `.qrspi-commit-msg.txt` blob (staging-before-scratch invariant observably held); that `<worktree>/.git/info/exclude` carries the `.qrspi-commit-msg.txt` entry immediately after worktree setup (worktree-local-exclude invariant observably held); that the scratch file is absent from the worktree after the cycle completes (cleanup-after-commit invariant observably held); that the commit was authored via `git commit -F <scratch>` (file-based commit-message convention preserved, no heredoc); and that with the worktree-local exclude artificially emptied between cycles, a subsequent staging cycle still finds no stale scratch file (cleanup-after-commit invariant remains load-bearing on its own when the worktree-local exclude is absent). The pin runs under the unit BATS surface so the Slice 3 `bash32` job executes it.
- **Test expectations:**
  - The worktree-setup step in `skills/implement/SKILL.md` instructs the orchestrator to append `.qrspi-commit-msg.txt` to `<worktree>/.git/info/exclude` during per-task worktree creation, creating the file when absent.
  - The append happens once at worktree creation time independent of any per-commit ordering, satisfying the worktree-local-exclude invariant for every commit cycle the implementer runs in that worktree including the first one.
  - The worktree-setup edit preserves the file-based commit-message convention (`git commit -F <scratch>`) and does not reorder the existing per-commit steps owned by `skills/implementer-protocol/SKILL.md`.
  - `tests/unit/test-commit-hygiene-invariants.bats` exists and runs under the unit BATS surface.
  - The pin constructs a fixture git worktree configured the same way Implement configures implementer worktrees and runs a representative implementer commit cycle against it.
  - The pin asserts no committed tree in the cycle contains the `.qrspi-commit-msg.txt` blob, observably proving the staging-before-scratch invariant held.
  - The pin asserts `<worktree>/.git/info/exclude` carries the `.qrspi-commit-msg.txt` entry immediately after worktree setup, observably proving the worktree-local-exclude invariant held.
  - The pin asserts the scratch file is absent from the worktree after the cycle completes, observably proving the cleanup-after-commit invariant held.
  - The pin asserts the commit was authored via `git commit -F <scratch>` rather than via heredoc, preserving the user-global file-based commit-message convention.
  - The pin asserts that with the worktree-local exclude artificially emptied between cycles, a subsequent staging cycle still finds no stale scratch file — demonstrating the cleanup-after-commit invariant remains load-bearing on its own when the worktree-local exclude is absent.
