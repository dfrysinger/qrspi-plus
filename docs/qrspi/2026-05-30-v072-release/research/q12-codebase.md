---
status: draft
question_ids: [12]
research_type: codebase
---

# Q12: Handling of `.qrspi-commit-msg.txt` — exclusion mechanisms in SKILL.md, test-writer agent, and root `.gitignore`

## Summary

**TL;DR:** `skills/implementer-protocol/SKILL.md` references **only the worktree-local `.git/info/exclude`** for the scratch-file exclusion (Invariant 3 prose, line 174) and explicitly states the committed `.gitignore` should NOT be polluted with QRSPI internals. However, at line 241 (Commit-Before-Reporting step 4) the same file contradicts itself with a parenthetical claiming the file is "not gitignored." `agents/qrspi-test-writer.md` line 28 references only the worktree-local `.git/info/exclude`. Meanwhile, the root `.gitignore` (line 4) **does** contain `.qrspi-commit-msg.txt`, meaning both exclusion mechanisms are currently active in the repo despite SKILL.md saying only the worktree-local exclude should be used.

**Key findings:**
- `SKILL.md` **Invariant 3** (line 174) names only the worktree-local `.git/info/exclude`; it explicitly says "the target repository's committed `.gitignore` is not polluted with QRSPI internals."
- `SKILL.md` **Commit-Before-Reporting step 4** (line 241) parenthetical states "the scratch file is **not gitignored**" — contradicting the root `.gitignore` which does list `.qrspi-commit-msg.txt`.
- `agents/qrspi-test-writer.md` **line 28** references only the worktree-local `.git/info/exclude`: "The worktree-local `.git/info/exclude` already lists `.qrspi-commit-msg.txt`."
- Root `.gitignore` **line 4** lists `.qrspi-commit-msg.txt` under the comment `# QRSPI implementer scratch file`, making the committed `.gitignore` an active exclusion mechanism.
- Both exclusion mechanisms (worktree-local `.git/info/exclude` per Invariant 3 prose, and committed root `.gitignore` per observed file content) are currently active.

**Surprises:** The Commit-Before-Reporting step 4 parenthetical in SKILL.md says the file is "not gitignored," but the root `.gitignore` does contain the entry. This is a direct internal contradiction: the Invariant 3 prose says the committed `.gitignore` should not be used, yet it is; and the procedural step says the file is not gitignored when it is.

**Caveats:** The worktree-local `.git/info/exclude` files for individual worktrees under `.worktrees/` were not examined — confirming whether they also carry the entry would require inspecting active worktree directories, which may or may not exist at investigation time. The `skills/implement/SKILL.md` file referenced in SKILL.md (as the location of procedural realization) was not examined.

## Full findings

### `skills/implementer-protocol/SKILL.md` — Commit hygiene invariants section

The **Commit hygiene invariants** section (starting around line 162) is the architectural declaration of how `.qrspi-commit-msg.txt` is to be kept out of commits.

**Invariant 3** (line 174) reads in full:

> **Invariant 3 — worktree-local-exclude.** The scratch file path is excluded via the worktree-local `.git/info/exclude` entry added during worktree setup, independently of any per-commit ordering. This ensures `git status` reports remain deterministic between scratch-file write and removal, and the target repository's committed `.gitignore` is not polluted with QRSPI internals.

- Reference: **worktree-local `.git/info/exclude` only**.
- Explicit statement that the **committed `.gitignore` should NOT be used** for this purpose.

**Invariant 2** (line 172) mentions worktree-local exclude in passing: "Even when the worktree-local exclude (Invariant 3) is absent — for example, in a worktree set up by a non-QRSPI mechanism…"

### `skills/implementer-protocol/SKILL.md` — Commit Before Reporting step 4

The **Commit Before Reporting** procedure (lines 236–245) includes:

> 4. `rm <worktree>/.qrspi-commit-msg.txt` **(the scratch file is not gitignored and you don't want it in the next round's diff).**

- This parenthetical asserts the scratch file "is not gitignored."
- This contradicts the root `.gitignore` content found at investigation time (see below).
- This step references neither worktree-local `.git/info/exclude` nor the committed `.gitignore` explicitly — it simply claims the file is not covered by either.

### `agents/qrspi-test-writer.md` — line 28

Line 28 (within the **Bash command scope / Commit ownership** bullet) reads:

> **Commit ownership.** You own the RED commit. Use the inline scratch-file commit pattern restated in the implement-phase Behavior block below (step 6): write `.qrspi-commit-msg.txt`, `git -c user.name=agent-echo -c user.email=<noreply> commit -F .qrspi-commit-msg.txt`, `rm .qrspi-commit-msg.txt`. **The worktree-local `.git/info/exclude` already lists `.qrspi-commit-msg.txt`.** Include `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>` trailer.

- Reference: **worktree-local `.git/info/exclude` only**.
- No mention of the committed `.gitignore`.

Line 80 (implement-phase step 6d) contains a matching statement:

> d. Remove the scratch file: `rm .qrspi-commit-msg.txt` (the worktree-local `.git/info/exclude` already lists it, but the file is not committed and must not appear in subsequent diffs).

### Root `.gitignore` — active exclusion mechanisms

The root `.gitignore` at `/Users/dfrysinger/code/qrspi-plus-v0.7.2/.gitignore` contains (full file content, 11 lines):

```
.worktrees/

# QRSPI implementer scratch file
.qrspi-commit-msg.txt

# Editor / IDE
.vscode/

# macOS metadata files
.DS_Store
**/.DS_Store
```

- `.qrspi-commit-msg.txt` appears at **line 4** under the comment `# QRSPI implementer scratch file`.
- This is the committed root `.gitignore` — it applies to all working trees rooted at the repo root.
- Combined with the `.git/info/exclude` mechanism described by SKILL.md Invariant 3, **both mechanisms are currently active**.

### Summary of which mechanism is referenced where

| Location | References `.git/info/exclude` | References committed `.gitignore` | Notes |
|---|---|---|---|
| `SKILL.md` Invariant 3 (line 174) | ✅ yes | ❌ no (explicitly excluded) | Architectural declaration |
| `SKILL.md` Commit-Before-Reporting step 4 (line 241) | ❌ no | ❌ no | Claims file "is not gitignored" — factually incorrect given root `.gitignore` content |
| `agents/qrspi-test-writer.md` line 28 | ✅ yes | ❌ no | Operational agent rule |
| `agents/qrspi-test-writer.md` line 80 | ✅ yes | ❌ no | Operational agent rule |
| Root `.gitignore` line 4 | N/A | ✅ present | Currently active exclusion |
