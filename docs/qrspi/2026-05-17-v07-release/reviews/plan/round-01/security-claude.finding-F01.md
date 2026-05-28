---
finding_id: R1-F01
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L197-L206
  - docs/qrspi/2026-05-17-v07-release/design.md:L108-L134
artifact: plan
round: 1
reviewer: security-claude
---

Task 03 (Universal third-party-LLM dispatcher) specifies that when the configured provider's `api_key_env` environment variable is missing or empty, the script should exit 1 with a validation failure. Design confirms this: "a missing or empty environment variable named in `providers:` causes a validation failure (exit 1) at call time, not a silent attempt with an empty Authorization header." The task test expectations do pin the exit-code matrix (0, 1, 10, 11, 13, 14, 15) and pin "API-key resolution from the configured environment variable." However, the test expectations text for T03 does not include an explicit test case that asserts the specific fail-closed behavior when the environment variable is unset or empty. The relevant expectation reads only "When `--provider` does not match any entry in `<artifact-dir>/config.md`, the script exits 1 with a named provider-resolution diagnostic" — it names the provider-absent case but not the key-absent or key-empty cases.

The test expectations for T07 (`test-run-third-party-llm.bats`) say the test "covers stdin-only enforcement, every numbered exit code (0, 1, 10, 11, 13, 14, 15), config resolution from `<artifact-dir>/config.md`, both transport-type branches, environment-variable key resolution, and the `supports_prompt_cache:` capability gate's effect on `cache_control` emission." The phrase "environment-variable key resolution" is present but does not explicitly require a test case for the empty-variable or missing-variable scenario producing exit 1. An implementer reading this might write a test that covers the happy-path resolution (variable is set and non-empty) without also pinning the fail-closed behavior for the empty or missing case.

The risk is that if the environment variable is present but empty (e.g., `export DEEPSEEK_API_KEY=""`), the dispatcher may silently issue an HTTP request with an empty Authorization header — the exact anti-pattern Design explicitly rejected. "Not a silent attempt with an empty Authorization header" is Design prose but does not appear as a required test assertion in either T03 or T07's test expectations.

Resolution: T03's test expectations should add: "When `api_key_env` names an environment variable that is unset or empty at call time, the dispatcher exits 1 with a named key-resolution diagnostic before issuing any HTTP request." T07's `test-run-third-party-llm.bats` expectations should name both the unset-variable case and the empty-string-variable case as explicit test assertions that each produce exit 1 with a stderr diagnostic and no outbound network call.
