# Implement Batch-End Detail

Read this file once per batch end, when every task in the current batch has reached terminal state (clean / accepted-with-issues / skipped-by-user) and the orchestrator is about to present the batch gate. It is not re-read during the per-task fix loop. ("Batch end" fires once per Implement batch — equivalent to phase end in full pipeline, equivalent to quick-fix-batch end in quick mode.)

This file consolidates the two batch-end concerns: the Orchestration Boundary Observability Check that runs immediately before the batch gate, and the Batch Gate (After All Tasks) rendering / autopilot evaluation rules.

## Orchestration Boundary Observability Check (Batch-End)

Process Step 7. Runs once per batch, at batch end after every task reaches a terminal state, immediately before the batch gate. The batch-end position is load-bearing: the stage-commit chain authored by wave-dispatch is where commit-based orchestration drift (main chat committing into the batch range under its own author identity instead of a `qrspi-<agent>` marker) is most likely to surface.

### Step N — Orchestration boundary observability check

Before presenting the batch-gate menu, verify the OBC script is present: if `scripts/orchestration-boundary-check.sh` is absent or not executable at invocation time, the orchestrator writes a `## Dispatch defects` section to `<ABS_ARTIFACT_DIR>/reviews/implement/orchestration-boundary.md` containing `obc-script-absent: scripts/orchestration-boundary-check.sh not found or not executable` and halts per § Batch Gate without attempting invocation. Otherwise, run `scripts/orchestration-boundary-check.sh --phase implement --artifact-dir "<ABS_ARTIFACT_DIR>"`. The script runs `git status --porcelain` (catches uncommitted main-chat edits; `reviews/` allowlisted) and `git log <phase-base>..HEAD --format='%H %an' | awk '$2 !~ /^qrspi-/ {print $1}'` (catches main-chat-committed edits; subagent commits carry the `qrspi-<agent-name>` author marker).

Findings go to `reviews/implement/orchestration-boundary.md` under up to two sections: `## Boundary violations` (uncommitted-edit, non-subagent-commit) and `## Dispatch defects` (script-absent, phase-base unreadable, git crash, named-diagnostic classes — `sha-format-invalid`, `obc-unknown-phase`, `obc-author-name-malformed`, `wave-1-sidecar-missing`/`malformed`). Each header emits only when populated; clean run produces byte-empty file. OBC exits 0 when `## Dispatch defects` empty (regardless of boundary-violations) and non-zero when non-empty.

Boundary violations are fail-soft (batch-gate menu). Dispatch defects are fail-loud — `## Dispatch defects` non-empty halts batch advancement unconditionally. Interactive: automatic halt (no acknowledge-and-continue); autopilot dispatch-defects halt branch in § Batch Gate.

## Batch Gate (After All Tasks)

**Orchestration-boundary violations.** When `## Dispatch defects` is non-empty, render only options (a) and (b); option (c) is suppressed (the boundary state is undeterminable). The populated `## Dispatch defects` section halts batch advancement unconditionally regardless of mode.

**Autopilot mode** evaluates branches in strict precedence order (first match wins; no default-proceed fallback):

1. **OBC report absent/unreadable after OBC invocation completed (regardless of exit code) — evaluate first.** Halt unconditionally as a dispatch-defect condition (write `HALT-orchestration-boundary-undeterminable.md`). An atomic-rename failure or any crash leaving "OBC exit 0, no report" must not be silently reinterpreted as clean.
2. **Dispatch defects (`## Dispatch defects` non-empty).** Halt unconditionally (same halt file). No auto-revert, no operator override, no skip-and-continue.
3. **Non-subagent commits in the batch range.** Auto-escalate: dispatch a fix-task subagent with mode `revert-orchestration-drift`; cap 1 attempt per batch; on recurrence, halt with `HALT-orchestration-boundary-recurring.md`.
4. **Uncommitted workspace changes.** Halt with `HALT-orchestration-boundary.md` listing dirty paths — auto-reverting uncommitted state would destroy in-flight work.

A clean OBC report proceeds to the next route step without a menu item. Interactive mode is unaffected by autopilot branching; the (a)/(b)/(c) menu applies with option (c) suppressed when `## Dispatch defects` is non-empty.

Read `references/batch-gate-autopilot.md` when presenting the batch gate (interactive menu rendering or autopilot branch evaluation) — full menu rendering, batch summary, advance menus, and gate-level reviewer dispatch detail.

### Batch Gate Red Flags — STOP

- Presenting "Fix remaining issues" when all tasks passed clean. Presenting the batch gate before every task is in (a), (b), or (c). Advancing to the next route step from inside the batch gate logic without explicit user "continue".
