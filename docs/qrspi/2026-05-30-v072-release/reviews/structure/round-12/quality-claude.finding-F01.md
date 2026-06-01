---
finding_id: R12-F01
reviewer_tag: quality-claude
artifact: structure
severity: low
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md:614-624
  - docs/qrspi/2026-05-30-v072-release/structure.md:966-975
  - docs/qrspi/2026-05-30-v072-release/design.md:1058
  - docs/qrspi/2026-05-30-v072-release/design.md:1103
---

# round-prepare.sh interface block — signature line and exit-10 description disagree on whether `task-branch` is a positional arg or a `--task-branch` flag

The R11 fix wave rewrote the exit-code contract in both `scripts/round-prepare.sh` per-file blocks (Slice 1.3 at L614-624; Slice 1.4 at L966-975) to fix the broken old descriptions (`Exit 10: SHA already matches (idempotent skip)` etc.). The new descriptions are behaviorally correct, but the rewrite introduced a small syntactic inconsistency with the (unchanged) signature line directly above them:

```bash
# scripts/round-prepare.sh <task-branch> <round-NN> <output-dir> [--implementer-commit <SHA>] [--verify]
# Exit 0: <output-dir>/round-NN.diff + <output-dir>/../round-NN-commit.txt written
# Exit 10: --task-branch set without --implementer-commit (orchestrator bug — halt + surface to user)
```

The signature line shows `<task-branch>` in positional-arg notation (angle-bracket placeholder, no `--` prefix), parallel to `<round-NN>` and `<output-dir>` and clearly distinct from the flag-form `[--implementer-commit <SHA>]` / `[--verify]` shown in brackets with `--` prefixes.

The exit-10 description then references `--task-branch` (double-dash flag syntax), which doesn't match the positional notation in the signature line. A required positional is *always set* when the script is invoked; "`--task-branch` set" only makes semantic sense if `--task-branch` is an optional flag.

design.md confirms `--task-branch` is meant to be an optional flag, not a positional:

- design.md §G4 L1058: "First action when `--task-branch` is set (per-task invocation — G9 amendment)" — flag syntax with dashes.
- design.md §G4 L1103: "When `--task-branch` is NOT set (artifact-level invocation), step 1 is a no-op" — confirms task-branch can be absent, so it is optional and flag-form (a required positional can't be "not set" in this contract sense).

So the correct signature should read along the lines of:

```bash
# scripts/round-prepare.sh [--task-branch <name>] <round-NN> <output-dir> [--implementer-commit <SHA>] [--verify]
```

or, if the positional form is genuinely preferred and the exit-10 description is what's stale, rewrite the exit-10 line to say "positional task-branch set without --implementer-commit flag".

**Why this matters.** The per-file block paradigm's stated load-bearing benefit (structure.md L15) is that "each per-file block is the single anchor point where an architect, Plan consumer, or Implement consumer reads everything that pertains to one target file." A Plan/Implement consumer reading just this Interface block today cannot determine whether to author the shell as `if [[ "$1" == "" ]]` (positional) or `getopts/case ... --task-branch)` (flag) — they have to dereference design.md §G4 to disambiguate, which is the very dereference cost the per-file block exists to eliminate.

**Recommended fix.** Update both interface blocks (L614-624 and L966-975 of structure.md) to bracket `[--task-branch <name>]` consistently with the other flags. Both blocks should mirror each other — they already do for the unchanged invocation form and the new "Authoritative table: design.md §G4 L1090-L1097" reference line.

**Scope.** Pre-existing signature line was not part of the R11 fix delta, but the R11 fix's exit-10 rewrite introduced the conflict by adopting `--task-branch` flag syntax in the description without harmonizing the signature line above. This is the smallest correction that closes the inconsistency.

Informational note: the four other exit-code descriptions (0, 11, 12) and the new authoritative-table cross-reference are clean; this finding is narrow.
