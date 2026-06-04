---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files: ["tests/unit/test-change-type-partition.bats:62-104", "skills/reviewer-protocol/SKILL.md:57-59"]
artifact: code
round: 1
reviewer: silent-failure-claude
---

**Tautological schema-guard test — helper is defined in the test file, not in production code.**

The schema-guard tests (L73-94 legacy fixture, L96-104 well-formed fixture) assert behavior of `_partition_finding` (L62-71), a helper authored inside the test file itself. There is no production schema guard being exercised: the awk one-liner is invented by the test, returns 2 with the named-cause diagnostic the test then greps for, and exits 0 routing on the well-formed fixture. Self-fulfilling — test-private function rejects test-private fixture.

SKILL.md L59 declares "the schema guard halts with a named cause that explicitly names the missing `change_type:` field." T04 Out scope (L31) defers `scripts/verifier-fan-in.sh` to T05, so the gap is intentional — but the test name `"schema guard halts with named cause when change_type is missing"` is misleading: no schema guard ran, only a test-local mirror did. A future reader will reasonably assume "the field-name contract is now pinned by regression coverage" when in fact production routing has zero coverage against `category:` drift.

**Fix (in-scope):** Rename helper to make locality explicit (e.g., `_test_mirror_partition_finding`) and add a comment block stating "This is a test-local mirror of the contract documented in SKILL.md §Finding Schema. The production schema guard that enforces this contract is added in T05."
