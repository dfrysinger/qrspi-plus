---
finding_id: R2-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L394-L401]
artifact: plan
round: 2
reviewer: test-coverage-claude
---

T10 adapter test expectations are missing the edge case for an unrecognized output format on each individual adapter. The current test expectations for T10 only cover the positive classification paths (assertion-failure, infrastructure-failure, pass) for each framework and the generic "unrecognized runner output causes each adapter to exit 1 with a diagnostic" case. However, they do not specify what constitutes "unrecognized" output for each adapter individually. The T09 contract document pins `0` on classification and `1` with loud stderr on unrecognized output, but T10's test expectations do not include at least one concrete unrecognized-output fixture per adapter.

Specifically: for `bats-adapter.sh`, what constitutes "unrecognized" output is not tested (e.g., a runner that produces neither `ok` nor `not ok` nor a parse-error marker); for `vitest-adapter.sh`, there is no test that a Vitest output not matching any of the enumerated patterns exits `1`; similarly for `jest-adapter.sh` and `pytest-adapter.sh`. The design's per-framework adapter test at design.md § G6 requires each adapter to return one of three tokens — but only the T09 contract establishes what the adapter does when it cannot classify. The T10 test expectations state "Unrecognized runner output causes each adapter to exit 1 with a diagnostic written to stderr (no silent default classification)" but do not specify a concrete example of "unrecognized" runner output per framework.

This is partially weak rather than entirely missing: the test expectation IS present but is phrased generically across all four adapters rather than as a per-framework example with a concretely-named trigger. An implementer could satisfy this by testing a single adapter against a generic empty-output fixture and declare all four covered. To be falsifiable, add at least one named unrecognized-output scenario per adapter (e.g., for BATS: an output containing only a TAP version header with no test lines; for Vitest: an output containing only ANSI escape codes with no classification markers; for Jest: an output whose exit code is non-zero but stdout contains no `FAIL` or `PASS` line; for pytest: a runner whose output begins with "INTERNALERROR" and whose exit code is neither 1 nor 5).
