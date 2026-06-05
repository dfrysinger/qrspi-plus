---
finding_id: R3-F01
reviewer_tag: spec-claude
severity: medium
change_type: correctness
referenced_files:
  - agents/qrspi-finding-verifier.md
  - tests/unit/test-verifier-agent-file.bats#L318-L335
---

# Success sidecar template violates Fix E's "defect_class MUST appear LAST" invariant

The success sidecar template places `reason:` AFTER `defect_class:`, violating the invariant Fix E added to both the agent body and fan-in header which states "in every sidecar … `defect_class:` MUST appear LAST among the YAML frontmatter fields."

```yaml
+   defect_class: <kebab-case tag ...>
    reason: <present only when score is 0 due to Cite Check failure ...>
    ---
```

**Test-suite gap:** Unit test at L337–L355 tests only the *failure* template for "defect_class: last." The success-template test at L318–L335 only asserts `score:` < `defect_class:` line number — does NOT assert `defect_class:` is the last field. So `reason:` after `defect_class:` passes the test while violating the stated invariant.

**Disposition:** REORDER — move `reason:` to BEFORE `defect_class:` in the success template so `defect_class:` is unconditionally last. Update the corresponding unit test to assert `defect_class:` is the last field on the success path.
