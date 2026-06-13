---
severity: medium
change_type: correctness
location: plan.md § T03 Test expectations (line 233); see also T03 Dependencies (line 217) and T04a Dependencies (line 241)
---

# F02 — T03's new byte-identical test expectation requires T04a's deliverable and creates an unsatisfiable ordering

## What

Round-03 adds a new T03 test expectation (diff round-03.diff line 157):

```
- A side-by-side fixture proves dispatch-agent's high-level invocation produces a prompt byte-identical to the equivalent low-level invocation with pre-computed paths (design.md CD-2 Acceptance bullet 2 — paired-coverage assertion with T04a).
```

T03's deliverables are `scripts/review-prep.sh` and `tests/unit/test-review-prep.bats`; T03's declared `Dependencies:` is `T02` only (line 217). T04a — the task that adds `scripts/dispatch-agent.sh`'s high-level entry mode — depends on T03 (line 241), not the other way round. Sequencing is therefore strictly T02 → T03 → T04a.

The added test expectation asserts a behavior of dispatch-agent's high-level mode, which does not exist when T03 lands. To exercise the assertion, `tests/unit/test-review-prep.bats` would have to invoke `scripts/dispatch-agent.sh --step ... --round ... --artifact-dir ...` in high-level mode — a code path that does not exist in the repository until T04a's GREEN lands. T03 cannot pass its own bats suite at T03's RED-verification gate, nor at T03's GREEN merge, without depending on T04a.

The same assertion is also present in T04a's test expectations (line 249, also added in round-03):

```
- High-level `--step --round --artifact-dir` invocation produces a dispatch byte-identical (in prompt content and manifest entries) to the equivalent low-level invocation with pre-computed paths — side-by-side bats fixture asserts byte-equality of the resulting prompt (CD-2 Acceptance bullet 2 — paired with the T03 byte-identical expectation).
```

So the same behavioural assertion is attributed to two tasks whose deliverables cannot both be the test's subject — `scripts/review-prep.sh` (T03) has nothing to do with prompt-equivalence between dispatch-agent invocation modes; only `scripts/dispatch-agent.sh` (T04a) does.

## Why it matters

This is two coupled defects:

1. **Dependency-ordering defect.** Per `skills/plan/SKILL.md`, every task's test expectations must be exercisable when that task's GREEN lands. T03 lands before T04a; T03's added expectation transitively requires T04a's deliverable. The implementer dispatched against T03 cannot drive the test to GREEN without inventing T04a's high-level mode inside T03's scope (out-of-scope sprawl) or marking the expectation as deferred (which the test-expectations contract does not permit).

2. **Duplicated cross-task attribution.** The "paired-coverage assertion with T04a" / "paired with the T03 byte-identical expectation" reciprocal wording in both task bodies establishes the same observable as living in two places. The plan does not have a documented "paired-coverage" shape for behavioural assertions; the closest documented shape is the `cross_task_consumers:` / `dependent_tests:` cross-task surface, which is for paired-edit obligations (file co-edits), not for shared test assertions. Two task bodies asserting the same observable means a reviewer cannot mechanically determine which task owns proving the observable.

The intent appears to be: dispatch-agent's high-level mode produces a prompt byte-identical to the low-level mode. That is exclusively a T04a observable (T04a's deliverable contains the high-level mode; T04a's test owns proving the byte-equivalence). T03 should not carry this expectation.

## Suggested change

Remove the byte-identical-prompt test expectation from T03's body (line 233). The assertion already lives in T04a (line 249) where it belongs — T04a's deliverable is the high-level mode being asserted. T04a's "paired with the T03 byte-identical expectation" parenthetical on line 249 should also be revised to drop the back-reference, since the assertion no longer pairs across tasks.

If the author's intent was that T03's bats suite should prove some review-prep-internal byte-stability property (e.g., review-prep's stdout is deterministic across two invocations with identical inputs), that is a separate assertion and should be re-worded to avoid invoking dispatch-agent. For example: "A side-by-side fixture proves review-prep.sh produces byte-identical output across two invocations with identical inputs (determinism guarantee that downstream byte-identical-prompt assertions in T04a rely on)."
