---
finding_id: R2-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L393-L401]
artifact: plan
round: 2
reviewer: scope-claude
---

The round-1 scope fix (scope-claude.R1-F02) removed per-framework parsing-marker enumeration from the T10 **description**, adding the deferrral clause "Implement selects the specific markers per framework." However the T10 **test expectations** still enumerate the same specific detection markers that the description now defers to Implement:

- "A BATS runner output containing `not ok` lines emits `assertion-failure`; a stdout containing only `ok` lines emits `pass`; a stderr containing a parse error emits `infrastructure-failure`."
- "A Vitest runner stderr containing `SyntaxError` or `Cannot find module` emits `infrastructure-failure`"
- "A Jest runner stderr containing `Cannot find module` or `SyntaxError` emits `infrastructure-failure`"
- "A pytest collection error or import error emits `infrastructure-failure`"

By specifying which exact stderr strings constitute `infrastructure-failure` versus `assertion-failure` for each framework, these test expectations foreclose Implement's negotiation room on exactly the question the description said Implement should decide. The test expectations are functionally equivalent to specifying the per-framework marker enumeration that was trimmed from the description — the trim was applied to one location but not the other, leaving the two sections of the same task in contradiction.

Plan DEFERS "Line-by-line logic, control-flow detail" to Implement; the specific stdout/stderr signals that classify an adapter's output are the detection algorithm, which is Implement-layer. Plan OWNS test expectations in plain language (e.g., "given an infrastructure error in the test runner, the adapter should emit `infrastructure-failure`") but not the specific string literals that constitute evidence of an infrastructure error in each framework.

The fix is to rewrite each framework-specific test expectation to describe the **class of behavior** without naming the specific marker strings. For example:

- "Given BATS runner output where the tests fail due to an assertion (not a setup or syntax error), the adapter emits `assertion-failure`" — plain language, defers choice of detection signal to Implement.
- "Given Vitest runner output indicating a module or syntax error, the adapter emits `infrastructure-failure`" — behavioral description without locking `SyntaxError`/`Cannot find module` as the specific literals.

The five framework-specific expectations (lines ~396-400) should each be rewritten this way. The one test expectation that should be kept as-is is the structural contract (adapter accepts the three flags and rejects other invocation shapes, adapter exits 0 on classification or 1 with diagnostic on unrecognized output) — those are observable behavior claims Plan owns.
