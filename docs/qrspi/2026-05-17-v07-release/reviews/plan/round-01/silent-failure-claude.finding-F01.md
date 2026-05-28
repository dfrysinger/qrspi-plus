---
finding_id: R1-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L974-L982]
artifact: plan
round: 1
reviewer: silent-failure-claude
---

T33's test expectations for `scripts/g4-cache-probe.sh` specify that "A dispatcher failure during any of the three dispatches causes the script to exit `1` with a loud diagnostic naming the failed dispatch and to NOT write a partial report." However, the description and the test expectations do not specify what happens when the script's dispatch of exactly three prompts partially succeeds — for example, dispatches 1 and 2 succeed but dispatch 3 fails. The test expectations name the "no partial report" outcome but do not assert what happens to the already-captured `cache_read_input_tokens` values from the earlier successful dispatches. More importantly, the test expectations do not specify an exit code when the `--report-out` write itself fails (the report file path is unreachable or the filesystem is read-only). A write failure after a successful three-dispatch run would produce exit 0 with no report, which is a silent failure: callers would receive exit 0 and attempt to consume a non-existent report file.

The test expectation "On success the script writes the report file at the `--report-out` path and exits `0`" is expressed as a positive-path assertion only. There is no corresponding test expectation that asserts "if the report file cannot be written, the script exits non-zero with a loud diagnostic." T36's `test-cache-hit-rate.bats` reads the spike-report deliverable from T33 to choose between Path A and Path B fixture sets — if that file is absent (because T33 silently failed to write it), T36 will either fail with an obscure parse error or silently pick a default path.

The fix is to add a test expectation in T33: "If the report file cannot be written to `--report-out`, the script exits `1` with a loud diagnostic naming the write-failure reason and does not exit `0`." This matches the existing "Invoking without `--report-out` exits non-zero" guard and closes the write-failure silent-failure path.
