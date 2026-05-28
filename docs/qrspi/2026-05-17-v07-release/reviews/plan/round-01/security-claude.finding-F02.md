---
finding_id: R1-F02
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L172-L181
  - docs/qrspi/2026-05-17-v07-release/design.md:L107-L108
artifact: plan
round: 1
reviewer: security-claude
---

Task 02 introduces `guard_marker_injection <file>` in `scripts/lib/llm-prompt-utils.sh`. The function is designed to detect collisions between file content and the untrusted-data sentinel markers (`<<<UNTRUSTED-ARTIFACT-START id=...>>>` / `<<<UNTRUSTED-ARTIFACT-END id=...>>>`). The function "exits 0 when no untrusted-data marker collision is present in the file and exits 1 with a stderr diagnostic naming the offending marker when a collision is detected."

This is a fail-closed function for preventing prompt injection: if an input file contains the sentinel marker strings, the function must signal failure before the file's content is embedded in a dispatch prompt. The test expectations for T02 do pin the happy-path and the collision case: "`guard_marker_injection` exits 0 on a file containing no untrusted-data sentinel markers and exits 1 with a named-marker stderr diagnostic when a collision is present."

However, the plan does not specify what the CALLER of `guard_marker_injection` must do when the function exits 1. The test expectations for T02 cover only the function's own exit-code behavior — they do not require the dispatcher (T03) or the caller in any dispatch site to propagate the failure. If a caller sources `llm-prompt-utils.sh` and invokes `guard_marker_injection` without checking its exit code, the function exits 1 but the caller continues anyway, embedding the colliding file content into the dispatch prompt. The shell convention for ignored return codes (a `guard_marker_injection somefile` call without `|| exit 1` or `set -e`) means the protection silently does nothing.

Neither T03's test expectations nor T07's test expectations include a test case asserting that the dispatcher aborts when `guard_marker_injection` returns 1. The test expectations for T03 only test for the named argument/flag validation failures and transport-type branching. There is no test case of the form: "When the assembled prompt payload contains content whose source file contains a sentinel marker, the dispatcher exits 1 with a prompt-injection diagnostic and does not issue any network call."

The risk is a prompt-injection vector: adversarially crafted content in a file that the dispatcher is asked to embed in a prompt (e.g., a `config.md` or an agent body that a malicious contributor placed a sentinel string into) passes `guard_marker_injection` silently if the caller does not check the return code, allowing a real `UNTRUSTED-ARTIFACT-START` token to appear inside the trusted prompt region and confuse downstream reviewer agents about instruction boundaries.

Resolution: T03's test expectations should add: "When `guard_marker_injection` returns non-zero for any component of the prompt payload, the dispatcher exits 1 with a prompt-injection diagnostic and does not issue any network call." T07's `test-run-third-party-llm.bats` expectations should name this as an explicit test case. The task description for T03 should also state that every invocation of `guard_marker_injection` in the dispatcher propagates non-zero exit to the dispatcher's own exit-code.
