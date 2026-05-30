---
finding_id: R5-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 5
reviewer: security-claude
---

FAIL_OPEN gap: mismatch + transport-failure combined case lacks fail-closed test requirement

R5 non-zero propagation expectation qualifies "correctly-routed, Codex available" — i.e., non-mismatch path. The mismatch-path expectation says "exit code remains 0" as a definitive statement. Implementer could read this as "always return 0 when mismatch detected", silently swallowing subsequent dispatch failures.

No test covers: mismatch warning fires → dispatch exits non-zero → caller receives non-zero.

Fix:
1. Reword Task 6 mismatch exit-code line: "the mismatch warning does not override the dispatch exit code; the exit code propagated to the caller is the exit code returned by the underlying dispatch"
2. Add to Task 6/7: "When the dispatch-surface detects a mismatch (warning emitted), then invokes a mocked transport that exits with a non-zero exit code, the dispatch surface propagates that same non-zero exit code — mismatch warning does not suppress dispatch failures"

DISPOSITION: ACCEPT — legitimate fail-open gap not previously covered. The R4 fix for non-zero propagation only covered the no-mismatch path. This is a real combinatorial gap, not a re-emission of the design-intent set-aside (that was about whether mismatch ALONE should fail-close; this is about mismatch + transport-fail not silently succeeding).
