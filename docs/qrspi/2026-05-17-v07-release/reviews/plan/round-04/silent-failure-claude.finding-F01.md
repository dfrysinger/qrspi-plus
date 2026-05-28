---
finding_id: R4-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L327
artifact: plan
round: 4
reviewer: silent-failure-claude
---

T07's description (L327) describes what `test-run-third-party-llm.bats` exercises as: "capability-gated `cache_control` emission keyed on `supports_prompt_cache:`" — citing only the single `supports_prompt_cache:` flag. The test expectations at L329 correctly require the full four-cell dual-flag truth table (`supports_prompt_cache:` × `emit_cache_control_markers:`). The description is stale residue from before the round-3 dual-flag architecture fix.

The silent-failure risk is implementation-order: the task description is the implementer's first signal, read before the test expectations. An implementer who reads the description and implements single-flag gating (only `supports_prompt_cache:`) would pass the description's intent but fail the T07 test expectations — which is fine for TDD, EXCEPT that this pin is in T07, a BATS test authoring task. The implementer of T07 writes the test file; if the description says "keyed on `supports_prompt_cache:`," the implementer may author a test that exercises only the single flag and miss the `emit_cache_control_markers:` dimension. The T07 test expectations do enumerate the full truth table, but the description contradicts them.

More specifically: the description says the pin exercises "capability-gated `cache_control` emission keyed on `supports_prompt_cache:`." The test expectations require: "the dual-flag `cache_control` emission gate: the pin exercises all four cells of the `supports_prompt_cache:` × `emit_cache_control_markers:` truth table." An implementer reading only the description to understand what the pin covers would produce a single-flag test, leaving the `emit_cache_control_markers:` gate unexercised — the same gate that ensures T33's spike measurement integrity.

**Fix:** Update T07's description bullet for `test-run-third-party-llm.bats` to say "capability-gated `cache_control` emission keyed on the dual-flag combination (`supports_prompt_cache:` AND `emit_cache_control_markers:`) covering all four cells of the truth table" to match the test expectations that follow. This is a description-level residue from before the round-3 dual-flag architecture fix.
