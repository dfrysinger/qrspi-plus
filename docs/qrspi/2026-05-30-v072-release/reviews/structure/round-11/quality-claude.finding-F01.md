---
artifact: structure
reviewer_tag: quality-claude
finding_id: R11-F01
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md:612-619
  - docs/qrspi/2026-05-30-v072-release/structure.md:961-968
  - docs/qrspi/2026-05-30-v072-release/structure.md:978-1002
  - docs/qrspi/2026-05-30-v072-release/design.md:1090-1097
severity: high
change_type: correctness
---

# `scripts/round-prepare.sh` exit-code contract is internally contradictory and conflicts with the design.md authoritative table

## What is broken

The exit-code semantics for `scripts/round-prepare.sh` are documented in three places in structure.md, and the three are mutually inconsistent. design.md G4 (L1090-1097) is the authoritative source.

**design.md L1090-1097 (authoritative Exit-code recovery table):**

| Exit | Cause |
|------|-------|
| 0  | All checks passed; anchor written |
| 10 | `--task-branch` set without `--implementer-commit` (orchestrator bug) |
| 11 | Passed SHA ≠ `git rev-parse HEAD` (worktree integrity break) |
| 12 | Passed SHA == prior round's anchor (re-dispatch implementer) |

**Place 1 — Slice 1.3 `scripts/round-prepare.sh` Interface block (structure.md L612-619):**

```bash
# scripts/round-prepare.sh <task-branch> <round-NN> <output-dir> [--implementer-commit <SHA>] [--verify]
# Exit 0: <output-dir>/round-NN.diff + <output-dir>/round-NN-commit.txt written
# Exit 10: SHA already matches (idempotent skip)        ← WRONG (design says: missing-flag orchestrator bug)
# Exit 11: worktree integrity break
# Exit 12: re-dispatch implementer needed
```

**Place 2 — Slice 1.4 `scripts/round-prepare.sh` Interface block (structure.md L961-968):**

```bash
# scripts/round-prepare.sh <task-branch> <round-NN> <output-dir> [--implementer-commit <SHA>] [--verify]
# Exit 0: <output-dir>/round-NN.diff + <output-dir>/round-NN-commit.txt written
# Exit 10: SHA already matches (idempotent skip)  [orchestrator bug: missing --implementer-commit]
#         ↑ two contradictory glosses on one line ↑
# Exit 11: worktree integrity break
# Exit 12: re-dispatch implementer needed
```

**Place 3 — Slice 1.4 verbatim payload (structure.md L978-1002), which IS faithful to design.md G4:**

```sh
# Check 1: required-flag check (exit 10 — orchestrator bug).
if [[ -z "$IMPLEMENTER_COMMIT" ]]; then
  echo "round-prepare: --task-branch requires --implementer-commit. ..." >&2
  exit 10
fi
# Check 2: across-rounds advance check (exit 12 — re-dispatch implementer).
# Check 3: within-round equality check (exit 11 — halt + diagnose worktree).
```

## Why it matters

Exit code 10 has two completely different meanings across the three locations:
- "SHA already matches (idempotent skip)" — a benign no-op
- "Missing `--implementer-commit` flag" — an orchestrator bug

These are **opposite** signals. The first says "everything is fine, nothing to do." The second says "halt, the orchestrator is broken." Plan and Implement consumers reading these interface blocks cannot author either `scripts/round-prepare.sh` or its callers (especially `dispatch-agent.sh` exit-code passthrough at L881; `skills/implement/SKILL.md` "Between rounds" checklist at L782 step 4 which branches on exit codes) without picking one of the two conflicting contracts.

A first-time Plan-author following the Slice 1.3 interface block would author a caller that treats `exit 10` as "skip and proceed to dispatch" — directly inverting the design.md-mandated "halt + surface to user" recovery. The verbatim block (which IS correct) is buried below the interface block in Slice 1.4 and overridden in the consumer's mental model by the contradictory interface block above it.

There is also no "SHA already matches (idempotent skip)" exit code in the design.md table at all — the gloss appears to be a hallucinated semantic that does not exist anywhere in design.md G4.

## Suggested fix

Three coordinated edits:

1. **structure.md L614** (Slice 1.3 interface): change `Exit 10: SHA already matches (idempotent skip)` to `Exit 10: missing --implementer-commit flag (orchestrator bug — halt + surface to user)`.
2. **structure.md L965** (Slice 1.4 interface): strip the contradictory `SHA already matches (idempotent skip)` half of the comment so the line reads `# Exit 10: --task-branch set without --implementer-commit (orchestrator bug — halt + surface to user)`.
3. Add a one-line cross-reference from the Slice 1.3 interface block to the Slice 1.4 verbatim payload (so authors reading the earlier slice know the authoritative shell lives below).

Alternatively, factor the round-prepare.sh exit-code table out into the `## Cross-Cutting Schemas` section (it is genuinely cross-cutting — consumed by `dispatch-agent.sh`, `skills/implement/SKILL.md`, and the two interface blocks) and have the two slice rows reference the one canonical table.
