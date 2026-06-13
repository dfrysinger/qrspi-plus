---
finding_id: R5-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L687-L698
artifact: plan
round: 5
reviewer: test-coverage-claude
---

T03 (`review-prep.sh`) Test Expectations — missing round-1 / absent-anchor-file behavior.

The test expectations for T03 explicitly scope the anchor-file diff-narrowing test to "round ≥ 2": "Diff narrowing in round ≥ 2 reads `reviews/<step>/round-<NN-1>-commit.txt` for the narrowing ref." For round 1, `reviews/<step>/round-00-commit.txt` does not exist — this is the most common real-world scenario (every first review round of every artifact step), and the plan provides no test expectation covering it.

**What is unverifiable:** The test writer cannot write a deterministic test for round-1 invocations because the expected behavior is unspecified: does the script (a) halt non-zero with the `anchor-file-missing:` diagnostic (consistent with T26/T27's contract for step-12 anchor-file reads), (b) silently emit no diff and exit 0 (consistent with the "nothing to produce → exits 0" catch-all), or (c) fall back to a base-branch diff? The existing "When there is nothing to produce for a step … exits 0, no files" test expectation covers artifact-dir-not-in-git-tree and empty-git-diff, but a missing anchor file at round 1 is a structurally different condition — the artifact IS in a git tree, the diff IS non-empty, but the anchor file to scope the diff simply hasn't been written yet.

**Fix:** Add one test expectation bullet that specifies the round-1 behavior. If the intended behavior is the same as T26/T27's `anchor-file-missing:` diagnostic and non-zero exit, say so explicitly; if round 1 is expected to fall through to the "nothing to produce → exits 0" path, say that instead and explain why missing-anchor-file is treated as no-input rather than a real error.

<!-- SKIP-RECORD: skipped_lightweight_tasks: T05 (lightweight), T07 (lightweight), T09 (lightweight), T13a (lightweight), T13b (lightweight), T15 (lightweight), T16 (lightweight), T20a (lightweight), T20b (lightweight), T21 (lightweight), T22 (lightweight), T23 (lightweight), T26 (lightweight), T30 (lightweight), T31 (lightweight), T32 (lightweight), T33 (lightweight), T34 (lightweight), T35 (lightweight), T36 (lightweight) -->
