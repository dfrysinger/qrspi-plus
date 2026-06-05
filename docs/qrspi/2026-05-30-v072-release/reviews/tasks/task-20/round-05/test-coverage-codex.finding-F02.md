---
reviewer: test-coverage-codex
round: 5
finding_id: R5-F02
severity: medium
change_type: correctness
referenced_files: [tests/unit/test-dispatch-sites.bats, scripts/await-round.sh]
---

# F02 — Companion `await` payload silence only asserted for stdout, not stderr

task-20.md L43, L55 require await payload to be silent on BOTH stdout AND stderr. tests/unit/test-dispatch-sites.bats:403-430 asserts payload not in stdout but does not capture/assert stderr is payload-free. Raw reviewer text leaking via stderr would bypass current tests.
