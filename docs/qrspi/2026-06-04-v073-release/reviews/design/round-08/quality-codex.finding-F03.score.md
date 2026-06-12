---
verifier_status: passed
score: 20
actual_model: unknown
defect_class: altitude-mismatch
---

Finding correctly observes that design.md has per-goal/CD Acceptance bullets rather than a consolidated Testing Strategy section grouped by unit/integration/contract/e2e. However, design altitude in QRSPI focuses on "what + why + per-element acceptance"; test-level grouping (unit vs integration vs contract vs e2e) is a Plan-altitude concern. The finding does not cite an upstream SKILL or CLAUDE.md requirement that design must carry such a section. Per-CD acceptance bullets already specify concrete checks (bats fixtures, grep tests, side-by-side comparisons), so adding a grouping section would mostly be restatement. Treated as an altitude-mismatch / general code-quality suggestion not anchored in an upstream constraint.
