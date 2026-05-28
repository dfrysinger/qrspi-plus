---
finding_id: R1-F02
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L1053-L1053]
artifact: plan
round: 1
reviewer: silent-failure-claude
---

T36's `test-cache-hit-rate.bats` is described as "Path-conditional: Path A produces verification-only assertions; Path B produces add-then-verify assertions. The path the test runs is read from the spike report deliverable from T33." This design makes the test's behavior contingent on runtime data from another task's artifact. The test expectations list no assertion about what happens when the spike-report deliverable is absent, malformed, or contains an unrecognized decision token (something other than "Path A" or "Path B").

If T33's spike report is missing, the test will silently branch to some default behavior (likely Path A as the safe default, or will produce a parse error that may be misread as a test failure unrelated to the missing file). Neither outcome is a loud, named failure that identifies "the cache-hit-rate test cannot run because the spike report deliverable is missing."

This is a log-and-continue pattern at the test level: a missing prerequisite causes undefined behavior in the test, and the test may appear to pass (if it silently defaults to Path A) while the actual measurement decision was never made. Because T36's Phase 1 Acceptance Criteria require "a recorded decision determines whether the platform's existing caching behavior is sufficient," a missing spike report that causes the test to silently assume Path A would produce a false-green acceptance criterion.

The fix is to add a test expectation: "When the T33 spike-report deliverable is absent or does not contain a valid Path A or Path B decision line, `test-cache-hit-rate.bats` fails with a loud diagnostic naming the missing or malformed prerequisite and does not silently default to either path." This ensures the dependency between T33 and T36 is load-bearing in both directions.
