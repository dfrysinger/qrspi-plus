---
finding_id: R6-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

Task 19's test expectation permits non-executable evidence for a fail-loud behavior that should be runtime-verifiable.

Evidence:
- DoD requires behavioral rejection: `skills/using-qrspi/SKILL.md` "config-validation prose rejects legacy `codex_reviews:` with a rename-naming diagnostic instead of aliasing it." (plan.md:1133)
- But the test expectation is: `Config-validation tests or grep-pinned prose confirm ...` (plan.md:1146, emphasis on "or grep-pinned prose").

A grep-only check can pass while actual validation behavior is wrong (e.g., field silently accepted/aliased at runtime). This leaves the error-condition coverage nondeterministic for a documented fail-loud invariant.
