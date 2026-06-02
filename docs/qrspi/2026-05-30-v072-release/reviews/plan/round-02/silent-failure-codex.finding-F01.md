---
reviewer_tag: silent-failure-codex
change_type: correctness
severity: medium
artifact: plan.md
location: "Task 16 — G22 model_routing resolver"
referenced_files:
  - plan.md
---

# F01 — Hardcoded model fallback on config defect

## Defect

T16 `_resolve-lib.sh` precedence explicitly allows falling back to a hardcoded `medium` tier with only a warning when config/default tier is missing. The "warning" is log-and-continue.

## Impact

This is the log-and-continue fallback pattern for misconfiguration. Routing proceeds with possibly wrong model selection instead of failing loudly. Contradicts T18's class-level "no fallback target" invariant.

## Recommended fix

Halt on incomplete/missing tier config; exit non-zero with a diagnostic naming the missing tier. Remove the hardcoded `medium` fallback.

## Duplicate-of note

Same finding as silent-failure-claude.F01 and security-codex.F01. Scope-tagger dedupe expected.
