---
finding_id: R6-F03
severity: low
change_type: correctness
referenced_files: ["plan.md:L275-L281"]
artifact: plan
round: 6
reviewer: test-coverage-claude
---

T04b test expectations don't cover the empty agent-name edge case. The valid charset is "lowercase letters, digits, hyphen"; an empty string contains no characters outside the valid charset but also satisfies no valid-charset character requirement. An implementation that silently accepts `""` (producing `GIT_AUTHOR_NAME=qrspi-` with no discriminator) would pass all stated tests, defeating per-agent OBC attribution. Fix: add one test expectation bullet rejecting zero-length agent names.

---

**SKIP-RECORD:**
```
skipped_lightweight_tasks: [T05, T07, T09, T13a, T13b, T15, T16, T20a, T20b, T21, T22, T23, T26, T30, T31, T32, T33, T34, T35, T36]
```
