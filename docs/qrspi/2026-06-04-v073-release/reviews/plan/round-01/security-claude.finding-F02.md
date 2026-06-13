---
finding_id: F02
reviewer: security-claude
reviewer_tag: security-claude
artifact: plan.md
round: 1
severity: medium
change_type: defect
category: input-validation
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md
tasks_affected: [T04, T19, T21, T22]
---

# F02 — `<agent>` value not constrained before injection into GIT_AUTHOR_NAME; OBC author-marker filter is fail-open against newlines

## Summary

T04 specifies that every dispatched subagent git command is env-wrapped with
`GIT_AUTHOR_NAME=qrspi-<agent>` and `GIT_AUTHOR_EMAIL=bot@qrspi.local`, and the
T19 OBC script post-filters `git log <phase-base>..HEAD --format='%H %an'` through
`awk '$2 !~ /^qrspi-/ {print $1}'` to detect non-subagent commits. The plan does
not constrain the `<agent>` interpolation to a safe charset, and the OBC filter
silently fails open against any author-name value that contains a newline,
multiple whitespace characters, or other awk-record-breaking bytes.

## Two coupled gaps

### (a) `<agent>` interpolation has no charset constraint at T04

T04's description reads: "every dispatched subagent git command is executed with
`GIT_AUTHOR_NAME=qrspi-<agent>`". The placeholder `<agent>` comes from the
dispatch agent's identifier (likely the `subagent_type` field). T04's test
expectations validate the marker round-trips through `git log --format='%an'`
but do NOT specify that `<agent>` is validated against an allowlist (e.g.
`^[a-z0-9-]+$`) before env-wrap.

Failure modes the plan does not close:

- `<agent>` carrying a newline embeds a newline into `GIT_AUTHOR_NAME`. Git
  accepts this and the resulting commit's author header spans two lines; the
  T19 awk filter (which operates per-record on `%an` output) sees the part
  after the newline as a separate record whose `$2` does not begin with
  `qrspi-`, and the filter classifies the commit as a non-subagent commit —
  triggering an auto-revert in T20's autopilot path against a legitimate
  subagent commit.
- `<agent>` carrying `<`, `>`, or null bytes corrupts git's author parsing
  (git uses `<email>` delimiters in author headers).
- `<agent>` carrying shell metacharacters has no effect inside the
  `KEY=VALUE` env-wrap shape (env values are not re-parsed), but does
  pollute logs and the OBC report output.

### (b) OBC awk filter is unsafe even with valid agent names

`git log --format='%H %an'` separates the SHA and author name with a single
space, and the author name itself may legitimately contain spaces (`Dave
Frysinger`) or other multi-token shapes. The plan's filter
`awk '$2 !~ /^qrspi-/ {print $1}'` reads `$2` (the second whitespace-separated
field) — which for an author name `Dave Frysinger` is `Dave`, not the full
name. The filter happens to work for the `qrspi-<agent>` marker convention
because that marker is one token and lives in `$2`; but the filter
fundamentally cannot distinguish "second field of multi-word author name"
from "single-token author name", and any subagent whose `<agent>` interpolation
embeds whitespace would be classified as a non-subagent commit by `$2`
inspection.

A safer filter shape uses `%aN` (or `%an`) with a delimiter that cannot appear
in author names, or uses `--author='^qrspi-'` (regex match form). The plan
does NOT specify which shape is required; an implementer following the
T19/T21/T22 prose literally builds the unsafe `$2`-based filter, and a
defensive author name (or a malicious one) defeats the OBC's safety property.

## Plan-spec gap

### T04 test expectations

Add to T04:

- A fixture dispatch with `<agent>` containing a newline character is rejected
  with a named diagnostic (`agent-name-malformed:` or equivalent), NOT wrapped
  into `GIT_AUTHOR_NAME`.
- A fixture dispatch with `<agent>` containing whitespace, `<`, `>`, `$`, or
  backtick is rejected.
- An allowlist regex (e.g., `^[a-z0-9-]+$`) is named in the T04 description as
  the validation rule.

### T19 (and consequently T21 / T22 SKILL prose carrying the same incantation)

Add to T19's description an explicit decision: either

- (a) replace the awk filter with `git log --author='^qrspi-' --invert-grep
  <phase-base>..HEAD --format='%H'` (git-native negation via `--invert-grep`,
  which composes with `--author`'s regex form), OR
- (b) keep the awk shape but specify the delimiter explicitly — e.g.,
  `git log --format='%H%x09%an' | awk -F'\t' '$2 !~ /^qrspi-/ {print $1}'`
  (tab separator, which is rejected by the T04 allowlist for `<agent>` so it
  can never appear inside a marker value).

The plan currently specifies the unsafe `$2`-based shape verbatim in T19, T21,
T22 (and locks it via T24's lint), so any fix must update all four task specs
in lockstep.

Add a T19 test expectation: a fixture commit whose author name contains a
literal space passed through the OBC filter is classified correctly (subagent
vs non-subagent) regardless of whether the author is the first or second token
on the row.

## Why this matters

T20's autopilot batch-gate auto-dispatches `revert-orchestration-drift` on
non-subagent commits (cap 1 per phase). A false-positive from the awk filter
auto-reverts a *legitimate* subagent commit; a false-negative misses a real
main-chat orchestration drift. Both directions silently corrupt the safety
property the OBC was added to enforce.

The `<agent>` charset is also a write-path defense: if `<agent>` is ever
derived from any value that crosses a trust boundary (a dispatch parameter
file, a future remote-dispatch protocol, an env var), no charset constraint
means the env-wrap shape is the attack surface itself.

## Severity

Medium. Internal-only inputs today, but the plan locks the unsafe shape into
SKILL prose via T24's lint, making it harder to fix later. Closing the
charset constraint at T04 and the filter shape at T19/T21/T22 is one round of
edits now; reopening the locked-down prose after release is multiple rounds.
