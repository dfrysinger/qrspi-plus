---
reviewer_tag: silent-failure-codex
change_type: correctness
severity: medium
artifact: plan.md
location: "Task 09 — G20 verifier actual_model field"
referenced_files:
  - plan.md
---

# F03 — Missing `actual_model` silently normalized to `unknown`

## Defect

T09 verifier is specified to accept missing `actual_model` and write `actual_model: unknown` instead of failing.

## Impact

Silent fallback on missing audit input: schema drift/omission is masked as a normal value, reducing detectability of upstream contract breaks. If a future runtime change drops the `actual_model` field, the verifier would silently produce `unknown` records and the regression wouldn't surface.

## Recommended fix

Fail loud on missing `actual_model`: exit non-zero with diagnostic `actual_model field missing — upstream dispatch transport did not record model identity`. Reserve `unknown` for legitimate runtime states where the model genuinely cannot be identified (e.g., raw HTTP transport without model echo).

## Counter-argument to consider

If `unknown` is the legitimate value for transports that don't echo model identity, then accepting missing-field-as-unknown is correct. The fix may need to distinguish "field absent" (hard fail) from "field present with value `unknown`" (accept).
