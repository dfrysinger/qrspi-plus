---
status: draft
question_ids: [20]
research_type: codebase
---

# Q20: How does `skills/plan/SKILL.md` describe the post-approval plan-split step?

## Summary

**TL;DR:** The post-approval plan-split step is invoked immediately after `plan.md` is human-approved (or auto-approved in quick-fix mode) and fans out one `tasks/task-NN.md` file per task. The skill documents strict transactional / non-idempotent semantics: partial failures trigger full rollback of all written task files, and the step cannot be re-entered without starting from a clean slate. Target files are not assumed to be absent, but any duplicate-ID or missing-ID condition causes an immediate HALT before `plan.md` is ever marked `status: approved`.

**Key findings:**
- **Invocation point:** Documented at `skills/plan/SKILL.md` line 427–454 (the "On approval:" block, step 3). It fires after the human gates pass (or quick-fix auto-approve fires) and after an optional compaction recommendation.
- **Preconditions (split-specific):** `plan.md` must be in an approved state (human gate or quick-fix auto-approve passed), the `tasks/` directory must be in a clean pre-fanout state (during review, `tasks/` is empty per merge/split mechanics), and the exact task count N is read from the approved `plan.md` overview.
- **N-threshold carve-out:** N ≥ 3 → parallel sub-subagent fan-out (one per task); N ≤ 2 → inline main-chat write. Both paths must produce the exact same output shape.
- **Failure behavior — Duplicate-ID:** HALT with named diagnostic; do NOT write `status: approved`. Message: `"Split verification failed: duplicate task file(s) detected: task-NN.md (K copies). Resolve before proceeding."` (`SKILL.md` line 450; `post-approval-split-contract.md` § Exact-Set Verification).
- **Failure behavior — Missing-ID:** HALT with named diagnostic; do NOT write `status: approved`. Message: `"Split verification failed: expected task files not written: task-NN.md. Re-run split for missing tasks before proceeding."` (`SKILL.md` line 451).
- **Failure behavior — Sub-subagent contract violation:** Full rollback — every `tasks/task-NN.md` written in the current run is removed, `plan.md` stays unapproved, `phase_start_commit:` is not written. Loud diagnostic names the failed dispatch and reason (`post-approval-split-contract.md` § Atomicity Contract on Partial Returns).
- **Semantics:** Non-idempotent. The split is described as a transactional unit with a rollback clause. A failed split restores the pre-fanout state entirely; there is no "re-try from partial progress" path. The Atomicity Contract explicitly states partial successes must be removed before re-running.
- **Transactional order (success path):** (1) fan-out writes → (2) exact-set verification → (3) reduce `plan.md` to overview-only → (4) capture `phase_start_commit:` → (5) write `status: approved`.

**Surprises:** The skill explicitly prohibits marking `plan.md` as `status: approved` without ALL corresponding `tasks/task-NN.md` files verified present — described as the invariant "an approved `plan.md` is never observable on disk without all corresponding `tasks/task-NN.md` files present" (line 433). This is enforced by sequencing the `status: approved` write last, not first.

**Caveats:** The full `post-approval-split-contract.md` companion document was also read; it is the normative source for atomicity and exact-set verification contract details. The SKILL.md references it as the "single source of truth for the dispatch shape" (line 435). The research is exhaustive for both files.

---

## Full findings

### Invocation Point

The post-approval plan-split step is triggered at the "On approval:" block in `skills/plan/SKILL.md` (lines 427–454). The three-step sequence is:

1. **Step 1 (lines 429):** If reviews have NOT passed clean, ask the user before proceeding whether to run a review loop.
2. **Step 2 (line 431):** Recommend compaction before splitting: `"Plan approved. This is a good point to compact context (/compact) before I split tasks into individual files…"` Wait for the user to compact or decline.
3. **Step 3 (line 433):** Perform the split: fan out per-task spec writing, verify file set, reduce `plan.md` to overview-only, capture `phase_start_commit:`, then write `status: approved`. The skill states the mandatory ordering: "in this exact transactional order, so an approved `plan.md` is never observable on disk without all corresponding `tasks/task-NN.md` files present."

The quick-fix auto-approve branch (lines 458–474) bypasses the human gate when `pipeline: quick` is set and the verifier has affirmatively confirmed zero kept findings. In that case the split, `status: approved` write, and `phase_start_commit:` capture proceed automatically. However, the split mechanics and verification are identical to the standard path.

### Preconditions

The skill documents the following preconditions (mostly in lines 20–49 and the approval block):

| Precondition | Source |
|---|---|
| All required upstream artifacts must be `status: approved` (full: goals + research + design + structure + phasing; quick: goals + research) | `SKILL.md` lines 24–36 |
| `plan.md` must itself be approved (human gate OR quick-fix auto-approve) | `SKILL.md` line 427 |
| `tasks/` directory is empty going into the split (during review, all specs live inside `plan.md` only) | `SKILL.md` line 479 |
| N (task count) is read from the approved `plan.md` overview | `SKILL.md` line 437 |
| `config.md` must be readable and carry a `route` field | `SKILL.md` line 22 |
| Quick-fix auto-approve gate: verifier must have affirmatively confirmed zero kept findings (vacuous zero does not satisfy) | `SKILL.md` line 462 |

For the sub-subagent fan-out path specifically (`post-approval-split-contract.md`):
- Each sub-subagent receives the wrapped `### Task NN:` block, the canonical task-file template, the G7 ID-Hygiene Contract, and the absolute `output_path`.

### N-Threshold Carve-Out (Dispatch Shape)

From `SKILL.md` lines 437–447:

- **N ≥ 3:** Parallel sub-subagent fan-out. One sub-subagent per task, each writes exactly one `tasks/task-NN.md`. Sub-subagents MUST NOT edit `plan.md`.
- **N ≤ 2:** Inline main-chat write. Both `tasks/task-01.md` and `tasks/task-02.md` (or just `task-01.md` for single-task plans) are written directly in main chat without dispatching sub-subagents.

### Failure Behavior When Target Files Already Exist / Contract Violations

The skill's exact-set verification check (`SKILL.md` lines 449–452; `post-approval-split-contract.md` § Exact-Set Verification) covers three failure conditions:

**Duplicate-ID condition** (`SKILL.md` line 450):
> Two or more files share the same `task-NN` identifier. HALT with named diagnostic: `"Split verification failed: duplicate task file(s) detected: task-03.md (2 copies). Resolve before proceeding."` Do NOT write `status: approved`.

**Missing-ID condition** (`SKILL.md` line 451):
> One or more expected task IDs are absent. HALT with named diagnostic: `"Split verification failed: expected task files not written: task-04.md. Re-run split for missing tasks before proceeding."` Do NOT write `status: approved`.

**Compound duplicate-and-missing condition** (`post-approval-split-contract.md` § Exact-Set Verification):
> Both the duplicated ID and the missing ID must be surfaced in a single diagnostic so the operator sees the complete failure mode in one pass.

The skill does NOT describe a scenario where target files exist from a previous run (i.e., stale files from a prior partial split). The atomicity contract handles this implicitly via the rollback clause below.

**Sub-subagent contract violation / atomicity rollback** (`post-approval-split-contract.md` § Atomicity Contract on Partial Returns):

If any sub-subagent fails to return, returns a malformed task file, fails to write its file, or violates any output clause:

1. **Abort the split.** Do NOT proceed to the `plan.md` overview-rewrite step.
2. **Roll back partial successes.** Remove EVERY `tasks/task-NN.md` file written during the current fan-out run — not only the file from the failed dispatch.
3. **Leave `plan.md` unapproved.** Frontmatter retains `status: draft`. The `phase_start_commit:` field MUST NOT carry a non-null SHA after a failed split.
4. **Surface a loud diagnostic:** `"Plan split aborted: sub-subagent for task-NN failed (<reason>); rolled back <K> partial task file(s); plan.md left unapproved."` Where `<reason>` is one of: `no-return`, `malformed-output`, `wrong-file-count`, `wrong-file-name`, `plan-md-edit-detected`, or `write-failure`.

### Idempotent vs. Non-Idempotent Semantics

The plan-split step is documented as **non-idempotent**. Key evidence:

1. **Rollback on failure** (`post-approval-split-contract.md` § Atomicity Contract): "Remove EVERY `tasks/task-NN.md` file written during the current fan-out run — not only the file from the failed dispatch." This is an explicit statement that a re-run starts from scratch; there is no "skip already-written files" path.
2. **Count-only verification is prohibited** (`SKILL.md` line 449; `post-approval-split-contract.md` § Exact-Set Verification): The check must enumerate actual IDs, not just count files — this would be unnecessary if the split were idempotent (safe to re-apply over existing files).
3. **Transactional ordering** (`SKILL.md` line 433): The `status: approved` write is last in the sequence. This is a one-way gate: once written, the plan is approved and the split is complete. An idempotent step would not need this sequencing invariant.
4. **The merge/split lifecycle** (`SKILL.md` lines 476–480): During review, `tasks/` is empty. After approval, `plan.md` is reduced to overview-only. There is no defined state in the lifecycle where a partial set of task files would coexist with an un-approved `plan.md` except during the in-progress split transaction — and the rollback contract ensures that state is cleared on failure.

The only reference to "idempotent" in the SKILL.md (`SKILL.md` line 8) is about loading the `qrspi:using-qrspi` skill on session re-entry, which is unrelated to the split step.

### Merge/Split Lifecycle Overview

From `SKILL.md` lines 476–480 (§ Merge/Split Mechanics):

- **Before review (generation phase):** Large plans (6+ tasks) → sub-subagents write `tasks/task-NN.md` → Plan skill reads all task files, appends them as sections to `plan.md`, then deletes the individual `tasks/task-NN.md` files → `plan.md` is the single source of truth during review.
- **During review:** All changes happen in `plan.md`; `tasks/` directory is empty.
- **After approval (post-approval split):** Plan skill splits each `### Task N` section back into `tasks/task-NN.md` files, then reduces `plan.md` to overview-only (removing the appended task specs). No duplication.

### Companion Document

The formal per-sub-subagent contract lives in `skills/plan/post-approval-split-contract.md`. The `SKILL.md` (line 435) describes this as the "single source of truth for the dispatch shape" and references it rather than re-declaring the contract inline. The contract document covers: wrapped task section format, canonical task-file template requirements, G7 ID-hygiene contract, exactly-one-file-per-dispatch clause, no-`plan.md`-edits clause, atomicity contract on partial returns, and exact-set verification rules.
