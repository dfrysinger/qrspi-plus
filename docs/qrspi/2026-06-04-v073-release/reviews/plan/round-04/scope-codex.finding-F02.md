---
finding_id: R4-F02
severity: high
change_type: scope
referenced_files: [/Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-06-04-v073-release/plan.md]
artifact: plan
round: 4
reviewer: scope-codex
---

Test Expectations repeatedly include assertion/code-like content (literal grep commands, exact CLI snippets, and concrete matcher-style checks) instead of plain-language behavior expectations. `skills/plan/owns-defers.md` explicitly keeps plan test expectations in plain language and defers assertion/code text to Implement-TDD. Rewrite these expectations as behavioral statements (inputs/outputs, failure direction, edge cases) and defer concrete command/assertion text to test implementation artifacts.
