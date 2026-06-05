# spec-claude review — Task 21, Round 11

**Verdict:** CLEAN — no findings.

## Scope of review
Narrow R11 fix-cycle increment (298 lines) closing the 8 R10 findings. Diff covers:
- `scripts/dispatch-agent.sh` (helper hoist + batch wiring + --round int regex + hygiene)
- `scripts/dispatch-companion.sh` (post-canonicalization round_dir guard + _codex_job_id newline reject)
- `tests/unit/test-dispatch-agent.bats` (two new value-emission tests + hygiene)

## Closure verification (against the R10 finding ledger in dispatch context)

1. **cq-claude/cq-codex F01 — hygiene leaks.** Confirmed: 3 review-attribution comments stripped from `dispatch-agent.sh` (lines 104, 113, 295 of the diff replacing "(sec-claude review)" / "(sf-claude review)" / "round-3 review" mentions, and the long comment block at L134-L195 collapsed) and 2 from the bats file (L246, L294). No new attributions introduced.

2. **sf-claude F01 / sec-codex F01 — BATCH_ARTIFACT path-emission guard.** Confirmed at diff L86-L96: the batch `--artifact` branch now calls `reject_if_path_unsafe_for_emission` and `reject_if_contains_marker_file` after `assert_path_under_repo_root`. Order is correct (boundary first, then emission/marker).

3. **sf-claude F02 — post-canonicalization round_dir \n/\r reject.** Confirmed at companion diff L210-L224: case-statement check on `$_canon_round_dir` after `_qrspi_canonicalize` and before `_jobs_dir` derivation. Comment correctly explains the symlink-target attack vector.

4. **sec-claude F01 — `--round` integer regex.** Confirmed in BOTH parse loops:
   - Batch loop diff L77-L82: `^[0-9]+$` regex with descriptive error, mirrored
   - Single loop diff L122-L127: same regex, same message
   Test coverage added at bats diff L255-L268 asserts a newline-bearing `--round` is rejected at parse time with "non-negative integer" in the error.

5. **sec-claude F02 — --field VALUE \n/\r reject.** Closed via the generalized `reject_if_value_unsafe_for_emission` helper (diff L41-L56) which the existing single-mode `--field` guard plumbing now routes through. New bats test at diff L270-L284 confirms a `\n`-bearing `--field` value is rejected with "embedded newline" in the message.

6. **sec-codex F02 — _codex_job_id \n/\r reject.** Confirmed at companion diff L228-L233: dedicated case arm next to the existing `*/*|*..*|""` validator. Defense-in-depth correctly framed in the die message.

## Mechanism check (hoist correctness)

The hoist of `FORBIDDEN_MARKERS` + helpers from L1010-area to L520 (above the `_is_batch_mode` detection block) is the right structural fix:
- Helpers are now defined before BOTH the batch arg-parse + validation block AND the single-mode arg-parse loop
- The old `reject_if_contains_marker_value` name is preserved as a thin alias forwarding to `reject_if_value_unsafe_for_emission`, so any prior single-mode call sites remain wired
- The renamed `reject_if_value_unsafe_for_emission` correctly bundles the newline check WITH the marker check (previously these were split across `reject_if_path_unsafe_for_emission` and `reject_if_contains_marker_value`), eliminating the asymmetry where scalar values escaped the newline check
- `reject_if_path_unsafe_for_emission` now delegates to the generalized helper, so paths get the same combined newline+marker treatment

No double-evaluation, no shadowed locals, no ordering bug observed.

## Spec checklist

- **Completeness:** All 8 R10 closures land in the diff; no claimed closure missing implementation.
- **Scope:** No out-of-scope additions. Comment hygiene stripping is appropriate fix-cycle housekeeping.
- **Interpretation:** Correct — sec-claude F01's intent ("--round must be integer, not just non-empty") is implemented as `^[0-9]+$` (rejects negatives, decimals, and embedded newlines). The test asserts the integer-validation path triggers, not the post-emission newline guard, matching how parse-time validation should fire.
- **Test coverage:** Two new tests added covering --round and --field value-emission. R10 findings F01/F02 from sec-claude both have asserting tests now. The other closures (BATCH_ARTIFACT guard, round_dir post-canon, _codex_job_id) ride on existing test surfaces or are defense-in-depth (acceptable per do-not-reflag context).
- **TDD evidence:** Implementer's prior rounds established TDD; this fix-cycle's two new bats tests assert real behavior (status != 0 + error-message regex), not just non-crash.
- **Extras:** None. Alias preservation (`reject_if_contains_marker_value`) is a backward-compat shim, not new feature scope.
- **Target-files deviation:** None — all edits within the three files in the task target list.

## Do-not-reflag honored
Confirmed I am not reopening: _resolve-lib `|| true`, QRSPI_REPO_ROOT, TOCTOU symlink swap, batch _path fallback WARN, batch reviewer-protocol/emission-override silent-skip asymmetry, `resolve_tier 2>/dev/null`, per-agent launch-failure batch exit-0, mktemp+mv non-atomic job record, R7/R8 spec-codex amendments, R7 cq-codex bats split.

Gate: PASS. Other reviewers may proceed.
