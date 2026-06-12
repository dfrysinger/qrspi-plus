# Structure R05 — apply-fix log

Codex reviewers (quality + scope) both flagged the same correctness issue: the new `tests/lint/test-integrate-test-skill-phase-base-write.bats` was bundled into the T1 G5 acceptance bullet, but T1 is `tests/unit/` and T2 is `tests/lint/`. Claude reviewers clean.

Applied:
- Removed the T2 lint reference from the T1 G5 bullet.
- Added a dedicated T2 § G5 acceptance bullet for the integrate/test SKILL-body phase-base-write anchor-phrase lint.
