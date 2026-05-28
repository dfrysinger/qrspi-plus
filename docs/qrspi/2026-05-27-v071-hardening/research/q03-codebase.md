---
status: draft
question_ids: [3]
research_type: codebase
---

# Q03: Step-by-step commit procedure in `skills/implementer-protocol/SKILL.md`

## Summary

**TL;DR:** The commit procedure in `skills/implementer-protocol/SKILL.md` § "Commit Before Reporting" is a five-step sequence. The scratch file (`.qrspi-commit-msg.txt`) is **written first** (step 2), then `git add -A` is run, then `git commit -F` is invoked — both as a single chained shell command in step 3. This ordering appears to contradict "Invariant 1 — staging-before-scratch" declared earlier in the same file; the contradiction is resolved by Invariant 3, which excludes the scratch file via `.git/info/exclude` so `git add -A` cannot accidentally stage it.

**Key findings:**
- The five-step procedure lives at `skills/implementer-protocol/SKILL.md` lines 238–242 under § "Commit Before Reporting".
- **Step order:** (1) `git status --porcelain` preflight → (2) Write scratch file via Write tool → (3) `git add -A && git commit -F .qrspi-commit-msg.txt` (single chained command) → (4) `rm .qrspi-commit-msg.txt` → (5) `git rev-parse HEAD` to capture SHA.
- `git add -A` and `git commit -F` are specified as a single `&&`-chained command; there is no separate step between writing the scratch file and running `git add`.
- Three architectural invariants (lines 170–181) govern the overall commit cycle; Invariant 1 says staging must complete *before* the scratch file is written, but the § "Commit Before Reporting" procedure writes the scratch file first, relying on Invariant 3 (`.git/info/exclude` entry for the scratch path) to prevent accidental staging.
- The scratch file is named `.qrspi-commit-msg.txt` and lives in the worktree root.
- After `git commit -F`, the scratch file is explicitly deleted (step 4) before any subsequent staging cycle, fulfilling Invariant 2.

**Surprises:** The concrete procedure (scratch file written *before* `git add -A`) is the reverse of what Invariant 1 literally states ("staging completes before the scratch file is written"). The file itself acknowledges this by noting that the procedural realization lives in the procedure sections and that Invariants 2 and 3 cover the cases where Invariant 1 alone would be insufficient.

**Caveats:** The file references `skills/implement/SKILL.md` § "TDD Process step 6 multi-line message convention" as the canonical source for the convention; that file was not read for this report. The procedure text in `implementer-protocol/SKILL.md` is taken as authoritative for this question.

## Full findings

### Source location

File: `skills/implementer-protocol/SKILL.md`  
Section: **§ Commit Before Reporting** (lines 232–244)  
Related section: **§ Commit hygiene invariants** (lines 162–181)

---

### The five-step procedure (lines 238–242)

The procedure is introduced as:

> "Procedure (per `implement/SKILL.md` § TDD Process step 6 multi-line message convention):"

The numbered steps, verbatim:

| Step | Action |
|------|--------|
| 1 | `git -C <worktree> status --porcelain` — confirm there is something to commit |
| 2 | Write a multi-line commit message to `<worktree>/.qrspi-commit-msg.txt` using the Write tool |
| 3 | `git -C <worktree> add -A && git -C <worktree> commit -F .qrspi-commit-msg.txt` |
| 4 | `rm <worktree>/.qrspi-commit-msg.txt` |
| 5 | `git -C <worktree> rev-parse HEAD` — capture SHA; include as `commit_sha:` in terminal-status report |

**Ordering of the three focal operations:**

1. **Scratch file created** — Step 2 (Write tool writes `.qrspi-commit-msg.txt` to the worktree root).
2. **`git add -A` run** — First half of the step 3 chained command.
3. **`git commit -F` invoked** — Second half of the step 3 chained command (`git commit -F .qrspi-commit-msg.txt`).

`git add -A` and `git commit -F` are **not** separate steps; they are written as a single `&&` shell chain in step 3.

---

### Commit hygiene invariants (lines 162–181)

Three invariants constrain this procedure architecturally:

**Invariant 1 — staging-before-scratch** (line 170):  
> "The staging operation for a commit cycle completes before the commit-message scratch file is written to the worktree."

_Tension with procedure:_ The § "Commit Before Reporting" procedure writes the scratch file (step 2) **before** running `git add -A` (step 3). The file notes (line 168) that the *procedural realization* of the invariants "lives in `skills/implement/SKILL.md` and in Plan-authored task specs" and that the invariants section "declares the architectural contract." Invariant 3 provides the practical safety that compensates when ordering places scratch-before-staging.

**Invariant 2 — cleanup-after-commit** (line 172):  
> "The scratch file is removed after the commit completes and before any subsequent staging cycle begins."  
Realized by step 4 (`rm .qrspi-commit-msg.txt`).

**Invariant 3 — worktree-local-exclude** (line 174):  
> "The scratch file path is excluded via the worktree-local `.git/info/exclude` entry added during worktree setup."  
This ensures `git add -A` cannot pick up `.qrspi-commit-msg.txt` even when it already exists on disk at the time `git add` runs. This is the backstop that makes the step 2 → step 3 ordering safe.

---

### Commit-message content requirements (lines 238–239)

The commit message written to the scratch file in step 2 **must** reference:
- The round number.
- For fix-mode rounds: the findings being addressed (e.g., `fix(task-NN/round-3): server-side bytes/mime check (closes security-codex.F01)`).

---

### When nothing is staged (line 244)

If there is nothing to commit, the implementer must report `BLOCKED` or `DONE_WITH_CONCERNS` with an explanation. Silently skipping the commit is prohibited; the orchestrator's HEAD-advanced verification will fail-loud regardless.

---

### Scratch-file accidental-commit history note (line 164)

The three-invariant scheme was introduced specifically to eliminate "the recurring regression where implementers accidentally committed `.qrspi-commit-msg.txt` (the commit-message scratch file) by staging it alongside the task's actual changes." The `&&`-chained step 3 combined with Invariant 3 is the primary defense.
