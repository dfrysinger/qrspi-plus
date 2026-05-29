# tc-claude · Finding F05 · LOW

## Title
Reverse-direction mismatch (copilot-cli detected, `codex_reviews: false`) is not tested; absent `config.md` dispatch scenario is also unexercised

## Severity
**Low** — production code handles both paths, but the tests for mismatch only cover one of the two asymmetric directions.

## Location
`tests/unit/test-host-detection.bats`  
- Lines 511–573: mismatch tests only cover `COPILOT_CLI=""` (claude-code) + `codex_reviews: true`

`scripts/run-codex-review.sh` lines 607–611 (mismatch logic):
```bash
if ! check_codex_available "$_detected_host"; then
  if [[ "${_codex_reviews}" == "true" ]]; then
    echo "[mismatch] …" >&2
  fi
fi
```

## Description

### Gap 1 — Reverse mismatch not tested
All four mismatch-path tests configure:
- `COPILOT_CLI=""` → detected host = `claude-code`
- `codex_reviews: true` in config.md
- No companion in MOCK_HOME → `check_codex_available` returns non-zero → mismatch fires

No test covers the opposite case:
- `COPILOT_CLI=1` (+ gh in trusted prefix on the test host) → detected host = `copilot-cli`
- `codex_reviews: false` in config.md
- Expected: `check_codex_available copilot-cli` returns 0 → `if !` guard does **not** fire → no mismatch echo

A mutation that unconditionally emits the mismatch diagnostic (even when `check_codex_available` succeeds) would not be caught by the existing tests, because all mismatch tests are on the `check_codex_available` failure branch.

### Gap 2 — Absent `config.md` in dispatch path not tested
The production code:
```bash
_codex_reviews=""
if [[ -f "$ARTIFACT_DIR/config.md" ]]; then
  _codex_reviews="$(awk … "$ARTIFACT_DIR/config.md")"
fi
```
When `config.md` is absent, `_codex_reviews` remains `""`, which the sanitization `case` normalises to `"false"`, so no mismatch fires. This entire branch (absent config → no mismatch) has no dedicated test. A mutation that skips the absent-file guard or unconditionally reads the file would not be caught.

## Recommended additional tests

```bash
@test "[dispatch-surface] no mismatch echo when check_codex_available succeeds (copilot-cli + codex_reviews false)" {
  # copilot-cli detected; codex_reviews=false; no mismatch expected
  printf -- '---\ncodex_reviews: false\n---\n' > "$TMP_DIR/artifact-dir/config.md"
  TMP_STDERR="$TMP_DIR/nomismatch.txt"
  QRSPI_REPO_ROOT="$TMP_DIR" COPILOT_CLI=1 \
    bash "$WRAPPER" … >"$TMP_DIR/nm-stdout.txt" 2>"$TMP_STDERR" || true
  ! grep -q '\[mismatch\]' "$TMP_STDERR"
}

@test "[dispatch-surface] absent config.md is treated as codex_reviews=false; no mismatch echo" {
  rm -f "$TMP_DIR/artifact-dir/config.md"    # ensure absent
  TMP_STDERR="$TMP_DIR/noconfig.txt"
  QRSPI_REPO_ROOT="$TMP_DIR" COPILOT_CLI="" HOME="$MOCK_HOME" \
    bash "$WRAPPER" … >"$TMP_DIR/nc-stdout.txt" 2>"$TMP_STDERR" || true
  ! grep -q '\[mismatch\]' "$TMP_STDERR"
}
```

Note: the first test shares the environment-dependency issue described in F02 (requires trusted-prefix `gh`). Adding the absent-config test (Gap 2) is fully self-contained and straightforward.
