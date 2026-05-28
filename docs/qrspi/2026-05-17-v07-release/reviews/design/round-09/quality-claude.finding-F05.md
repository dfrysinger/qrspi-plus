---
finding_id: R9-F05
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L281, docs/qrspi/2026-05-17-v07-release/design.md:L304-L311]
artifact: design
round: 9
reviewer: quality-claude
---

G6's pre-implementer RED-verification gate specifies a verdict ("every failure is a target-behavior-not-satisfied signal — assertion failure, not a syntax error, import/load error, fixture/setup error, missing-symbol error, or other infrastructure failure") without naming the load-bearing mechanism that classifies a failure as "assertion vs. infrastructure" across the language/test-framework surface that QRSPI tasks span (BATS, Vitest/Jest, pytest, etc.).

The gate is described at lines 280–281:

> The orchestrator parses the test runner output and verifies BOTH (a) no test passes pre-implementation [...] AND (b) every failure is a target-behavior-not-satisfied signal — assertion failure, not a syntax error, import/load error, fixture/setup error, missing-symbol error, or other infrastructure failure.

The classifier is not specified. Different test frameworks emit different exit codes, different stderr/stdout shapes, and different failure tags for "assertion" vs. "compile/load failure." BATS, for example, conflates assertion failure and arbitrary command failure under exit code 1; a Vitest failure with a stack trace can mean either an assertion or an uncaught import error; pytest has separate exit codes for collection errors vs. test failures.

The test strategy (lines 308–309) pins the behavioral expectation:

> - Pre-implementer RED-verification test (pause cases): the orchestrator pauses when (i) any pre-implementation test passes, OR (ii) any test fails for an infrastructure reason — syntax error, import error, fixture/setup error.

…but does not specify how the orchestrator reliably distinguishes (ii) from (iii) "test fails for assertion reason" across the supported test surfaces.

This is a clarity issue, not a correctness one: the design states the contract but defers the load-bearing classification mechanism without naming where it gets specified. Downstream (Structure/Plan) cannot tell whether the design intends a per-framework adapter, a heuristic on stderr patterns, or a wrapper that normalizes verdicts.

Suggested fix: add a sentence to G6's pre-implementer gate description naming where the assertion-vs-infrastructure classifier is owned. Candidates: (a) "The classifier mechanism — per-framework adapter or normalized verdict wrapper — is owned by Structure"; (b) "The implementer-protocol defines a normalized test-output contract that the test-writer's runner emits; the classifier reads that contract, not raw test-framework output"; (c) Some other explicit owning surface. Otherwise Phasing/Structure will receive an unspecified gate.
