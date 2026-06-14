# Visual-Fidelity Hard-Gate (Pre-Fanout Refusal Condition)

Read this file only when `config.md` carries `visual_fidelity_required: true`. Runs with the flag unset, absent, or `false` are exempt entirely and the gate is a no-op.

Before dispatching plan-review fan-out, the Plan orchestrator inspects `config.md` and merged `plan.md`. The gate fires **only when** `config.md` carries `visual_fidelity_required: true` (the flag Goals writes at run creation and using-qrspi documents in Config File). When on, the orchestrator walks every task spec and asserts that any task with `visual_fidelity_check.ui_producing: true` also carries a non-empty `visual_fidelity_check.wireframe_refs` list.

## Failure mode

If any UI-producing task fails the assertion, the round halts before reviewer dispatch. The halt names the offending task by number and surfaces which sub-case fired (`wireframe_refs` absent-key vs. empty-list vs. null) — the diagnostic preserves that distinction. Multiple offending tasks are reported together.

## Exemptions and parse errors

Tasks with `ui_producing: false` pass regardless of `wireframe_refs`. Whole-block omission (no `visual_fidelity_check` block at all) is treated as `ui_producing: false` and passes — the upstream invariant catching "forgot the block on a UI task" lives in the Split task file format template (seeds the block) and the per-task spec reviewer (surfaces missing-block authoring errors against UI descriptions).

**Present-block parse error:** a `visual_fidelity_check` block present but omitting `ui_producing` is a HARD parse error, not a falsy default — the gate halts and names the missing field. Treating absence as `false` here would silently exempt UI tasks whose author dropped a one-line boolean.

## Why a Plan-skill hard-gate

This is a Plan-skill hard-gate (not a per-task review-time check) so the wireframe-binding contract is enforced once at plan-review time, not on every UI task during Implement.
