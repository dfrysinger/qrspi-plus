---
finding_id: R9-F01
severity: medium
change_type: clarity
referenced_files: ["plan.md:L1395-L1396"]
artifact: plan
round: 9
reviewer: test-coverage-codex
---
T37's first test expectation "resolves `!cat` references transitively against a fixture skill body with nested `!cat` references (cycle detection coverage)" lacks an observable expected output (exact resolved content, ordered path set, or deterministic token count). Fix: name a deterministic observable for the happy-path transitive-resolution test.

