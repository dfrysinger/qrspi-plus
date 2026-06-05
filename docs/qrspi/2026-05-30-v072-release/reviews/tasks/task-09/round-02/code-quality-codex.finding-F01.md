---
finding_id: R2-F01
severity: low
change_type: clarity
artifact: code
round: 2
reviewer: code-quality-codex
model: gpt-5.3-codex
referenced_files:
  - scripts/run-codex-review.sh#L569
  - scripts/run-codex-review.sh#L573
  - scripts/run-codex-review.sh#L577
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1446
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1461
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1581
disposition: defer-v0.7.3
defer_rationale: |
  File-wide recurring pattern. The Phase 1 acceptance file is the documented
  traceability spine (T01-T37 / G1-G37); EVERY task slice carries its IDs as
  inline `# T<NN>` markers and as `_t<NN>_*` helper-function prefixes. Scrubbing
  only T09 tokens would make the file structurally inconsistent with T01-T08
  slices that all use the pattern. Same finding raised at T08 R3 from
  code-quality-codex and deferred there with same rationale. v0.7.3 backlog
  carries the "ID hygiene leak in test-files" item; the fix is a global pass
  with a project-wide rename to descriptive labels, not a per-task scrub.
---

# ID hygiene violations (T09, T11, G3) in non-doc surfaces

`T09`, `T11`, and `G3` tokens are present in changed non-doc files, which would violate the ID hygiene rule for QRSPI-internal IDs outside `docs/qrspi/` if applied strictly.

Examples:
- `scripts/run-codex-review.sh:569`, `:573`, `:577`
- `tests/acceptance/v07-phase1/test-phase1-acceptance.bats:1446`, `:1461-1466`, `:1469`, `:1581`

**Disposition:** Defer to v0.7.3. This is a file-wide recurring pattern; the Phase 1 acceptance bats file is the documented traceability spine and uses these IDs as inline markers across every task slice (T01-T08 all carry their IDs). Scrubbing only T09 tokens would make the file structurally inconsistent with prior slices. The proper fix is a project-wide rename to stable descriptive wording — already on the v0.7.3 backlog as "ID hygiene leak in test-files (recurring across multiple tasks)".
