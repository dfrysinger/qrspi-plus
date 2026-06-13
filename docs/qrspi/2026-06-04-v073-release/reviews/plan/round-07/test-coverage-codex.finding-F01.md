---
finding_id: R7-F01
severity: medium
change_type: correctness
referenced_files: [/Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-06-04-v073-release/plan.md:L843-L866]
artifact: plan
round: 7
reviewer: test-coverage-codex
---
T11's test expectations do not cover the bracketed finding-ID token class (`[F<digits>]`) even though the task scope and its own search-proof text define that token as part of the sweep contract. Current expectations only assert zero matches for `[T<digits>]` and `R<digits>-F<digits>`. An implementation could fail to strip `[F<digits>]` from `@test "..."` descriptions and still satisfy the listed tests.

