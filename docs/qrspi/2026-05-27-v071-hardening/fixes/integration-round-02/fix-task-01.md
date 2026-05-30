---
task_id: fix-int-r2-01
task_type: lightweight
mode: fix
round: 2
artifact: integration
addresses:
  - R2-F02 (security-codex, security, score 72) — preloaded implementer-protocol conflicts with test-writer HARD CONSTRAINT
defers:
  - R2-F01 (integration-claude, clarity, score 58) — status-token list mismatch, rolled into v0.7.2 #233
references:
  - agents/qrspi-test-writer.md (the only file to touch)
  - skills/implementer-protocol/SKILL.md (read-only — verify the directives being conflicted with)
---

# fix-int-r2-01: Reconcile test-writer ↔ implementer-protocol preload conflict

## Problem

The round-01 fix (575c00a) added `skills: [implementer-protocol]` to `agents/qrspi-test-writer.md:6` to close R1-F04 (preload symmetry with implementer). Verified by security-codex round 02 (verifier score 72), this preload pulls in two directives that contradict the test-writer's HARD CONSTRAINT block (lines 13-31):

1. **`git -C <worktree> add -A`** at `skills/implementer-protocol/SKILL.md:240` — contradicts test-writer line 22's "`git add <test-file-paths>` (only); never `git add -A`"
2. **Write `reviews/tasks/task-NN/round-NN-implementer.md`** at `skills/implementer-protocol/SKILL.md:248-249` — contradicts test-writer line 17's "writes only files under `tests/` or with test-suffix conventions"

Both conflicts are prompt-layer only (no path-containment tool restriction); an LLM following the preloaded protocol blindly could stage non-test files or write outside `output_dir`.

## Fix (Option A — revert preload, inline the minimal restatement)

The test-writer never needed the full `implementer-protocol` body — it only needed the **scratch-file commit pattern**'s three lines plus the "stage only your authored files" invariant. Pulling in the entire skill brought conflicting wider directives along with the desired content.

### Step 1: revert frontmatter preload

Remove `skills: [implementer-protocol]` from `agents/qrspi-test-writer.md` frontmatter (currently at line 6, between `tools:` and the closing `---`).

### Step 2: expand the body reference at line 76 to inline the relevant content

Current line 76 reads (within the implement-phase Mode block, step 5/6 area):
> ... use the scratch-file commit pattern from `implementer-protocol`: write `.qrspi-commit-msg.txt`, commit with the agent author config, then `rm .qrspi-commit-msg.txt`.

Replace that single bullet with an inline expansion that restates the scratch-file pattern explicitly within the test-writer's narrower scope envelope. The replacement bullet MUST:

- Restate the three commands: write `.qrspi-commit-msg.txt` via the Write tool, then `git add <test-file-paths>` followed by `git commit -F .qrspi-commit-msg.txt`, then `rm .qrspi-commit-msg.txt`.
- Explicitly forbid `git add -A` again at the point of use (defense-in-depth — the HARD CONSTRAINT block already says it, but co-locating with the commit step removes any "but I was told to add -A by a preloaded skill" rationale).
- Reference the HARD CONSTRAINT block by name as the binding scope authority.
- Be self-contained: a reader should not need to load any other skill to execute this step correctly.

### Step 3: re-verify the no-dangling-reference closure of R1-F04

R1-F04's underlying concern was "test-writer references `implementer-protocol` but doesn't preload it, so the referenced content isn't actually in the agent's prompt." After this fix, the body no longer references `implementer-protocol` for the scratch-file pattern (because the pattern is inlined). Confirm:

```
grep -n 'implementer-protocol' agents/qrspi-test-writer.md
```

Should return either zero matches OR only matches that don't depend on the body being preloaded (e.g., a comparative note like "the same pattern used by the implementer agent" is fine; an instruction like "follow the implementer-protocol scratch-file pattern" without inline content is NOT fine — that would re-create R1-F04).

## Probes (run after the edit, BEFORE committing)

1. **frontmatter no longer preloads the skill:**
   ```
   grep -n '^skills:' agents/qrspi-test-writer.md
   ```
   Expected: zero matches.

2. **inline scratch-file pattern is present:**
   ```
   grep -n '\.qrspi-commit-msg\.txt' agents/qrspi-test-writer.md
   ```
   Expected: at least 2 matches (the existing HARD CONSTRAINT-block reference at ~line 29 + the new inline expansion at the implement-phase step).

3. **explicit "never git add -A" at the commit step:**
   ```
   grep -n 'git add -A' agents/qrspi-test-writer.md
   ```
   Expected: at least 2 matches (the existing HARD CONSTRAINT reference + the new defense-in-depth reference at the commit step). Both should be in NEGATIVE context ("never", "not", "do not").

4. **no dangling reference to implementer-protocol for instructions:**
   ```
   grep -n 'implementer-protocol' agents/qrspi-test-writer.md
   ```
   Expected: zero or one match (and if one, it must be a comparative note, not an instruction to follow the skill).

5. **full bats suite still green:**
   ```
   bats tests/unit/
   ```
   Expected: 1305/1305 passing (matching the pre-fix baseline at 575c00a).

## Commit message

```
integrate(wave-1): R2-F02 inline scratch-file pattern; revert implementer-protocol preload

Closes round-02 security-codex finding (verifier score 72): the round-01 fix
preloaded implementer-protocol to close R1-F04, but the skill carries
`git add -A` and `reviews/tasks/...` write directives that contradict the
test-writer's HARD CONSTRAINT block (test-files-only Bash + write scope).

Option A: revert the frontmatter preload and inline the three-line scratch-file
commit pattern at the implement-phase step, restating the HARD CONSTRAINT's
"never git add -A" at the point of use. R1-F04's underlying concern
(dangling reference to unloaded skill body) is still closed because the
referenced content is now inline rather than externally referenced.

R2-F01 (status-token list mismatch) deferred to v0.7.2 (#233).
```

## Out of scope

- Do NOT modify `skills/implementer-protocol/SKILL.md`. The protocol is correct as-is for its intended consumers (implementer + lightweight); the bug is the test-writer using it as a preload when its directives don't fit the narrower scope.
- Do NOT modify `agents/qrspi-implementer.md` or `agents/qrspi-implementer-lightweight.md` — they correctly preload `implementer-protocol` and operate under a wider scope envelope where its directives apply.
- Do NOT touch the Output Contract block (lines 268-280). The R2-F01 status-token mismatch (line 78 vs line 271) is deferred to v0.7.2.

## Expected output

Single-file diff on `agents/qrspi-test-writer.md`:
- `-` 1 line removed from frontmatter (`skills: [implementer-protocol]`)
- `+` ~6-10 lines added at the implement-phase commit step (inline expansion)
- `-` 1 line removed at the implement-phase commit step (the old bullet that referenced the skill by name)

Status: DONE / commit SHA / 1 file modified / 1305 tests passing.
