# Prose Bundle: #113 fixes→dispositions rename + #41 Group→Wave collapse + #90 nested-task naming

**Status:** Design
**Issues:** [#113](https://github.com/dfrysinger/qrspi-plus/issues/113), [#41](https://github.com/dfrysinger/qrspi-plus/issues/41), [#90](https://github.com/dfrysinger/qrspi-plus/issues/90)
**Milestone:** v0.5
**Date:** 2026-05-05

## 1. Bundle Rationale

Three cross-cutting prose changes that share both a risk profile and a test surface:

- **#113** — pure rename (`round-NN-fixes.md` → `round-NN-dispositions.md`)
- **#41** — vocabulary collapse (Parallel Group → Wave)
- **#90** — naming convention for sub-tasks under each Wave (`  └─ task-NN ...`)

All three are SKILL.md-prose edits with bats grep-based tests; none touch schema, routing, or runtime control flow. Per the qrspi-plus prose-handling preference: skip full reviewer suite, decide test handling per change, no TDD ceremony for non-runtime edits.

Bundling avoids three near-identical "audit and edit prose" PRs back-to-back. Each section below is independently implementable; the sequencing in §5 keeps grep-guards and rename targets from stepping on each other.

## 2. #113: Rename `round-NN-fixes.md` → `round-NN-dispositions.md`

### 2.1 Problem

The per-round main-chat-authored summary file is named `round-NN-fixes.md` but its content can legitimately include `disposition: no-action` entries (the fix-round agreed with the user that the finding is intended behavior, or that the finding is wrong). The current name implies every entry produced a code change, which is false.

### 2.2 Fix shape

Rename the artifact across every reference site. No semantic or content change to the file itself — only its filename and the prose pointing at it.

Confirmed reference sites (`grep -rE "round-[0-9N]+-fixes|fixes\.md"` across `skills/`, `agents/`, `tests/`):

| File | Lines | Surface |
|---|---|---|
| `skills/using-qrspi/SKILL.md` | 171, 191, 493, 656, 660, 709 | Artifact tree (`round-01-fixes.md` example + `round-NN-fixes.md` template), Per-Round Commit prose, Round-NN Fixes Document section header + body, Per-Round Commit Coverage block |
| `tests/unit/test-verifier-dispatch-contract.bats` | 22 | grep-guard regex `Write.*round-NN-fixes\.md` |
| `tests/unit/test-no-legacy-disk-write-references.bats` | 12 | comment listing legitimate non-reviewer artifacts |

The `using-qrspi` surface is the canonical one; per-skill SKILLs reference the contract through `using-qrspi` rather than re-naming the file directly. Confirmed by inverse grep: no `skills/{plan,implement,integrate,...}/SKILL.md` references the literal filename. (One implicit reference: the per-round commit description in each per-skill review-round section says "fixes" as a noun — those stay; the rename is filename-only, not concept-renaming.)

### 2.3 Test handling

- **Update** `tests/unit/test-verifier-dispatch-contract.bats:22` regex from `Write.*round-NN-fixes\.md` → `Write.*round-NN-dispositions\.md`. Existing assertion semantics preserved.
- **Update** the comment in `tests/unit/test-no-legacy-disk-write-references.bats:12` to list `round-NN-dispositions.md` instead of `round-NN-fixes.md` — the test itself doesn't enforce that name, the comment is documentation.
- **Add** a new bats assertion in `test-no-legacy-disk-write-references.bats` (or a sibling file) that fails on any remaining `round-NN-fixes\.md` literal in `skills/`, `agents/`, or `docs/superpowers/` — guards against partial rename:

  ```bash
  @test "no skill or agent file references the legacy fixes filename" {
    local offenders
    offenders=$(grep -rnE 'round-[0-9N]+-fixes\.md' skills/ agents/ 2>/dev/null || true)
    if [ -n "$offenders" ]; then
      echo "legacy round-NN-fixes.md references remain:"
      echo "$offenders"
      return 1
    fi
  }
  ```

  Five lines of bats; same shape as the existing legacy-pattern guards introduced for #125.

### 2.4 Out of scope

- **Renaming the *concept*** ("fix-round" → "disposition-round"). The orchestrator step that produces this file is still naturally called "fix-apply" — most rounds do produce fixes; "disposition" is the more accurate name for *the file*, not for the orchestrator phase. Keep "fix-round" prose intact.
- **Migrating existing on-disk artifacts** in `reviews/{step}/round-NN-fixes.md` from prior runs. The rename is forward-only; historical artifacts keep their old name. (Untracked `reviews/` dirs are gitignored anyway.)

## 3. #41: Collapse Parallel Group into Wave (Phase / Slice / Task / Wave)

### 3.1 Problem

QRSPI today maintains five levels of decomposition for one body of work — Phase, Vertical Slice, Task, Parallel Group, Dispatch Wave. The Parallelize SKILL spends a ~200-word disambiguation paragraph (line 72 of `skills/parallelize/SKILL.md`) explaining why Group ≠ Wave despite the two being numbered 1:1 in every realistic phase. F-22 evidence: the 9-task v0.4-bundle test produced exactly one parallel group per wave; the theoretical "multiple disjoint groups in one wave" case never materialized. Cognitive load + explicit user complaint.

### 3.2 Fix shape — semantic decision

**Wave is the surviving name.** "Parallel Group" deletes from the vocabulary. Wave inherits *all* of Group's invariants:

- Wave membership = tasks share a base AND have no file overlap (was Group's defining invariant)
- Wave numbering does not imply dispatch ordering (was Group's caveat; Wave's own caveat is dropped — concurrency is a runtime property, not a vocabulary concept)
- Wave bases use the same symbolic vocabulary (`feature branch tip`, `task-NN tip`, `stage-after-W{N}`, `task-00 tip`)

**Concurrency derives from the Wave dependency graph at runtime, not from "Waves can contain multiple Groups."** Implement's runtime rule becomes: "Each tick, dispatch every Wave whose dependencies are satisfied and whose tasks are not yet dispatched." A "wave with two groups in it" under the old vocab becomes "two Waves with no inter-Wave dependency, dispatched concurrently" under the new vocab.

**Slice stays as a Design-time soft conceptual aid** (vertical slice across the architecture), not a Branch Map entity — same status it has today. Phasing produces Phases; Plan produces Tasks; Parallelize groups Tasks into Waves. Slice is referenced in Design prose only.

**Stage-commit naming consequence.** `stage-after-G{N}` → `stage-after-W{N}`. The branch ref name changes (`qrspi/{slug}/stage-after-G{N}` → `qrspi/{slug}/stage-after-W{N}`); existing on-disk branches from prior runs keep their G-named refs (forward-only rename).

### 3.3 Sweep targets

Confirmed sites (`grep -rnE "Parallel Group|parallel group|Dispatch Wave|stage-after-G"` across `skills/` and `agents/`):

| File | Surface |
|---|---|
| `skills/parallelize/SKILL.md` | Lines 50, 60–62 (table), 72 (disambiguation paragraph — DELETE), 73, 75, 82, 88, 98, 101, 111, 114, 133–134 (terminal output example), 249, 259, 262, 289, 293–298 (Hybrid example table), 302–304 (Wave 1/Wave 2 narrative), 348, plus `stage-after-G` everywhere |
| `skills/parallelize/owns-defers.md` | Lines 6–7 (file-overlap analysis prose) |
| `skills/integrate/SKILL.md` | "Merge Strategy" section — references `stage-after-G{N}` and parallel-group concepts |
| `skills/phasing/owns-defers.md` | Cross-skill reference to parallelize |
| `agents/qrspi-parallelize-reviewer.md` | Reviewer body — references "parallel groups" / "dispatch waves" |
| `tests/acceptance/test-hardening-skills.bats` | bats grep-guard text checking for "parallel group" terminology |
| `skills/using-qrspi/SKILL.md` | Lines mentioning Wave / Group in Branch Model and Per-Round Commit prose |
| `skills/implement/SKILL.md` | Wave references in dispatch logic prose |
| `agents/qrspi-implement-gate-reviewer.md` | Wave / Group cross-references |

Implementer's audit step: re-grep on PR-tip to confirm zero remaining `Parallel Group` / `parallel group` / `parallel-group` literals (the bats guard in §3.4 enforces this).

The 200-word disambiguation paragraph at `skills/parallelize/SKILL.md:72` deletes entirely. It is replaced by a one-line definition at the same anchor:

> **Wave:** A set of tasks that share a base AND have no file overlap. Wave numbering does not imply dispatch ordering — Implement's runtime rule is "dispatch every Wave whose dependencies are satisfied each tick."

### 3.4 Test handling

- **Update** `tests/acceptance/test-hardening-skills.bats` grep assertions that look for "parallel group" / "Parallel Group" — flip them to look for "Wave" instead, OR (preferred) reframe each existing assertion around what it's actually testing (e.g., "the parallelize artifact lists dispatch concurrency" rather than "the artifact uses the word 'group'"), so the test isn't coupled to vocabulary.
- **Add** a regression guard in `tests/unit/` (new file: `test-no-parallel-group-vocab.bats`):

  ```bash
  #!/usr/bin/env bats
  # Guards #41: "Parallel Group" / "parallel group" / "stage-after-G" must not
  # reappear in skill or agent prose after the Group→Wave collapse. Allow-list
  # any historical references in docs/superpowers/specs/ and reviews/ (frozen
  # artifacts from before the rename).

  @test "no Parallel Group vocabulary in skills/" {
    local offenders
    offenders=$(grep -rnE 'Parallel Group|parallel group|parallel-group' skills/ 2>/dev/null || true)
    if [ -n "$offenders" ]; then
      echo "legacy Parallel Group vocabulary remains:"
      echo "$offenders"
      return 1
    fi
  }

  @test "no stage-after-G branch naming in skills/ or agents/" {
    local offenders
    offenders=$(grep -rnE 'stage-after-G[0-9{]' skills/ agents/ 2>/dev/null || true)
    if [ -n "$offenders" ]; then
      echo "legacy stage-after-G naming remains (should be stage-after-W):"
      echo "$offenders"
      return 1
    fi
  }

  @test "no Parallel Group vocabulary in agents/" {
    local offenders
    offenders=$(grep -rnE 'Parallel Group|parallel group|parallel-group' agents/ 2>/dev/null || true)
    if [ -n "$offenders" ]; then
      echo "legacy Parallel Group vocabulary remains in agents/:"
      echo "$offenders"
      return 1
    fi
  }
  ```

  ~30 lines of bats; same shape as the legacy-pattern guards from #125.

### 3.5 Out of scope

- **F-23 Parallelize presentation cleanup.** F-23 is downstream — only makes sense after Group/Wave merge — but it's not in v0.5. Deferred to a future milestone. This spec touches the disambiguation paragraph; F-23 will touch the broader narrative shape later.
- **Schema/runtime change to the dispatch loop.** Implement's existing wave-dispatch logic already implements the "dispatch every unblocked group concurrently" rule under different naming. This rename does not change runtime behavior — only how the rule is described.
- **Reviewer-prompt regeneration.** Parallelize reviewer agent file gets the vocabulary update, but the reviewer's *checks* (file-overlap, symbolic-base vocabulary, stage commits, completeness) are unchanged.

## 4. #90: Nested-Task Naming Convention for TaskCreate UI

### 4.1 Problem

Claude Code's TaskCreate has no nested-task support — no `parentId`, no subtask field, no indent-by-dependency renderer. QRSPI's natural hierarchy (Phase → Wave → Task → Subagent dispatch) is invisible in the task list. F-24 (`docs/qrspi/2026-04-26-findings.md`) flagged this; the workaround it proposes is a naming-prefix convention.

### 4.2 Fix shape

Adopt a one-line convention for sub-tasks under each Wave: prefix with `  └─ ` (two leading spaces + box-drawing tee). Document the convention once in `using-qrspi/SKILL.md`, then reference it from every SKILL that creates per-task TaskCreate entries.

**Convention text** (added to `using-qrspi/SKILL.md` as a new short subsection within the existing TaskCreate guidance):

```markdown
### TaskCreate naming for QRSPI hierarchy

Claude Code's TaskCreate has no native nested-task UI. To make QRSPI's hierarchy visible in the task list, use this naming convention:

- **Phase / Wave parent task:** `Phase 2 / Wave 3 — auth endpoints`
- **Sub-task under a Wave:** `  └─ task-04: validate JWT signature`

Two leading spaces + the box-drawing tee (`└─`) indents the sub-task one level visually. The convention is naming-only — TaskCreate has no schema for nesting; orchestrators set parent status manually as sub-tasks complete. Do not introduce extra indentation levels (no `  ├─ ` or three-deep nesting); QRSPI is two levels max in the TaskCreate surface.
```

### 4.3 Sweep targets

This is **additive prose only.** No existing TaskCreate sites need to be retroactively renamed in the source SKILLs — the convention applies at *runtime* TaskCreate calls the orchestrator makes, not in skill text. The only edits:

- **Add** the convention subsection to `skills/using-qrspi/SKILL.md` (the umbrella every SKILL preloads).
- **Optionally** add a one-line cross-reference in `skills/parallelize/SKILL.md` near where Wave dispatch is described, pointing at the convention. (Optional because the umbrella is already preloaded.)

### 4.4 Test handling

**No bats test.** The convention is a documentation guideline, not a runtime contract. Adding a grep that asserts "TaskCreate calls follow the convention" would require parsing TaskCreate invocations in skill text, but the runtime calls are *generated by the orchestrator*, not present as literal strings in the skills. Test debt would be misaligned with what the convention actually enforces.

If a future PR adds a runtime hook that lints TaskCreate subjects, it could enforce this convention. Out of scope here.

### 4.5 Out of scope

- **F-22 / F-23 hierarchy work.** F-22 is #41 (this spec). F-23 is the parallelization-presentation cleanup deferred above.
- **Engaging Claude Code on real nested-task UI** (`parentId` schema, indent renderer). Anthropic-side work; QRSPI uses the workaround until upstream support exists.
- **Three-level nesting** (Phase → Wave → Task → Sub-task in the TaskCreate UI). YAGNI — QRSPI's natural depth is two levels at the TaskCreate surface; deeper hierarchy lives in the artifact tree.

## 5. Sequence

Single PR, **three commits** grouped by atomicity unit:

1. **`docs(skills): #113 rename round-NN-fixes.md → round-NN-dispositions.md`** — touches `using-qrspi/SKILL.md` filename references, `tests/unit/test-verifier-dispatch-contract.bats:22` regex, `tests/unit/test-no-legacy-disk-write-references.bats:12` comment, and adds the new `round-NN-fixes\.md` legacy guard. Smallest blast radius; lands first.
2. **`docs(skills): #41 collapse Parallel Group into Wave (Phase/Slice/Task/Wave)`** — sweeps every "Parallel Group" / "stage-after-G" site per §3.3, deletes the disambiguation paragraph at `parallelize/SKILL.md:72`, replaces with one-line definition, updates bats guards (`test-hardening-skills.bats` reframe + new `test-no-parallel-group-vocab.bats`).
3. **`docs(using-qrspi): #90 add TaskCreate naming convention for QRSPI hierarchy`** — additive subsection in `using-qrspi/SKILL.md` only.

Test plan:
- `bats tests/unit/test-verifier-dispatch-contract.bats` — passes (regex updated to new filename).
- `bats tests/unit/test-no-legacy-disk-write-references.bats` — passes (comment updated; new fixes-filename guard added at end of commit 1).
- `bats tests/unit/test-no-parallel-group-vocab.bats` — passes after commit 2 (new file).
- `bats tests/acceptance/test-hardening-skills.bats` — passes after commit 2 (vocabulary reframe).
- `bats tests/unit/` full suite — same baseline failures as parent (`a1db28d`); no regressions.
- Manual scan: open `parallelize/SKILL.md` and confirm the disambiguation paragraph is gone and Wave/Slice/Task vocabulary reads cleanly. Open `using-qrspi/SKILL.md` and confirm the new TaskCreate-naming subsection sits naturally next to existing TaskCreate prose.

## 6. Backwards Compatibility

Pure prose. No agent file invocation contract, schema, or routing impact. All three changes are forward-only renames or additions — historical on-disk artifacts (old `round-NN-fixes.md` files, branches named `stage-after-G{N}`) keep their existing names; new runs use the new names. The orchestrator does not need a migration shim.

## 7. Closes

- Closes #113
- Closes #41
- Closes #90
