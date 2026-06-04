---
finding_id: R5-F01
reviewer_tag: test-coverage-claude
round: 5
severity: medium
change_type: additive-test
referenced_files: [tests/unit/test-second-reviewer-available.bats]
model: claude-sonnet-4.6
---

Unknown-host DEFAULT path: joint contract split across three fragmented tests (L248-261 single-line+tag; L264-273 host= only; L276-285 vendor= only). DoD L42/L52 requires "exactly one stderr line ... naming the detected host PLUS requested/default vendor" as a joint per-case contract. No single test pins the joint format [second-reviewer-unavailable] host=unknown vendor=none for the default no-override path; the exact value vendor=none on this path is never asserted (only the key vendor= in a separate test). The L451-479 unknown-host-guard test covers only the override sub-variant (vendor=openai-codex), not the default path. Round-05 delta left these unchanged. Converges with test-coverage-codex R5-F02 (GAP B). Fix (test-only additive): add one joint test asserting non-zero + count==1 + ^[second-reviewer-unavailable] + host=unknown + vendor=none.
