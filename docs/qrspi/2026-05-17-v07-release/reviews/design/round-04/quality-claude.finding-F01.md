---
finding_id: R4-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L546-L553]
artifact: design
round: 4
reviewer: quality-claude
---

G12's "Commit sequence (defense in depth)" lists a 4-step procedure that appears to replace the existing 5-step protocol but silently drops two load-bearing steps. The existing `skills/implementer-protocol/SKILL.md` Commit Before Reporting procedure (per `research/summary.md` Q17) is:

1. `git status --porcelain` (nothing-to-commit guard, branches to `BLOCKED`/`DONE_WITH_CONCERNS` on empty)
2. Write commit message scratch
3. `git add -A && git commit -F`
4. `rm` scratch
5. `git rev-parse HEAD` → `commit_sha:` in terminal-status report

The design's replacement sequence is:

1. Stage tracked work (`git add -A`)
2. Write commit message to scratch
3. `git commit -F`
4. Post-commit cleanup: remove scratch

This omits both the status-check guard (step 1 of the existing protocol) and the SHA-capture step (step 5 of the existing protocol). The SHA capture is load-bearing — the implementer's terminal-status report requires `commit_sha:` for downstream review-loop wiring, and the round-numbered fix-commit convention also depends on it (per Q12/Q29).

The design's reframing is genuinely about reordering scratch-removal relative to staging, but a downstream implementer reading the 4-step list as the new authoritative sequence could conclude the status check and SHA capture have been deprecated. Two ways to resolve:

(a) Frame the 4-step block explicitly as an ordering-delta against the existing 5-step procedure, noting that status check (pre-step) and SHA capture (post-step) are unchanged in placement and remain required.

(b) Restate the full 6-step procedure (status check, stage, write message, commit, cleanup, SHA capture) so the canonical sequence lives in one place.

Either fix lets the implementer-protocol edit derive an unambiguous procedure from the design without re-reading research/Q17 to recover the dropped steps.
