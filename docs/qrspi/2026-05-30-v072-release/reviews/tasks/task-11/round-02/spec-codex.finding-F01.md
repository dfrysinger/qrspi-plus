---
finding_id: R2-F01
reviewer: spec-codex
severity: med
change_type: scope
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats
---

# F01 — First-party acceptance tests don't assert dispatch_spec.host/vendor/model

**Spec requirement (task-11.md lines 37, 41, 45-46):** First-party manifest entries include `dispatch_spec.subagent_type`, `dispatch_spec.host`, `dispatch_spec.vendor`, `dispatch_spec.model`, and `dispatch_spec.prompt_file`. Acceptance coverage verifies the full provenance field set.

**Implementation status:** `scripts/run-codex-review.sh` lines 286-299 writes all five fields correctly.

**Gap:** First-party acceptance tests at:
- test-phase1-acceptance.bats lines 2337-2348 (AC2 — sourced helper test)
- test-phase1-acceptance.bats lines 2537-2545 (AC5 — end-to-end COPILOT_CLI=1 test)

…assert only `mode`, `status`, `subagent_type`, and `prompt_file`. They do NOT assert `dispatch_spec.host`, `dispatch_spec.vendor`, or `dispatch_spec.model`. Spec test expectations require explicit verification of the full first-party provenance set.

**Fix sketch:** add `jq` assertions to both AC2 and AC5 verifying `.dispatch_spec.host`, `.dispatch_spec.vendor`, `.dispatch_spec.model` are present and non-empty (or match the resolved values from the call site).

**Disposition:** in scope for T11 — closes the spec's full-provenance-field-set test coverage clause.
