# Structure R04 — apply-fix log

1 substantive finding (others clean):

- **quality-claude F1 (medium/behavior)** — R03 promoted G5 to a per-phase path map but the bats fixture row + T1 acceptance bullet were not updated to enumerate per-phase-source coverage; SKILL-prose write-side had no anchor lock.

Applied:
- File-map G5 bats row extended: per-phase source fixtures, implement multi-field tolerance, missing/malformed phase-base.txt negatives.
- New T2 lint row `tests/lint/test-integrate-test-skill-phase-base-write.bats` locking the integrate/test SKILL phase-base.txt write step against silent prose drift.
- T1 G5 acceptance bullet rewritten to enumerate the new fixtures + lint in parallel.
