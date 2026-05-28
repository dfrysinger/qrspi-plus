---
finding_id: F02
severity: medium
change_type: bundle
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 1
reviewer: spec-codex
---

## Task 8 bundles many distinct observable changes

Task 8 includes 4 deletions, multiple runtime/prose removals, acceptance-suite rewiring, plus new test creation, without sizing exception. Violates atomic-task rule.

**Recommendation:** Split into 3 ordered tasks: (1) delete obsolete cache artifacts/tests; (2) remove cache fields/branches from SKILL.md, run-third-party-llm.sh, unit assertions; (3) acceptance-suite cleanup.

**Disposition:** After removing the new test creation (per F01 / quality-codex F02), Task 8 remains a coupled deletion across one mechanism. Add an explicit sizing exception "mechanism retirement" and a one-paragraph rationale that the deletions are tightly coupled (mechanism boundary closes atomically). Keep as a single task. Document via sizing-exception note rather than split.
