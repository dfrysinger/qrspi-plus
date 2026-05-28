---
finding_id: R2-F07
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L563-L568]
artifact: plan
round: 2
reviewer: silent-failure-claude
---

T16 specifies that Integrate "queries the workflow run status for the head commit of the integrate branch" and "requires success of all jobs in that workflow run as the gate condition." Neither the T16 description nor its test expectations address the case where no CI workflow run exists for the head commit at all — that is, when CI has not yet been triggered on this commit.

When `gh run list` returns an empty result set (zero workflow runs found for the head commit), the gate condition "all jobs in that workflow run succeeded" is vacuously true (the empty set has no failing jobs). An Integrate session running against a head commit whose CI hasn't been triggered — for example immediately after a force-push that reset the branch tip — would pass the CI gate and proceed to integration without any CI having run. This is a silent fallback: "no CI run found" is misclassified as "all CI passed."

The T16 test expectations only assert: the section names the workflow file, states the `gh` CLI query method, and requires success of ALL jobs (not a subset). None of the four test expectations cover the "no workflow run found" outcome.

Resolution: Add a test expectation to T16 stating that when the `gh` CLI query for the head commit returns zero workflow runs for `.github/workflows/ci.yml`, the CI gate FAILS with a named diagnostic identifying the missing run (e.g., "No CI workflow run found for commit SHA <sha>; CI may not have triggered yet") and does NOT pass the gate. This closes the vacuous-success path and forces the user (or orchestrator) to wait until CI has actually run before proceeding with integration.
