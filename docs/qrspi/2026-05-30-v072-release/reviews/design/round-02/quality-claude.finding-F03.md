---
finding_id: R2-F03
severity: low
change_type: correctness
artifact: design
round: 2
reviewer: quality-claude
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md
---

## Test Strategy § Cross-cutting invariants — G21 clause assigns T2 to a `tests/lint/` bats lint test, outside T2's `scripts/` coverage boundary

**Location:** `design.md` L735 (Test Strategy § Cross-cutting invariants)

**Problem.** The G21 cross-cutting invariant reads:

> "G21 bats BW02 guard (T2 lint rule — the rule that catches its own pattern in test fixtures)."

T2's coverage boundary at L720 is "one bats file **per script under `scripts/`**." G21's lint gate lives at `tests/lint/test-bats-body-assertion-guard.bats` — it is a bats test that lints other bats test files for the `$body` guard pattern. This is not a per-script behavioral test for a script in `scripts/`; it is a lint gate over the test corpus. It is architecturally similar to T1 (static-analysis lint) applied to bats fixtures rather than to shell scripts.

Calling the G21 lint gate "T2" is a taxonomy mismatch: T2 is "per-script behavioral assertions" but G21's lint gate has no associated script-under-test. The G21 design block itself correctly describes the gate as a "lint gate," which signals T1 framing.

**Impact.** This is lower severity than F01 and F02 because G21's implementation spec is fully described in the G21 design block — the cross-cutting invariant label is supplementary taxonomy, not the authoritative spec. An implementer following the G21 block directly would build the lint gate correctly regardless of the T2 label. However, Plan authors assembling T2 tasks would include G21's lint gate in the per-script bats task list, creating an awkward mismatch between "scripts/ scripts" and "tests/lint/ lint test."

**Suggested fix.** Change the G21 invariant classification from "T2 lint rule" to "T1 lint (bats-based lint gate in `tests/lint/`, following G21 spec)" or introduce a "T1-bats" sub-classification for lint gates that use bats tooling but cover non-script content. Either makes the G21 gate's relationship to the taxonomy explicit without forcing it into T2's per-script boundary.
