# Reference-Gate Human Pause (per-task DONE handling) — full pause procedure

This file is `!cat`-included under the `### Reference-Gate Human Pause (per-task DONE handling)` H3 in `skills/implement/SKILL.md`. It carries the full path-validation, render, confirmation, and approval-record procedure for tasks whose `tasks/task-NN.md` frontmatter carries `reference_gate: true`.

When a task reaches DONE state (all reviewers passed clean) and its frontmatter carries `reference_gate: true`, the orchestrator **halts before dispatching any dependent task** and executes the reference-gate pause:

#### Step 1 — Path validation (before any render or Read)

Resolve the `reference_artifact:` value from the task spec to an absolute path. Before any render or Read against that path:

- Assert the resolved absolute path lies within the artifact-directory tree (`<artifact-dir>/**`), OR within a declared `sibling_allowed_paths:` entry from the task spec.
- If the task spec carries a `sibling_allowed_paths:` list, validate each declared entry first: every `sibling_allowed_paths:` entry MUST itself resolve to within either the artifact-directory tree OR within the project's worktree root. A `sibling_allowed_paths:` entry that resolves outside both bounded trees (e.g., `/etc`, `/var`, `~/.ssh`, any absolute path under the user's home directory, or any path resolved via symlink outside the worktree) is **rejected** with the named sibling-allowed-path-validation diagnostic BEFORE the `reference_artifact:` resolution is even attempted:

  > `"reference-gate-sibling-path-validation: task=task-NN, entry=<entry>, reason=out-of-bounds-tree"`

  This closes the confused-deputy gap where a task spec could otherwise widen the path-traversal guard to arbitrary filesystem locations by declaring a permissive `sibling_allowed_paths:` entry.

- After sibling-allowed-path validation passes, validate the `reference_artifact:` path itself: a path that resolves outside the allowed tree — including path-traversal attempts using `../`, absolute paths to filesystem secrets like `/etc/shadow` or `~/.ssh/id_rsa`, or symlink resolutions that escape the tree — is **rejected** with the named path-validation diagnostic, the pause aborts with no render or Read against the offending path, and no dependent dispatches:

  > `"reference-gate-path-validation: task=task-NN, path=<resolved-path>, reason=out-of-bounds-tree"`

#### Step 2 — Render the artifact to the user

After path validation passes, render the `reference_artifact:` in a user-visible form keyed on the artifact's file extension:

- **Images** (`.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`) and **PDFs** (`.pdf`): dispatch `SendUserFile` with the validated absolute path so the user sees the rendered artifact, not a path string.
- **Text artifacts** (`.md`, `.txt`, `.json`, `.yml`, `.yaml`, and other text MIME types): surface via inline Read so the body appears in the conversation.

#### Step 3 — Require explicit human confirmation

After rendering, the orchestrator presents:

> "Reference artifact for task NN rendered above. Please review and confirm by replying **reference approved** before I dispatch dependent tasks."

The orchestrator MUST NOT dispatch any dependent of the gated task until the user replies with the confirmation phrase. A bypass attempt (dispatching a dependent before the approval file exists) is blocked with:

> `"reference-gate-bypass: task=task-NN, reason=approval-file-absent, blocked-dependent=task-MM"`

#### Step 4 — Record the approval

On user confirmation, write an approval record to `reviews/tasks/task-NN/reference-gate.md` with the following fields (at minimum):

```yaml
timestamp: <ISO-8601 UTC>
run_slug: <slug>
task_id: NN
reference_artifact: <validated absolute path>
approver_acknowledgment: "reference approved"
```

The Write tool's success must be confirmed before any dependent is dispatched. On write failure, the gate remains open — do NOT dispatch dependents and surface the write failure to the user.

#### Step 5 — Release dependents

Once the approval file is confirmed written, the orchestrator proceeds to dispatch dependent tasks per the wave schedule.

#### Coordination with `ui: true` visual-fidelity dispatch

When a reference-gated task also carries `ui: true`, the reference-gate pause runs AFTER the task's own per-task reviewer flow completes (including the visual-fidelity reviewer dispatch on the `ui: true` path). The gate fires at DONE time, before any dependent — including sibling UI tasks in later waves whose visual-fidelity dispatch would consume the gated task's reference — is dispatched.

#### Tasks without `reference_gate: true`

Proceed directly from terminal DONE state to dependent dispatch with no pause and no approval file.
