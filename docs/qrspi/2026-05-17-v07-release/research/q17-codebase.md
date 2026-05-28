---
status: draft
question_ids: [17]
research_type: codebase
---

# Q17: How does `skills/implementer-protocol/SKILL.md` sequence the steps of its commit procedure, and what does the qrspi-plus repo's `.gitignore` currently exclude from staging?

## Summary

**TL;DR:** `skills/implementer-protocol/SKILL.md` § Commit Before Reporting prescribes a five-step ordered procedure: status check, write commit message to a scratch file, `git add -A && git commit -F`, remove the scratch file, then capture the resulting SHA. The repo's `.gitignore` contains five effective lines excluding the `.worktrees/` directory, the `.vscode/` editor directory, and macOS `.DS_Store` metadata files (both top-level and recursive).

**Key findings:**
- The commit procedure is defined in § Commit Before Reporting at lines 139–151 of `skills/implementer-protocol/SKILL.md`, with the numbered steps at lines 145–149.
- Step 1 is `git -C <worktree> status --porcelain` to confirm there is something to commit (line 145).
- Step 2 writes a multi-line commit message to `<worktree>/.qrspi-commit-msg.txt` via the Write tool; the message MUST reference the round number and (for fix mode) the findings being addressed (line 146).
- Step 3 is `git -C <worktree> add -A && git -C <worktree> commit -F .qrspi-commit-msg.txt` (line 147).
- Step 4 is `rm <worktree>/.qrspi-commit-msg.txt`, with the rationale that the scratch file is not gitignored and would otherwise appear in the next round's diff (line 148).
- Step 5 captures the resulting SHA via `git -C <worktree> rev-parse HEAD` and includes it as `commit_sha:` in the terminal-status report (line 149).
- The procedure cross-references `implement/SKILL.md` § TDD Process step 6's "multi-line message convention" as its source (line 143).
- A nothing-to-commit clause at line 151 directs the agent to report `BLOCKED` or `DONE_WITH_CONCERNS` rather than proceeding silently.
- The `.gitignore` at the repo root is 9 lines, 84 bytes, last modified May 4. It contains three pattern groups: `.worktrees/` (line 1), an "Editor / IDE" group with `.vscode/` (lines 3–4), and a "macOS metadata files" group with `.DS_Store` and `**/.DS_Store` (lines 6–8).

**Surprises:** The .gitignore does NOT exclude `.qrspi-commit-msg.txt` — the scratch file the commit procedure uses — and the procedure explicitly calls this out at line 148 as the reason step 4 (the `rm`) is required.

**Caveats:** Only the repo-root `.gitignore` was inspected. The investigation did not survey `.gitignore` files that may exist in subdirectories or in worktrees, nor global excludes (e.g., `core.excludesFile`).

## Full findings

### Commit-procedure sequencing in `skills/implementer-protocol/SKILL.md`

The commit procedure is the § Commit Before Reporting section, lines 139–151. Its prose preamble (lines 139–141) establishes that the procedure must run before returning a DONE or DONE_WITH_CONCERNS terminal status, framing skipping the commit as a "stale diff" correctness defect.

Line 143 cross-references the source convention: "Procedure (per `implement/SKILL.md` § TDD Process step 6 multi-line message convention)".

The five numbered steps appear at lines 145–149:

1. (line 145) `git -C <worktree> status --porcelain` to confirm there is something to commit.
2. (line 146) Write a multi-line commit message to `<worktree>/.qrspi-commit-msg.txt` using the Write tool. The message MUST reference the round number and (for fix mode) the findings being addressed — example given: `fix(task-NN/round-3): server-side bytes/mime check (closes security-codex.F01)`.
3. (line 147) `git -C <worktree> add -A && git -C <worktree> commit -F .qrspi-commit-msg.txt`
4. (line 148) `rm <worktree>/.qrspi-commit-msg.txt` — parenthetical states "the scratch file is not gitignored and you don't want it in the next round's diff".
5. (line 149) Capture the resulting SHA via `git -C <worktree> rev-parse HEAD`, include it as `commit_sha:` in the terminal-status report.

A trailing nothing-to-commit clause (line 151) tells the agent to report `BLOCKED` or `DONE_WITH_CONCERNS` with explanation when no edits resulted, and notes that "the orchestrator's HEAD-advanced verification will fail-loud regardless".

The procedure is also referenced from two adjacent sections:
- § Self-Review (shared) discipline bullet at line 122: "Did I commit the round's changes? (`git -C <worktree> status --porcelain` empty AND `git -C <worktree> rev-parse HEAD` distinct from the round's base commit) — see § Commit Before Reporting".
- § Done Signal item 5 at line 135: requires `git -C <worktree> status --porcelain` empty AND `git -C <worktree> rev-parse HEAD` to be a NEW SHA distinct from the base commit (round 1) or the prior round's commit (fix rounds).

The § Report Format five-line brief at lines 159–165 includes a `Commit:` line carrying the full SHA when a commit was produced, and the literal `N/A` otherwise. Line 173 codifies that `Status: DONE` with `Commit: N/A` is a contract violation.

### `.gitignore` contents at qrspi-plus repo root

Path: `/Users/dfrysinger/Documents/claude-workspace/qrspi-marketplace/qrspi-plus/.gitignore`. Size: 84 bytes. 9 lines total (including blank line and comments). Last modified May 4 23:32.

Line-by-line:

| Line | Content | Effect |
|------|---------|--------|
| 1 | `.worktrees/` | Excludes the `.worktrees/` directory at any depth |
| 2 | *(blank)* | — |
| 3 | `# Editor / IDE` | Comment header |
| 4 | `.vscode/` | Excludes `.vscode/` editor directory |
| 5 | *(blank)* | — |
| 6 | `# macOS metadata files` | Comment header |
| 7 | `.DS_Store` | Excludes top-level `.DS_Store` |
| 8 | `**/.DS_Store` | Excludes `.DS_Store` at any nested depth |
| 9 | *(blank — trailing newline)* | — |

Three pattern groups in total:
- **Worktree directory:** `.worktrees/` — the implementer-protocol's `<worktree>` references resolve into this excluded directory.
- **Editor / IDE:** `.vscode/`.
- **macOS metadata files:** `.DS_Store` and `**/.DS_Store`.

The `.qrspi-commit-msg.txt` scratch file path referenced by the commit procedure's step 2 is NOT present in `.gitignore`; the commit procedure's step 4 (`rm`) is therefore the only mechanism preventing the scratch file from surfacing in subsequent diffs. This is stated explicitly in the parenthetical at line 148 of the SKILL.
