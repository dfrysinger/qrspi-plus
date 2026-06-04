---
finding_id: F02
reviewer_tag: spec-codex
round: 2
severity: medium
change_type: test-coverage
referenced_files:
  - tests/unit/test-second-reviewer-available.bats:237-311
  - docs/qrspi/2026-05-30-v072-release/tasks/task-19.md:42
---

Test coverage misses the unknown-host + recognized-vendor-override path that
should be unavailable. The existing tests cover the unknown host WITHOUT an
override (exits 1 via the `none` default) and an unknown vendor override on a
known host (Copilot), but they do not assert that an `unknown` host WITH a
recognized override (e.g. `openai-codex`) still fails with one
`[second-reviewer-unavailable]` stderr line naming host and vendor. That gap is
exactly what let the F01 spec break go uncaught.

Fix: add a bats test asserting `second-reviewer-available.sh openai-codex` with
no host env signals set exits non-zero and emits exactly one stderr line
beginning `[second-reviewer-unavailable]` containing `host=unknown` and
`vendor=openai-codex`.
