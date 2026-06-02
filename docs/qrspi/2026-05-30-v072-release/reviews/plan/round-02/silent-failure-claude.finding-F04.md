---
finding_id: F04
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
artifact: docs/qrspi/2026-05-30-v072-release/plan.md
---

# Task 32 incremental in-place rewrites of `design.md` / `goals.md` lack atomicity spec — partial-state risk on mid-write interruption

## Where

Task 32 (G30 Goals and Design dialogue authoring quality and compaction-resilient incremental persistence), Scope `**In:**`:

> Update `skills/design/SKILL.md` so each per-decision lock writes directly to `design.md` with `status: draft`, using the Task 30 five-field per-goal template and a dedicated `## Cross-Goal Decisions` section for cross-goal locks.

> Update `skills/goals/SKILL.md` so each locked goal writes directly to `goals.md` with `status: draft`, while preserving the existing per-goal template, Interactive Dialogue question-topic checklist, and Pipeline Mode Selection step.

> Document presence-as-locked semantics in both skills: tentative, placeholder, `to be filled`, TODO, or similar incomplete decision bodies never enter draft artifacts; **re-locking an existing decision overwrites that keyed block in place** instead of appending a duplicate.

Definition of done and Test expectations both pin the *content* of incremental writes ("presence-as-locked," "keyed in-place overwrite," "Resumed after compaction…" diagnostic), but **neither requires the write to be atomic** (write-to-temp + rename) or specifies what happens when the write is interrupted mid-rewrite.

The only durability assertion is:

> Simulated-compaction coverage uses a mid-phase decision such as G15 and verifies resume produces the same final artifact content as a no-compaction run.

…where "compaction" means the LLM-context-window compaction the skill is designed to survive — i.e., the assistant process restarts cleanly between turns, with `design.md` on disk in a complete state. This test does not cover the case where the assistant is interrupted (host kill, network drop on a hosted CLI, terminal SIGINT, OS-level OOM) *during* the in-place rewrite of `design.md`.

## Why this matters

This is the PARTIAL_STATE_ON_FAILURE pattern: a multi-step write operation (read existing artifact → splice in updated keyed block → write back the whole file) with no atomicity spec. If the assistant is interrupted between the truncate-and-open-for-write and the final flush:

- `design.md` on disk is partially rewritten — possibly missing the trailing locked decisions, possibly containing a partial keyed block.
- Resume-after-compaction reads the partial artifact and enumerates "locked decisions" from a corrupt snapshot.
- The "M decisions locked, K remaining" diagnostic prints wrong counts.
- The skill silently continues from `G(NN+1)` based on the corrupt snapshot, potentially overwriting valid locked decisions or skipping ones that were already locked.

Worse: the user's verification surface for this is "does the final `design.md` look right?" — which is exactly what a partial write makes hard to spot, because the file *looks* well-formed up to the truncation point.

The contrast with Task 11 (G29) is instructive — Task 11 explicitly requires:

> Make manifest writes atomic and append-safe for repeated invocations and multiple reviewer tags in the same round.

…for the dispatch manifest. The dispatch manifest is *machine-readable bookkeeping*; `design.md` and `goals.md` are *the load-bearing draft artifacts of the whole pipeline.* If anything in the v0.7.2 release deserves atomic-write semantics, the incremental-persistence target files do.

## What the plan should require instead

Add to Task 32's Scope `**In:**` and Definition of done:

- "Each incremental write to `design.md` / `goals.md` is atomic on the operator's filesystem: the skill writes the updated artifact body to a sibling tempfile in the same directory, fsyncs (when the host shell supports it), then `mv`s the tempfile over the target. A failed/interrupted write leaves the prior on-disk artifact intact."
- "Resume-after-compaction begins by validating that the on-disk `design.md` / `goals.md` parses cleanly under the Task-30 / existing per-goal template; if validation fails, the skill emits a loud diagnostic and refuses to enumerate locked decisions from a corrupted snapshot rather than silently continuing from a partial read."

Add to Test expectations:

- "Simulate a mid-write interruption (kill the rewrite step before completion); verify the on-disk artifact is byte-identical to the pre-rewrite state and the resume diagnostic correctly reports the pre-rewrite locked-decision count."
- "Simulate a corrupted on-disk `design.md` (truncated mid-block, malformed frontmatter); verify resume exits with a loud diagnostic rather than silently re-locking decisions."
