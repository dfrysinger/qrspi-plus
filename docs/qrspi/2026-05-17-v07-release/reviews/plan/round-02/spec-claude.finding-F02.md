---
finding_id: R2-F02
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L621-L652]
artifact: plan
round: 2
reviewer: spec-claude
---

T19's `sizing_exception` value is `reusable primitives`, but the task creates two BATS pin files that validate a CI workflow (`test-ci-workflow-shape.bats` and `test-bash32-runtime-coverage.bats`). These are CI verification tests, not shared library primitives consumed by downstream tasks. The correct sizing exception from the closed set for a task that introduces CI workflow verification is `CI scaffolding`.

The reviewer protocol's task-sizing rule states that a sizing exception is only valid when its reason is one of the closed exception set: `schema migration`, `CI scaffolding`, or `reusable primitives`. The `reusable primitives` exception applies when the task creates shared infrastructure consumed by other tasks (like T13's `skill-markdown.bash` helper, or T02's `llm-prompt-utils.sh` library). T19's two pin files are not loaded or called by any other task in the plan — they observe the CI workflow from outside. They are CI scaffolding, not reusable primitives.

The round-1 Group A fix normalized T19's `dependencies:` correctly, but the `sizing_exception` label was not in scope for that fix and the incorrect label persisted.

Fix: change T19's `sizing_exception: reusable primitives` to `sizing_exception: CI scaffolding`. Update the task's sizing rationale comment (in the description block) to match. The in-description rationale currently reads "both observe the workflow's bash-3.2 verification surface and the ban-list-versus-runtime relationship the workflow encodes" — this rationale supports CI scaffolding, not reusable primitives, so the label change aligns the exception with the already-stated rationale.
