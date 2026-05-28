---
finding_id: R1-F07
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L462-L468]
artifact: plan
round: 1
reviewer: silent-failure-claude
---

T13's shared BATS helper `tests/helpers/skill-markdown.bash` specifies that `extract_section` "returns 1 with a loud stderr diagnostic when the file is unreadable, the heading anchor is not found, or the extract is empty (silent-pass guard)." The `require_repo_root` function "returns 1 with a loud diagnostic if neither resolution succeeds."

However, T13's test expectations for the helper do not specify the BATS-level behavior when these functions return 1. In BATS, a helper returning 1 inside a `@test` block without `run` will cause the test to fail — which is the correct behavior. But the `assert_section_contains` wrapper "emits a BATS-style `file:section:regex` failure diagnostic on miss" and is presumably used with `run` semantics. The question is whether calling `extract_section` directly (not via `assert_section_contains`) inside a `@test` block with `run` will cause the test to fail-loudly or to silently pass when the heading is missing.

The critical gap is in the `extract_and_grep` function: "chains extract plus grep with the same loud-failure semantics." If a test calls `run extract_and_grep <file> <heading> <regex>` and the heading is not found, BATS records `run`'s exit code but does NOT fail the test — the test only fails if the test author subsequently asserts `[ "$status" -eq 0 ]`. If downstream consumer tests call `extract_and_grep` via `run` without checking the status (a natural BATS anti-pattern), they get a silent pass when the heading anchor is missing.

T13's helper-self test expectations mention the loud diagnostic requirement but do not specify whether consumer tests are expected to use `run` semantics or direct-call semantics. Nine downstream consumers in Slices 2, 4, 5, and 10 will adopt these patterns. If the recommended usage pattern is not specified, implementers may choose `run` semantics which silently passes on empty-extract.

The fix is to add a test expectation or description note that specifies the expected calling convention: "Consumer tests MUST call `extract_section`, `extract_and_grep`, and `require_repo_root` WITHOUT wrapping in `run`, so that a non-zero return directly fails the `@test` block. The `assert_section_contains` wrapper is the only function designed for `run` semantics." Alternatively, the helper should be designed so that calling it through `run` is still verifiable — but then the convention needs to be specified.
