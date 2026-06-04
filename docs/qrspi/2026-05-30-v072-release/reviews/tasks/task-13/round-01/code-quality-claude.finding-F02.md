---
reviewer: code-quality-claude
task: 13
round: 1
severity: low
dimension: cleanliness / maintainability
file: tests/unit/test-scope-tagger-dispatch.bats
---

## Finding F02 — Hardcoded `design.md` line numbers in test comments will rot

Two of the new test comments cite the authority by absolute line number:

- `# Per design.md §G9 L1356 companion lint: ...` (diff line ~116)
- `# Architectural boundary (design.md §G9 L1358 acceptance criterion): ...`
  (diff line ~308)

Line-number anchors into a sibling document drift the moment `design.md` gains
or loses a line above L1356/L1358, after which the comment points at the wrong
place and silently misleads the next reader. The section anchor (`design.md §G9`)
is the stable, self-correcting reference and is already present in both
comments; the `L####` suffix adds fragility without adding durable signal.

Recommend dropping the `L####` portion and keeping the named-section citation,
matching how the rest of the file refers to authorities (e.g. the existing
`per T9 hardening, G9` / `B8 full-artifact-fallback` references carry no line
numbers).

Severity low: comment-only, no behavioral impact.
