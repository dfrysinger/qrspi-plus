---
name: notifications
description: Sibling-notification protocol — how cross-task contract changes surface to dependent tasks
---

# Sibling notifications

Tasks running in parallel QRSPI worktrees can drift apart when one task's
fix-cycle changes a contract another task depends on. Two canonical
shapes: a sibling renames or reshapes an exported type that other tasks
emit or consume, and two siblings independently introduce a helper with
the same name and a slightly different signature. In both cases the
divergence only surfaces at integrate, after both tasks have already
been signed off as DONE in their own worktrees.

This protocol surfaces those drifts at the source: when task-N's fix-cycle
modifies a file outside its own scope, the implementer skill computes a
notification for each sibling task whose spec or code references the
changed symbol and writes it to that sibling's notifications directory.

## Notification location

`tasks/task-MM/notifications/<timestamp>-from-task-<NN>.md`

Where `MM` is the affected sibling's task number, `NN` is the source task,
and `<timestamp>` is ISO 8601 (e.g., `2026-05-09T18-04-22Z` — colons
replaced with hyphens for filesystem safety).

## Notification content

Each notification names:

- `source_task` — the task whose change triggered this notification
- `source_commit` — the SHA of the commit that introduced the change
- `target_file` — the file whose contract changed
- `target_symbol` — the affected exported symbol, when applicable
- `change_shape` — one of `signature_change`, `rename`, `removal`, `behavior_change`
- `before` / `after` — minimal diff fragment showing the contract delta
- `suggested_action` — one short sentence — refit, rename, no-op-with-rationale

Example notification file (`tasks/task-30/notifications/2026-05-09T18-04-22Z-from-task-29.md`):

````markdown
---
source_task: 29
source_commit: 011a770
target_file: src/lib/jobs/types.ts
target_symbol: SweepError
change_shape: signature_change
suggested_action: refit emit sites to discriminated-union shape
---

## Before

```ts
export type SweepError = { targetId: string; message: string };
```

## After

```ts
export type SweepError =
  | { kind: 'target'; targetId: string; message: string }
  | { kind: 'sweep'; message: string };
```

The `targetId: '__sweep__'` sentinel is replaced by the `kind: 'sweep'` arm.
Sibling tasks emitting `SweepError` must update emit sites; sibling tests
reading `error.targetId` must narrow to the `kind: 'target'` arm.
````

## At-task-start protocol

At the start of any task run, list `tasks/task-NN/notifications/`. A
notification is **unaddressed** iff its frontmatter has no `resolution`
field (or `resolution: pending`). If any unaddressed notification is
present:

1. Surface each unaddressed notification in the implementer's
   spec-context block.
2. Treat each as a checklist item that must be either:
   - **addressed** — change this task's code to refit the contract, OR
   - **n/a** — confirm this task is not affected (e.g., "this task no
     longer imports the changed symbol").

## Recording the resolution

When an unaddressed notification is handled, the implementer edits the
notification file in place, adding two frontmatter fields:

- `resolution: addressed | n/a`
- `resolution_reason: <one short sentence>`

Optional: `resolution_commit: <sha>` if the resolution landed in a
specific commit on this task's branch.

A file with `resolution: addressed` or `resolution: n/a` is considered
**resolved** and is ignored by the at-task-start protocol on subsequent
dispatches. The file is kept on disk for traceability — do not delete
resolved notifications.

Unaddressed notifications block DONE. The implementer cannot mark a task
DONE while any notification is in pending state. If a notification cannot
be resolved within the task's scope (e.g., the refit requires a separate
plan), report DONE_WITH_CONCERNS and explicitly name the deferred
notification — it stays unresolved for the next round to pick up.

## Main-chat n/a authoring (orchestrator shortcut)

The default resolution path is implementer-driven: an in-batch implementer
dispatches and writes `resolution: addressed` or `resolution: n/a` per the
section above. That path is correct when the notification has any chance of
producing a code change in the current task's worktree.

When the notification is **clearly** out of the current batch's scope and
no code change is possible — typical example: an integrate-time contract
delta whose resolution can only happen at merge — main chat MAY write
`resolution: n/a` directly into the notification file's frontmatter
without dispatching an implementer subagent. This is treated as artifact
metadata authoring (notifications live under `tasks/task-NN/notifications/`,
inside the artifact directory) and does NOT violate the
"main chat does not edit target-project source files" rule in
`implement/SKILL.md` § Per-Task Execution → Orchestration Boundary.

**Criteria — all must hold:**

1. The notification's `target_file` is not modified by any task in the
   current batch (full pipeline: tasks listed in `parallelization.md`
   for the current phase; quick fix: tasks in the main dispatch event).
2. The notification's `change_shape` requires no in-batch code change:
   the resolution is genuinely "wait for integrate" or
   "no longer relevant — current-batch scope does not import the symbol."
3. The user has assented (the shortcut is not unilateral — main chat
   surfaces the proposed n/a resolution and the reason at the
   Round-Level Notification Sweep step and proceeds only on user
   acknowledgement).

**Required frontmatter fields when authored by main chat:**

```yaml
resolution: n/a
resolution_reason: <one short sentence>
resolution_author: orchestrator   # distinguishes main-chat-authored n/a from implementer-authored
```

The `resolution_author: orchestrator` field is REQUIRED on this path so
that audit trails (and any future verifier pass) can distinguish
orchestrator-authored n/a from implementer-authored n/a. Implementer-authored
resolutions omit this field.

If any criterion fails, fall back to the default implementer-fix dispatch
path. Drift created by an inappropriate orchestrator shortcut is harder to
unwind than the cost of a single 75-second implementer dispatch.

## Source-side: writing notifications

The Implement skill's per-task verification step runs the shared-base
impact analyzer (`scripts/sibling-impact.mjs`) after a fix-cycle modifies
files outside the task's own scope. The analyzer emits notifications for
each affected sibling task. The implementer running the source task does
NOT need to author notifications by hand — the analyzer does it.

Notifications are advisory: a future planner pass or sibling implementer
can mark them n/a if they're false positives. False positives are
preferable to silent drift.
