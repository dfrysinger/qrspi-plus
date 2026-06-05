---
id: F01
reviewer: code-quality-claude
round: 2
severity: medium
area: test-quality
file: tests/unit/test-detect-interaction-mode.bats
line: 309
---

# `grep -qv` negative assertion is vacuous — cannot detect DETECTION_TYPE=llm-context in multi-line output

## Location

`tests/unit/test-detect-interaction-mode.bats`, line 309:

```bash
@test "[T24] QRSPI_INTERACTION_MODE=auto override wins even on COPILOT_CLI=1 host" {
  ...
  echo "$output" | grep -q '^VERDICT=auto$'
  # Must NOT emit DETECTION_TYPE=llm-context when override wins
  echo "$output" | grep -qv '^DETECTION_TYPE=llm-context$'
}
```

## Problem

`grep -qv PATTERN` exits 0 whenever **at least one line in the input does NOT match
the pattern**. With multi-line output like:

```
PLATFORM=copilot-cli
DETECTION_TYPE=user-override-only
VERDICT=auto
EVIDENCE=QRSPI_INTERACTION_MODE=auto override
```

`grep -qv '^DETECTION_TYPE=llm-context$'` exits 0 because `PLATFORM=copilot-cli`
doesn't match — regardless of whether `DETECTION_TYPE=llm-context` is also present.
The assertion is effectively **always true** for any output with more than one line,
so the test cannot detect the bug it claims to guard against.

The specific scenario under test is: "override wins, override emits
`DETECTION_TYPE=user-override-only` not `DETECTION_TYPE=llm-context`". If a future
regression caused the script to emit both `DETECTION_TYPE=user-override-only` and
`DETECTION_TYPE=llm-context`, this test would still pass.

## Fix

Replace the vacuous `grep -qv` with a proper negative assertion:

```bash
  # Must NOT emit DETECTION_TYPE=llm-context when override wins
  ! echo "$output" | grep -q '^DETECTION_TYPE=llm-context$'
```

Alternatively, assert the correct positive variant that is already covered separately
(`DETECTION_TYPE=user-override-only`), and remove the redundant negative check
entirely — the positive test at line 228 already covers this scenario.
