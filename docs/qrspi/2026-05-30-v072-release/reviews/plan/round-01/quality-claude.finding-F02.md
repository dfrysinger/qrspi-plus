---
finding_id: R1-F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
artifact: plan.md
round: 1
reviewer: quality-claude
---

# T05 claims `(create)` for `scripts/verifier-fan-in.sh` that T02 already creates

## What's wrong

T05 (G13 `change_type` enum drift hardening, around plan.md line 353) declares:

> **Target files:** scripts/verifier-fan-in.sh (create), skills/reviewer-protocol/SKILL.md (modify), tests/unit/test-change-type-partition.bats (modify)
> **Dependencies:** Task 02, Task 04

But Task 02 (G12 verifier-fan-in script, line 188) already declares:

> **Target files:** scripts/verifier-fan-in.sh (create), skills/_shared/verifier-dispatch-prose.md (create)

So `scripts/verifier-fan-in.sh` is asserted to be created by both T02 and T05, and T05 explicitly depends on T02. By the time T05 runs, T02 has already landed the file (and T05's own scope text confirms it: "Add the canonical `change_type` enum (`style`, `clarity`, `correctness`, `scope`, `intent`) to the `scripts/verifier-fan-in.sh` header" — that wording is unambiguously modification of an existing file).

## Why it matters

The `(create) | (modify)` marker on Target files is part of the canonical bullet schema the implementer agent and the plan reviewer rely on. Two consequences when the marker is wrong:

1. **Implementer ambiguity.** A fresh-context implementer dispatched against T05's spec will see the script listed as `(create)` and may either (a) try to write the file from scratch, clobbering T02's work, or (b) detect the mismatch with the on-disk state and stall to clarify with the orchestrator. Both are recoverable but waste a round.

2. **Reviewer-graph noise.** Plan-reviewer / Structure-reviewer correctness checks that cross-reference Target files against the dependency DAG should flag every `(create)` as the unique owner of that path — having two `(create)` claims for the same file is exactly the schema violation the marker exists to catch.

This is symmetric with T13 (which correctly declares `scripts/round-prepare.sh (modify)` after T12 created it) — the convention is in place, T05 just deviates from it.

## Suggested fix

Change T05's Target-files line to:

```
**Target files:** scripts/verifier-fan-in.sh (modify), skills/reviewer-protocol/SKILL.md (modify), tests/unit/test-change-type-partition.bats (modify)
```

No other change required — T05's Definition of done and Test expectations already read as modifications, not initial creation.
