# Implement-Entry Task-Count Read and Dynamic Skip

Read this file when running the count-read step that decides between halt (N=0), dynamic-skip of Parallelize+Integrate (N=1), and normal full-pipeline dispatch (N>1). The count-read fires once per Implement entry, immediately after the Implement-Entry Smoke Check passes and before any per-task worktree creation or Parallelize/Integrate dispatch. It is not repeated during fix-round dispatches within the same phase.

## Count-Read Procedure

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

## N=0 Branch — Halt (Precondition Violation)

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

## N=1 Branch — Dynamic Skip of Parallelize and Integrate

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

## N>1 Branch — Full-Pipeline Behavior

When `N > 1`, fall through to existing full-pipeline behavior: Parallelize runs before per-task dispatch and Integrate runs after the last task completes. The N>1 audit append (`task_count: <N>`, `branch: run-full-pipeline`) is best-effort — a write failure is logged as a canonical WARN but does not halt the phase (unlike N=1, where the write is a hard precondition):

```
<ISO-8601 UTC timestamp> WARN audit-write-failed: could not append to reviews/implement-entry-decisions.md — <error description>. Attempted payload: {timestamp: <ISO-8601>, task_count: <N>, branch: run-full-pipeline}. Proceeding to full-pipeline dispatch.
```

## Audit Trail

`reviews/implement-entry-decisions.md` records one append per Implement entry with three fields:

| Field | Values |
|-------|--------|
| `timestamp` | ISO-8601 UTC at append time |
| `task_count` | Integer `N` on branches where enumeration succeeded (`run-full-pipeline`, `skip-parallelize-integrate`, `halt-zero-tasks` — `0` is an observed count there). `null` on halt branches where `N` was not bound (`halt-tasks-dir-io-error`, `halt-unreadable-task-file`). Consumers aggregating on `task_count` must read `branch` first; treat as an observed count only when `branch` ∈ {`run-full-pipeline`, `skip-parallelize-integrate`, `halt-zero-tasks`}. |
| `branch` | `skip-parallelize-integrate` (N=1), `run-full-pipeline` (N>1), `halt-zero-tasks` (N=0), `halt-tasks-dir-io-error`, or `halt-unreadable-task-file` |

This file is the audit surface for the skip behavior. An operator can distinguish "N=0 empty plan that slipped through precondition gating" from "N=1 single-task quick-fix that legitimately skipped orchestration overhead" by reading `branch`. The file is append-only; do not overwrite prior entries from earlier Implement invocations in the same run. If absent, create with the first append; if present, append below the last `---` marker.

**Integrity limitation.** The audit log is best-effort; provenance hardening (append-only enforcement, hash-chained entries) is out of scope. Operators relying on the audit log for forensic integrity should treat it as advisory, not tamper-evident.
