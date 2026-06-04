---
finding_id: R3-F03
reviewer: cq-codex
severity: low
change_type: clarity
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats
---

# F03 — Stale section header for changed test intent

**File:** tests/acceptance/v07-phase1/test-phase1-acceptance.bats lines 785-787

The comment header still says TE10 validates a "mocked task-tool dispatch" with "distinguishable marker," but the updated test (lines 790-833) validates first-party `DISPATCH_FILE` + manifest behavior — entirely different scope.

**Fix:** update the section header comment to describe what the test actually verifies in the R2/R3 implementation: first-party `DISPATCH_FILE=` marker on stdout + manifest entry with `mode: first_party` + dispatch_spec.prompt_file matching the stdout marker.
