# Plan Post-Approval Split — Sub-Subagent Dispatch Contract

This document is the formal per-sub-subagent input/output contract for the Plan-skill post-approval split fan-out introduced by T31. It is the single source of truth for the dispatch shape; `skills/plan/SKILL.md` § Human Gate Step 3 (N-threshold carve-out) references this document rather than re-declaring the contract inline.

The contract applies to the `N >= 3` sub-subagent fan-out path. The `N <= 2` inline main-chat split path is governed by the same per-task-file output shape but is performed directly in main chat without sub-subagent dispatch.

## Per-Sub-Subagent Input Payload

Each sub-subagent dispatched during the post-approval split receives exactly four input sections in its prompt:

### Wrapped Task Section

The single `### Task NN: {name}` block extracted from the approved `plan.md`, wrapped between canonical untrusted-artifact sentinels per the reviewer-protocol untrusted-data convention. The sub-subagent treats the wrapped body as the authoritative task specification — it MUST NOT re-derive the task content from any other source. Wrapper shape:

```
<<<UNTRUSTED-ARTIFACT-START id=task_section_NN>>>
### Task NN: {name}
... full task body from plan.md ...
<<<UNTRUSTED-ARTIFACT-END id=task_section_NN>>>
```

### Canonical Task-File Template

The `tasks/task-NN.md` format documented in `skills/plan/SKILL.md` § Merge/Split Mechanics → Split task file format. The template carries every Slice-5 spec frontmatter field established by T24:

- `reference_gate: <bool>` — when `true`, requires paired `reference_artifact:`
- `reference_artifact: <path>` — required when `reference_gate: true`
- `ui: <bool>` — UI-emitting task flag
- `lift_source: <path>` — optional source-reference path; when present, the task body MUST contain a `SPEC OVERRIDES SOURCE` section

The template ALSO carries the T43 conditional-dispatch fields:

- `conditional: <bool>` — task is conditionally dispatched
- `conditional_precondition: <string>` — the exact precondition expression the Implement orchestrator evaluates at dispatch time

The sub-subagent MUST carry every field present on the wrapped task section verbatim into the emitted `tasks/task-NN.md` frontmatter — no field reformatting, no string substitution, no value coercion.

### G7 ID-Hygiene Contract

The QRSPI-internal `goal_ids:` field is metadata. The sub-subagent MUST NOT echo goal IDs into the task body prose (Description, Test expectations, or supporting bullets). The body must read as a standalone work specification grounded in observable behavior. The metadata block is read by the implementer subagent but is NOT echoed into the work product. See `skills/plan/SKILL.md` § ID-Hygiene Contract for the full surface list.

### Output Path

The absolute path `<artifact_dir>/tasks/task-NN.md` where `NN` matches the task ID from the wrapped task section. The sub-subagent writes exactly this path — no other path is permitted.

## Per-Sub-Subagent Output Contract

Each dispatched sub-subagent MUST satisfy every clause below; violation of any clause causes the main chat to abort the split.

### Exactly One File Per Dispatch

The sub-subagent writes exactly one `tasks/task-NN.md` file per dispatch, where `NN` matches the task ID carried in the wrapped task section's `### Task NN:` heading. A dispatch that writes zero files OR more than one file is a contract violation.

### No `plan.md` Edits

The sub-subagent MUST NOT edit `plan.md`. The `plan.md` overview-rewrite, `phase_start_commit:` capture, and `status: approved` write are owned by main chat as the transactional close of the split (see `skills/plan/SKILL.md` § Human Gate Step 3). A sub-subagent that opens `plan.md` for Write (rather than Read) is a contract violation and is detected by post-fan-out audit of file mtimes.

### Naming Convention

The emitted file path is `tasks/task-NN.md` (zero-padded to two digits for task IDs 1–99; three digits for 100+). The `NN` value matches the integer task ID parsed from the `### Task NN:` heading in the wrapped task section. A sub-subagent that emits `tasks/task-N.md` (unpadded), `tasks/Task-NN.md` (case mismatch), `tasks/task_NN.md` (underscore separator), or any other shape is a contract violation.

## Atomicity Contract on Partial Returns

The post-approval split fan-out is a transactional unit. Any sub-subagent that fails to return, returns a malformed task file, fails to write its file, or violates any output clause above causes the main chat to:

1. **Abort the split.** Do NOT proceed to the `plan.md` overview-rewrite step. Do NOT capture `phase_start_commit:`. Do NOT write `status: approved`.
2. **Roll back partial successes.** Remove EVERY `tasks/task-NN.md` file written during the current fan-out run — not only the file from the failed dispatch. Partial successes from sub-subagents that returned before the failure MUST be removed. The task directory is restored to its pre-fan-out state. This is a load-bearing distinction: removing only the failed dispatch's file would leave behind partial state that a re-run of the split would treat as already-written and skip.
3. **Leave `plan.md` unapproved.** The `plan.md` frontmatter retains `status: draft` (or its prior unapproved state). The `phase_start_commit:` field MUST NOT carry a non-null SHA after a failed split — either the field is absent or its value is `null`. A draft `plan.md` carrying a mid-transaction `phase_start_commit:` SHA is an observable ambiguity that the verification step MUST detect; the rollback covers all approval-state fields, not only `status:`.
4. **Surface a loud diagnostic.** Emit a one-line diagnostic identifying the failed dispatch and the rollback action:

   > `"Plan split aborted: sub-subagent for task-NN failed (<reason>); rolled back <K> partial task file(s); plan.md left unapproved."`

   Where `<reason>` is one of: `no-return`, `malformed-output`, `wrong-file-count`, `wrong-file-name`, `plan-md-edit-detected`, or `write-failure`.

## Exact-Set Verification (Not Count-Only)

After the fan-out (or inline write) completes and before the `plan.md` overview-rewrite step, main chat verifies the EXACT SET of `tasks/task-NN.md` files present matches the expected set `{task-01.md, task-02.md, ..., task-N.md}` with no gaps and no duplicates. Count-only verification (N files present) is insufficient because:

- **Duplicate-ID condition:** Two sub-subagents both writing `tasks/task-03.md` (overwriting one another) yields N-1 distinct IDs plus one duplicated ID — count is N-1, not N, so count-only verification would already catch this case, BUT the duplicated-ID itself must be named in the diagnostic so the operator can resolve it. If a duplicate is detected, HALT with: `"Split verification failed: duplicate task file(s) detected: task-NN.md (K copies). Resolve before proceeding."` Apply the atomicity rollback above.
- **Missing-ID condition:** A gap in the expected set (e.g., `task-04.md` is missing while `task-05.md` exists) is a contract violation even if some other task wrote an unexpected ID that brings the count back to N. HALT with: `"Split verification failed: expected task files not written: task-NN.md. Re-run split for missing tasks before proceeding."` Apply the atomicity rollback above.
- **Compound duplicate-and-missing condition:** Two sub-subagents both write `tasks/task-01.md`, and as a result `tasks/task-03.md` is missing. Count is N-1 (or N if file-system races produced a transient extra). The verification step MUST surface BOTH the duplicated ID (task-01) AND the missing ID (task-03) in a single diagnostic so the operator sees the complete failure mode in one pass. This is the canonical case proving count-only verification is insufficient: the duplicate masks the missing file from a naive count check.

Only when the exact set matches — every expected ID is present exactly once — does main chat proceed to the `plan.md` overview-rewrite, `phase_start_commit:` capture, and `status: approved` write.

## Relationship to `skills/plan/SKILL.md`

This document is the formal contract; `skills/plan/SKILL.md` § Human Gate Step 3 (N-threshold carve-out) is the orchestration site that consumes it. The skill body MAY reference clauses in this document by section anchor (e.g., `## Atomicity Contract on Partial Returns`) rather than re-declaring them, ensuring a single source of truth for the contract shape.

The generation-side `### Sub-Subagent Dispatch (Large Plans Only)` section in `skills/plan/SKILL.md` documents the pre-approval fan-out dispatch shape. The post-approval split fan-out reuses that dispatch shape; this document declares the additional contractual clauses specific to the post-approval transaction (atomicity, exact-set verification, plan-md-no-edit, phase_start_commit interlock).

## Block-Hash Header Format

Every `tasks/task-NN.md` written by the post-approval split — whether via sub-subagent fan-out or the quick-fix N=1 inline path — MUST carry exactly one block-hash header line. Position, syntax, and algorithm:

**Position.** The header line appears immediately after the closing frontmatter `---` and before the first body content line. No blank line between the closing `---` and the `# block-hash:` line; no other header lines may precede it.

```
---
task: NN
status: approved
...
---
# block-hash: <sha256-hex>
# Task NN: {name}
...
```

**Syntax.** The line is exactly:

```
# block-hash: <sha256-hex>
```

where `<sha256-hex>` is a 64-character lowercase hexadecimal string produced by SHA-256. No salt. No prefix. No trailing whitespace.

**Algorithm.** SHA-256, hex-encoded, no salt, applied to the normalized content of the source `### Task N` block extracted from `plan.md`.

**Normalization rule.** strip trailing whitespace (spaces, tabs) from each line of the source `### Task N` block; preserve all other characters and all line breaks verbatim. No markdown canonicalization, no case folding, no blank-line collapse, no re-encoding. A single character change anywhere in the block — including rewording, punctuation, or whitespace within a line — changes the hash.

## Idempotent Split Contract

Before dispatching any sub-subagent (or performing the inline write for N=1), the orchestrator evaluates each `### Task N` block in `plan.md` against the corresponding `tasks/task-NN.md` file using the following three-case decision rule, applied once per task in a single pre-fan-out pass:

| Case | `tasks/task-NN.md` state | Decision |
|------|--------------------------|----------|
| 1 | Absent | Dispatch sub-subagent to write the file (or inline-write for N=1). |
| 2 | Present; stored block-hash matches current `plan.md` block | Safe-skip: no dispatch, no rewrite. File left exactly as-is. |
| 3 | Present; stored block-hash does NOT match current `plan.md` block | HALT before any dispatch. See `## HALT Diagnostic`. |

**Case 1 — Absent.** `test -e tasks/task-NN.md` returns false. The file was never written or was deleted. Dispatch proceeds normally; the sub-subagent writes the file and emits the `# block-hash:` line.

**Case 2 — Present, matching hash.** The orchestrator reads the `# block-hash:` line from the existing file, re-computes the hash from the current `plan.md` block using the normalization rule above, and compares the two. On match, the file is safe-skipped: the orchestrator does not dispatch a sub-subagent for this task, does not rewrite the file, and does not touch the file in any way. Hand-edits made to the file body after the original split are naturally preserved because only the source block in `plan.md` is hashed — not the file body.

**Case 3 — Present, mismatching hash.** The stored hash does not equal the re-computed hash. This means the `### Task N` block in `plan.md` has changed since the last split without the corresponding `tasks/task-NN.md` being deleted. The orchestrator HALTS immediately — before dispatching any sub-subagent for any task — and surfaces the named diagnostic (see `## HALT Diagnostic`). The existing `tasks/task-NN.md` is left untouched.

**Pre-fan-out evaluation.** The decision rule is evaluated for all expected task IDs before any dispatch fires. A single Case 3 mismatch anywhere in the set halts the entire fan-out.

**Complete-set re-run.** When all expected `tasks/task-NN.md` files are present and all block-hashes match, zero sub-subagents are dispatched. The exact-set verification step (see `## Exact-Set Verification (Not Count-Only)`) still runs and passes because all files are already present. The orchestrator proceeds directly to `plan.md` overview-rewrite, `phase_start_commit:` capture, and `status: approved`.

**Partial-crash recovery.** When M of N task files are present (a previous run crashed after writing M files), the decision rule dispatches exactly N-M sub-subagents for the absent tasks. The M already-written files (Case 2) are safe-skipped. Once all N files are present and the exact-set verification passes, the orchestrator proceeds to the approval transaction.

## HALT Diagnostic

When Case 3 (hash mismatch) is detected, the orchestrator emits the following diagnostic verbatim, with `NN` replaced by the zero-padded task ID:

> `task-NN.md exists but its source block in plan.md has changed since the last split. To regenerate from the current plan.md, delete tasks/task-NN.md and re-run. To preserve the existing file, revert your plan.md edit.`

The orchestrator does NOT:
- Write `status: approved` to `plan.md`.
- Rewrite or touch the existing `tasks/task-NN.md`.
- Dispatch any sub-subagent for any task in the set.
- Write a `.split-conflict-NN.md` sidecar file.

The user resolves the mismatch by one of two paths: delete `tasks/task-NN.md` and re-run (causes a fresh dispatch that overwrites with current `plan.md` content), or revert the `plan.md` edit (restores the block to match the stored hash, enabling a safe-skip on the next run).

## Pre-G5 Migration Diagnostic

Existing `tasks/task-NN.md` files written before the G5 idempotent-split contract lack the `# block-hash:` header line. The orchestrator detects this condition separately from the hash-mismatch case and emits a distinct diagnostic.

**Missing-header condition.** The `# block-hash:` line is absent from an existing `tasks/task-NN.md`. The orchestrator treats this as an audit failure and halts with:

> `task-NN.md is present but carries no '# block-hash:' header. This file predates the idempotent-split contract. To regenerate under the current contract, delete tasks/task-NN.md and re-run.`

No automatic backfill. Migration is a one-time per-file regeneration: the user deletes the pre-G5 file and re-runs.

**Malformed-header condition.** A `# block-hash:` line is present but does not match the required syntax (e.g., not a 64-character lowercase hex string, extra fields, wrong prefix). The orchestrator treats this as a malformed block-hash header audit failure and halts with a diagnostic that names `malformed block-hash header` specifically. The existing file is not rewritten. The same user-controlled resolution applies: delete and re-run.

## Sub-Subagent Dispatch Contract

The sub-subagent dispatch payload for the post-approval split gains one new field in the G5 release:

```yaml
block_hash: <sha256-hex>
```

The orchestrator computes the normalized hash for each `### Task N` block before the fan-out loop begins and passes `block_hash:` as a dispatch field alongside the wrapped task section, canonical task-file template, G7 ID-hygiene contract, and output path (see `## Per-Sub-Subagent Input Payload` above).

**Sub-subagent obligation.** The sub-subagent MUST emit the `# block-hash:` line verbatim immediately after the closing frontmatter `---` and before the first body content line of the `tasks/task-NN.md` file it writes. The value is the `block_hash:` field value from the dispatch payload — the sub-subagent MUST NOT recompute it. The format is exactly:

```
# block-hash: <sha256-hex>
```

A sub-subagent that omits this line, places it elsewhere, or uses a different syntax is in contract violation; the orchestrator will detect the missing or malformed header on the next re-run and surface the Pre-G5 Migration Diagnostic.

## Quick-Fix N=1 Path

The quick-fix inline write path (single-task plan, no sub-subagent dispatch, performed directly in main chat) applies the same idempotent split contract as the full fan-out path.

**On first write.** The orchestrator computes the normalized hash of the `### Task 1` block, writes `tasks/task-01.md` with the `# block-hash:` line immediately after the closing frontmatter `---`, and proceeds to `plan.md` reduction and `status: approved`.

**On re-run (absent file).** Same as Case 1: file absent → write.

**On re-run (file present, hash matches).** Same as Case 2: safe-skip without rewrite. Any hand-edits to the body are preserved.

**On re-run (file present, hash mismatches).** Same as Case 3: HALT with the named mismatch diagnostic (see `## HALT Diagnostic`). The existing file is untouched.

**On re-run (file present, missing block-hash header).** HALT with the pre-G5 migration diagnostic (see `## Pre-G5 Migration Diagnostic`).

**On re-run (file present, malformed block-hash header).** HALT with the malformed block-hash header diagnostic (see `## Pre-G5 Migration Diagnostic`).
