---
finding_id: R8-F01
severity: medium
change_type: scope
referenced_files: ["plan.md:L954-L971","design.md:L167-L189","structure.md:L54-L62"]
artifact: plan
round: 8
reviewer: goal-traceability-codex
---
T39 (tests/unit/test-check-bats-id-hygiene-sweep.bats coverage for pre-committed structural-lint script) has no upstream commitment in design.md/structure.md G2 (which decomposes G2 into 3 surfaces: sweep / self-check / CI lint+fail-direction). Fix: remove T39 OR amend design+structure to add this G2 component.
