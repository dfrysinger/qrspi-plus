---
finding_id: R5-F02
reviewer_tag: test-coverage-codex
round: 5
severity: medium
change_type: additive-test
referenced_files: [tests/unit/test-second-reviewer-available.bats]
model: gpt-5.3-codex
---

Test-quality / contract-robustness gap: the UNKNOWN-HOST (default/no-override) unavailable case is validated across multiple SEPARATE tests rather than one joint contract assertion, weakening the guarantee that all required properties hold together for the same run. Evidence: exit status L237-245; single-line/tag L248-261; host= L264-273; vendor= L276-285 — four separate tests. DoD task-19.md:42,52 requires the combined contract per unavailable case. Fix (test-only additive): add one unknown-host/no-override test that jointly asserts non-zero + exactly one tagged line + both host= and vendor= in that same line (optionally pin host=unknown + vendor=none).
