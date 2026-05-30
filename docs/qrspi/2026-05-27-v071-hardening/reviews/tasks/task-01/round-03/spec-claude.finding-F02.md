---
reviewer: spec-claude
round: 3
finding: F02
severity: scope-excess-advisory
verdict: FLAG-ADVISORY
---

# F02 — API key control-char screening + corresponding test not in spec's 12 test expectations

## Location

`scripts/run-third-party-llm.sh`, API-key-resolution block (diff lines 126–130):

```bash
# Screen the API key for control characters: it is placed verbatim into the
# Authorization header, so the same injection risk applies as for any other
# header value.  Use the "api_key_env/<var>" label so the die message
# identifies the source without leaking the key value itself.
_control_char_check "api_key_env/${API_KEY_ENV}" "$_API_KEY"
```

`tests/unit/test-run-third-party-llm.bats`, 42nd test (round-2 addition):

```bats
@test "[control-char-detect] API key containing control character causes exit before network dispatch" {
  ...
  CTRL_TEST_KEY="sk-ok$(printf '\015')X-Injected: evil" QRSPI_ALLOW_LOCALHOST_BASE_URL=1 run bash -c \
    "printf 'test-prompt\n' | '$DISPATCHER' ..."
  [ "$status" -eq 1 ]
  [[ "$output" == *"header-validation"* ]]
}
```

## What the spec requires

The spec's 12 test expectations enumerate a closed list of behaviours for
`_control_char_check`.  All 12 focus on `default_headers` entries (header
names and values parsed from the config.md `default_headers:` block).  The
list does not include API key value screening.

## The ambiguity

The spec description contains broad language:

> "Every header name and every header value is screened before any network
> call"

The API key IS placed verbatim into the `Authorization: Bearer <key>` header
— it IS a header value.  Under a broad reading of this sentence, API key
screening falls within scope.

Under a narrow reading (the rest of the description and all 12 test
expectations address only `default_headers`), API key screening is an
extension beyond the enumerated surface.

## Why this is flagged

The spec's test expectations are the binding contract for the test-writer
phase and the spec-reviewer gate.  The 42nd test (`API key containing control
character…`) is not traceable to any of the 12 enumerated test expectations
in task-01.md.  It was added as a response to security-claude F01 (a
pre-existing security finding), not as a task-01 deliverable.

The production code change — the `_control_char_check` call on `$_API_KEY` —
is correct and desirable.  The implementation is not broken.  The issue is
that neither the behaviour nor its test is formally enumerated in the spec.

## Severity: Advisory

This is lower severity than F01 because:
- The production behaviour IS arguably within the spec's "every header value"
  language.
- The test validates the same `_control_char_check` function the spec requires
  — just applied to a different input surface.
- No new die-path diagnostic string is introduced (re-uses `"header-validation"` 
  output, which the test correctly asserts).

## Recommendation

One of two clean options:

**Option A — Amend task-01.md with a 13th test expectation.**  Add: "The API
key value is screened for control characters using the same `_control_char_check`
helper before being placed into the Authorization header; a control character
in the API key causes exit 1 with a `header-validation` diagnostic."  This
back-names the existing 42nd test into the spec formally.

**Option B — Accept under broad "every header value" language.**  Treat the
existing description ("every header value is screened") as sufficient to cover
the Authorization header's value, and accept that the 12 bullets are
representative rather than exhaustive.  Document the decision in the task
record.

Either option resolves this finding.
