---
finding_id: R9-F01
severity: medium
change_type: correctness
referenced_files:
  - plan.md:L709
  - plan.md:L713-L718
---

# T11 atomic-append requirement is not actually tested for contention

**Problem.** Task 11's DoD requires manifest writes to be "atomic and append-safe," but the Test Expectations only cover repeated invocations and JSON well-formedness. They do not require a contention scenario that can reveal lost-update races.

**Evidence.**
- DoD explicitly requires atomic append safety (L709).
- Tests state repeated invocations / multiple tags and well-formed JSON checks (L715-L718), with no parallel/interleaving assertion.

**Suggested fix.** Add a Test Expectation that runs overlapping dispatch writes to the same round directory and asserts no entry loss/corruption and a complete expected entry count.

(Materialized by orchestrator from Codex chat-only return — Codex CLI chat-only-output constraint recurred.)
