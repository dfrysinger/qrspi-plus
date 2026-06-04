---
finding_id: silent-failure-claude.finding-F03
severity: low
change_type: correctness
artifact: code
round: 2
reviewer: silent-failure-claude
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1159-L1161
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1197-L1199
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1235-L1237
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1116-L1119
---

## TC5/TC6/TC7 bare score assertions swallow the failure diagnostic; empty `raw_score` produces a cryptic shell error

### What TC4 does (correct pattern)

TC4 (line 1116–1119):

```bash
raw_score=$(grep "^score:" "$tmp/${stem}.score.md" | awk '{print $2}')
[ "$raw_score" -eq 0 ] \
  || { echo "hallucination: expected score 0 in sidecar, got: $raw_score"; return 1; }
```

If the assertion fails, a human-readable diagnostic is emitted before the test
exits, identifying the expected and actual values.

### What TC5, TC6, TC7 do (bare assertion)

TC5 (lines 1159–1161), TC6 (lines 1197–1199), TC7 (lines 1235–1237):

```bash
raw_score=$(grep "^score:" "$tmp/${stem}.score.md" | awk '{print $2}')
[ "$raw_score" -eq 0 ]
```

The `|| { echo ...; return 1; }` branch is absent. Two failure modes result:

**1. `raw_score` has a non-zero integer value:**  
The test fails with bats's generic line-failure output, showing only the file
and line number. No diagnostic says what value was found or what was expected.
Debugging requires manually reading the sidecar file.

**2. `raw_score` is the empty string** (i.e., `grep "^score:"` matched nothing
because the sidecar has `verifier_status: failed` with no `score:` key):  
`bash: [: : integer expression expected` — the test fails with an arithmetic
expression error, not a meaningful "score field absent" message. Because this
error looks like a script bug rather than an assertion failure, it can mislead
a developer into suspecting the test infrastructure rather than the sidecar
content.

### Why the empty-`raw_score` path matters specifically

If the verifier agent were to write a `verifier_status: failed` sidecar (no
`score:` field) for a Cite Check halt — instead of the intended
`verifier_status: passed, score: 0` path — the fan-in would record
`score_unparseable` halt and exit 1. TC5's `[ "$status" -eq 0 ]` assertion
would then catch the fan-in failure, but the earlier `[ "$raw_score" -eq 0 ]`
would have already failed with the cryptic arithmetic error, obscuring the
root cause entirely.

### Fix

Apply the TC4 diagnostic pattern consistently to TC5, TC6, and TC7:

```bash
# TC5
[ "$raw_score" -eq 0 ] \
  || { echo "hallucination: expected score 0 in sidecar (line-range), got: $raw_score"; return 1; }

# TC6
[ "$raw_score" -eq 0 ] \
  || { echo "hallucination: expected score 0 in sidecar (quoted-content), got: $raw_score"; return 1; }

# TC7
[ "$raw_score" -eq 0 ] \
  || { echo "hallucination: expected score 0 in sidecar (named-anchor), got: $raw_score"; return 1; }
```
