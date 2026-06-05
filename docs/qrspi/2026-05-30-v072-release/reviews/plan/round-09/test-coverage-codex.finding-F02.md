---
finding_id: R9-F02
severity: medium
change_type: correctness
referenced_files:
  - plan.md:L1128
  - plan.md:L1140
---

# T19 — one test expectation is conditional and not verifiable

**Problem.** Task 19's Test Expectation says the Codex host signal returns `codex-cli` "when implemented," which is not a deterministically verifiable acceptance condition for this release.

**Evidence.**
- DoD lists `codex-cli` as an expected returned identifier (L1128).
- The matching Test Expectation weakens this to a conditional phrase (L1140).

**Suggested fix.** Replace with a concrete, current fixture-driven signal check, OR explicitly remove/defer `codex-cli` from this task's DoD so expectations remain testable now.

(Materialized by orchestrator from Codex chat-only return — Codex CLI chat-only-output constraint recurred.)
