# tc-claude · Finding F04 · MEDIUM

## Title
sec.F03 sanitization of `_codex_reviews` is tested structurally (grep-on-source) not behaviourally; a malicious config.md value that bypasses the gate is not exercised at runtime

## Severity
**Medium** — the test proves the sanitizing code was written but not that it works correctly when triggered by actual input.

## Location
`tests/unit/test-host-detection.bats` lines 695–711:
```bash
@test "[r3-sec.F03] codex_reviews value is validated to a safe literal before echoing in mismatch diagnostic" {
  …
  # structural assertion only:
  grep -qF 'true|false' "$WRAPPER"
}
```

## Description
The test's comment acknowledges the limitation:
> "Behavioural injection tests would require the echo to fire with a polluted value, which the strict `== "true"` guard in the current code prevents."

That self-description identifies the real gap: **the strict `== "true"` guard already prevents the mismatch `echo` from firing with a polluted value**, so the sanitization `case` is never exercised at runtime in any test. The grep simply proves the text `true|false` appears somewhere in the script, which would pass even if the case statement were dead code or on the wrong variable.

### Specific untested scenario
A crafted `config.md`:
```yaml
---
codex_reviews: "\x1b[H\x1b[2J"
---
```
After the awk extraction, `_codex_reviews` holds the escape-sequence string. The sanitization `case` must normalise it to `"false"`. The mismatch `echo` must NOT fire (because `"false" != "true"`). The test does not exercise this end-to-end.

### Also untested: `codex_reviews` with a value that is neither "true" nor "false"
The production `case` sets `_codex_reviews="false"` for any unexpected value. There is no runtime test that:
1. Writes a config.md with `codex_reviews: garbage-value`
2. Invokes the dispatch surface
3. Asserts the mismatch echo is **absent** from stderr (i.e., normalised to "false" and guard did not fire)

## Recommended additional test
```bash
@test "[r3-sec.F03] config.md with unexpected codex_reviews value is normalised to false; no mismatch echo" {
  # Write a config.md whose codex_reviews field is neither "true" nor "false".
  printf -- '---\ncodex_reviews: garbage-value-99\n---\n' > "$TMP_DIR/artifact-dir/config.md"

  TMP_STDERR="$TMP_DIR/sec-f03-runtime.txt"
  QRSPI_REPO_ROOT="$TMP_DIR" \
    COPILOT_CLI="" \
    HOME="$MOCK_HOME" \
    bash "$WRAPPER" \
      --agent-file agents/qrspi-spec-reviewer.md \
      --reviewer-tag spec-codex \
      --output-dir "$TMP_DIR/out" \
      --round 1 \
      --subject-code "$TMP_DIR/src/subject.ts" \
      --model gpt-5-codex \
      --output-file "$TMP_DIR/result.md" \
      --artifact-dir "$TMP_DIR/artifact-dir" \
    >"$TMP_DIR/sec-f03-stdout.txt" 2>"$TMP_STDERR" || true

  # Normalised to "false" → mismatch echo must NOT appear.
  ! grep -q '\[mismatch\]' "$TMP_STDERR"
  # And the raw garbage value must not appear verbatim in stderr.
  ! grep -q 'garbage-value-99' "$TMP_STDERR"
}
```
