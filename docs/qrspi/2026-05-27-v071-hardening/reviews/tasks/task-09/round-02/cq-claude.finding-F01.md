---
finding: F01
reviewer: cq-claude
round: 2
task: task-09
severity: medium
change_type: correctness
file: tests/unit/test-agent-frontmatter-no-model.bats
lines: 100-110
persistence_note: orchestrator-persisted (chat-only fallback)
---

# Tautological message-shape assertion can never fail

## Location

`tests/unit/test-agent-frontmatter-no-model.bats` lines 100–110, inside the
`[agent-frontmatter-no-model] per-file failure message names the offending file path` test.

## What is wrong

The test constructs `rendered` by interpolating `$sample_offender` directly into the message string, then uses a `case` statement to check whether `rendered` contains `$sample_offender`:

```bash
local rendered
rendered="${sample_offender}: forbidden top-level frontmatter key 'model:'"
case "$rendered" in
  *"$sample_offender"*) : ;;
  *)
    echo "per-file failure message does not name the offending path: $rendered"
    return 1
    ;;
esac
```

Because `rendered` is literally defined as starting with `$sample_offender`, the `case` match is unconditionally true. The test can never fail. It does not exercise any real behaviour of the sweep loop; it merely proves that a string containing a variable also contains that variable.

## Why it matters

This test is supposed to guard the regression scenario: if someone later modifies the sweep error message to omit the offending file path, this test should catch it. In that regression state, the test would still pass unconditionally, giving a false-green signal.

## Suggested fix

Factor the per-file message string into a named helper (e.g. `_violation_msg "$f" "$offending_line"`) shared between the sweep and this test. Then call `_violation_msg "$sample_offender" "1:model: sonnet"` and assert the result contains both the path and the offending line.

Alternatively, use BATS `run` to call a wrapper that exercises the sweep with a synthetic fixture carrying `model:`, then `assert_output --partial "$sample_offender"` against the captured output — testing the actual rendered message from the real code path.
