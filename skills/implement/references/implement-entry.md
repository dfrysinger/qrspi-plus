# Implement Entry Detail

Read this file once per Implement entry — first activation of Implement in a phase (full pipeline) or in a quick-fix batch (quick mode). Sections 1 → 2 → 3 fire in order; do NOT re-read on fix-task dispatches within the same entry (those reuse `config.md` and the already-prepared feature branch).

This file consolidates every one-shot entry concern: smoke check (halt gate), task-count read (skip-decision gate), run-entry artifact preconditions, config validation, phase-level configuration prompt, subagent permissions, and baseline-tests handling.

## 1. Smoke Check (Halt Gate)

Before dispatching the first per-task wave, run this one-shot smoke check. Any failure aborts the entry with a named diagnostic; no per-task dispatch fires. Three conditions:

1. **Verifier agent exists and is readable.** `agents/qrspi-finding-verifier.md` must exist on disk. Failure: `"Implement smoke check failed: agents/qrspi-finding-verifier.md not found or not readable — verifier wiring cannot be activated for this phase."`.
2. **Sidecar write path is reachable.** `reviews/tasks/` must be a writable directory. Probe `.smoke-probe-NN` (NN = `config.md` `phase:`). Before the leftover-probe check, branch on the `phase:` field state:
   - **Field absent (fresh run):** runtime-backfill. Scan phase-bearing artifacts under the run's artifact directory — at minimum `reviews/tasks/.smoke-probe-NN` leftover probe filenames and `reviews/integration/round-NN-commit.txt` files. If no phase-bearing artifacts exist in any scanned source, choose `1`. If every observed ordinal is well-formed, choose `max(NN observed) + 1`. If any scanned source contains a malformed ordinal, or the sources conflict or are ambiguous, halt rather than silently selecting `1`. Before writing, assert no stale `reviews/tasks/.smoke-probe-NN` exists for the chosen ordinal; if it exists, halt with the leftover-probe diagnostic rather than overwriting. Write `phase: NN` back to `config.md` (preserving all other fields), then re-read `config.md` and confirm round-trip. On write failure or read-back mismatch, halt: `"Implement smoke check failed: could not backfill missing phase field to config.md — check write permissions"`.
   - **Field present but non-integer or < 1:** halt immediately: `"Implement smoke check failed: config.md has a malformed phase field (found: <raw value>). Expected positive integer."` — malformed values are not eligible for backfill (corrupted state, not a missing default).
   Read `references/process-steps.md` when the `phase:` field is absent or the backfill scan finds ambiguous/malformed phase ordinals — full backfill procedure, audit YAML schemas, and conflict-resolution rules.
3. **`config.md` carries a parseable `verifier_enabled` field.** Value must be exactly `true` or `false` (YAML boolean, case-sensitive). **Recorded as the phase-start snapshot — authoritative for the entire phase.** Held in main-chat context, NOT written to disk. `config.md` is orchestrator-exclusive-writer; subagents MUST NOT modify it. The HARD-GATE (§ Review Fix Loop step 5) compares against this snapshot, not a gate-time re-read.

All three pass → log `"Implement smoke check passed — verifier_enabled: <value>."` and proceed. When `verifier_enabled: false`, conditions 1 and 2 still apply; verifier dispatch and HARD-GATE are inactive for the phase.

<HARD-GATE>
Do NOT dispatch the first per-task wave before this smoke check passes. A failure halts the entry.
</HARD-GATE>

## 2. Task-Count Read and Dynamic Skip

Runs immediately after the smoke check, before any per-task / Parallelize / Integrate dispatch. The count-read decides between halt (N=0), dynamic-skip of Parallelize+Integrate (N=1), and normal full-pipeline dispatch (N>1).

### Count-Read Procedure

The count-read is a ONE-SHOT bind. The orchestrator reads all matching files into an in-memory list, counts from that list, and binds the result to `N`. The same `N` value governs the rest of the entry sequence — subsequent additions to `tasks/` after the bind do NOT update N. The orchestrator must NOT re-glob `tasks/` between this step and the completion of the first per-task dispatch; for the N=1 skip, the single task file's path is captured at count-read time and the dispatch references that captured path, not a fresh glob.

QRSPI's task-spec lifecycle is not designed for concurrent writes to `tasks/` during Implement entry; the orchestrator treats `tasks/` as quiescent and any concurrent write is operator error. As an optional cross-check at dispatch entry, the orchestrator MAY re-read the count; on mismatch, emit a loud diagnostic naming the mismatch and halt — do not silently proceed with a stale `N`.

Count files matching `tasks/task-[0-9][0-9].md` (or `tasks/task-[0-9][0-9][a-z].md` for Plan-induced letter-suffix splits like `task-07a`) whose YAML frontmatter carries `status: approved`. Bind the result to `N`.

- Include files matching the canonical globs exactly, readable, with `status: approved`.
- Exclude unreadable / unparseable files.
- Exclude `fixes/{type}-round-NN/task-NN.md` — only the top-level canonical task glob is counted.
- **Exclude `tasks/task-00*.md`** (including `task-00.md`, `task-00a.md`, etc.). Baseline-fix tasks are runtime-injected predecessor scaffolding and are not counted as primary plan tasks. N counts only `task-01.md` through `task-99.md`.
- **Filename precondition.** Non-canonical filenames in `tasks/` (e.g., `tasks/task-readme.md`, `tasks/task-template.md`) MUST NOT satisfy the count even with `status: approved`. Emit a `non-canonical-task-filename` diagnostic naming the offending file and halt.

### Filesystem error handling

Before counting individual files, verify the `tasks/` directory is readable:

- **Directory unreadable / glob fails** (`halt-tasks-dir-io-error`): abort with `"Implement entry halted: filesystem error reading <ABS_ARTIFACT_DIR>/tasks/ — <I/O error description>. Resolve the directory access issue before re-invoking Implement."` Attempt one audit append (see below) with `task_count: null`; abort regardless of audit-append outcome.

- **Individual canonical task file unreadable** (`halt-unreadable-task-file`): halt BEFORE binding N with a diagnostic naming the unreadable file. WARN-and-exclude is insufficient — silently excluding a single unreadable file from a two-task plan would shift `N` from 2 to 1 and trigger the dynamic-skip branch on the basis of an I/O error rather than an operator decision. Attempt one audit append with `task_count: null`.

If an audit append itself fails on top of an underlying I/O error, emit a canonical WARN to stderr (format: `<ISO-8601 UTC timestamp> WARN <branch-label> path=<absolute path> error=<errno description>`) and halt anyway, surfacing both the original diagnostic and the audit-write failure.

`N` is bound once from the in-memory list — only after every canonical task file has been successfully read.

### N=0 Branch — Halt (Precondition Violation)

> Filesystem errors are handled by the `halt-tasks-dir-io-error` path above. This branch covers only the case where the directory exists and is readable but contains zero approved canonical task files.

When the canonical glob succeeds but N=0, abort before any per-task dispatch with audit-log branch label `halt-zero-tasks`:

```
Implement entry halted: no approved plan tasks found in <ABS_ARTIFACT_DIR>/tasks/.
The canonical task glob (tasks/task-[0-9][0-9].md, tasks/task-[0-9][0-9][a-z].md)
matched no files with status: approved frontmatter. This is a precondition violation —
no plan tasks exist or all task specs are missing the required status: approved
frontmatter field. Resolve the missing or unapproved task specs before re-invoking
Implement.
```

N=0 is a **precondition violation**, not a degenerate single-task run — treated with the same fail-loud philosophy as the smoke check. Zero approved tasks means either no plan was produced or every task spec failed approval, and neither is safe to silently ignore.

Attempt one audit append with `task_count: 0`, `branch: halt-zero-tasks`. The abort is unconditional regardless of audit outcome (unlike N=1, which treats audit success as a hard precondition).

N=0 is **not the same as the N=1 branch**. The skip branch fires only on N=1; N=0 is always a halt. A quick-fix run that produces zero approved tasks halts; a full-pipeline run that produces zero approved tasks halts.

### N=1 Branch — Dynamic Skip of Parallelize and Integrate

When `N` is exactly one, the orchestrator **skips both Parallelize and Integrate dispatch** for this Implement entry. No Parallelize artifact is produced and no Integrate artifact is produced. The per-task implementation flow proceeds directly from the count-read to the single-task dispatch.

**The skip is purely dynamic and count-based.** It does not depend on `config.md: pipeline: quick`.

- A full-pipeline run (`pipeline: full`) that happens to yield exactly one approved task takes the skip branch.
- A quick-fix run (`pipeline: quick`) that somehow yields N > 1 approved task specs takes the full-pipeline branch.

The mode (derived from `config.md.route`) governs per-task orchestration shape; the N=1 skip is a count-based override on the Parallelize-and-Integrate dispatch layer only.

**Audit append is a required precondition for the skip.** Before bypassing Parallelize and Integrate, the orchestrator **must successfully append** one entry to `reviews/implement-entry-decisions.md` with `task_count: 1`, `branch: skip-parallelize-integrate`. If the append fails for any filesystem reason, the orchestrator **aborts with a named diagnostic** rather than silently bypassing:

```
Implement N=1 skip branch aborted: audit append to
<ABS_ARTIFACT_DIR>/reviews/implement-entry-decisions.md failed — <reason>. The audit
append is a precondition for the skip branch. Resolve the filesystem issue and
re-invoke Implement.
```

After a confirmed successful audit append, proceed directly to per-task dispatch for the single approved task, bypassing Parallelize and Integrate entirely. The per-task TDD + review flow is unchanged — the skip is additive at the entry-time orchestration layer only.

**Artifact Gating suspension for N=1.** The standard requirement for `parallelization.md` with `status: approved` is suspended when the N=1 skip fires. The absence of a Parallelize artifact is the expected consequence of the skip, not an error. The `branch: skip-parallelize-integrate` label in the audit append is the audit signal that this suspension is in effect.

**Security tradeoff — cross-task integration review.** Integrate's primary role is cross-task integration and security review. An N=1 run has no cross-task interactions to review — single-task Integrate would re-run the same per-task gates that already ran in Implement. The N=1 skip therefore loses no review surface; per-task review remains the load-bearing gate.

### N>1 Branch — Full-Pipeline Behavior

When `N > 1`, fall through to existing full-pipeline behavior: Parallelize runs before per-task dispatch and Integrate runs after the last task completes. The N>1 audit append (`task_count: <N>`, `branch: run-full-pipeline`) is best-effort — a write failure is logged as a canonical WARN but does not halt the phase (unlike N=1, where the write is a hard precondition):

```
<ISO-8601 UTC timestamp> WARN audit-write-failed: could not append to reviews/implement-entry-decisions.md — <error description>. Attempted payload: {timestamp: <ISO-8601>, task_count: <N>, branch: run-full-pipeline}. Proceeding to full-pipeline dispatch.
```

### Audit Trail

`reviews/implement-entry-decisions.md` records one append per Implement entry with three fields:

| Field | Values |
|-------|--------|
| `timestamp` | ISO-8601 UTC at append time |
| `task_count` | Integer `N` on branches where enumeration succeeded (`run-full-pipeline`, `skip-parallelize-integrate`, `halt-zero-tasks` — `0` is an observed count there). `null` on halt branches where `N` was not bound (`halt-tasks-dir-io-error`, `halt-unreadable-task-file`). Consumers aggregating on `task_count` must read `branch` first; treat as an observed count only when `branch` ∈ {`run-full-pipeline`, `skip-parallelize-integrate`, `halt-zero-tasks`}. |
| `branch` | `skip-parallelize-integrate` (N=1), `run-full-pipeline` (N>1), `halt-zero-tasks` (N=0), `halt-tasks-dir-io-error`, or `halt-unreadable-task-file` |

This file is the audit surface for the skip behavior. An operator can distinguish "N=0 empty plan that slipped through precondition gating" from "N=1 single-task quick-fix that legitimately skipped orchestration overhead" by reading `branch`. The file is append-only; do not overwrite prior entries from earlier Implement invocations in the same run. If absent, create with the first append; if present, append below the last `---` marker.

**Integrity limitation.** The audit log is best-effort; provenance hardening (append-only enforcement, hash-chained entries) is out of scope. Operators relying on the audit log for forensic integrity should treat it as advisory, not tamper-evident.

## 3. Run-Entry Artifact Preconditions, Config, Permissions, Baseline

After smoke-check and task-count have passed and bound `N`, the remaining entry concerns prepare the run for per-task dispatch.

### Run-Entry Artifact Preconditions

Required inputs must exist and be approved before Implement dispatches anything. Mode-dependent (derived from `config.md.route`):

- **Full pipeline:** `parallelization.md`, `plan.md`, `tasks/*.md` (or `fixes/{type}-round-NN/*.md`), `design.md`, `phasing.md`, `structure.md`, `config.md`.
- **Quick fix:** `plan.md`, `tasks/*.md` (or `fixes/{type}-round-NN/*.md`), `goals.md`, `research/summary.md`, `config.md`.

If any required artifact is missing or not approved, refuse to run and name it.

Per-task prompt composition (which subset of inputs rides in each subagent prompt based on the task's `pipeline:` field) is a separate concern — see implement/SKILL.md § Per-Task Input Routing (Prompt Composition).

### Config Validation

Per `using-qrspi/references/config-runtime-contract.md` § Config Validation Procedure. Implement validates `route`, `second_reviewer`, and (after Phase-Level Configuration) `review_depth` and `review_mode`.

### Phase-Level Configuration (Runtime)

`review_depth` and `review_mode` are runtime concerns. At Implement entry, ask:

1. **Review depth** — Quick (4 correctness reviewers) or Deep (all 8).
2. **Review mode** — Single round or Loop until clean.

Write to `config.md` as `review_depth` and `review_mode`. Fix-task dispatches reuse — do not re-ask. Source of truth is `config.md`.

### Subagent Permissions

Subagent containment is the runtime sandbox's responsibility (auto-mode plus the host runtime's judgment); there is no in-pipeline worktree wall. Subagents should be dispatched with the task's worktree path `.worktrees/{slug}/task-NN[a-z]?/` named in the prompt and treat that path as their working scope. The optional `[a-z]?` letter suffix supports Plan-induced task splits like `task-07a`/`task-07b`.

**Recommended:** run sessions with `--dangerously-skip-permissions` enabled so per-tool approval prompts do not stall subagents.

### Baseline Tests

Run baseline tests in a single throwaway worktree at `.worktrees/{slug}/baseline/` (forked from the feature branch tip). If a prior baseline worktree exists from a halted run, delete it first.

If tests fail, present failure summary with 3 options:

- **(a) Auto-fix (recommended):** Inject baseline fix task `task-00` with all others depending on it. Implement writes `task-00.md` with `status: approved` (runtime-generated; approval asserted so the Iron Law gate passes on dispatch). `task-00` uses `task: 0` and inherits the run's mode in `pipeline:`.
    - **Full pipeline:** Append one row to the Branch Map (`task-00 → qrspi/{slug}/task-00 (base: feature branch tip)`) without rewriting existing rows. Append a `## Runtime Adjustments` section listing tasks whose effective base changed. Implement reads the Branch Map first, then applies `## Runtime Adjustments` overrides on top. Repeated failures inject `task-00b`, `task-00c`, etc.
    - **Quick fix:** `task-00` is its own isolated dispatch event — no Branch Map, no `## Runtime Adjustments`. Write `tasks/task-00.md` with `status: approved`, dispatch as a standalone event with task set `{tasks/task-00.md}`, then dispatch the originally-requested task set as a separate event (excluding the runtime-written singletons).
- **(b) Proceed anyway:** Log failures to `reviews/baseline-failures.md`.
- **(c) Stop:** Halt the pipeline.

**Invariant — baseline worktree gone before any per-task worktree exists.** Auto-fix deletes it as the first sub-step of Process Step 5; Proceed-anyway deletes it immediately after writing `reviews/baseline-failures.md`; Stop requires no deletion.
