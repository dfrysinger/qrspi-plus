---
finding_id: R4-F06
severity: medium
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/plan.md:L706"]
artifact: plan
round: 4
reviewer: test-coverage-claude
---

T27's Fixture 2 test expectation at line 706 reads: "Missing anchor file — the orchestrator's call 'exits non-zero with a clear error (no silent fallback)'" (G7 Acceptance bullet 3 sub-bullet 2). "Clear error" is not a specific testable assertion — the test writer cannot write `assert_output --partial "<diagnostic>"` without a named diagnostic. The description of T27 (line 702) identically uses "clear error" without naming the diagnostic. By contrast, Fixture 4 in the same task (line 708) names the precise diagnostic: "the orchestrator's call halts with the `sha-format-invalid:` named diagnostic." The missing-anchor-file case and the malformed-anchor-file case are distinct scenarios and should have distinct named diagnostics. T26's description (line 689) names `sha-format-invalid:` for the malformed case but never names a diagnostic for the missing-file case. A deterministic test requires a specific expected string (e.g., `anchor-file-missing:` or `round-commit-file-not-found:`) to distinguish this failure mode from malformed content. Without it, the Fixture 2 test can only verify non-zero exit, leaving the correct diagnostic untested.
