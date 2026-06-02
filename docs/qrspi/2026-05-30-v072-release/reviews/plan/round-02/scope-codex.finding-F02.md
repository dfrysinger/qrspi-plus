---
reviewer_tag: scope-codex
change_type: scope
severity: low
artifact: plan.md
location: "Multiple tasks — Test expectations sections"
referenced_files:
  - plan.md
---

# F02 — Test-code assertion leakage in Plan-level Test Expectations

## Defect

Many tasks' Test Expectations include test-code and assertion specifics: exact grep commands, exact stderr strings, exact fixture mechanics. This exceeds Plan's plain-language test-expectation boundary per `skills/plan/owns-defers.md`.

## Impact

Drift downward from Plan into the test-writer's territory. Replicates content the implementer's test-writer subagent will produce, and creates drift risk between Plan's pinned strings and the actual implementation's emitted strings.

## Recommended fix

Restate as plain-language behavior bullets ("verifier exits non-zero with a diagnostic that mentions the missing field") rather than literal command snippets. Reserve literal-string expectations for cases where the exact wire format is part of the public contract (e.g., diagnostic strings users grep for in CI).

## Counter-argument to consider

Some literal-string expectations are intentional: the diagnostic strings ARE the public contract (operators grep for them). The F-5 fix-altitude rule's "decline scope-extension findings" guidance may apply for those bullets; restrict the fix to the genuinely-internal mechanics.
