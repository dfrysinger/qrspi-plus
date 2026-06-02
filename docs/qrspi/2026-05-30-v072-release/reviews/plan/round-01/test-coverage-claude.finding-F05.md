---
finding_id: R1-F05
reviewer: test-coverage-claude
artifact: plan.md
task: Task 12, Task 11
severity: medium
change_type: correctness
---

# T12 & T11 — atomic / parallel-dispatch test recipe unspecified

## What

Two tasks claim atomic + parallel-dispatch safety in their DoD but leave the
parallel-dispatch test recipe unspecified.

**T12 (G4 round-prepare)** DoD:

> `scripts/round-prepare.sh` exists and writes `round-NN.diff`,
> `.round-prepare.json`, and the round commit anchor on valid inputs, with
> deterministic repeated output and **no sidecar corruption under parallel
> dispatch**.

T12 Test expectation:

> Exercise `round-prepare.sh` happy-path inputs and verify it writes
> `round-NN.diff`, `.round-prepare.json`, and the round commit anchor;
> rerun with the same inputs and verify **deterministic output without
> corrupting sidecars under parallel dispatch**.

"Rerun with the same inputs" is a sequential repetition, not parallel
dispatch. The expectation invokes the concept ("under parallel dispatch")
but does not name:

- How many concurrent processes to launch.
- Whether shared `.round-prepare.json` is the target or per-round files.
- What "corruption" looks like in a positive test (truncated JSON, partial
  write visible to a concurrent reader, lost entry, duplicate entry).
- Whether the test should use `flock`, `&` background launches, or a
  process-pool fixture.

**T11 (G29 artifact_path escape hatch)** DoD:

> Manifest append behavior is **atomic and append-safe** across multiple
> reviewer tags in one round and **repeated invocations** for the same
> output directory; no entries are lost or malformed.

T11 Test expectation:

> Run **repeated** dispatch-script invocations against the same round
> output directory with multiple reviewer tags, then validate the manifest
> remains well-formed JSON with all expected entries present.

"Repeated" implies sequential. The DoD requires "atomic" — which is a
concurrency property — but the test recipe is serial-only. A serial-only test
can never falsify the atomicity claim.

## Why this is a test-coverage problem

Test criteria 1 (Behavioral Coverage) asks "Can someone write a deterministic
test from this expectation?" — for the atomicity claim, the answer is no,
because the test recipe doesn't specify the concurrency-introducing mechanism.

Test criteria 3 (Error Conditions) asks what the caller receives when this
task fails — under parallel dispatch the failure modes are race-condition-
specific (interleaved writes, lost updates, partial JSON), but the test
recipe doesn't name them.

A Test writer following the current expectations will produce a serial test
that passes against a non-atomic implementation. This is exactly the
"vacuous pass" class T40 (G21 bats short-circuit hardening) exists to
prevent — yet T11/T12 introduce a new instance of it at a different layer.

## Falsifiable alternative

For both tasks, specify:

- "Launch N (e.g., 8) concurrent `round-prepare.sh` or dispatch-agent.sh
  invocations against the same round directory using `&` background launches
  + `wait`; after all complete, assert the resulting manifest/sidecar is
  well-formed JSON with exactly N entries (or the expected count), no
  duplicate keys, no truncated values, and no interleaved partial lines."
- OR explicitly state that atomicity is enforced by an external lock (e.g.,
  `flock(1)`) and pin the lock-file path / acquisition behavior in the test,
  so the atomic claim is structural rather than concurrency-tested.
- OR remove the "atomic" / "parallel dispatch" language from the DoD and
  scope the contract to "single-writer append" so the serial test
  legitimately covers the contract.

## References

- plan.md ### Task 12 — DoD bullet 1, Test expectation bullet 2.
- plan.md ### Task 11 — DoD bullet 3, Test expectation bullet 3.
- plan.md ### Task 40 — G21 bats short-circuit hardening (precedent for
  rejecting vacuous-pass test recipes).
