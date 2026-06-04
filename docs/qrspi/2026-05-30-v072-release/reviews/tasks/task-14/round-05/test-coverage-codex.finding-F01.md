---
finding_id: R5-F01
reviewer_tag: test-coverage-codex
round: 5
severity: low
change_type: scope
referenced_files: [tests/integration/test-reference-gate-pause.bats]
---

# F01: Positive sweep-detection lacks combined end-to-end fixture

tc-codex flagged that current tests inspect prose elements (threshold, keywords, finding shape) independently via grep but do not exercise a single sweep-shaped fixture (`>5 same-ext + keyword + missing dependent_tests:`) end-to-end and assert resulting pause/failure behavior.

## Adjudication: SCOPE-DEFER (not blocking)

The T14 spec's test expectations (lines 46-52) deliberately call for **inspect-style** validation (5x "Inspect" + 1x targeted-run "cases" covering both positive missing-field pause and malformed variants). The cases ARE present and section-scoped via `extract_and_grep`. End-to-end behavioral fixture (constructing a fake task spec, running the reviewer agent against it, asserting pause) is a different test architecture — full plan-reviewer harness — not what T14 scoped.

Tracked for v0.7.3 backlog: G15 behavioral end-to-end harness. T14 satisfies the inspect-style contract.
