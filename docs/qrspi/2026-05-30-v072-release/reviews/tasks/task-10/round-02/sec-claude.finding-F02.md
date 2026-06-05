---
finding_id: R2-F02
reviewer_tag: sec-claude
severity: low
change_type: correctness
referenced_files:
  - skills/using-qrspi/SKILL.md#L995-L1008
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L2075-L2076
---

# finding_paths[] values in Sub-Threshold Observations YAML carry no path-traversal constraint

The `finding_paths:` list in the observations YAML block is documented as containing "relative paths" with no stated constraint against directory-traversal sequences. The canonical example shows safe values; no test, schema rule, or prose clause prevents the orchestrator from writing:

```yaml
finding_paths:
  - ../../../../secrets/api-keys.md
  - ../task-11/reviews/sec-claude.finding-F01.md
```

**Concrete attack scenario:** When future tooling reads `finding_paths[]` and opens them to display or aggregate finding content, it would follow traversal sequences to files outside the reviews directory — potentially reading task secrets, plan files, or other review rounds' unpublished findings.

AC5 asserts `finding_paths:` is present (`grep -qE '^\s*finding_paths:'`) but performs no check that values are confined to the review directory or are free of traversal sequences.

**Fix:** Document an explicit constraint in SKILL.md that `finding_paths[]` values MUST be relative paths within the current `round-NN/` directory and MUST NOT contain `../` components. Add AC5 sub-assertion: `! grep -qE '(\.\./|^/)' <<< "$yaml"`. Enforce server-side when future tooling lands.
