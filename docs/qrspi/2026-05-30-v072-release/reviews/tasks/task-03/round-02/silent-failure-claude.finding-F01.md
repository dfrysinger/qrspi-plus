---
finding_id: R2-F01
severity: high
change_type: correctness
referenced_files:
  - skills/reviewer-protocol/first-party-emission.md:55
artifact: task-03
round: 2
reviewer: silent-failure-claude
---

# F01 — Partial-write silent failure: explicitly documented, no detection or mitigation path (high · correctness)

**Convergence:** Same as `silent-failure-codex.finding-F01.md` — partial-write expected-count manifest gap. Two independent reviewers caught it.

`first-party-emission.md` line 55 contains the parenthetical:

> *(Partial-write failures — some finding files persisted, some not — are not separately signaled. The schema-violation guard at apply-fix step 2 catches only the all-or-nothing case where the expected tag produced ZERO output.)*

This documents a named silent failure mode and **stops there**. The brief-return shape includes `Findings: N (high=X, medium=Y, low=Z)` which COULD be reconciled against file count in `round_subdir`, but nothing instructs that reconciliation.

**DoD impact:** Task-03 DoD requires "wrong-channel output fails loudly." Partial-write is a wrong-channel variant currently failing silently.

**Architectural fix — DEFERRED TO v0.7.3:** Add orchestrator-side reconciliation of brief-return `Findings: N` count vs. on-disk file count. This requires changes to apply-fix step 2 schema guard contract, which lives in the orchestrator skill (using-qrspi), not in T03's scope.
