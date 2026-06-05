---
finding_id: R3-F03
reviewer_tag: spec-codex
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/tasks/task-10.md#L13-L29
  - agents/qrspi-finding-verifier.md#L69-L70
  - tests/unit/test-verifier-agent-file.bats#L388-L403
---

# On-error branch scope-creep + new test file outside target-files list

Task-10 spec L13 lists 4 target files: agents/qrspi-finding-verifier.md, skills/using-qrspi/SKILL.md, tests/unit/test-verified-file-shape.bats, tests/acceptance/v07-phase1/test-phase1-acceptance.bats.

R2 fix added a new pre-step "on unrecoverable error ... never return without writing a sidecar" branch to the verifier agent procedure (Fix I from R2 fan-in). This was authorized by sf-claude R2 F04 but is scope-creep versus Task-10's in-scope changes (which require only `defect_class:` instrumentation per spec L24-L28).

R2 fix ALSO added a NEW unit test file `tests/unit/test-verifier-agent-file.bats` — not in the spec's target-files list.

**Convergent with spec-claude R3 F03 (severity LOW informational there).**

**Disposition:**
- REVERT the on-error branch text from `agents/qrspi-finding-verifier.md` (out-of-scope; file PI-V072-T10-001 already covers this for v0.7.3).
- CONSOLIDATE retained unit tests from `test-verifier-agent-file.bats` into the in-scope `test-verified-file-shape.bats`. Delete the new file.
