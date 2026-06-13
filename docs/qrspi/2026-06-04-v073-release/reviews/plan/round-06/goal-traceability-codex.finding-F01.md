---
finding_id: R6-F01
severity: medium
change_type: correctness
referenced_files:
  - goals.md:L35-L48
  - design.md:L165-L170
  - plan.md:L148-L148
  - plan.md:L392-L399
  - plan.md:L410-L417
artifact: plan
round: 6
reviewer: goal-traceability-codex
---

G2 coverage is partial in plan-authored acceptance criteria: the upstream goal/design require eliminating **both** `[Tnn]` and `R\d+-F\d+` tokens from bats `@test` descriptions, but the explicit plan checks only hard-assert `[Tnn]` removal.

- Upstream requirement is explicit in goals/design (`[Tnn]` + `R\d+-F\d+`).
- Phase acceptance currently asserts only `grep ... \[T[0-9]+` (no explicit `R\d+-F\d+` check).
- T11/T12 expectations similarly do not provide an explicit, auditable assertion for the `R\d+-F\d+` pattern; T11's consumer-detection grep is instead keyed to `\[F[0-9]+`.

This leaves a traceability gap for one of G2's required token classes. Add explicit plan-authored test expectations (task-level and/or phase-level) that assert zero `R\d+-F\d+` matches and include a fail-direction fixture for that pattern.
