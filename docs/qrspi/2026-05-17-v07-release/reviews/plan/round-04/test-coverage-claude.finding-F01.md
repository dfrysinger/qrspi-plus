---
finding_id: R4-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L1106-L1117]
artifact: plan
round: 4
reviewer: test-coverage-claude
---

T36 `test-cache-control-capability-gate.bats` test expectations specify the four-cell dual-flag truth table at lines 1106–1117, but do not declare the transport type of the fixture providers. The expectation reads: "Invokes the T03 universal dispatcher against fixture providers exercising all four cells..." without specifying whether the fixture providers use `openai-chat-completions` or `codex-broker` transport.

This matters because `cache_control` field emission in the assembled request body is specific to `openai-chat-completions` transport — for `codex-broker` transport, the dispatcher chains through `codex-companion-bg.sh` where the JSON assembly is internally handled. A fixture provider with `codex-broker` transport and both flags true might produce different behavior than the pin intends to assert, or might be a vacuous test (the dispatcher branches before ever assembling an openai-chat-completions body).

The test expectation at line 1117 states: "asserts the request body contains `cache_control` ONLY in cell (d)" — but "the request body" is undefined unless the transport type is specified. For `codex-broker` transport there is no chat-completions JSON request body assembled by the dispatcher itself.

Fix: Add to T36's `test-cache-control-capability-gate.bats` test expectations that all four truth-table fixture providers use `openai-chat-completions` transport (or explicitly state the pin exercises only the `openai-chat-completions` transport path, since that is the path where the dispatcher assembles the request body and can be observed in a fixture without a live network call).
