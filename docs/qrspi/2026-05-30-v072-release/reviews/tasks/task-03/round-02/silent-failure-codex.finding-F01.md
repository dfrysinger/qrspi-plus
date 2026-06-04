---
finding_id: R2-F01
reviewer_tag: silent-failure-codex
round: 2
task: 3
severity: medium
change_type: silent_failure
referenced_files:
  - skills/reviewer-protocol/first-party-emission.md
---

# F01 — Partial-write silent failure: no expected-count check

## Location

`skills/reviewer-protocol/first-party-emission.md:55` (and surrounding wrong-channel iron-law section)

## Issue

The contract explicitly treats partial-write failures as not separately signaled — only the all-or-nothing zero-output case is caught by the "expected tag produced no output" iron law. If a reviewer intends to emit N findings but only some Write calls succeed, the run can proceed with incomplete findings and no loud failure.

## Silent-failure surface

A reviewer with intermittent disk-write failures (rate limit, full filesystem, race condition with the round-dir creation) could land K of N findings. The orchestrator sees K finding files present → tag produced output → contract satisfied → no loud diagnostic. The missing (N - K) findings are silently lost. This is a data-loss path masked by the contract's all-or-nothing framing.

## Concrete failure scenario

1. Reviewer agent decides on 5 findings (F01–F05).
2. Writes F01.md, F02.md successfully.
3. Disk write for F03.md fails (transient I/O error).
4. Reviewer's hygiene check is per-file ("did this write succeed?") not aggregate ("did all N writes succeed?").
5. Reviewer returns chat-side telemetry summary saying "5 findings emitted" but only 2 are on disk.
6. Orchestrator counts disk files = 2, sees output exists for the tag, proceeds to fan-in.
7. F03/F04/F05 are silently lost — possibly including the highest-severity finding.

## Suggested fix

Require the contract to mandate one of:

1. **Expected-count manifest:** Each reviewer writes a single `<reviewer_tag>.manifest.md` declaring `expected_count: N`; orchestrator asserts `count(*.finding-F*.md) == N` before fan-in. Mismatch → loud failure naming the missing IDs.
2. **Sequential commit semantics:** Reviewer writes per-finding files atomically via temp-and-rename, AND writes a final `.commit` sentinel only after all per-finding writes succeed. Orchestrator requires the `.commit` sentinel; absence → reviewer failed mid-emission, loud failure.

Either pattern closes the data-loss surface and preserves the existing iron law.

## Severity rationale

Medium: requires transient I/O failure or reviewer hygiene bug to trigger, but the impact is silent loss of review findings — exactly the silent-failure class the iron law was designed to prevent.
