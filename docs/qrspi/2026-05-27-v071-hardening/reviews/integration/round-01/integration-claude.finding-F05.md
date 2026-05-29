---
finding_id: R1-F06
severity: low
change_type: scope
referenced_files: [scripts/run-codex-review.sh, skills/using-qrspi/SKILL.md]
artifact: integration
round: 1
reviewer: integration-claude
---

## T6's detect_host() has no production consumer in Wave 1; DKR10 shared-probe contract half-instantiated (informational)

**Surface:** `scripts/run-codex-review.sh:122-139` (detect_host definition), `:147-190`
(check_codex_available), only consumer `tests/unit/test-host-detection.bats` via
`QRSPI_SOURCE_ONLY=1` guard, ↔ `skills/using-qrspi/SKILL.md` (no detect_host references).

Per design DKR10 and structure.md:177-197 ("One env-var probe implementation, surfaced at
config-load time, serves both G6 and G7b"), Wave 1 lands the mechanism but
`using-qrspi/SKILL.md:405-410` still uses pre-T6 inline glob, not a call into detect_host /
check_codex_available.

Dispatcher-prose binding is scheduled for Wave 2 (task-07) and Wave 5 (task-10).

**Cross-task impact at Wave-1 boundary:** zero. **Forward-looking risk:** Wave-2 integration
needs to either source `scripts/run-codex-review.sh` (QRSPI_SOURCE_ONLY=1 guard already
exists for this) or duplicate detection logic in prose (would violate DKR10).

**Suggested action:** flag for Wave-2 integration review. Verify task-07 actually wires
`using-qrspi/SKILL.md` to call detect_host / check_codex_available rather than re-implementing
the probe in prose.

**Why LOW/informational:** legitimate scope-boundary state of multi-wave plan, not a
Wave-1 defect.
