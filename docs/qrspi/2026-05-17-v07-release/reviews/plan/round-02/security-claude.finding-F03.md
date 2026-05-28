---
finding_id: R2-F03
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L178-L182, docs/qrspi/2026-05-17-v07-release/plan.md:L207]
artifact: plan
round: 2
reviewer: security-claude
---

T02's test expectations verify `guard_marker_injection`'s own exit codes in isolation, but there is no test expectation that ties T02's exit-1 contract to T03's abort-on-nonzero contract in a shared fixture, leaving a gap where a misimplementation of the library could print a diagnostic but return 0, silently proceeding past the injection guard.

T02's relevant test expectation reads: "`guard_marker_injection` exits 0 on a file containing no untrusted-data sentinel markers and exits 1 with a named-marker stderr diagnostic when a collision is present."

T03's relevant test expectation reads: "When any component of the assembled prompt payload sources from a file whose body contains an untrusted-data sentinel token and `guard_marker_injection` therefore returns non-zero, the dispatcher exits 1 with a prompt-injection diagnostic on stderr and issues no outbound network call."

The gap: T02 tests the library's exit code using an isolated invocation (sourcing the library and calling `guard_marker_injection` directly in a BATS test). T03 tests the dispatcher's abort behavior. But no test spec requires a shared fixture that (a) sources the library from a real dispatcher invocation and (b) confirms that a collision-containing payload causes the dispatcher to abort. If an implementer of T02 introduces an API variant where `guard_marker_injection` is called with `run` semantics (capturing exit code in `$?`) but a library bug causes it to always return 0 while printing the diagnostic, T02's isolated unit test would fail on the wrong assertion, but the T03 integration test may ALSO pass if T03 tests the dispatcher against a stub or mock for `guard_marker_injection`.

This is a fail-open risk: an assembled prompt payload containing a `<<<UNTRUSTED-ARTIFACT-START>>>` token injected by a malicious feedback file would be sent outbound to the LLM provider unchanged.

Required fix: Add to T07's test expectations for `test-run-third-party-llm.bats`: the prompt-injection abort path test MUST exercise `guard_marker_injection` through the actual sourced library (not a stub), with a fixture file containing a real `<<<UNTRUSTED-ARTIFACT-START id=x>>>` sentinel token, confirming the end-to-end abort path from library through dispatcher exit 1 with no outbound call. The existing T03 description language "every invocation of `guard_marker_injection` checks the return code" should be echoed in T07 as a falsifiable contract: "the prompt-injection abort pin uses the real `llm-prompt-utils.sh` library sourced by the dispatcher (not a mock), so the pin breaks if the library's return-code contract changes."
