---
finding_id: R2-F02
reviewer_tag: code-quality-claude
severity: low
change_type: style
referenced_files:
  - tests/unit/test-verifier-fan-in-script.bats
---

**F02 — Test section comments reference process-internal artifacts.**

`tests/unit/test-verifier-fan-in-script.bats` lines 261–390 embed the process-internal `# Round-01 review fixes` section header and reviewer-handle labels (`security-claude`, `silent-failure-claude`, `silent-failure-codex`, `code-quality-claude`) in subsection comments. These make the tests read as temporary scaffolding rather than permanent regression coverage, and will be opaque to future maintainers without the review archive.

**Recommendation:** rewrite section comments to describe the behavior under test (e.g., `# Octal-arithmetic crash protection`) rather than the QRSPI round/reviewer that surfaced it.
