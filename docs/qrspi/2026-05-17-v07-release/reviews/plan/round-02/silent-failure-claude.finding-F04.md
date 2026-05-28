---
finding_id: R2-F04
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L997-L1008]
artifact: plan
round: 2
reviewer: silent-failure-claude
---

T33 specifies that when a dispatcher failure occurs during any of the three cache-probe dispatches, the script exits 1 with a loud diagnostic and does NOT write a partial report. This correctly blocks the partial-report path during the current invocation.

However, T33's test expectations do not address the stale-report scenario: if a prior successful run of `scripts/g4-cache-probe.sh` wrote a complete `g4-cache-probe.md` at the `--report-out` path, and the current invocation fails mid-dispatch and exits 1 without overwriting the file, the stale report from the prior run remains at the path. T36's `test-cache-hit-rate.bats` is documented to "read the T33 spike-report deliverable to determine the Path A vs Path B branch" — with no mechanism to verify that the report corresponds to the current run rather than a prior run.

In practice this means: a developer who runs `g4-cache-probe.sh` successfully (report written, Path A), then changes the environment or config and re-runs the probe (it fails on dispatch 2, exits 1, does not overwrite), then runs T36's test suite — T36 reads the stale Path A report, silently branches to Path A fixtures, and produces a green test run against stale data. The developer believes the test passed against the current probe output when it actually passed against prior-run data.

T36 does specify: "When the T33 spike-report deliverable is absent, malformed, or does not contain a recognizable Path A or Path B decision line, `test-cache-hit-rate.bats` fails with a loud diagnostic." But a stale-yet-complete-yet-valid report is none of these — it passes all three checks.

Resolution: Add a test expectation to T33 requiring that `scripts/g4-cache-probe.sh` writes an explicit run-ID or invocation-timestamp field into the spike report header. Add a complementary expectation to T36 requiring that `test-cache-hit-rate.bats` surfaces the spike report's timestamp so a human reviewer can verify freshness, or alternatively require T36 to check a lock/sentinel file that T33 atomically creates only after a complete successful run (and that T33 removes at invocation start so a failed mid-run leaves no lock file for T36 to find).
