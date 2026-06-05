---
reviewer_tag: scope-codex
change_type: scope
severity: medium
artifact: plan.md
location: "Multiple tasks (T21, T34, T39)"
referenced_files:
  - plan.md
---

# F01 — Implementation-detail drift from Plan into Structure/Implement altitude

## Defect

Several task specs encode implementation contracts that belong at Structure or Implement altitude:

- T21 specifies `assert_path_under_repo_root <label> <abs-path>` — a function signature, which is Structure's domain.
- T34 specifies hash/normalization mechanics — algorithm detail, which is Implement's domain.
- T39 specifies resolver grammar and fail paths — implementation logic, which is Implement's domain.

## Impact

Plan-altitude tasks should specify observable behavior, not function shapes or algorithm internals. Drift downward over-constrains the implementer, replicates content in Structure/Implement, and creates drift risk between Plan and Structure on the same surface.

## Recommended fix

Per the F-5 fix-altitude rule in using-qrspi: minimal additions. Restate these as observable-behavior bullets ("path-validation helper rejects paths outside the repo root with diagnostic `<exact-string>`") and let Structure/Implement own the function shape and algorithm grammar.

## Counter-argument to consider

Several of these specifications were intentional during the v0.7.2 round-01 fixes (e.g., T39's symlink canonicalization clause is a security regression fence). Declining this finding for tasks where the implementation detail is load-bearing for the security invariant may be defensible per the fix-altitude rule's "decline scope-extension findings" guidance.
