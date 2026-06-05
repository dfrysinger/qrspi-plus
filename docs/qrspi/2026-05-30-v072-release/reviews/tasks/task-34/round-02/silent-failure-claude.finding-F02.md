---
finding_id: R2-F02
severity: high
change_type: correctness
referenced_files:
  - tests/unit/test-plan-post-approval-split.bats
reviewer_tag: silent-failure-claude
---

Vacuous "file left untouched" assertions. Tests (+455-487, +913-946, +973-1003) capture original_content, then assert after_content equal — but between captures NO code touches or attempts to rewrite the file. No orchestrator invoked, no competing write simulated. Comparison structurally always true.

Bonus: dead `original_mtime` capture at +471-472 — captured via stat but never referenced; suggests stronger assertion was intended but never written.

A buggy orchestrator that rewrites task-NN.md with amended content upon mismatch would still pass every assertion because the test never gives it a chance to run. Safety property "existing tasks/task-NN.md is left untouched" exercises no code path that could violate it.

Fix: invoke the orchestrator code path that detects the HALT condition and assert the file is untouched AFTER that code runs (compare mtime + content before vs after the orchestrator's HALT path).
