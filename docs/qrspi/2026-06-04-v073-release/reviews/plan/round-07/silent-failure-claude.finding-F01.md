---
finding_id: R7-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md
artifact: plan
round: 7
reviewer: silent-failure-claude
---

T20b's autopilot branched-default leaves the implement-phase autopilot in an **undefined state** when the OBC report file is absent after the OBC script is invoked — an implementer may silently resolve that undefined state as "proceed," bypassing the boundary safety check.

## The gap

T20b defines five autopilot outcomes (description + test expectations):

| Outcome | Trigger | Action |
|---------|---------|--------|
| Pre-check | OBC script absent or non-executable | Write dispatch-defect entry, halt without invocation |
| Branch (a) | `## Dispatch defects` section non-empty | Halt unconditionally, write `HALT-orchestration-boundary-undeterminable.md` |
| Branch (b) | Non-subagent commits under `## Boundary violations` | Auto-escalate (revert-orchestration-drift), then re-run OBC |
| Branch (c) | Uncommitted workspace changes under `## Boundary violations` | Halt to `HALT-orchestration-boundary.md` |
| Proceed | "byte-empty file, OBC exit 0" | Advance to next phase |

None of these cover the case where OBC was **successfully invoked**, the invocation completes, but the report file at `reviews/implement/orchestration-boundary.md` is **absent or unreadable**. An absent file is not "byte-empty" (the proceed condition is unsatisfied), and the three content-based branches cannot evaluate sections of a non-existent file (no match). The autopilot receives "OBC invoked, report absent, no branch matched" with no spec-defined outcome.

## How this arises

T19's atomic-write contract proves the final report is either complete or absent (no truncated partial file). The atomic-write mechanism writes to a temp path and then renames into place. If the `mv`/rename step fails (disk-full after writing the temp file, permission denied on the target directory), the report is absent. T19's test expectation verifies the **file-state invariant** ("final report path either contains the complete report or does not exist") but does **not** explicitly require the OBC script to exit non-zero when the rename step fails. If the rename failure is unchecked, the script may exit 0 (satisfying "exit 0 fail-soft only when the report contains zero dispatch-defect entries" — vacuously true for an absent file). T20b then sees: OBC exit 0, no report file.

Under that state, the proceed condition ("byte-empty file AND OBC exit 0") requires a file that exists and is empty — an absent file does not satisfy it. The three halt branches require readable content — an absent file satisfies none. The autopilot is stuck in an unhandled branch.

## The silent failure mode

An implementer who encounters "no branch matches, proceed condition unsatisfied" and applies a "default proceed" fallback (a natural defensive-coding reflex when all named conditions fail) silently allows the implement phase to advance past a failed boundary check. The OBC script was invoked but never produced a readable report, and the safety gate is bypassed without any HALT file written.

This is distinct from the "silent-clean-on-truncation" failure mode T19's atomic-write test already prevents (partial report with empty dispatch-defects section → wrongly proceeds). In that mode, a truncated file would have an empty section and trigger the wrong branch. In **this** mode, there is no file at all, so no branch triggers and the proceed condition is also unsatisfied — the gap is a missing explicit fallback handler, not a content-evaluation error.

## Fix

**T20b description and test expectations** should add an explicit sixth case:

> If the OBC report file is **absent or unreadable** after OBC invocation (regardless of OBC exit code), the autopilot treats this as a dispatch-defect condition: write `HALT-orchestration-boundary-undeterminable.md` to `<ABS_ARTIFACT_DIR>/` and exit the autopilot loop — same halt file and halt semantics as branch (a).

**T19 test expectations** should additionally verify that the script exits **non-zero** when the atomic rename step fails (e.g., a fixture that makes the target directory unwritable after the temp file is written), not only that the partial-file state is clean. This closes the companion gap where OBC silently exits 0 despite a failed report write, which would present as "exit 0, no report" to T20b's autopilot.
