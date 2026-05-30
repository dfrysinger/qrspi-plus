# Finding F08: Task 7 — Config-vs-detection mismatch diagnostic has no behavioral test expectation

**Artifact:** plan.md
**Task:** Task 7 (G6 part 2 — per-host dispatch transport prose in using-qrspi SKILL)
**Category:** Behavioral Coverage
**Severity:** blocking

## Problem

Design DKR6 specifies a runtime diagnostic:

> "At goals-time, if detection result disagrees with the `codex_reviews` config value, emit a one-line diagnostic naming the disagreement."

The task description says: "A one-line diagnostic hook is described at the detection boundary; it fires when the detected host disagrees with the `codex_reviews` config value, identifying the specific disagreement."

The single test expectation for this feature is:

> "`skills/using-qrspi/SKILL.md` contains a mismatch-diagnostic description that fires when the host detected by the probe disagrees with the `codex_reviews` config value."

This is a **prose assertion** — it verifies that the SKILL.md text describes the diagnostic, not that the diagnostic actually fires at runtime. No test expectation covers the observable runtime behavior:
- Under what conditions does the diagnostic fire?
- What does it write (to stdout? stderr? a log file)?
- What is the format or content of the one-line diagnostic message?
- Does execution continue or halt after the diagnostic fires?

The mismatch diagnostic is listed in Design DKR6 as a key correctness feature ("catches the misdetection that surfaced at config-time in this run"). Without a behavioral test expectation, the test writer can only verify that the SKILL.md *says* a diagnostic will fire — not that the implementation actually emits one.

## Recommendation

Add one behavioral expectation for the diagnostic, for example:

- "When `detect_host()` returns `claude-code` but the `codex_reviews` config value is set to `copilot-cli` (or vice versa), the dispatch helper emits a one-line warning message to stderr that names both the detected host and the configured host value, and execution continues rather than aborting."

This requires a unit test in `tests/unit/test-host-detection.bats` (Task 6's test file) or a new assertion in the acceptance test, mocking the config disagreement scenario.
