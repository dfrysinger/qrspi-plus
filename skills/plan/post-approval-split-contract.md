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
