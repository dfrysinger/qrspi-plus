---
finding_id: R7-F02
severity: medium
change_type: correctness
referenced_files: [/Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-06-04-v073-release/plan.md:L867-L883]
artifact: plan
round: 7
reviewer: test-coverage-codex
---
T12's permanent lint expectations verify fail-direction for `[T<digits>]` and `R<digits>-F<digits>`, but omit an explicit fail-direction scenario for bracketed finding IDs (`[F<digits>]`) even though the task description says it blocks forbidden finding-ID tokens generally. Without a `[F<digits>]` fixture expectation, the lint can regress on that token shape while still passing the documented tests.
