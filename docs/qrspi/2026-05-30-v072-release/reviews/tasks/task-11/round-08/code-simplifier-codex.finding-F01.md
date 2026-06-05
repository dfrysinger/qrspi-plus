---
reviewer_tag: code-simplifier-codex
round: 8
finding_id: R8-F01
severity: low
change_type: clarity
referenced_files: [scripts/run-codex-review.sh, tests/acceptance/v07-phase1/test-phase1-acceptance.bats]
status: non-blocking-suggestion
---

# F01 — Simplification opportunities (non-blocking)

## Suggestions

1. **Deduplicate `_append_manifest_entry` failure cleanup** (scripts/run-codex-review.sh ~320–364). Same 6-step rm/trap-clear/rmdir/eval/exit-1 sequence in 5 error branches. Helper: `_append_manifest_fail "<msg>"`.

2. **Deduplicate first-party prompt tmp cleanup + trap bodies** (scripts/run-codex-review.sh ~928–951). KEEP 3-trap split (EXIT/INT/TERM with exit-130/143). Helpers: `_cleanup_fp_tmp`, `_fail_fp_dispatch "<msg>"`.

3. **Remove redundant absolute-path validation for `--output-dir`** (lines ~473–476 and ~576–581). `_validate_output_dir` already enforces absolute path; the second `[[ "$OUTPUT_DIR" != /* ]]` check is dead.

4. **Reduce repeated test fixture boilerplate** (test-phase1-acceptance.bats AC1/AC2/AC3 blocks ~1398–1431, 1528–1548, 2218–2244, 2382–2402). `_t7_make_mock_repo` exists at ~334–390 but AC blocks re-inline mkdir/printf scaffolds.

## Recommendation

All non-blocking. #3 is a 1-line cleanup safe to do in this cap-bend cycle. #1, #2, #4 are substantive refactors with non-zero regression risk after 8 rounds of fix work — defer to v0.7.3 backlog.
