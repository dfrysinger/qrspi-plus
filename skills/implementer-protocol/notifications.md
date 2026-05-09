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

At the start of any task run, list `tasks/task-NN/notifications/`. If
non-empty:

1. Surface each notification in the implementer's spec-context block.
2. Treat each as a checklist item that must be either:
   - **addressed** — with a one-line reason describing what was changed in
     this task to refit the contract, OR
   - **n/a** — with a one-line reason describing why this task is not
     affected (e.g., "this task no longer imports the changed symbol").

Unaddressed notifications block DONE. The implementer cannot mark a task
DONE while any notification is in pending state. If a notification cannot
be resolved within the task's scope (e.g., the refit requires a separate
plan), report DONE_WITH_CONCERNS and explicitly name the deferred
notification.

## Source-side: writing notifications

The Implement skill's per-task verification step runs the shared-base
impact analyzer (`scripts/sibling-impact.mjs`) after a fix-cycle modifies
files outside the task's own scope. The analyzer emits notifications for
each affected sibling task. The implementer running the source task does
NOT need to author notifications by hand — the analyzer does it.

Notifications are advisory: a future planner pass or sibling implementer
can mark them n/a if they're false positives. False positives are
preferable to silent drift.
