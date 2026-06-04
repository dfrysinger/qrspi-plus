---
finding_id: R2-F02
severity: high
change_type: test-coverage
referenced_files:
  - tests/unit/test-dispatch-sites.bats
  - scripts/dispatch-agent.sh
---
New positive tests don't exercise the actual batched call path — they cannot catch R2-F01.

`tests/unit/test-dispatch-sites.bats:354-359, 393-398` invoke `dispatch-companion.sh --vendor codex ...` (flag-based, no `launch` token). The real batched caller in `dispatch-agent.sh:705-710` invokes `dispatch-companion.sh launch --vendor ...` (with `launch` token). The two shapes are not equivalent — the latter is rejected by the companion's flag parser. The new tests therefore PASS while the production batched call path FAILS, and a regression in either side would not be caught.

Additionally, no test asserts that `dispatch-agent.sh --agents` produces a manifest entry with a real (non-empty) third-party `job_id` after a successful launch — the integration assertion that would surface R2-F01.

Violates the test-coverage portion of DoD (`tasks/task-20.md:54-55, 59`).

**Fix path:**
1. Add an end-to-end test in `test-dispatch-agent.bats` (or `test-dispatch-sites.bats`) that runs `dispatch-agent.sh --agents <list-with-third-party-reviewer>`, with the codex transport stubbed via `tests/fixtures/stub-codex-companion.mjs`, and asserts the resulting manifest contains a real non-empty `job_id` for the third-party tag.
2. Either keep the existing two F02 tests as-is and add the integration test above, OR rewrite the existing F02 tests to invoke `dispatch-companion.sh launch --vendor ...` matching the production call shape (whichever shape ends up canonical after R2-F01 is fixed).
