---
reviewer: coverage-claude
artifact: plan.md
round: 3
note_type: skip-record
---

# Skip record: lightweight tasks excluded from RED-gate coverage review

Per the plan-test-coverage-reviewer dispatch instructions, tasks with
`task_type: lightweight` are out of scope for RED-gate test-coverage
criteria — their Test Expectations carry the prompt-prose
rules-application clause (verified by `qrspi-code-quality-reviewer` /
`qrspi-design-reviewer` content-semantic rules application), not
executable acceptance-test claims.

The following tasks were skipped on this basis (all carry
`task_type: lightweight`):

```
skipped_lightweight_tasks:
  - T05: lightweight
  - T07: lightweight
  - T09: lightweight
  - T13a: lightweight
  - T13b: lightweight
  - T15: lightweight
  - T16: lightweight
  - T20a: lightweight
  - T20b: lightweight
  - T21: lightweight
  - T22: lightweight
  - T23: lightweight
  - T26: lightweight
  - T30: lightweight
  - T31: lightweight
  - T32: lightweight
  - T33: lightweight
  - T34: lightweight
  - T35: lightweight
  - T36: lightweight
```

Total: 20 lightweight tasks skipped, 23 code tasks reviewed (T01, T02,
T03, T04a, T04b, T06, T08, T10, T11, T12, T14, T17a, T17b, T17c, T18,
T19, T24, T25, T27, T28, T29, T37, T38). Round 3 split former T17
into T17a/T17b/T17c — three reviewed code tasks where round-02 had one.

## Round-02 prior-finding disposition snapshot

For audit-trail continuity:

- Round-02 coverage-claude F01 (T37 named diagnostic tokens for
  unresolvable/circular `!cat`) — **addressed**: T37 Description and
  Test expectations now pin `footprint-snippet-unresolvable:` and
  `footprint-snippet-cycle:` as literal diagnostics.
- Round-02 coverage-claude F02 (T19 unknown `--phase` value) —
  **unaddressed**: re-filed as round-03 F01.
- Round-02 coverage-claude F03 (T25 missing-sidecar / out-of-order
  `--validate`) — **partially addressed**: round-03 added
  `sidecar-schema-mismatch:` for file-exists-but-malformed cases; the
  file-missing and out-of-order cases remain uncovered. Re-filed as
  round-03 F02.
- Round-02 coverage-claude F04 (T04a no-input edge — silent skip in
  dispatch-prompt path-parameter omission) — **addressed via design
  redirection**: round-03 reshaped T03 to fail-loud on
  `review-prep-no-diff-source:` / `review-prep-empty-diff:` by default
  (silent-claude R2-F01 direction), with `--allow-empty-no-diff` as a
  fixture-only opt-in. T04a now asserts the fail-loud direction
  propagates through dispatch-agent (line "A production-default
  high-level invocation against an artifact-dir not in a git repo
  halts non-zero with review-prep's `review-prep-no-diff-source:`
  named diagnostic"). The silent no-input edge case F04 was written
  against no longer exists in the plan.
