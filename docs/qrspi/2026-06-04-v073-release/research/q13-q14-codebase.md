---
status: draft
question_ids: [13, 14]
research_type: codebase
---

# Q13, Q14: Apply-Fix Protocol — Per-Round Commit Structure and Diff-Reference Anchoring

## Summary

**TL;DR:** Each apply-fix review round produces exactly one git commit. That commit bundles the updated artifact, the entire `round-NN/` subdirectory, and several sibling bookkeeping files. The anchor-capture step writes a one-line SHA file to disk *after* the commit (or, in the per-task path, before reviewers dispatch), but it does not add any extra git commit, so the total per-round commit count is always 1. The reference used to narrow the diff between consecutive rounds is `HEAD~1`, and it is anchored by the per-round commit-anchor text file (`reviews/{step}/round-NN-commit.txt`), which stores the 40-char SHA of the prior round's per-round commit and is verified by `scripts/round-prepare.sh` before `<ref>=HEAD~1` is committed to.

**Key findings:**
- The per-round git commit (step 11 of the Standard Review Loop) bundles exactly five categories of files: (1) the artifact itself, (2) the entire `round-NN/` subdirectory (including verifier sidecar `.score.yml` files), (3) `round-NN-scope-set.txt` (when emitted by scope-tagger step 6), (4) `round-NN-verified.md`, and (5) `round-NN-dispositions.md`. (`skills/using-qrspi/SKILL.md:993`)
- The anchor-capture step writes `reviews/{step}/round-NN-commit.txt` (40-char SHA + newline) **after** `git commit` in the artifact-level flow (`skills/using-qrspi/SKILL.md:995`) — this is a file-write only, not a separate git commit, so each round still produces exactly one commit.
- In the per-task implement path, the anchor file `reviews/tasks/task-NN/round-NN-commit.txt` is written by `scripts/round-prepare.sh` as a pre-flight step for round NN+1, after the Step 10 prior-artifact presence assertions pass (`scripts/round-prepare.sh:225–233`). The script defers the write deliberately to ensure a failed verification leaves no stale anchor on disk.
- For the diff `<ref>` to narrow (i.e., be set to `HEAD~1` rather than the base branch), the convergence rule in step 12 (ref selection) must fire — requiring round NN's scope-set to be equal to or a proper subset of round NN-1's scope-set, AND rounds must be ≥ 3. (`skills/using-qrspi/SKILL.md:999–1027`)
- The file that anchors the `<ref>=HEAD~1` decision is `reviews/{step}/round-(NN-1)-commit.txt`. Step 12 / `round-prepare.sh` reads the SHA from that file and compares it against `git rev-parse HEAD~1`; any mismatch falls through to broaden. (`skills/using-qrspi/SKILL.md:1026`, `scripts/round-prepare.sh:300–308`)
- Main chat reads the resolved `<ref>` and `narrowed` flag from `<round-dir>/.round-prepare.json` (written atomically by `round-prepare.sh`) rather than computing the comparison itself. (`skills/implement/SKILL.md:1117`, `scripts/round-prepare.sh:390–420`)

**Surprises:** The anchor-capture step for the artifact-level path is performed by main chat *after* committing (making `round-NN-commit.txt` an uncommitted file on disk until the next per-round commit picks it up), while the per-task path writes the anchor as a pre-flight to the *next* round via `round-prepare.sh`. These are two distinct mechanisms for the same logical operation.

**Caveats:** The investigation focused on `skills/using-qrspi/SKILL.md`, `skills/implement/SKILL.md`, and `scripts/round-prepare.sh`. The artifact-level skills (`skills/goals/SKILL.md`, `skills/design/SKILL.md`, etc.) defer to the Standard Review Loop description in `using-qrspi/SKILL.md` and were not individually verified to confirm they do not add commits of their own.

## Full findings

### Q13: Per-round commit structure and how the anchor-capture step affects total commits

#### Canonical commit structure (artifact-level, Standard Review Loop step 11)

`skills/using-qrspi/SKILL.md:993` states:

> **Per-round commit** covers the artifact, the entire `round-NN/` subdir (including sidecars), `round-NN-scope-set.txt` (when emitted by step 6), `round-NN-verified.md`, and `round-NN-dispositions.md`.

Five categories in one git commit:

| Category | Notes |
|---|---|
| Artifact file (e.g., `goals.md`, `design.md`) | The updated artifact after fix-apply |
| `reviews/{step}/round-NN/` (entire subdirectory) | All per-finding files (`*.finding-FNN.md`), clean sentinels (`*.clean.md`), verifier sidecars (`*.score.yml`) |
| `reviews/{step}/round-NN-scope-set.txt` | Present only when scope-tagger step 6 fired |
| `reviews/{step}/round-NN-verified.md` | Assembled by step 5 from findings + sidecars |
| `reviews/{step}/round-NN-dispositions.md` | Main-chat-authored, ≤30 lines |

This is always exactly **one** git commit per round.

#### Anchor-capture step: what it does and does NOT do

Immediately after the `git commit`, step 11 continues (`skills/using-qrspi/SKILL.md:995`):

> **Capture the per-round commit SHA (per-round commit anchor for step 12).** Immediately after `git commit`, capture the commit SHA into `reviews/{step}/round-NN-commit.txt` (one line, the 40-char SHA, trailing newline).

This is a **file-write operation**, not an additional `git commit`. The file `round-NN-commit.txt` is written to disk after the per-round commit completes, making it an uncommitted file until the next round's per-round commit (or approval commit) picks it up. The anchor-capture step therefore does **not** change the total number of commits produced per round; the count remains **1**.

#### Per-task path differs in timing

For the per-task implement path, the anchor is not written by main chat after the per-round commit. Instead, `scripts/round-prepare.sh` writes it as a pre-flight step when setting up round NN+1 (`scripts/round-prepare.sh:225–233`):

```sh
if [ "$PER_TASK" -eq 1 ]; then
  ANCHOR_PATH="$TASK_DIR/round-${ROUND_NN}-commit.txt"
  ANCHOR_TMP="${ANCHOR_PATH}.tmp.$$"
  printf '%s\n' "$IMPLEMENTER_COMMIT" > "$ANCHOR_TMP"
  ...
  mv "$ANCHOR_TMP" "$ANCHOR_PATH"
fi
```

The script comments explicitly state (`scripts/round-prepare.sh:172–176`):

> NOTE: the round commit anchor is NOT written here [in step 1]. It is deferred until AFTER the Step 10 prior-artifact presence assertions below so that any exit-1 from a missing/malformed prior anchor or empty prior scope-set leaves NO stray current-round anchor on disk (preserves the documented "failed verification leaves no round-NN-commit.txt" invariant).

This deferral ensures the fail-loud exit codes (11 = worktree integrity break, 12 = implementer did not advance HEAD, 1 = prior-artifact integrity failure) all leave no anchor on disk, preserving consume-once invariants downstream.

`skills/implement/SKILL.md:1096` documents this equivalently:

> The script consolidates the three SHA-correctness checks (missing-flag → exit 10; across-rounds advance → exit 12; within-round equality → exit 11) and writes the anchor on exit 0 with the format `<40-char SHA>\n`.

Per-task rounds also produce exactly **one** commit per round (the implementer's task commit).

---

### Q14: Reference used to narrow diffs between consecutive rounds and the anchoring artifact

#### How the `<ref>` is determined

The diff-emission step runs `git diff "<ref>" -- "<artifact_path>"` (or `git diff "$REF" -- "$ARTIFACT"` in `scripts/round-prepare.sh:374–378`). The `<ref>` value is determined by step 12 (ref selection for round NN+1) per a convergence rule (`skills/using-qrspi/SKILL.md:999`):

> Ref selection for round NN+1 — executes after step 11's per-round commit. … Computes the next round's `<ref>` and optional `<scope_hint>` from the scope-sets emitted by step 6.

Two possible outcomes:

| Case | `<ref>` value | Condition |
|---|---|---|
| **Narrow** | `HEAD~1` | Round NN's scope-set equal to or proper-subset of round NN-1's; round ≥ 3; HEAD~1 matches prior anchor SHA |
| **Broaden** | `<base-branch>` (artifact-level) or `<task-base-commit>` (per-task) | All other cases: rounds 1–2, missing/empty scope-sets, `<full>` token present, superset/partial/disjoint scope-sets, HEAD~1 mismatch, backward-loop reset, `scope_tagger_enabled: false` |

`skills/using-qrspi/SKILL.md:1026` states the narrow path produces:

> `<ref>=HEAD~1` (this round's delta only, vs the per-round commit step 11 just made — so the diff file shrinks naturally)

The earliest a narrow decision can fire is for round 3 dispatch (comparing scope-sets from rounds 1 and 2): `skills/using-qrspi/SKILL.md:1003`.

#### The artifact that anchors `<ref>=HEAD~1`

The reference `HEAD~1` is validated against the file `reviews/{step}/round-(NN-1)-commit.txt` (artifact-level) or `reviews/tasks/task-NN/round-(NN-1)-commit.txt` (per-task). This is the **per-round commit anchor** file, a single-line text file containing the 40-char SHA of the prior round's per-round git commit.

`skills/using-qrspi/SKILL.md:1026` states:

> **Per-round commit anchor assertion:** before committing to `<ref>=HEAD~1`, read the SHA from `reviews/{step}/round-(NN-1)-commit.txt` (captured at step 11 of the prior round) and run `git -C "<repo>" rev-parse HEAD~1`. If they differ, `HEAD~1` is no longer the prior per-round commit (manual user commit between rounds, intermediate process commit, etc.). Fall through to the broaden branch with a one-line diagnostic to the user transcript.

In `scripts/round-prepare.sh`, the `decide_narrow()` function implements this at lines 300–308:

```sh
local prior_anchor="$TASK_DIR/round-$(printf '%02d' $((ROUND_NUM - 1)))-commit.txt"
if [ -f "$prior_anchor" ]; then
  local prior_sha head1
  prior_sha="$(tr -d '[:space:]' < "$prior_anchor")"
  head1="$(git -C "${WORKTREE:-.}" rev-parse HEAD~1 2>/dev/null || true)"
  if [ -z "$head1" ] || [ "$head1" != "$prior_sha" ]; then
    REASON="HEAD~1 ($head1) does not match prior round anchor ($prior_sha) — fall back to broaden"
    return 1
  fi
fi
```

If the anchor file is absent or the SHA doesn't match HEAD~1, the function returns 1 (broaden), never setting `NARROWED=true`.

#### Output channel for the ref selection decision

The resolved `<ref>`, `narrowed` flag, `scope_hint`, `diff_file` path, and `reason` string are written atomically to `<round-dir>/.round-prepare.json` by `round-prepare.sh` (`scripts/round-prepare.sh:391–420`). Main chat reads this sidecar rather than computing the decision itself, as stated in `skills/implement/SKILL.md:1117`:

> Main chat reads the resolved `<ref>` and `narrowed` flag from `<round-dir>/.round-prepare.json` rather than computing the comparison itself.

#### Anchor file format

The anchor file is specified at `skills/using-qrspi/SKILL.md:995` and `skills/implement/SKILL.md:1096` as:

```
<40-char hex SHA>\n
```

The regex enforced by `round-prepare.sh` step 10 (lines 193–200) is `^[0-9a-f]{40}\n$` — exactly 40 lowercase hex characters followed by a single trailing newline. Any other content is treated as a malformed anchor, causing exit 1 before the new anchor is written.
