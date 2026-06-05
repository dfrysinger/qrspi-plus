---
finding_id: R3-F01
reviewer: cq-claude
severity: med
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
---

# F01 — Stale lock on process kill leaves manifest permanently unwritable

**Convergent with sec-claude R3-F02 / sec-codex R3-F02 / sf-claude R3-F05.** cq-claude adds the observation that the comment on `_append_manifest_entry` creates a false assurance — it explains the concurrency guarantee but does not mention the stale-lock limitation under forced termination.

**Suggested remediation (either):**
(a) Probe lock dir age before spin-loop; rmdir if older than 30s and re-enter.
(b) At minimum, update the comment to document the limitation and name `rmdir "${manifest}.lock"` as the manual recovery step.
