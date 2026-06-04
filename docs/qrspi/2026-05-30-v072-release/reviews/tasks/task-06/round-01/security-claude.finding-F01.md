---
finding_id: R1-F01
reviewer_tag: security-claude
round: 1
task: 6
severity: medium
change_type: correctness
referenced_files:
  - agents/qrspi-finding-verifier.md
  - tests/unit/test-verifier-agent-file.bats
---

# F01 — `score: VERIFY_FAILED` string in YAML frontmatter creates integer type confusion enabling silent fan-in bypass

## Location

- `agents/qrspi-finding-verifier.md:58–64` (failure-case sidecar schema)
- `tests/unit/test-verifier-agent-file.bats:72–77` (G11 integer-score test)

## What the code does

Task 06 migrates the verifier sidecar to Markdown-with-YAML-frontmatter. Success case:

```yaml
---
score: <int 0..100>
---
```

Failure case:

```yaml
---
score: VERIFY_FAILED
reason: <one-sentence diagnosis>
---
```

In YAML, `score: 87` parses as integer `87`; `score: VERIFY_FAILED` parses as the string `"VERIFY_FAILED"`. Two different scalar types sharing the same key in the sidecar schema.

## Security gap

Neither the verifier agent doc nor any test specifies what the fan-in script MUST do when `score:` is a non-integer. The agent says "the disk sidecar is the load-bearing fan-in input" but does not say "consumers must branch on type before comparing scores." The G11 test at lines 72–77 only checks that the agent MENTIONS `score: integer 0-100` in text; it does not assert that `VERIFY_FAILED` sidecars are handled as a distinct, non-numeric outcome.

## Concrete attack scenario

1. A finding file is crafted with adversarial prose (see F02 for the mechanism), or the verifier agent misbehaves, and writes `score: VERIFY_FAILED` for a legitimate high-severity finding.
2. The fan-in script reads the sidecar YAML. In shell (`awk`/`bash`) contexts, arithmetic on `VERIFY_FAILED` silently coerces to `0`; in Python it raises `TypeError`; in Ruby it returns `nil` in comparison. Depending on implementation:
   - **Shell coercion:** `VERIFY_FAILED` → `0`; if threshold is `> 0`, the finding is dropped silently as "below threshold." Bypasses the fan-in filter with no log noise.
   - **Exception path:** fan-in aborts processing the whole round file, dropping all remaining findings for that reviewer.
3. In either case a real finding is excluded from fan-in output with no operator-visible signal — chat-side summary is explicitly "non-load-bearing telemetry."

## Why tests don't catch it

The G11 test suite checks the agent's PROSE (does the document say the right things?) but has no test that asserts `VERIFY_FAILED` is treated as a categorically separate outcome from an integer score of `0`. Missing test: *"failure sidecars must use a key other than `score:` (e.g., `status:`) to avoid integer type confusion."*

## Convergence with sec-codex F02

Same root cause as `security-codex.finding-F02.md` (VERIFY_FAILED → fan-in halt DoS) viewed from a different angle: codex saw the global-halt path, claude saw the silent-coercion-to-zero path. Both surface the same fix — keep `score:` strictly numeric and use a separate field for failure state.

## Suggested fix

Move failure state out of `score:`:

```yaml
---
verifier_status: failed
failure_reason: <one-sentence diagnosis>
---
```

`score:` becomes either an integer 0–100 OR absent. Fan-in branches on `verifier_status:` first; numeric comparison on `score:` only fires when `verifier_status:` is `passed` (or absent on the success path). Add a behavioral test asserting that a `verifier_status: failed` sidecar produces a fan-in entry tagged as `verifier-failed`, NOT a `score=0` finding-dropped entry.

## Severity rationale

Medium: requires either adversarial input (F02) or verifier misbehavior to trigger; impact is silent finding-drop or global fan-in halt — both block release-blocking signal at the worst moment.
