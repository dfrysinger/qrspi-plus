---
reviewer_tag: security-codex
change_type: correctness
severity: medium
artifact: plan.md
location: "Task 16 — G22 model_routing schema and resolver"
referenced_files:
  - plan.md
---

# F01 — Invalid config can silently degrade to default routing (fail-open / insecure default)

## Defect

T16 spec preserves resolver precedence ending in a hardcoded `medium` fallback with warning. Test expectations also pin this behavior.

## Impact

Default substitution on invalid/incomplete config rather than hard failure routes work with unintended model/vendor settings when config is broken, reducing operator control and making failures non-obvious. This is the silent-fallback-to-hardcoded-model class G22 sets out to eliminate.

## Recommended fix

Replace the hardcoded `medium` fallback with a hard halt and non-zero exit when config is incomplete. The "loud warning" path is exactly the silent-failure pattern the v0.7.2 release is trying to close.

## Duplicate-of note

Same root issue as silent-failure-codex.F01 and silent-failure-claude.F01. Verifier/scope-tagger should dedupe via H2/file grouping.
