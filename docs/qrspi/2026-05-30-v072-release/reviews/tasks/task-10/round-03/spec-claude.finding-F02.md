---
finding_id: R3-F02
reviewer_tag: spec-claude
severity: medium
change_type: scope
referenced_files:
  - scripts/verifier-fan-in.sh
  - tests/unit/test-verifier-agent-file.bats#L429-L435
---

# scripts/verifier-fan-in.sh modified despite Task-10 prohibition (convergent with spec-codex)

12 lines of documentation added to `verifier-fan-in.sh` header documenting the sidecar field-ordering invariant. Spec L31, L44, L57 unconditionally prohibit changes to this file.

**Compounding factor:** A test (`tests/unit/test-verifier-agent-file.bats` L429-L435) was added that REQUIRES this out-of-scope modification, locking in the deviation.

**Convergent with spec-codex R3 F02 (severity HIGH there).** Convergent → take MAX severity = HIGH.

**Disposition:** REVERT both the fan-in header documentation and the locking test. The agent body already documents the invariant; redundant documentation in the fan-in script is unnecessary and out-of-scope.
