---
finding_id: R4-F04
severity: low
change_type: clarity
referenced_files: [tests/unit/test-verified-file-shape.bats]
---

# No test asserts examples of well-formed defect_class tags documented in agent body (L50)

Spec L50 requires asserting the documented token shape, ≤30-char limit, **examples**, and `unspecified` fallback. Unit tests cover shape/cap/regex and unspecified — but no test asserts examples of well-formed tokens (e.g., `goal-leakage`, `swallowed-error`, `fabricated-citation`) are present.

The implementation includes a rich set of examples (diff L14: "Examples of well-formed tags: `goal-leakage` … `fabricated-citation`"), but their deletion would degrade verifier classification quality silently.

Convergent with tc-codex.finding-F04 (examples-not-pinned) → PI-V072-T10-013.

**Recommended remediation:**
```bats
grep -qiE 'goal-leakage|swallowed-error|fabricated-citation|unanchored-claim' \
  agents/qrspi-finding-verifier.md
```
