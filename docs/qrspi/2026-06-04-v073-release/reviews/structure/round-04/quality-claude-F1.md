---
finding_id: quality-claude-F1
reviewer: quality-claude
artifact: structure
severity: medium
change_type: behavior
---

# G5 bats fixture row not updated for new per-phase phase-base.txt sources

## Where

`docs/qrspi/2026-06-04-v073-release/structure.md`:
- File-map row for `tests/unit/test-orchestration-boundary-check.bats` (line 95, G5 block).
- Test Architecture § T1 G5 acceptance bullet (line 680).

## What

This round's diff promotes `orchestration-boundary-check.sh` from "phase-base anchor read path is Plan's call" to a Structure-owned per-phase path map with three concrete sources:

- `--phase implement` → reads `integration_base_sha=` from `reviews/implement/wave-state/wave-W1-expected-parents.txt` (G6 sidecar; multi-field format including `task_tip_shas=...`).
- `--phase integration` → reads `integration_base_sha=` from `reviews/integration/phase-base.txt` (single-line `integration_base_sha=<SHA>` format).
- `--phase test` → reads from `reviews/test/phase-base.txt` (same single-line format).

These three sources are distinct code paths in the script: different file locations, different surrounding file content (the implement source carries a second field `task_tip_shas=...` that the integration/test sources don't have), and a new write side (integrate/test SKILLs writing the phase-base.txt at phase start).

The bats fixture row (`tests/unit/test-orchestration-boundary-check.bats` responsibility column) was not updated in this diff. It still enumerates fixtures that are phase-source-agnostic:

> Bats fixtures: clean integration branch (empty report), one non-subagent commit (one entry), uncommitted workspace edits (entry, with `reviews/` path tree excluded), `--phase` accepts directory-name verbatim (no `integrate`→`integration` normalization).

Likewise, the T1 G5 acceptance bullet ("orchestration-boundary-check fixtures (clean / one non-subagent commit / uncommitted-workspace / `reviews/` exclusion); dispatch-agent author-marker fixture") doesn't enumerate per-phase-source coverage.

## Why this matters

Structure's job in a fixture row is to commit to the test surface that locks the named contract. The new contract IS the per-phase source path divergence — that's the whole substance of the diff. With the fixture row unchanged, there is no T1 anchor that:

- Asserts `--phase implement` reads `integration_base_sha=` from the G6 sidecar path (and tolerates the extra `task_tip_shas=` field).
- Asserts `--phase integration` reads from `reviews/integration/phase-base.txt`.
- Asserts `--phase test` reads from `reviews/test/phase-base.txt`.
- Catches a missing phase-base.txt (integration/test phase where the SKILL forgot to write the file at phase start) with a named diagnostic.
- Catches a malformed phase-base.txt (e.g., empty file, wrong key name, multi-line content).

Without those fixtures, a regression that swaps the integration and test read paths, or silently falls through on a missing phase-base.txt, slips past T1 and only surfaces at T3 self-host. The path-divergence is the load-bearing change of this round; the test surface should match.

Also tangentially: the write side (integrate/SKILL.md and test/SKILL.md writing `phase-base.txt` at phase start) has no enumerated anchor check. An anchor-phrase grep — "the integrate/test SKILL body contains a line that writes `phase-base.txt` with `integration_base_sha=`" — would catch the case where the SKILL prose drifts and the file stops being written, which would silently break `orchestration-boundary-check`'s integration/test paths.

## Suggested fix

Extend the `tests/unit/test-orchestration-boundary-check.bats` fixture enumeration to add:

- Per-phase source coverage: one fixture per `--phase` value (`implement`, `integration`, `test`) that places a known `integration_base_sha=<known-SHA>` value at the documented read path and asserts the script computes the phase range from it (single non-subagent commit fixture with the SHA at HEAD-N produces N entries).
- Implement-side multi-field tolerance: a fixture where the wave-1 sidecar carries both `integration_base_sha=` and `task_tip_shas=` lines, asserting the script greps the first field and ignores the second.
- Missing-phase-base-file negative case: per phase, omit the phase-base file and assert the documented exit shape (argument-failure exit non-zero per the interfaces block, OR named diagnostic — Structure's call which).
- Malformed phase-base.txt negative case: empty file, wrong key (`base_sha=` instead of `integration_base_sha=`), multi-line content — assert the documented diagnostic.

Also add to the file-map rows for `skills/integrate/SKILL.md` and `skills/test/SKILL.md` (or to a new lint row under T2) an anchor-phrase coverage commitment: a bats anchor grep asserts the SKILL body contains the phase-base.txt write step. This locks the write side against silent drift.

Update the T1 G5 acceptance bullet (line 680) to enumerate the new fixtures in parallel.
