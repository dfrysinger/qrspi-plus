---
finding_id: R4-SF-F03
reviewer: silent-failure-claude
severity: low
change_type: test-coverage
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats
at_cap: true
escalate: true
---

# F03 — AC3 test suppresses all invocation errors — root-cause failures are invisible when assertions trip

**Introduced by R4 (dispatch-manifest AC3 test is new in this round).**

## Location

`tests/acceptance/v07-phase1/test-phase1-acceptance.bats` — `[dispatch-manifest AC3]` test, the two invocation blocks (around lines 2408–2435 in the full test file, matching the diff `@@ -932,24 +941,18 @@` area for the new AC3 test):

```bash
# First invocation: reviewer tag spec-codex
QRSPI_REPO_ROOT="$TMP_DIR" COPILOT_CLI="" \
  bash "$REPO_ROOT/scripts/run-codex-review.sh" \
    ...
  >/dev/null 2>/dev/null || true

# Second invocation: reviewer tag sec-codex
QRSPI_REPO_ROOT="$TMP_DIR" COPILOT_CLI="" \
  bash "$REPO_ROOT/scripts/run-codex-review.sh" \
    ...
  >/dev/null 2>/dev/null || true
```

## Failure mode

Both invocations redirect **all** output to `/dev/null` and append `|| true`, which means:

1. Both invocations' stdout, stderr, and exit codes are entirely discarded.
2. If either invocation fails — for example because the mock dispatcher is missing, because the `_validate_output_dir` check fails for `OUTDIR`, because the manifest lock cannot be created, or because any new R4 code path `exit 1`s — the test silently continues.
3. The only signal that something went wrong is the final `jq -e 'type == "array" and length == 2'` assertion, which fails with:

```
manifest does not have exactly 2 entries
```

At that point there is **no diagnostic information** about which invocation failed, why it failed, or whether both failed or only one. The manifest may have 0 or 1 entries, but the test cannot distinguish "first invocation succeeded, second failed" from "both failed" from "dispatcher mock bug" from "lock race."

## Why this matters as a silent failure

The AC3 test is specifically designed to guard the append-safety invariant: "two successive invocations with different reviewer tags produce a well-formed two-entry manifest." If either invocation introduces a silent exit (e.g., a future regression where `emit_dispatch_manifest_entry` silently skips writing when a condition is unmet), the test's `|| true` pattern means the regression is masked at the invocation level and only detected by the count assertion — if at all.

More concretely: if R4's exit-code-replacement bug (sf-codex F01) causes one invocation to exit 1, and a fix later wraps `emit_dispatch_manifest_entry` in `|| true` to recover the dispatcher exit code, the "failed" path manifest entry might not be written either — and AC3 would miss it because `|| true` on both invocations means neither failure is distinguished from success at the test level.

## Fix

Capture each invocation's exit code explicitly and emit a diagnostic before returning 1:

```bash
local inv1_status=0
QRSPI_REPO_ROOT="$TMP_DIR" COPILOT_CLI="" \
  bash "$REPO_ROOT/scripts/run-codex-review.sh" \
    --reviewer-tag spec-codex \
    ...
  >/dev/null 2>"$TMP_DIR/inv1-stderr.log" || inv1_status=$?
if [[ "$inv1_status" -ne 0 ]]; then
  echo "First invocation (spec-codex) failed with exit $inv1_status"
  cat "$TMP_DIR/inv1-stderr.log"
  return 1
fi

local inv2_status=0
QRSPI_REPO_ROOT="$TMP_DIR" COPILOT_CLI="" \
  bash "$REPO_ROOT/scripts/run-codex-review.sh" \
    --reviewer-tag sec-codex \
    ...
  >/dev/null 2>"$TMP_DIR/inv2-stderr.log" || inv2_status=$?
if [[ "$inv2_status" -ne 0 ]]; then
  echo "Second invocation (sec-codex) failed with exit $inv2_status"
  cat "$TMP_DIR/inv2-stderr.log"
  return 1
fi
```

This preserves the intent of AC3 (both invocations must succeed AND the manifest must have 2 entries) while making root-cause diagnostics visible when the test fails.
