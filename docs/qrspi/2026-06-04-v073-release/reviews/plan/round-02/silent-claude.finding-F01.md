---
finding_id: R2-F01
severity: high
change_type: behavior
referenced_files: [docs/qrspi/2026-06-04-v073-release/plan.md:L208, docs/qrspi/2026-06-04-v073-release/plan.md:L217, docs/qrspi/2026-06-04-v073-release/plan.md:L230]
artifact: plan
round: 2
reviewer: silent-claude
---

T03 (`scripts/review-prep.sh`) specifies a designed silent fallback for "nothing to produce" inputs that hides a class of dispatch defects from the consumer.

Plan text — T03 description (L208): "The script emits no files for a step with nothing to produce and exits 0; on corrupt artifact-dir it halts non-zero with a named diagnostic." T03 test expectations (L217): "A step with nothing to produce (e.g., artifact not in a git repo) emits no files and exits 0 (CD-2 § Dependencies + edge cases — silent-on-no-input shape)."

T04a description (L230) says "review-prep failure propagates verbatim — dispatch-agent exits non-zero with review-prep's stderr." But because review-prep exits **0** in the silent-on-no-input branch, dispatch-agent never sees a failure signal. dispatch-agent then threads `diff_file_path: <artifact-dir>/reviews/<step>/round-NN.diff` into the reviewer prompt per T04a's own contract — pointing at a file that was never written. The downstream reviewer cannot distinguish three semantically distinct conditions from the same observed state (`diff_file_path` points at a missing file):

1. Artifact-dir genuinely not in a git repo (T03's intended fixture/edge case).
2. review-prep was never invoked (orchestrator bug, dispatch-agent regression, or operator dispatched the low-level mode by mistake).
3. review-prep was invoked but a transient git failure silently produced no diff (e.g., a `git diff` exit code 0 with no output because the anchor SHA resolved but the working tree was checked out at the anchor — a non-error condition that should still surface to the reviewer).

This is the classic SILENT_FALLBACK pattern from category 2: returning empty-equivalent output (zero files, exit 0) on a condition the caller needs to distinguish from genuine "nothing to review." The "silent-on-no-input shape" label in the test expectation acknowledges the pattern explicitly.

The downstream consequence is concrete and load-bearing for v0.7.3's own correctness: T17's plan-spec-reviewer-absorption fixture and T17's design-reviewer-fidelity fixture both depend on the reviewer receiving a diff to review against. If review-prep silently no-ops in a real review round (because the orchestrator pointed it at the wrong artifact-dir, because a git operation failed in a way that produced an exit-0 empty result, because a fresh artifact-dir hasn't yet been initialised as a git subtree), the reviewer dispatch proceeds with a missing diff file. Per the diff-file Read pattern documented in every reviewer body, the reviewer Reads the diff path and either (a) errors on missing file and the orchestrator surfaces an opaque file-not-found, or (b) the reviewer falls back to the wrapped `artifact_body` (the documented fallback in the reviewer-protocol skill for "no diff_file_path"), silently widening review scope and **not** producing the dispatch-defect signal the operator needs to detect that the orchestration is broken.

The contradiction with the plan's own fail-loud philosophy is sharp. T19 (OBC) explicitly partitions dispatch defects into a distinct `## Dispatch defects` section with named diagnostics. T16 explicitly makes absent `absorption_map_path:` at the Design step a `dispatch-defect:` non-zero halt. T01 makes unknown `--step` a non-zero `upstream-paths-unknown-step:` diagnostic. T28 makes missing/empty/multi-line VERSION a non-zero `version-source-missing-or-malformed:` diagnostic. T27 makes a missing anchor file a non-zero halt. T03 stands alone in carrying a designed silent-zero-exit branch on a not-in-git-repo condition that production review rounds should never legitimately encounter.

The fix is to differentiate the two callers: production-review review-prep invocations (dispatched by dispatch-agent for a real review round) MUST halt non-zero with a named diagnostic if the artifact-dir is not in a git repo or if `git diff` produces no output when a diff was expected; test/fixture review-prep invocations that legitimately want the silent-zero behaviour MUST pass an explicit `--allow-empty-no-diff` (or equivalently named) opt-in flag. Without that opt-in, the default must be fail-loud. The T03 description must name the named diagnostic for the "artifact not in git repo without opt-in" condition, and the T03 test expectations must add a case asserting non-zero exit with the named diagnostic on the production-default branch. T04a's "review-prep failure propagates verbatim" contract then carries meaning — currently it carries no meaning for the silent-on-no-input branch because review-prep never signals failure on that branch.

Resolution scope: T03 description, T03 test expectations (replace the "emits no files and exits 0" expectation with a fail-loud default plus an opt-in flag for the legitimate non-git fixture case), and a corresponding T04a test expectation that the production-default review-prep invocation halts on a not-in-git artifact-dir.
