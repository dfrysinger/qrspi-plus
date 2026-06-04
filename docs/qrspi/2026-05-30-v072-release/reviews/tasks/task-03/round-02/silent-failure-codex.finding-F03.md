---
finding_id: R2-F03
reviewer_tag: silent-failure-codex
round: 2
task: 3
severity: medium
change_type: test_coverage
referenced_files:
  - tests/unit/test-per-finding-file-emission.bats
---

# F03 — Wrong-channel loudness asserted only by doc-grep, not by runtime exercise

## Location

`tests/unit/test-per-finding-file-emission.bats:113–114, 131–132`

## Issue

The "wrong-channel emission loudness" guarantee — that an emission to the wrong channel produces the diagnostic `expected tag produced no output` — is tested ONLY by grepping the contract docs (`first-party-emission.md`, `third-party-emission.md`) for the literal phrase. No executable test exercises the wrong-channel scenario end-to-end and asserts the orchestrator/splitter actually raises the diagnostic.

## Silent-failure surface

Runtime regressions can silently break loud failure behavior while the tests stay green — because the prose still contains the phrase. The contract documents the behavior; the test pins the documentation; nothing pins the runtime behavior. A future refactor that strips the diagnostic from the orchestrator's wrong-channel handler would not break the test.

## Suggested fix

Add executable negative tests for each emission channel:

**First-party wrong-channel test:**
1. Dispatch a reviewer (or simulate via a fixture script) that emits findings to stdout instead of disk.
2. Run the orchestrator's tag-presence check.
3. Assert the orchestrator emits `expected tag produced no output` (grep stderr/log).

**Third-party wrong-channel test:**
1. Dispatch a reviewer (or simulate) that writes per-finding files directly to disk instead of stdout.
2. Run the splitter on the empty stdout.
3. Assert the splitter or orchestrator emits the diagnostic.

If a full end-to-end harness is out of scope, a smaller test that drives the diagnostic emission code path directly (mocked input) is acceptable.

## Severity rationale

Medium: doc-grep tests are useful gate-keeping but they pin prose, not behavior. The whole point of the wrong-channel diagnostic is runtime fail-loudness — testing only the prose misses what matters.
