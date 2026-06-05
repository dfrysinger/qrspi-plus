---
finding_id: R2-F03
severity: medium
change_type: scope
artifact: code
round: 2
reviewer: security-codex
model: gpt-5.3-codex
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1073-L1075
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1089-L1095
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1103-L1250
---

# Acceptance tests do not execute verifier Cite Check, allowing silent bypass regressions

**What's wrong:** TC4–TC7 prewrite `.score.md` sidecars with `score: 0` + `HALLUCINATED:` and only test fan-in filtering. The verifier is explicitly not invoked ("IF the verifier were invoked…").

**Concrete attack scenario:** A malicious contributor weakens verifier behavior (e.g., skips quoted-content or anchor checks, or accepts obfuscated cites). These tests still pass because they never call the verifier; fabricated sidecars already contain expected outputs. The broken Cite Check ships undetected.

**Fix:** Add at least one end-to-end test per failure mode that runs the actual verifier on crafted finding files and asserts emitted sidecar values. Keep fan-in tests, but separate them from verifier-behavior tests.
