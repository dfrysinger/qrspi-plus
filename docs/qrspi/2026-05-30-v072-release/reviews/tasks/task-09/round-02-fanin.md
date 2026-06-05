# Task 09 — Round 2 Fan-In Disposition

**Base commit:** `13f7dcd4` (T09 R1 fix-cycle)
**Round:** 2
**Reviewers dispatched:** 6 (3 categories × 2 vendors)
**Gate status:** NOT CLEAN — fix-cycle required
**Fix-cycle budget:** R2 = 2 of 3 (this round)

## Reviewer Returns

| Reviewer | Findings | Convergence / Notes |
|----------|----------|---------------------|
| spec-claude | CLEAN | — |
| spec-codex | CLEAN | — |
| cq-claude | F01 (low, defer), F02 (low, in-scope) | F01 convergent with cq-codex F01 |
| cq-codex | F01 (low, defer) | Convergent with cq-claude F01 |
| sf-claude | CLEAN (acknowledges sf-codex F01/F02) | Dual convergence on both sf-codex findings |
| sf-codex | F01 (med, in-scope), F02 (med, in-scope) | Both acknowledged by sf-claude |
| sec-claude | F01 (high, in-scope) | Convergent with sec-codex F01 |
| sec-codex | F01 (high, in-scope) | Convergent with sec-claude F01 |

**Totals:** 5 unique findings (1 HIGH dual-convergent, 2 MEDIUM, 2 LOW). 4 in-scope fixes + 1 defer.

## Disposition

### Issue A — JSON injection in dispatch manifest (sec-codex F01 + sec-claude F01, HIGH, convergent)

`emit_dispatch_manifest_entry()` at `scripts/run-codex-review.sh:579-580` interpolates `--reviewer-tag` and `--model` into a hand-built JSON string via bare `%s` without escaping or validation. The very feature T09 introduces for model-audit integrity is itself tamperable via its own audited fields — self-defeating.

**Required fix (defense-in-depth, both):**
1. Build the manifest entry via `jq -n --arg tag "$REVIEWER_TAG" --arg host "$detected_host" --arg model "$MODEL" '{tag:$tag, host:$host, vendor:"openai-codex", model:$model}'`. (jq is already a documented dependency in this codebase per other scripts.)
2. Add allowlist validation at argument-parse time for `--reviewer-tag` (`^[a-z][a-z0-9_-]*$`) and `--model` (`^[A-Za-z0-9][A-Za-z0-9._-]*$`), consistent with existing `--companion NAME` / `--field NAME` guards in the same file.

Update AC5 to add a positive test that asserts well-formed JSON shape (e.g., parse via `jq -e 'has("tag") and has("host") and has("vendor") and has("model") and (keys | length == 4)'`).

### Issue B — AC5 swallows all dispatch exit codes with `|| true` (sf-codex F01, MEDIUM)

At `tests/acceptance/v07-phase1/test-phase1-acceptance.bats:1440`, the dispatch invocation `... || true` masks unknown non-zero exits. A future regression that crashes the script after manifest write but before completing dispatch invariants would silently pass.

**Required fix:** Capture the exit code; allow only documented-acceptable codes (e.g., 0 = full success, plus the documented launch-failure code for "no codex in CI environment"). Fail loudly on any other non-zero exit. If `run-codex-review.sh` does not yet have a stable launch-failure exit code, document the acceptable values inline in AC5 with explanatory comment.

### Issue C — AC8 grep exit-code semantics silently pass on missing files (sf-codex F02, MEDIUM)

At lines 1585 and 1590, the `if grep -qF '...' "$file"; then FAIL; fi` pattern silently passes on grep exit 2 (file missing or unreadable). If `agents/qrspi-finding-verifier.md` or `scripts/verifier-fan-in.sh` is renamed/moved, AC8 reports PASS — exactly the regression scenario AC8 was designed to catch.

**Required fix:** Add file-exists preconditions before each grep:
```bash
[ -f "$REPO_ROOT/agents/qrspi-finding-verifier.md" ] \
  || { echo "AC8 precondition failed: agents/qrspi-finding-verifier.md missing"; return 1; }
[ -f "$REPO_ROOT/scripts/verifier-fan-in.sh" ] \
  || { echo "AC8 precondition failed: scripts/verifier-fan-in.sh missing"; return 1; }
```

### Issue D — AC7 Case 4 is tautological (cq-claude F02, LOW)

At `tests/acceptance/v07-phase1/test-phase1-acceptance.bats:~1561-1575`, Case 4 ("clean-sentinel WITHOUT actual_model") writes a fixture via `printf` and asserts (a) the fixture doesn't contain `actual_model:` and (b) the file has two `---` markers. Both assertions only verify `printf` wrote what it was told; no production code path is exercised.

**Required fix:** Either:
- (Option A — recommended) Drop Case 4 entirely; the AC7 contract is already covered by Cases 1-3 plus the documented helper behavior. Document the clean-sentinel-absent path as a v0.7.3 follow-up if not yet directly testable.
- (Option B) Convert Case 4 to a documentation comment block describing the expected shape, with no `return 1` branches.

### Defer to v0.7.3

**cq-codex F01 + cq-claude F01 — ID hygiene in test-phase1-acceptance.bats and run-codex-review.sh (LOW, convergent).**

`T09`, `T11`, `G3` tokens appear in code comments and runtime error strings. The Phase 1 acceptance bats file is the documented traceability spine and uses these IDs across every task slice (T01-T08 all carry their IDs). Same finding raised at T08 R3 from cq-codex and deferred there with same rationale. Project-wide rename to descriptive labels is the proper fix — already on v0.7.3 backlog as "ID hygiene leak in test-files (recurring across multiple tasks)".

## Budget tracking

- R1 fix-cycle: 1 of 3 (consumed)
- R2 fix-cycle: 2 of 3 (this round)
- R3 reserve: 1 of 3 remaining if R3 spec gate finds new defects
