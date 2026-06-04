---
reviewer_tag: code-quality-codex
round: 9
finding_id: R9-F01
severity: medium
change_type: clarity
referenced_files: [tests/acceptance/v07-phase1/test-phase1-acceptance.bats]
---

# F01 — ID hygiene violation: `T11` token in test comment

## Finding

`tests/acceptance/v07-phase1/test-phase1-acceptance.bats:2785` contains the comment:
```
# AC5: dispatch_spec.subagent_type asserted on the real end-to-end first-party dispatch path
# (T11 spec requires this field; AC2 covers the helper-function path).
```

The literal `T11` is a QRSPI-internal task ID. Per repository convention (and aligns with stored hygiene rule "strip 'inside baseball' — notes written for us as developers"), internal task IDs should not appear in shipped test code outside `docs/qrspi/`.

## Severity

MEDIUM: documentation hygiene; no behavioral impact but leaks pipeline metadata into shipped code that long outlives the pipeline run.

## Suggested fix

Rewrite as semantic:
```
# AC5: dispatch_spec.subagent_type asserted on the real end-to-end first-party dispatch
# path (task spec requires this field; the helper-function test above covers it via the
# source-only path).
```
