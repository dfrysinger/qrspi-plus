---
finding: F01
reviewer: silent-failure-claude
round: 2
severity: high
category: Silent Failure in Test Coverage
file: tests/unit/test-detect-interaction-mode.bats
line: 309
---

# F01: `grep -qv` assertion is always-true — override branch never tested for wrong DETECTION_TYPE

## Location

`tests/unit/test-detect-interaction-mode.bats` line 309 (diff line 487):

```bash
@test "[T24] QRSPI_INTERACTION_MODE=auto override wins even on COPILOT_CLI=1 host" {
  …
  echo "$output" | grep -q '^VERDICT=auto$'
  # Must NOT emit DETECTION_TYPE=llm-context when override wins
  echo "$output" | grep -qv '^DETECTION_TYPE=llm-context$'   # ← always-true
}
```

## What goes wrong

`grep -qv PATTERN` exits 0 when **any** line in the input does NOT match
`PATTERN`. Since the output of the override branch always contains multiple
lines — `PLATFORM=copilot-cli`, `VERDICT=auto`, `EVIDENCE=…` — at least one
line never matches `^DETECTION_TYPE=llm-context$`, so `grep -qv` always exits
0 unconditionally.

The assertion is logically vacuous. It never fails under any output, regardless
of whether `DETECTION_TYPE=llm-context` is present or absent.

## Silent failure scenario

If the override branch in the script were broken and emitted:

```
PLATFORM=copilot-cli
DETECTION_TYPE=llm-context          ← wrong; should be user-override-only
INSTRUCTION=Inspect your active …   ← wrong; override should not emit INSTRUCTION
VERDICT=auto
```

The test at line 309 would still pass silently. An orchestrator consuming
`DETECTION_TYPE=llm-context` would treat the result as an LLM-context
inspection task and emit an `INSTRUCTION`, rather than writing the override
verdict directly into the audit JSON — a mis-classification with operational
consequences.

This is the exact behavioral property that the round-2 fix (adding PLATFORM +
DETECTION_TYPE to the override branch) was intended to verify. The test was
added to guard the fix, but the assertion is a no-op.

## Correct fix

Replace `grep -qv` with a negated `grep -q`:

```bash
# Must NOT emit DETECTION_TYPE=llm-context when override wins
! echo "$output" | grep -q '^DETECTION_TYPE=llm-context$'
```

Or equivalently, add a positive assertion for the correct value:

```bash
echo "$output" | grep -q '^DETECTION_TYPE=user-override-only$'
```

Both forms will fail the test when the wrong DETECTION_TYPE is present.
