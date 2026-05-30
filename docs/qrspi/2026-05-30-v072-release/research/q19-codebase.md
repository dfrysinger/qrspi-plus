---
status: draft
question_ids: [19]
research_type: codebase
---

# Q19: How do skill prompts and orchestrator-facing documentation describe cumulative-diff anchor construction in the Standard Review Loop?

## Summary

**TL;DR:** Diff-anchor construction for the Standard Review Loop is described exclusively as orchestrator-executed prose instructions (not scripts). The canonical algorithm lives in `skills/using-qrspi/SKILL.md` §§ Standard Review Loop and Review Output Handling, with every per-step SKILL.md cross-referencing it via a "Pre-dispatch diff-file emission" paragraph. Two distinct anchor types exist: `<base-branch>` (the default, cumulative diff from branch fork) and `HEAD~1` (a narrowed delta, enabled only via the convergence-narrowing rule at step 12). No script in `scripts/` implements the round-NN.diff generation itself; the one script that accepts a pre-computed diff file path (`scripts/run-codex-review.sh`) only receives and forwards the path — it does not compute the anchor.

**Key findings:**
- The canonical diff-anchor construction spec is in `skills/using-qrspi/SKILL.md:678–689` (Standard Review Loop step 1) and `skills/using-qrspi/SKILL.md:1086–1105` (§ "Diff handling between rounds" / "Ref selection rule").
- `<base-branch>` is the default anchor (cumulative diff from branch fork); `HEAD~1` is the narrowed anchor, only selected when step 12's convergence comparison fires "narrow" for round NN+1.
- `HEAD~1` safety depends on a per-round commit anchor file (`reviews/{step}/round-NN-commit.txt`) whose SHA is compared via `git rev-parse HEAD~1` before narrowing commits. If the SHAs differ, the system falls back to `<base-branch>`.
- Every per-step SKILL.md (goals, design, structure, plan, phasing, parallelize, research, questions, replan) contains an inline "Pre-dispatch diff-file emission" paragraph that states the `git -C "<repo>" diff "<ref>" -- "<artifact_path>"` command and defers selection-rule detail to `using-qrspi/SKILL.md`.
- `skills/implement/SKILL.md` uses `<task-base-commit>` as its broaden default (not `<base-branch>`), narrowing to `HEAD~1` via an identical convergence comparison within each task's worktree.
- `skills/integrate/SKILL.md` runs `git -C "<repo>" diff "<ref>"` with no `<artifact_path>` argument, covering the entire merged feature branch.
- `skills/test/SKILL.md` explicitly opts out of diff-file emission and convergence narrowing entirely (separate from `scope_tagger_enabled`).
- `skills/plan/SKILL.md:596` uses a separate non-review-loop anchor: the `phase_start_commit:` field (captured as `git rev-parse HEAD` at plan approval time), described as "the diff anchor Replan and Test use to scope post-phase changes."
- `skills/implement/references/resume-preconditions.md` uses `git merge-base` to check worktree in-sync state, not for diff-file construction.
- `skills/implementer-protocol/SKILL.md:152` uses `git -C <worktree> diff HEAD~1 --unified=0` to obtain added lines for a post-commit scan, distinct from the reviewer diff-anchor mechanism.
- **No script in `scripts/` computes `<ref>` selection, emits round-NN.diff files, or implements the convergence-narrowing logic.** `scripts/run-codex-review.sh` accepts a `--diff-file` path and forwards it; `scripts/sibling-impact.mjs` computes `<commit>^` vs `<commit>` for cross-task drift detection, an unrelated mechanism.
- All agent files (32 reviewer agents in `agents/`) contain the same boilerplate "Diff-file handling" section stating `<ref>` is `<base-branch>` default or `HEAD~1` on convergence narrowing, and cross-referencing `using-qrspi/SKILL.md`.

**Surprises:** The `<base-branch>` anchor is described as a simple branch-name reference passed directly to `git diff` — `git merge-base` is never mentioned in the context of the Standard Review Loop diff construction. Instead, `git merge-base` appears only in `skills/implement/references/resume-preconditions.md` for worktree re-attach inspection, a completely separate use case.

**Caveats:** The test files in `tests/unit/` were checked for additional implementation but contain only prose-assertion bats tests (text-scanning skills files, not bash code that runs git). No additional scripts beyond those enumerated were found in `scripts/`. The `skills/test/SKILL.md` mentions `git diff main...HEAD` in a human-facing code review window (line 303) but this is a user suggestion, not orchestrator-driven diff-anchor construction.

---

## Full findings

### The canonical diff-anchor construction specification

**`skills/using-qrspi/SKILL.md`** is the single authoritative source. Two sections describe anchor construction:

#### § Standard Review Loop (lines 673–689)

Step 1 of the review loop is labeled "Orchestrator emits the round's diff file" (line 678). The key text:

> `<ref>` is `<base-branch>` by default and `HEAD~1` only when step 12's convergence comparison fires "narrow" against round NN.

The "Fail-loud diff-emission contract" (lines 680–687) specifies the exact shell command the orchestrator runs:

```
git -C "<repo>" diff "<ref>" -- "<artifact_path>" > "<ABS_ARTIFACT_DIR>/reviews/{step}/round-NN.diff"
```

With `<ref>` being `<base-branch>` by default and `HEAD~1` only on convergence narrowing. The preconditions include:
1. Artifact must be tracked in git (`git ls-files --error-unmatch`)
2. `mkdir -p` the round directory
3. `rm -f` any pre-existing diff file (to neutralize stale symlinks)
4. Emit with double-quoted placeholders
5. Check `$?` and abort on non-zero
6. A zero-byte diff after successful exit is valid (no changes vs `<ref>`)

#### § Review Output Handling → "Diff handling between rounds" and "Ref selection rule" (lines 1086–1105)

The narrative restatement labels the same command and adds the complete ref-selection decision table:

| Condition | `<ref>` |
|-----------|---------|
| Round 1 or 2 | `<base-branch>` |
| `scope_tagger_enabled: false` | `<base-branch>` |
| Test step | `<base-branch>` (hard opt-out) |
| Backward-loop reset | `<base-branch>` |
| Round NN scope-set missing | `<base-branch>` |
| Round NN ≥ 2, scope_set(NN) ⊆ scope_set(NN-1) | `HEAD~1` |
| Otherwise (superset/partial/disjoint) | `<base-branch>` |

The `HEAD~1` anchor selection additionally requires a per-round commit anchor assertion (line 1026/995): the orchestrator reads `reviews/{step}/round-(NN-1)-commit.txt` (the SHA captured after the prior round's git commit at step 11) and runs `git rev-parse HEAD~1`. If they differ, fall through to `<base-branch>` with a diagnostic.

#### Step 12 (ref selection, lines 999–1037)

Named "Ref selection for round NN+1 — executes after step 11's per-round commit." Consumes the verifier-filtered scope-sets from step 6 (scope-tagger dispatch) and decides `<ref>` and `<scope_hint>`. The per-round commit anchor capture happens at step 11 (line 995): `git commit` immediately followed by capturing `git rev-parse HEAD` into `reviews/{step}/round-NN-commit.txt`.

---

### Per-step SKILL.md inline descriptions

Every per-step skill file contains a **"Pre-dispatch diff-file emission"** paragraph that states the git command inline and defers detail to `using-qrspi/SKILL.md`. The paragraph text is near-identical across all steps:

| File | Line | Artifact path in command | Notes |
|------|------|--------------------------|-------|
| `skills/goals/SKILL.md` | 238 | `"<ABS_ARTIFACT_DIR>/goals.md"` | Standard single-file |
| `skills/design/SKILL.md` | 153 | `"<ABS_ARTIFACT_DIR>/design.md"` | Standard single-file |
| `skills/structure/SKILL.md` | 151 | `"<ABS_ARTIFACT_DIR>/structure.md"` | Standard single-file |
| `skills/plan/SKILL.md` | 271 | `"<ABS_ARTIFACT_DIR>/plan.md" "<ABS_ARTIFACT_DIR>/tasks/"` | Multi-path artifact |
| `skills/phasing/SKILL.md` | 106 | `"<ABS_ARTIFACT_DIR>/phasing.md"` | Standard single-file |
| `skills/parallelize/SKILL.md` | 176 | `"<ABS_ARTIFACT_DIR>/parallelization.md"` | Standard single-file |
| `skills/research/SKILL.md` | 135 | `"<ABS_ARTIFACT_DIR>/research/summary.md"` | Standard single-file |
| `skills/questions/SKILL.md` | 81 | `"<ABS_ARTIFACT_DIR>/questions.md"` | Standard single-file |
| `skills/replan/SKILL.md` | 109 | `"<ABS_ARTIFACT_DIR>/plan.md"` | Notes diff is vs prior `plan.md`, not the Replan analyzer output |

All nine paragraphs state: "`<ref>` is `<base-branch>` by default and `HEAD~1` only when using-qrspi step 12 (ref selection) narrowed for this round." All cross-reference `using-qrspi/SKILL.md § Standard Review Loop step 1` for the fail-loud precondition list.

**`skills/integrate/SKILL.md:91`** is the exception: the command is `git -C "<repo>" diff "<ref>"` with no `<artifact_path>` (the entire merged feature branch diff). The `<ref>` default is `<base-branch>` but the section explicitly notes the integrate precondition #1 (artifact-tracked-in-git) is skipped; the other five still apply.

**`skills/test/SKILL.md:104–106`** explicitly opts out. The prose states: "The orchestrator does NOT emit a `round-NN.diff` for the test step and does NOT pass `diff_file_path` to the dispatches." The opt-out is independent of `scope_tagger_enabled` in `config.md`.

---

### Implement skill — task-base-commit as the broaden default

**`skills/implement/SKILL.md:919`** contains a separate "Pre-dispatch diff-file emission" paragraph for the per-task review context:

```
git -C ".worktrees/{slug}/task-NN/" diff "<ref>" > "<ABS_ARTIFACT_DIR>/reviews/tasks/task-NN/round-NN.diff"
```

Key distinction: `<ref>` broaden default is **`<task-base-commit>`** (the commit each task worktree forked from, read from `parallelization.md`'s Branch Map), not `<base-branch>`. Narrowing still uses `HEAD~1` via the same convergence rule (line 1209), with the anchor assertion using `reviews/tasks/task-NN/round-(NN-1)-commit.txt`.

The Implement gate reviewer (line 1215) is explicitly noted as a non-loop reviewer — no convergence narrowing fires, and it uses `<ref>=<base-branch>` for its diff.

---

### Agent files — reviewer-side diff handling

All 32 reviewer agents in `agents/` contain a "Diff-file handling" section derived from `skills/reviewer-protocol/SKILL.md:46`. The text is uniform across agents (verified in `qrspi-code-quality-reviewer.md:123` and `qrspi-implement-gate-reviewer.md:60`):

> If `diff_file_path` is provided in your dispatch prompt, Read that file with the Read tool to see the artifact-under-review diff against the orchestrator-configured `<ref>` (`<base-branch>` by default; `HEAD~1` only when the convergence rule narrowed for this round — see the Scope Hint section below). The orchestrator emits the diff once per round via `git diff <ref> -- <artifact_path>` redirect (see `## Reviewer Dispatch Contract` in the reviewer-protocol skill ...).

The agents describe the anchor mechanism from the consumer side: they read the pre-computed file and understand the two possible refs, but own no computation themselves.

**`skills/reviewer-protocol/SKILL.md:46`** is the template source. It describes the `<diff_file_path>` parameter and states the same anchor rule, cross-referencing `using-qrspi § Standard Review Loop step 1` and `step 12 (ref selection)`.

---

### Phase-start commit anchor — a separate mechanism

**`skills/plan/SKILL.md:596`** describes a different kind of diff anchor:

> "At plan.md approval time, capture the current HEAD SHA into plan.md frontmatter's `phase_start_commit:` field. This is the diff anchor Replan and Test use to scope post-phase changes."

Implementation (line 598): `git -C <artifact_dir> rev-parse HEAD` at plan approval time, written into `plan.md` frontmatter alongside `status: approved`. If the artifact dir is not in a git repo, `phase_start_commit: null` — Replan and Test fall back to whole-codebase scope. This anchor is distinct from the round-NN.diff anchor: it is captured once per phase at approval time and is used by downstream steps to scope their own diff queries (e.g., `git diff <phase_start_commit>...HEAD`).

---

### git merge-base — resume-preconditions, not review loop

**`skills/implement/references/resume-preconditions.md`** is the only site where `git merge-base` appears in the context of anchor construction, and it is explicitly for task-worktree resume classification, not for review-loop diff emission:

> `common_ancestor = git merge-base qrspi/{slug}/task-NN <expected_base>`

This determines whether a leftover task branch is "in-sync" or "diverged" from its expected fork point — a state-classification check before deciding whether to reuse or reset the worktree. It has no connection to round-NN.diff generation.

---

### implementer-protocol HEAD~1 — post-commit scan, not review-loop anchor

**`skills/implementer-protocol/SKILL.md:152`** uses `HEAD~1` in a different context:

> `git -C <worktree> diff HEAD~1 --unified=0 | grep '^+'`

This obtains the added lines from the implementer's most recent commit to run internal-ID and evergreen-markdown forbidden-token scans before reporting DONE. It is an implementer self-check, not orchestrator diff-anchor construction for reviewer dispatch.

---

### scripts/ — no implementation of round-NN.diff generation

No script in `scripts/` computes the `<ref>` anchor, emits round-NN.diff files, or implements the convergence-narrowing logic. The scripts directory contains:

| Script | Relevance to diff anchors |
|--------|--------------------------|
| `scripts/run-codex-review.sh` | Accepts `--diff-file <path>` (line 30) and `--scope-hint` (line 31). Forwards these as `diff_file_path:` (line 510) and `scope_hint:` (line 514) into the assembled dispatch prompt. Does **not** compute `<ref>` or emit the diff file itself. |
| `scripts/sibling-impact.mjs` | Uses `git diff --name-only <commit>^ <commit>` (lines 175–200) to find files changed by a specific implementation commit for cross-task notification. Uses `git rev-parse --verify <commit>^` (line 181) as a parent-existence check. Unrelated to review-loop diff anchors. |
| `scripts/codex-companion-bg.sh` | Uses `git rev-parse --show-toplevel` (line 669) to locate workspace root. No diff anchor computation. |
| All other scripts | No git diff or merge-base usage. |

The skill documentation explicitly specifies that diff emission is an orchestrator-in-main-chat operation ("the orchestrator runs `git -C ...` as a Bash redirect"), not a delegated script. The `scripts/run-codex-review.sh` shim receives a pre-computed diff file path from the orchestrator and forwards it to the reviewer dispatch — the diff construction itself is not delegated to this or any other script.
