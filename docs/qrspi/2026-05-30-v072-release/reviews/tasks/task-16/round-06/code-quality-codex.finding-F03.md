---
finding_id: R6-F03
reviewer_tag: code-quality-codex
round: 6
severity: medium
change_type: style
referenced_files: [scripts/_resolve-lib.sh:2, scripts/_resolve-lib.sh:17, tests/unit/test-config-model-routing.bats:55]
---

# code-quality-codex F03 — QRSPI-internal IDs in comments/tests

Claims QRSPI-internal IDs (`G22`, `T16`, `F02`) embedded in code comments/test
surfaces are forbidden outside `docs/qrspi/`.

**Orchestrator adjudication: DECLINE — false positive.** Design-ID provenance
references in code comments are an ESTABLISHED repo convention: `grep` finds 17
such references across 8 scripts (round-prepare.sh, verifier-fan-in.sh,
run-codex-review.sh, await-round.sh, codex-companion-bg.sh, etc.). The header
provenance comment ("G22 / design.md CD-1") aids traceability and matches the
existing codebase style; stripping it would reduce useful cross-references. The
reviewer over-applied a contract rule that does not match actual repo
convention.

Chat-only return persisted by orchestrator.
