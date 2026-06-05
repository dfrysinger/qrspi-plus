---
finding: F01
reviewer: spec-claude
severity: fail
category: completeness
task: 12
round: 1
---

# F01 — Four of six target files not modified: anchor manifest and per-skill anchor JSON files untouched

## What the spec requires

`task-12.md` **Target files** lists six files. Two are new creates (both scripts). Four are **modify**:

```
scripts/g4-section-anchor-manifest.json  (modify)
skills/using-qrspi/SKILL.anchors.json    (modify)
skills/reviewer-protocol/SKILL.anchors.json (modify)
skills/plan/SKILL.anchors.json           (modify)
```

**Scope** (in-scope):
> Update `scripts/g4-section-anchor-manifest.json` and the three per-skill anchor JSON files so refreshed windows cover the dispatch, round-preparation, reviewer-protocol, and plan-classification sections changed by this release.

**Definition of done** bullet 9:
> The anchor manifest and per-skill anchor JSON files remain valid JSON and contain refreshed windows for the dispatch, round-preparation, reviewer-protocol, and plan-classification sections changed by this release.

**Test expectation** bullet 10:
> Grep or diff the refreshed anchor JSON windows to confirm they cover the dispatch, round-preparation, reviewer-protocol, and plan-classification sections changed by this release.

## What the implementation does

The diff (`round-01.diff`) contains exactly four entries — two new scripts and two new test files:

```
diff --git a/scripts/await-round.sh b/scripts/await-round.sh   (new)
diff --git a/scripts/round-prepare.sh b/scripts/round-prepare.sh (new)
diff --git a/tests/unit/test-await-round.bats b/...             (new)
diff --git a/tests/unit/test-round-prepare.bats b/...           (new)
```

None of the four anchor/manifest JSON files appear anywhere in the diff. Inspecting the files directly confirms they preexist from the base branch and are byte-for-byte identical to what was there before this task.

- `scripts/g4-section-anchor-manifest.json` — unchanged (3-entry list, lines 4–17)
- `skills/using-qrspi/SKILL.anchors.json` — unchanged
- `skills/reviewer-protocol/SKILL.anchors.json` — unchanged
- `skills/plan/SKILL.anchors.json` — unchanged

## Impact

The "refreshed windows" required by DoD bullet 9 have not been produced. The anchor files reflect pre-release line numbers, not the sections changed by this release. Downstream narrow-read lookups by T13 and T20 consumers will read stale window boundaries.

Test expectation bullet 10 cannot be satisfied by any test because the content was never refreshed — no grep or diff of the windows could confirm coverage of the sections changed by this release.

## Required fix

Refresh all four files so their section windows cover the dispatch, round-preparation, reviewer-protocol, and plan-classification sections as they exist **after** this release's edits. The existing `scripts/g4-section-anchor-refresh.sh` tool exists in the worktree and should be run against the current state of each SKILL.md, with the results committed.
