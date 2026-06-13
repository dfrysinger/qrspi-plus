---
finding_id: R5-F03
severity: low
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L766-L770
artifact: plan
round: 5
reviewer: test-coverage-claude
---

T06 (`test-no-diff-redirect-prose.bats`) Test Expectations — missing named-diagnostic discipline for failure output.

T06's fail-direction test says: "The lint fails against a fixture skill body that re-introduces the redirect pattern (fail-direction guard)." This correctly asserts non-zero exit, but says nothing about what the failure output contains.

**What is unverifiable:** The test writer can assert `exit_code != 0` but cannot write a test asserting that the lint output is debuggable and actionable — that it names the offending file path, line number, and the offending pattern. Without an expectation on output format, an implementation that exits non-zero with `echo "FAIL"` satisfies the written expectation just as much as one that emits `skills/goals/SKILL.md:42: forbidden pattern 'git diff > round-NN.diff' found`.

**Comparison with sibling lints in this same plan:** T12 explicitly says "The lint's failure output lists `file:line` locations and the offending strings (named-diagnostic discipline; no silent fail)." T18 says "The lint's failure output names the offending file, line, and the non-enumerated marker text (named-diagnostic discipline)." T24 says "A fixture skill body missing the write step fails the lint with a named diagnostic." T06 is the only comparable lint in this plan without this requirement.

**Fix:** Add a bullet matching T12's pattern: "The lint's failure output names the offending file, line number, and the redirect pattern — not a silent non-zero exit."
