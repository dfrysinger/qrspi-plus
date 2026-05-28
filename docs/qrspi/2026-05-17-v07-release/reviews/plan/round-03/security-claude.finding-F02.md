---
finding_id: R3-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L866]
artifact: plan
round: 3
reviewer: security-claude
---

T27's path-traversal validation allows an open-ended "declared sibling-allowed path enumerated in the task spec" that is itself unvalidated, creating a confused-deputy path where an attacker-influenced task spec can cause arbitrary file reads via the reference-gate render.

**What the spec says today.** T27's test expectation (plan.md L866) states: "before any `SendUserFile` call or inline Read against the `reference_artifact:` value, the orchestrator validates that the resolved absolute path lies within the artifact-directory tree (`<artifact-dir>/**`) OR within a declared sibling-allowed path enumerated in the task spec."

**The gap.** The "sibling-allowed path enumerated in the task spec" is an open set with no stated constraints. Task specs in `plan.md` are generated artifacts produced by the Plan skill (T24, T31) and their per-task spec files (`tasks/task-NN.md`) come from the post-approval split sub-subagents. While the SPEC OVERRIDES SOURCE authority contract from T24 means the plan author controls these specs at approval time, the validation logic at render time is:

1. Read `reference_artifact:` from the task spec.
2. Check whether the path is inside `<artifact-dir>/**` OR inside a "sibling-allowed path from the task spec."

The second branch trusts a path from the task spec without requiring that sibling-allowed paths are themselves within any bounded tree. If a future sub-subagent (T31/T32) or a modified plan spec includes `sibling_allowed_paths: ["/etc"]`, the render step would treat `/etc/shadow` as an approved path for a `reference_artifact: /etc/shadow` reference, bypassing the path-traversal guard entirely.

This is a confused-deputy vulnerability: the orchestrator's path-traversal guard trusts a field from the task spec that was not itself validated for path traversal.

**Fix.** The test expectation for T27 should state that "sibling-allowed paths" declared in the task spec are themselves validated to lie within a bounded set — at minimum within the repository root or an enumerated set of safe parent directories (e.g., only paths under `<artifact-dir>/` or under the project root are eligible as sibling-allowed entries). Alternatively, remove the "sibling-allowed path" escape hatch entirely and require all `reference_artifact:` paths to be under `<artifact-dir>/**`. The T30 reference-gate-fields pin should exercise a task spec with a `sibling_allowed_paths` entry pointing outside the artifact dir and assert the orchestrator rejects the render with a named validation diagnostic.
