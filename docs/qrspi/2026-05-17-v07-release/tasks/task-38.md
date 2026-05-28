---
task: 38
status: approved
pipeline: full
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G12]
dependencies: [T15]
loc_estimate: 80
---

# Task 38: Codify the three commit-hygiene invariants in implementer-protocol so the commit cycle structurally cannot leak the commit-message scratch file

- **Phase:** 1
- **Target files:**
  - `skills/implementer-protocol/SKILL.md` (Modify) — append a `## Commit hygiene invariants` section that declares the three architectural invariants (staging-before-scratch, cleanup-after-commit, worktree-local-exclude) the implementer commit cycle must satisfy, sitting alongside the combined `## Hygiene contract` section authored in Task 15.
- **Dependencies:** T15
- **LOC estimate:** ~80
- **Description:** Adds the three commit-hygiene invariants to `skills/implementer-protocol/SKILL.md` as architectural invariants the implementer commit cycle must satisfy across every commit it produces, eliminating the recurring v0.6 regression where implementers accidentally committed their `.qrspi-commit-msg.txt` scratch file. The new `## Commit hygiene invariants` section declares exactly three invariants and frames them as load-bearing properties the procedure must hold rather than as a literal step-by-step command sequence (the procedure that realizes them is owned by `skills/implement/SKILL.md` and Plan-authored task specs per design G12). Invariant 1 — staging-before-scratch: the staging operation for a commit cycle completes before the commit-message scratch file is written to the worktree, so the scratch file does not exist on disk when staging runs and therefore cannot be accidentally included in that commit. Invariant 2 — cleanup-after-commit: the scratch file is removed after the commit completes and before any subsequent staging cycle begins, so even when the worktree-local exclude is absent (for example, in a worktree set up by a non-QRSPI mechanism), the next staging cycle finds no stale scratch file to include. Invariant 3 — worktree-local-exclude: the scratch file path is excluded via the worktree-local `.git/info/exclude` entry added during worktree setup independently of any per-commit ordering, so `git status` reports remain deterministic between scratch-file write and removal and the target repo's committed `.gitignore` is not polluted with QRSPI internals. The section states explicitly that these three invariants compose — any one alone is fragile — and that the file-based commit-message convention (`git commit -F <scratch>`) is preserved unchanged, honoring the user's global Bash convention against heredocs. The section does not enumerate the literal git command order, does not reauthor the existing pre-DONE self-check from Task 15's `## Hygiene contract` section, and does not duplicate the procedural prose owned by `skills/implement/SKILL.md` — it declares the invariants the procedure must satisfy and points downstream consumers to those sites for the realization details.
- **Test expectations:**
  - The `## Commit hygiene invariants` section exists in `skills/implementer-protocol/SKILL.md` and is positioned alongside (not inside) the combined `## Hygiene contract` section authored in Task 15.
  - The section enumerates exactly three invariants, each named (staging-before-scratch, cleanup-after-commit, worktree-local-exclude) and each stated as an architectural property the implementer commit cycle must satisfy.
  - The staging-before-scratch invariant states that the staging operation completes before the commit-message scratch file is written to the worktree, with the implication that the scratch file cannot be accidentally included in that commit.
  - The cleanup-after-commit invariant states that the scratch file is removed after the commit completes and before any subsequent staging cycle begins, with the implication that a missing worktree-local exclude still cannot strand a stale scratch file for inclusion.
  - The worktree-local-exclude invariant states that the scratch file path is excluded via the worktree-local `.git/info/exclude` entry added during worktree setup independently of any per-commit ordering, with the implication that the target repo's committed `.gitignore` is not polluted with QRSPI internals.
  - The section states explicitly that the three invariants compose and that any one alone is fragile.
  - The section preserves the file-based commit-message convention (`git commit -F <scratch>`) without introducing heredoc-based commit-message authoring.
  - The section does not enumerate the literal git command order and does not duplicate the procedural prose owned by `skills/implement/SKILL.md`.
