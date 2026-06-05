# Spec Review — Task 21 Round 6 — CLEAN

reviewer: spec-claude
round: 6
verdict: clean

## Summary

R6 addresses the two R5 sec-claude ACT findings without scope creep:

**F01 — launch `--round-dir` boundary check**
`scripts/dispatch-companion.sh` line 640: `assert_path_under_repo_root "launch:--round-dir" "$L_ROUND_DIR"` placed after prompt-file boundary check (L634) and before `_jobs_dir` construction (L646). Order is correct.

**F02 — await `_job_tag` allowlist + `_job_round_dir` boundary check**
Lines 551–555: `case "$_job_tag" in ""|*[!a-z0-9_-]*|[^a-z]*)` mirrors launch-time allowlist.
Line 559: `assert_path_under_repo_root "await:round_dir" "$_job_round_dir"` placed after tag validation and before `_raw_dir` construction (L561).

**Tests** (`tests/unit/test-dispatch-agent.bats` lines 1849–1910):
- `companion launch: --round-dir outside repo rejected` — `prompt_file` inside repo (TMP_DIR under REPO_ROOT), `oor_dir` in /tmp; round-dir check fires ✓
- `companion await: job record with traversal tag rejected` — tag `../../other-task/evil` fails allowlist ✓
- `companion await: job record with out-of-repo round_dir rejected` — `round_dir` in /tmp, tag valid; boundary check fires ✓

**Companion-audit DoD**: comment block at lines 46–65 documents legacy stdin form has no raw-path surface; launch `--prompt-file` and `--round-dir` are both guarded. Satisfies spec line 45–46.

**Scope**: diff touches only `scripts/dispatch-companion.sh` and `tests/unit/test-dispatch-agent.bats`. No unrelated changes.

All R5 findings resolved. No new spec deviations found.
