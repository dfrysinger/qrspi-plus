---
reviewer: code-quality-claude
task: 13
round: 1
severity: low
dimension: ID hygiene
file: tests/unit/test-scope-tagger-dispatch.bats
---

## Finding F03 — QRSPI-internal IDs (T13, G9, G4) in test names and comments

Grep-lint candidate scan of the diff (`\b[GRDFTQ]-?[0-9]+`) surfaces QRSPI-internal
task/goal IDs in test-name strings and comments outside `docs/qrspi/`:

- Every new test name is prefixed `[T13]` (15 occurrences, diff lines 72-318).
- Comment block references `T13`, `G9`, `G4` (diff lines 61-68, 116, 308).

Per the reviewer-protocol ID-hygiene rule, QRSPI-internal `T`/`G`-prefixed tokens
in test names and code comments are flaggable outside `docs/qrspi/`.

**Mitigating context — this is the pre-existing, pervasive convention of this very
file**, not a token accidentally copied from the task spec. The existing tests
already tag with `[112-PR2]` and reference `T9`, `G9`, `B8` in names and comments
(file lines 34-41, 56-60). The new `[T13]` tags are deliberate traceability
markers consistent with that norm, so they do not match the rule's intended
flag-target ("the implementer copying run-specific tokens into the diff").

Raised at low severity for completeness so the orchestrator can decide whether the
repo's task-ID-tagging convention should be exempted wholesale (it spans the whole
suite) rather than treated as a per-task defect. No action recommended on this task
alone — fixing only the new tests would make this file internally inconsistent.
