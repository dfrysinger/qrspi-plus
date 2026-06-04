---
reviewer: security-codex
round: 1
finding_id: R1-F01
severity: medium
change_type: scope
referenced_files:
  - agents/qrspi-plan-test-coverage-reviewer.md
  - skills/plan/SKILL.md
---

# F01 — Task-type misclassification can bypass all test-gate review for code changes

**Where:**
- `agents/qrspi-plan-test-coverage-reviewer.md:38-40` (explicitly requires skipping all `task_type: lightweight` tasks)
- `skills/plan/SKILL.md:159-164,171-179` (`task_type` controls dispatch path; `lightweight` bypasses test-writer + RED gate)

**Issue:**
Security control depends entirely on `task_type`, but `lightweight` tasks are now silently excluded from test-coverage review. If a code-changing task is mislabeled `lightweight`, both plan-stage test scrutiny and implement-stage RED gating are bypassed.

**Attack scenario:**
A malicious or compromised planning step submits a task targeting security-sensitive code (e.g., auth/session logic) but marks it `task_type: lightweight`. The plan-test-coverage-reviewer emits no "missing tests" finding. Implement follows the lightweight path (no test-writer, no RED verification), allowing the change to land without mandatory failing tests or coverage checks.

**Note (orchestrator):** This is largely a pre-existing concern about the `task_type: lightweight` design itself; T26's Addition C only documents the skip the lightweight pipeline already implements. Adjudication will weigh whether T26's plumbing meaningfully widens the attack surface or whether the concern belongs to the lightweight-task design decision (likely v0.7.3 hardening: e.g., spec-reviewer or a dedicated reviewer must validate `task_type` against actual content).
