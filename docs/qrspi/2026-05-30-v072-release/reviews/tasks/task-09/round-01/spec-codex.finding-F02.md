---
finding_id: R1-F02
severity: medium
change_type: correctness
artifact: code
round: 1
reviewer: spec-codex
model: gpt-5.3-codex
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1463-L1511
  - tasks/task-09.md#L43
  - tasks/task-09.md#L50
---

# Missing assertion for "no aggregate verified-file header introduced"

**Spec requirement:** Coverage must prove unchanged keep behavior AND no aggregate verified-file header introduction (`tasks/task-09.md` lines 43, 50).

**Observed:** AC6 checks score thresholds and model-threshold token grep only (`tests/acceptance/v07-phase1/test-phase1-acceptance.bats` lines 1463–1511). No assertion checks absence of an aggregate verified-file header.

**Result:** Acceptance criterion not fully covered.

**Fix:** Add a grep-based assertion that `verified.md` (or any aggregate-header file) is not produced by the verifier fan-in flow, OR that the verifier prose/scripts contain no introduction of an aggregate-header file emission. The simplest form: grep that `verified.md` does NOT appear as an output path in `agents/qrspi-finding-verifier.md` or `scripts/verifier-fan-in.sh`.
