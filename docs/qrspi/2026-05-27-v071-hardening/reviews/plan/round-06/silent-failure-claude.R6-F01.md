---
finding_id: R6-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 6
reviewer: silent-failure-claude
---

SILENT_FALLBACK: Task 7 mock-sentinel weakened; dispatch-emit-marker-then-return passes "provides evidence"

Transport markers ([transport: task-tool], [transport: shell-pipeline]) are written to stderr by the dispatch surface itself, BEFORE invoking transport. A dispatcher that emits the stderr marker and then returns without calling the mock passes all R5 assertions: marker on stderr, exit 0, "stdout provides evidence" satisfied by any interpretation.

Old wording mandated POSITIVE signal from mock in stdout. New "provides evidence" is implementation-deferred and auditor-unenforceable.

Fix: name the sentinel requirement explicitly (mock emits a distinguishable string, test asserts it appears in stdout) without specifying the literal value:

"captured stdout contains the mock's distinguishable sentinel string (a value the mock emits and no other code path produces), asserting the dispatch invoked the mock transport rather than silently bypassing it"

DISPOSITION: Same finding as testcov-claude R6-F01, testcov-codex R6-F01, spec-codex R6-F01. Four reviewers converging on this signal. Apply explicit-sentinel wording in fix synthesis. The R5 fix to scope-claude R5-F02 went too far.
