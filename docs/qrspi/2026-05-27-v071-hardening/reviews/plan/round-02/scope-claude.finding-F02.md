---
finding_id: F02
severity: low
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 2
reviewer: scope-claude
---

## Task 8 test expectation names an implementer-protocol mechanism ("modify-pass")

In Task 8's test expectations (added in round-02):

> "The `git diff --name-only` output for the Task 8 commit does not list any path under `docs/qrspi/2026-04-29-v0.4-bundle/` or `docs/superpowers/`; **a path-scope assertion in the modify-pass verifies** historical run-record directories are not touched"

The phrase "a path-scope assertion in the modify-pass" names an internal execution stage of the implementer protocol ("modify-pass" is an implement-layer concept describing a specific phase of the TDD dispatch cycle). Plan-appropriate framing states only the observable outcome; it does not prescribe which protocol stage or mechanism enforces it.

Per owns-defers:

> **Line-by-line logic, control-flow detail, algorithm pseudocode** → Implement (the implementation agent owns local logic decisions inside the task's bounded scope).

Naming the "modify-pass" as the enforcement location is an implement-layer prescription — it pre-empts the implementation agent's discretion over how and when to wire the path-scope guard. The observable outcome clause ("the Task 8 commit does not modify any path under those directories") is the correct plan-level statement.

**Recommended fix:** Trim the enforcement-mechanism clause. Replace:

> "The `git diff --name-only` output for the Task 8 commit does not list any path under `docs/qrspi/2026-04-29-v0.4-bundle/` or `docs/superpowers/`; a path-scope assertion in the modify-pass verifies historical run-record directories are not touched"

with:

> "The `git diff --name-only` output for the Task 8 commit does not list any path under `docs/qrspi/2026-04-29-v0.4-bundle/` or `docs/superpowers/`"

This preserves the observable constraint while leaving the enforcement mechanism to Implement.
