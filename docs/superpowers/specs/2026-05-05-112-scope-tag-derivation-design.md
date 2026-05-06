# #112: Convergence-Driven Diff Narrowing via `scope_tag` Subagent

**Status:** Design
**Issue:** [#112](https://github.com/dfrysinger/qrspi-plus/issues/112)
**Source plan:** Combined Opts #2 + #7 of `qrspi-review-optimization-plan.md`
**Milestone:** v0.5
**Date:** 2026-05-05

## 1. Problem

Long review loops on a single artifact pay full-token cost every round. A real example: the v0.4 bundle's `goals.md` review held three Claude+Codex reviewers reading the entire 1838-line bundle every round even when round-N-1 and round-N findings had already converged on the same surface (`## Approach`). Estimated waste: ~$8–10/round once findings have stabilized.

Two independent token-savings mechanisms in the optimization plan address this; both are bundled here because they compose naturally and share infrastructure.

## 2. Design

### 2.1 Two mechanisms, one PR

**Mechanism A — orchestrator-generated diff file:** the orchestrator runs `git diff <ref> -- <artifact_path> > reviews/{step}/round-NN.diff` once per round (Bash redirect: diff content never enters orchestrator context). Both reviewers (Claude + Codex) Read the same file. Single git op per round, byte-identical reviewer input, no main-chat pollution from the diff.

**Mechanism B — `scope_tag` subagent + convergence detection:** a dedicated `qrspi-scope-tagger` subagent reads each round's kept findings post-verifier-fan-in and emits a `scope-set` file. Main chat compares the current round's scope-set to the prior round's; on convergence (rule per §2.4) it narrows the next round's diff and injects a focus hint into reviewer prompts.

A is a useful mechanism on its own (purely how reviewers receive the diff). B is what creates the convergence-driven savings. They land in the same PR because B's narrowing is implemented by changing A's `<ref>` selection at dispatch time.

### 2.2 Why a dedicated subagent (not orchestrator-derived)

The optimization plan's original framing said "orchestrator-derived" because the work piggy-backs on the apply-fix turn that's already happening — main chat already reads findings and the artifact at that point.

In practice, this conversation chose Option C — a dedicated `qrspi-scope-tagger` Haiku subagent — for three reasons:

1. **Pattern consistency.** The verifier subagent introduced in #109 (a small Haiku model that scores each finding 0–100 and returns a structured sidecar) is the established precedent for "small structured task post-fan-in." Tagging is the same shape.
2. **Main-chat context preservation.** Main chat at apply-fix time is already heavy with synthesis state. Offloading the per-finding tag derivation to a subagent that returns only the structured tag list — never the finding bodies — keeps main chat's context focused on the apply-and-route work.
3. **Future-proofing.** If tag derivation gains nuance (e.g. cross-finding similarity scoring, semantic clustering within an H2 section), the subagent is the natural place for it. Orchestrator-derived would have to either accumulate the logic in main chat or get refactored to a subagent later anyway.

### 2.3 What the tagger derives

For each kept finding (kept = after the verifier filter from #109), the tagger derives one `scope_tag` string:

- **Multi-file artifacts** (integrate, implement-per-task, plan + tasks/, research/): `scope_tag = file path` from the finding's `referenced_files`. Already canonical in the existing schema; zero derivation work.
- **Single-file artifacts** (goals.md, design.md, questions.md, phasing.md, structure.md, parallelization.md, replan.md): `scope_tag = enclosing H2 heading text` (e.g. `"## Approach"`). The tagger reads the artifact body, parses heading structure, and maps each finding's line range to its enclosing H2. Granularity decision: **start at H2** (coarser, more conservative narrowing). H3 reconsidered if narrowing fires too rarely in practice.

**Reviewer-side prerequisite:** findings must include line-range citation in `referenced_files` (e.g. `path/to/file.md:120-145`). Most reviewers do already; this spec adds an enforcement note in the reviewer-protocol skill (one line — no schema field added).

### 2.4 Convergence rule (the narrowing decision)

After every round N ≥ 2, the orchestrator compares the current round's `scope_set(N)` to `scope_set(N-1)`. Decision:

| Relation between sets | Decision for round N+1 |
|---|---|
| `scope_set(N) == scope_set(N-1)` | **Narrow** to that set |
| `scope_set(N) ⊂ scope_set(N-1)` (proper subset) | **Narrow** to the broader set (= `scope_set(N-1)`) — safety margin against the dropped tags reappearing |
| `scope_set(N) ⊃ scope_set(N-1)` (proper superset; new tags appeared) | **Broaden** — back to full-scope |
| Partial overlap (neither subset relation holds) | **Broaden** — back to full-scope |
| Disjoint | **Broaden** — back to full-scope |

Notes on this rule:
- **Narrowing is incremental, not all-or-nothing.** A single tag in the set is not required; a 3-element set narrowing to a 2-element subset still narrows. Over successive rounds the diff size shrinks as findings stabilize.
- **Subset case uses the broader of the two sets** as the safety margin. If round N-1 had findings on `{Approach, Tradeoffs, Testing}` and round N had findings on `{Approach, Tradeoffs}`, round N+1 narrows to `{Approach, Tradeoffs, Testing}` — not just `{Approach, Tradeoffs}` — because we're not yet confident `Testing` is fully resolved.
- **Earliest narrowing = round 3** (needs scope-sets from rounds 1 and 2 to compare).
- **Auto-broaden** the moment a new tag appears (superset or partial overlap). The plan's "cluster breaks → return to full-scope" rule applies in any non-subset/non-equal case.

### 2.5 What the orchestrator does with a narrowed decision

When the rule says "narrow to set `S`":
1. Diff ref selection: `<ref> = HEAD~1` (this round's delta only, vs full-base).
2. Scope hint: `scope_hint = S` (a list of tags) is injected into reviewer dispatch prompts as advisory focus — not a hard restriction. Reviewers can still surface findings outside the hint if they notice them; that's exactly what triggers the auto-broaden on the next round.
3. The diff file (Mechanism A) is generated against `<ref>=HEAD~1`, so its byte size shrinks naturally with the narrower ref.

When the rule says "broaden":
1. `<ref> = base-branch` (full artifact treated as new).
2. No scope hint injected.

### 2.6 Per-step applicability

Convergence narrowing is enabled per-step. From the optimization plan, with no changes:

| Step | Apply convergence narrowing? | Reason |
|---|---|---|
| Goals / Questions / Research / Design / Phasing / Structure / Plan / Parallelize / Replan | **Yes** | Single-file (or small multi-file) artifacts; long review loops; primary target |
| Implement (per-task review) | For consistency only | Tasks usually narrow already; modest savings |
| **Integrate** | **Yes — high payoff** | Cross-task review touches many files; clustering into "auth-related changes" is exactly the right call |
| Test | **No** | Test reviewers analyze test quality / coverage gaps, not "where in the diff" — pattern doesn't fit |

## 3. Architecture

### 3.1 Where the tagger fits in the apply-fix flow

Current Apply-fix (per `using-qrspi/SKILL.md` § Apply-fix):

```
1. Enumerate finding-files in round-NN/
2. Compute round NN findings list
3. Verifier-enabled gate (config.md)
4. Parallel verifier dispatch (one Haiku per finding-file)
5. Main chat assembles round-NN-verified.md (kept vs dropped partition)
6. Apply scope/intent escalation rules
7. Edit auto-apply (style/clarity/correctness, score ≥80) OR pause-gate (scope/intent or low-score override)
```

#112 adds **one new substep** between 5 and 6:

```
5.5  Scope-tagger dispatch (one Haiku subagent reads kept findings, emits round-NN-scope-set.txt)
```

And a separate orchestrator step **after step 7** (after fixes are committed, before round NN+1 dispatch):

```
7.5  Convergence comparison + diff-file generation for round NN+1
     - Compare scope_set(NN) to scope_set(NN-1) per §2.4 rule
     - Choose <ref> per §2.5
     - Run `git diff <ref> -- <artifact_path> > reviews/{step}/round-(NN+1).diff`
     - Pass <diff_file_path>, <scope_hint> (if any) to round-(NN+1) reviewer dispatch
```

### 3.2 New artifact: `reviews/{step}/round-NN-scope-set.txt`

Tiny per-round file. Schema:

```
# scope-set for round 7
# generated_by: qrspi-scope-tagger
# total_findings_kept: 5
## Approach
## Tradeoffs
## Testing
```

Plain text, one tag per line, comments at top for diagnostics. Single-file artifact tags are H2 heading text (`## Approach`); multi-file artifact tags are file paths (`skills/research/SKILL.md`). The orchestrator reads only the tag lines (skips comments) when computing `scope_set`.

Choosing plain text over JSON: the orchestrator's set comparison is simple line-set equality; plain text gives a forensic-readable diff in `git log -p` between rounds (the user can see at a glance how the scope is evolving).

### 3.3 Tagger contract

`agents/qrspi-scope-tagger.md` — new file. Haiku, structured-output discipline.

**Inputs (via wrapped Task prompt):**
- `round_subdir`: absolute path to the round's directory
- `kept_findings`: list of finding-file paths after verifier filtering
- `artifact_path`: the single-file artifact (for H2 derivation), or null for multi-file artifacts
- `artifact_body`: artifact body wrapped between `<<<UNTRUSTED-ARTIFACT-START>>>` / `<<<UNTRUSTED-ARTIFACT-END>>>` markers (for H2 derivation), or null for multi-file artifacts

**Behavior:**
1. Read each kept finding (one at a time; small files).
2. Extract the line-range citation from `referenced_files`.
3. **Multi-file case:** emit `scope_tag = file path` from `referenced_files`.
4. **Single-file case:** parse the artifact body for H2 headings (lines matching `^## `), build a line-range index, find the H2 whose range contains the finding's line-range, emit that heading text as `scope_tag`.
5. Deduplicate the tag list and emit `round-NN-scope-set.txt` per §3.2.

**Output discipline:**
- Tagger writes only `round-NN-scope-set.txt`. No mutation of finding-files. No re-classification of `change_type` or `severity`.
- If a finding's `referenced_files` lacks line-range citation, the tagger emits a warning comment in the scope-set file (`# warning: F03 had no line-range; tagged as full-artifact`) and tags it with the artifact's whole-file marker (e.g. `<full>`). One whole-file tag in the set means convergence detection sees the round as "covers everything" — narrowing won't fire that round, which is the conservative behavior.

### 3.4 Tagger-disabled gate

Mirroring the verifier's `verifier_enabled` gate, add `scope_tagger_enabled: <bool>` to `config.md`. Default `true` for fresh runs. When `false`:
- Step 5.5 is skipped (no tagger dispatch, no scope-set file emitted).
- Step 7.5's convergence comparison treats every round as full-scope (no narrowing fires).
- Reviewer dispatch falls through to today's full-base-diff behavior.

Same backfill semantics as `verifier_enabled` — missing field on resumed pre-#112 runs treated as `true` with a one-line stderr warning.

### 3.5 Reviewer dispatch changes

Each reviewer Task prompt today includes the artifact body wrapped in untrusted-data markers. Two changes:

1. **Add `<diff_file_path>` parameter.** The diff file (Mechanism A) lives at `reviews/{step}/round-NN.diff`. Reviewer reads it via the Read tool; the diff content does not appear in the dispatch prompt.
2. **Add optional `<scope_hint>` parameter.** When present (narrowing fired), reviewer prompts include a one-line advisory: "This round's diff is narrowed to: {scope_hint}. Focus your review on this surface but flag anything significant outside it."

The reviewer-protocol skill needs an updated dispatch contract section documenting both parameters. Existing reviewer agent files need updates to document the diff-file Read pattern.

## 4. Files touched

### New
- `agents/qrspi-scope-tagger.md` — new agent file (~150 LOC; smaller than the verifier because the work is more structured)
- `tests/unit/test-scope-tagger-dispatch.bats` — tagger output schema regression
- `tests/unit/test-convergence-narrowing.bats` — orchestrator convergence-rule unit tests (table-driven over the §2.4 cases)
- `tests/unit/test-diff-file-emission.bats` — Mechanism A regression (orchestrator generates diff file; reviewer dispatch carries the path)

### Modified — orchestration
- `skills/using-qrspi/SKILL.md`:
  - § Apply-fix: insert step 5.5 (tagger dispatch)
  - § Apply-fix: insert step 7.5 (convergence comparison + diff-file generation for next round)
  - § Configuration: document `scope_tagger_enabled`
  - § Artifact tree: add `round-NN-scope-set.txt` and `round-NN.diff` to the per-round directory listing
- `skills/reviewer-protocol/SKILL.md`:
  - One-line note: `scope_tag` is derived by `qrspi-scope-tagger` post-fan-in, not reviewer-emitted
  - Reviewer dispatch contract: document `<diff_file_path>` and optional `<scope_hint>` parameters
  - Reviewer-boilerplate: line-range citation in `referenced_files` is required (most reviewers do this already; the note formalizes the requirement)

### Modified — per-skill review-round wiring (per the §2.6 applicability table)
- `skills/{goals,questions,research,design,phasing,structure,plan,parallelize,replan}/SKILL.md` — Yes, primary target
- `skills/integrate/SKILL.md` — Yes, high payoff
- `skills/implement/SKILL.md` — for consistency
- `skills/test/SKILL.md` — explicitly opts out (one-line note)

Each per-skill update is mechanical: replace "reviewer reads the artifact and produces findings" framing with "orchestrator generates `round-NN.diff` via Bash redirect; reviewer dispatch carries the diff-file path."

### Modified — agent files
- `agents/qrspi-{quality,scope}-reviewer.md` (Claude reviewers per skill) — document the new diff-file Read pattern + optional scope_hint focus
- Codex reviewer dispatch skills — document the same two parameters

### Tests touched
- Existing apply-fix bats (`tests/unit/test-using-qrspi.bats`, `tests/acceptance/test-pipeline-ordering.bats`) — extend to cover the new tagger step + convergence path

## 5. Sequence

This is the heaviest of the v0.5 round-4 specs. Strongly consider splitting implementation into two PRs:

- **PR-1 (Mechanism A read-only): orchestrator-generated diff file.** Add the diff file generation, route reviewer dispatch through it, but keep round NN+1 always running with `<ref>=base-branch`. No tagger, no convergence logic, no narrowing. Independently valuable: takes the diff out of main chat. Safe to land first.
- **PR-2 (Mechanism B): tagger + convergence narrowing.** Add the tagger agent file, the scope-set file emission, the convergence rule, the dispatch-time `<ref>` selection logic, and the optional `scope_hint` advisory. Builds on PR-1's diff-file infrastructure.

If implementation goes single-PR, **commit ordering**:
1. `feat(scripts): #112 orchestrator generates round-NN.diff via Bash redirect`
2. `feat(skills): #112 reviewer dispatch reads diff file (Mechanism A wiring)`
3. `feat(agents): #112 add qrspi-scope-tagger agent file`
4. `feat(skills): #112 wire tagger dispatch + scope-set file emission`
5. `feat(config): #112 scope_tagger_enabled gate + backfill`
6. `feat(skills): #112 convergence rule + ref selection + scope_hint advisory`
7. `test(unit): #112 tagger + convergence + diff-file regression`

Test plan:
- New bats files pass (tagger schema, convergence rule table-driven, diff-file emission).
- Existing apply-fix bats green.
- Manual: drive a long review loop on a single-file artifact (e.g. design.md) with stable findings on `## Approach`. Confirm:
  - Round 1 + 2 fire full-scope; scope-set files emitted correctly.
  - Round 3 narrows (`<ref>=HEAD~1`, scope_hint = `## Approach`).
  - If round 3 surfaces a finding on `## Tradeoffs`, round 4 broadens back.
- Manual: same loop with `scope_tagger_enabled: false` — confirm no tagger dispatch, no narrowing, behavior matches today.

## 6. Reviewer Suite

Heavily runtime-touching: new agent file, new orchestration step, new dispatch parameters, new convergence logic. Full reviewer suite required: spec, code-quality, security, silent-failure, goal-traceability, test-coverage, type-design (the scope-set comparison rules and tagger output schema warrant type-design review). Implement-stage gate enabled. The qrspi-plus prose-handling preference does **not** apply.

## 7. Out of scope

- **Reviewer-set `scope_tag`.** Explicitly rejected per the v0.5 sequencing constraint (normalization drift + perspective leak). The tag is orchestrator-side, computed by the tagger subagent.
- **Section-level diff filtering.** Mechanism A narrows by ref (`HEAD~1` vs base-branch), not by file/section. Section-level diffing isn't a native git operation; the `scope_hint` in reviewer prompts handles within-file focus advisorily. If hint-based focus proves insufficient, file/section filtering is a future spec.
- **Cross-round cluster persistence beyond `(N-1, N)` pairwise comparison.** No attempt at "this scope reappeared after broadening for two rounds, narrow again." Pairwise is what the rule covers; multi-round history is a future spec if pairwise undershoots.
- **Tag normalization registry.** Tags are descriptive strings; no canonical-form enforcement, no validator. The deterministic-orchestrator-derivation property in §2.2 is what prevents normalization drift.
- **Session-state caching of scope-sets across `/compact`.** The scope-set files live on disk per round; resume after compact reads them from disk. No in-memory cache.

## 8. Backwards Compatibility

- **Pre-#112 runs.** Resume into a pre-existing run directory: `scope_tagger_enabled` backfill (per §3.4) treats missing field as `true` with one-line warning; first round after upgrade runs the tagger. Prior rounds have no scope-set file on disk, so convergence comparison treats round NN-1 as a "missing prior" and stays full-scope until two consecutive rounds have scope-sets — earliest narrowing in a resumed run is round NN+2, not NN+1.
- **`scope_tagger_enabled: false`** is a clean opt-out; flow is identical to today.
- **Mechanism A diff files** are scratch artifacts; they're committed alongside the round's other review files but no consumer outside that round reads them.

## 9. Open / deferred decisions (from the optimization plan)

- **`scope_tag` granularity for single-file artifacts:** start at H2 per §2.3. Reconsider H3 if narrowing fires too rarely in practice.
- **Backward-loop edits:** when an earlier-artifact loop-back rewrites a downstream artifact, the orchestrator must reset `<ref>` to base-branch on the next round (the artifact has been rewritten; prior round's diff anchor is stale). Logic addition at loop-back reset points; flagged here so the implementer plans for it.
- **Round-1 default ref:** base-branch (artifact treated as fully new). Confirmed by the optimization plan.

## 10. Closes

- Closes #112
