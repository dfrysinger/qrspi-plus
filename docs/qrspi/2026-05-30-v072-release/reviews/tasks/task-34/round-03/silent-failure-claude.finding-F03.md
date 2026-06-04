---
reviewer: silent-failure-claude
round: 3
finding: F03
severity: medium
category: vacuous-test / trivially-true detection assertion
file: tests/unit/test-plan-post-approval-split.bats
lines: 721–766
---

# F03 — Missing-header and malformed-header tests: condition-detection assertions are trivially true

## Tests under examination

1. `[split] Missing block-hash header triggers pre-G5 migration HALT diagnostic` (line 721)
2. `[split] Malformed block-hash header triggers named malformed diagnostic` (line 747)

Both tests share the same structural flaw.

---

## Test 1 — Missing-header (lines 721–741)

The test creates a file *without* a `# block-hash:` line (lines 723–729), then detects its absence:

```bash
local has_hash
has_hash="$(grep -c "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md" || true)"
[ "$has_hash" -eq 0 ]                                                  # line 734
```

`has_hash` will always be `0` because the test just created the file without that line. No orchestrator, no mtime change, no modification — the count is determined entirely by what was in the `cat > …` heredoc. The assertion `has_hash == 0` is trivially true and cannot distinguish "we created a pre-G5 file" from "an orchestrator correctly detected the absence."

The two `extract_and_grep` assertions at lines 737–740 are **meaningful** doc-audit checks. But the `has_hash == 0` assertion adds nothing.

---

## Test 2 — Malformed-header (lines 747–766)

The test creates a file containing `# block-hash: not-valid-hex` (line 753), then asserts:

```bash
local hashline
hashline="$(grep "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md" | head -1)"
! echo "$hashline" | grep -qE "^# block-hash: [0-9a-f]{64}$"           # line 761
```

`hashline` is `# block-hash: not-valid-hex`. The pattern `[0-9a-f]{64}` obviously does not match `not-valid-hex` (8 chars, not 64, contains a hyphen). This assertion is guaranteed to pass regardless of any orchestrator logic. It only verifies that the test author wrote a malformed line and a regex correctly rejects it — not that an orchestrator would detect the malformation.

The `extract_and_grep` assertion at line 764–765 is **meaningful**.

---

## What IS covered in each test

Both tests contain legitimate doc-audit assertions (`extract_and_grep` calls) that pin the contract document's exact text. Those are not vacuous. Only the "condition detection" assertions (`has_hash == 0` and `! … grep -qE …`) are trivially true.

---

## Risk

The two trivially-true assertions create a false impression of behavioral coverage. A reader scanning the test names ("triggers pre-G5 migration HALT diagnostic", "triggers named malformed diagnostic") expects that the tests verify a diagnostic is *triggered* — but neither test simulates an orchestrator at all. If an orchestrator were to silently skip the missing-header check (no halt, no diagnostic), these tests would still pass.

---

## Remediation sketch

Both tests' behavioral claims are carried by the `extract_and_grep` doc-audit calls. The condition-detection assertions could be removed without reducing real coverage, or replaced with a comment acknowledging that the HALT behavior (the name implies) is doc-pinned by the `extract_and_grep` calls rather than exercised through a live orchestrator action.

Alternatively: use the existing file as input to a inline orchestrator-style decision function:

```bash
# Missing-header: detect and assert doc says to HALT
local audit_result
if grep -qE "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md"; then
  audit_result="ok"
else
  audit_result="missing-header"
fi
[ "$audit_result" = "missing-header" ]  # ← same trivially true, but naming intent is clearer
# Better: simulate the halt path and verify no dispatch increment
```

The fundamental gap is that BATS fixture tests cannot invoke the real orchestrator (an LLM). The tests should clearly signal which properties are *doc-pinned* (extract_and_grep) vs *behaviorally simulated* (hash computation loops). The current naming implies the former is the latter.
