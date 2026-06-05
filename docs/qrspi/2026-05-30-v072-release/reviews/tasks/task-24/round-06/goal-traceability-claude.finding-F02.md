---
finding_id: F02
severity: low
change_type: correctness
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
Spec-to-test fidelity: the "[T24] Header: override chain documented" test greps `QRSPI_INTERACTION_MODE` (-ge 1), which appears 11x in functional code — so it passes even if the header OVERRIDE CHAIN section were deleted. It does not actually pin test-expectation #7's "header asserts...override chain". Fix: grep the header-unique anchor `OVERRIDE CHAIN` (appears 1x). ORCHESTRATOR: VALID — ACTING (r7 one-line grep fix).
