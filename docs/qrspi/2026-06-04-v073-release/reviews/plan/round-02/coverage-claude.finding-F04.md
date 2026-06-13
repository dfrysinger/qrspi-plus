---
reviewer: coverage-claude
finding_id: F04
artifact: plan.md
round: 2
severity: minor
change_type: behavioral
category: Missing Scenarios from Design
task_refs: [T04a, T03]
---

## Finding

design.md CD-2 § Dependencies + edge cases explicitly governs the
"review-prep produces no files" case:

> Edge case — `review-prep.sh` invocation when there is nothing to
> produce (e.g. an artifact-step that has no diff because the artifact
> is not in a git repo): the script emits no files for that step and
> exits 0. dispatch-agent omits the corresponding `*_path:` parameter
> from the dispatch prompt.

The plan covers the script side (T03 has a bullet: "A step with
nothing to produce (e.g., artifact not in a git repo) emits no files
and exits 0"). But T04a — the dispatch-agent half of the contract —
has no Test expectation for the dispatch-prompt-omission side.

T04a's existing coverage only asserts the positive case (paths threaded
when present) and the parameter-applicability matrix (Design has both,
Goals has only `diff_file_path:`). The third row of the matrix —
"review-prep emitted zero files for this step, so the prompt omits
BOTH parameters" — is not asserted.

This matters because the failure mode is silent: a regression where
dispatch-agent threaded an empty `diff_file_path:` value (or threaded
a stale path from a previous round) would not be caught by any
existing T04a bullet. The reviewer would receive a malformed prompt
parameter and either ground its review on stale content or surface a
content-free finding — both observable consequences design.md's
edge-case clause was written to prevent.

## Test that cannot be written deterministically

"For a fixture artifact-dir that is not under a git repo (or has no
diff to produce for the given step), dispatch-agent's high-level mode
emits a prompt that contains zero `diff_file_path:` and zero
`absorption_map_path:` parameter lines" — not covered by any current
T04a bullet.

## Recommended fix

Add a Test-expectation bullet to T04a covering the dispatch-agent
half of design.md CD-2's no-input edge case. Suggested:

> When `review-prep.sh` emits no files for the requested step (e.g.,
> a fixture artifact-dir not under a git repo, or a step with no
> applicable inputs), dispatch-agent's high-level mode produces a
> prompt with zero `diff_file_path:` and zero `absorption_map_path:`
> parameter lines — the corresponding `*_path:` parameters are
> omitted, not threaded with empty or stale values (design.md CD-2
> § Dependencies + edge cases — silent-on-no-input edge).
