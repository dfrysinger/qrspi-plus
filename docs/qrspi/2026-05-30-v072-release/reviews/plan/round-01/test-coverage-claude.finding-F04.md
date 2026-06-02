---
finding_id: R1-F04
reviewer: test-coverage-claude
artifact: plan.md
task: Task 10
severity: medium
change_type: correctness
---

# T10 — `defect_class:` ≤30-character limit not exercised at boundary

## What

Task 10 (G28 verifier convergent-evidence exception and
sub-threshold-observations instrumentation) DoD specifies:

> Verifier sidecar examples and rubric prose require a `defect_class:`
> frontmatter field emitted after scoring and before sidecar write, using
> lowercase kebab-case letters, digits, and hyphens, **no more than 30
> characters**.

The Test expectations cover:

- Token shape (lowercase kebab-case, letters/digits/hyphens)
- `unspecified` fallback
- Sub-threshold requires `defect_class:`; above-threshold may carry it

They do NOT cover:

- The 30-character boundary: `defect_class:` of length 30 (accepted),
  length 31 (rejected).
- Uppercase letters (rejected).
- Underscores or other separators (rejected).
- Empty value `defect_class:` with no token (rejected vs. interpreted as
  `unspecified`?).
- Trailing/leading hyphens (e.g., `-foo`, `bar-`) — ambiguous in kebab-case
  conventions.

The "lowercase kebab-case letters, digits, and hyphens, no more than 30
characters" rule is a four-axis validation (case + alphabet + separator
charset + length). The Test expectations exercise only "lowercase kebab-case
letters, digits, and hyphens" loosely as a shape check, without naming the
rejected counter-examples or the 30-char boundary.

## Why this is a test-coverage problem

Test criteria 2 (Edge Cases) explicitly calls out "maximum/minimum values if
the task operates on bounded quantities." The 30-character cap is a hard
upper bound. Without a 30-vs-31 boundary fixture, a length validator could
ship as ≤29 or ≤31 (off-by-one) and still pass every existing test.

Test criteria 3 (Error Conditions) explicitly calls out "the behavior when
input is malformed or invalid." The Test expectations describe what good
input looks like but not what rejection looks like for malformed cases
(uppercase, underscores, empty string, overlength).

## Falsifiable alternative

Extend the T10 Test expectations:

- "Unit fixture: `defect_class:` of exactly 30 characters is accepted; 31
  characters is rejected with a token-shape diagnostic naming the length
  limit."
- "Unit fixture: `defect_class: Foo-Bar` (uppercase) is rejected with a
  case-shape diagnostic; `defect_class: foo_bar` (underscore) is rejected
  with a charset-shape diagnostic."
- "Unit fixture: an empty `defect_class:` value (no token at all) is
  rejected with a missing-required-token diagnostic, distinct from
  `defect_class: unspecified` which is accepted as the documented absence
  signal."

## References

- plan.md ### Task 10 — Definition of done bullets 1–2 and Test expectations
  bullets 1–3.
- Test criteria 2 (Edge Cases) and 3 (Error Conditions) from this reviewer's
  dispatch contract.
