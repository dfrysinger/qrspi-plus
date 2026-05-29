---
finding: F02
reviewer: spec-claude
round: 4
severity: blocking
category: test-expectation-without-test
---

# F02 — Spec bullet 14 is a test expectation with no corresponding test

## Spec claim (amended task-01.md, bullet 14)

> An `api_key_env` field containing characters outside `[A-Za-z0-9_]` or an empty
> string causes the script to exit with a `key-resolution` diagnostic before
> API-key resolution

This appears in the **Test expectations** section of the amended spec (dispatch
`task_definition` lines 1494–1495), meaning a test is expected to verify it.

## Production code — behavior IS implemented

`scripts/run-third-party-llm.sh` lines 637–639 (commit 383dc84):

```bash
case "$API_KEY_ENV" in
  ''|*[!A-Za-z0-9_]*) die "key-resolution: api_key_env must be a valid shell identifier (for provider '$PROVIDER')" ;;
esac
```

The guard is present and correct: it rejects an empty `api_key_env` value (the
identifier name is empty) and any value containing characters outside
`[A-Za-z0-9_]`. The die message uses the `key-resolution:` prefix as the spec
requires.

## Test file — NO test covers this behavior

`tests/unit/test-run-third-party-llm.bats` (commit 383dc84) contains **42 tests**.
None of them exercise the identifier-validation path:

- Test `"exit 1: api_key_env environment variable is unset"` (line 847): uses
  `api_key_env: NEVER_SET_KEY_XYZ` — a valid identifier, merely absent from the
  environment. Tests the env-var-unset code path, not the identifier-validator.
- Test `"exit 1: api_key_env environment variable is set but empty"` (line 857):
  uses `api_key_env: EMPTY_KEY_XYZ` — a valid identifier whose environment variable
  is set to the empty string. Tests the empty-value code path, not the
  identifier-validator.

No test supplies a config with an invalid `api_key_env` field (e.g.,
`api_key_env: MY-BAD-KEY` with a hyphen, or `api_key_env: 123STARTS_DIGIT`, or
an empty `api_key_env:` field value) and asserts exit 1 with a `key-resolution`
diagnostic.

## Distinction from bullet 13

Bullet 13 (API key control-char screening) has a corresponding test at line 1446:
`[control-char-detect] API key containing control character causes exit before
network dispatch`. Bullet 14 does not.

## Impact

The spec (in its amended form) lists bullet 14 as a Test Expectation, implying the
test suite verifies this behavior. The test suite does not. Either:

(a) A test must be added to `tests/unit/test-run-third-party-llm.bats` exercising
    the `api_key_env` identifier validator, OR
(b) Bullet 14 must be moved from the "Test expectations" list to the description
    prose as a non-tested implementation note (and the spec status re-evaluated
    accordingly).

Option (a) is preferred: the behavior is security-relevant (prevents shell-word
injection into the env lookup) and deserves explicit test coverage.

## Suggested test sketch

```bash
@test "exit 1: api_key_env identifier with invalid chars exits with key-resolution diagnostic" {
  cat > "$FIXTURE_DIR/config.md" <<EOF
---
providers:
  p1:
    base_url: https://api.example.com
    api_key_env: MY-BAD-KEY
    transport_type: openai-chat-completions
---
EOF
  run bash -c "echo hi | '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider p1 --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"key-resolution"* ]]
  [ ! -f "$OUTPUT_FILE" ]
}
```
