---
status: approved
task: 2
phase: 1
pipeline: full
goal_ids: [G2]
task_type: code
model: sonnet
---

# Task 2: Add scratch commit-message filename to committed gitignore

- **Target files:** `.gitignore` (modify), `tests/unit/test-commit-hygiene-invariants.bats` (modify)
- **Dependencies:** none
- **LOC estimate:** ~40
- **Description:** The scratch commit-message file used by the implementer-protocol commit procedure (`.qrspi-commit-msg.txt`) is added to the committed root `.gitignore`. This closes the structural gap where `git add -A` on a fresh clone or worktree stages the scratch file when it happens to exist on disk at staging time, since the prior protection relied on a per-clone `.git/info/exclude` entry that is not present on fresh clones or worktrees. Two new assertions are added to `tests/unit/test-commit-hygiene-invariants.bats`: one verifies the scratch filename appears in the committed `.gitignore`, and one verifies the scratch file is absent from the staged index in a simulated implementer commit flow. The existing `.git/info/exclude` invariant assertions in the same suite are not modified. Dispatch order: test-writer first, implementer second (RED-verification gate between).
- **Test expectations:**
  - The string `.qrspi-commit-msg.txt` appears verbatim in the content of the committed root `.gitignore` file
  - When a scratch commit-message file is present on disk and `git add -A` is executed in a simulated commit flow, the scratch file path does not appear in the resulting staged index
  - The fresh-clone simulation uses a temporary scratch git directory created via `mktemp -d` + `git init` with no `.git/info/exclude` entry for the scratch path; the test asserts the staged-index behavior independently of any per-clone exclude file
  - Existing commit-hygiene invariant assertions in the test suite continue to pass with no changes
