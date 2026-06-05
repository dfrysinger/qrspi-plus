---
finding_id: F03
reviewer: code-quality-claude
round: 1
severity: advisory
change_type: code
file: tests/lint/test-structure-altitude-boundary-include.bats
line: 82
---

# F03 — Test scope: content-semantic assertions beyond the named include-guard lint

The task DoD scopes the lint to: "asserts the literal `!cat skills/_shared/structure-altitude-boundary.md` directive is present in both consumer files at the canonical insertion points; removal of either directive fails the lint with a file-and-directive-naming diagnostic." The task's negative list states: "no implementation-level test assertions beyond the named include-guard lint."

The bats file's first four tests are within scope:

- existence of the directive in `skills/structure/owns-defers.md`
- existence of the directive in `agents/qrspi-structure-scope-reviewer.md`
- positional placement (line immediately after the introducer prose) in the agent file
- primitive-file existence + non-empty

Three additional tests assert content-semantic invariants of the shared primitive's **body**, not the include contract:

1. `Structure OWNS:` precedes `Structure DEFERS:` (polarity ordering of the primitive body)
2. Six canonical substring anchors are present in the primitive body (e.g., `'Unified system architecture diagram'`, `'Per-task assertions'`)
3. Six anti-pattern grep patterns must not appear in `owns-defers.md` (the inline-body residual check)

Test (3) is partially in-scope (the directive must "replace" the inline body, so verifying the body is gone is reasonable) but goes wider than necessary — six anti-patterns rather than a single canonical absence check.

Tests (1) and (2) verify the **content** of the shared primitive's body. They go beyond the include-guard contract and couple the lint to the primitive's specific wording. Future legitimate edits to OWNS/DEFERS phrasing would now require coordinated test updates despite the include contract still holding.

## Code-quality assessment

Each individual test is well-written, well-named, and produces a clear diagnostic. The concern is contract scope, not test quality. From a pure code-quality lens this is advisory; it overlaps with spec-reviewer scope concerns.

## Suggested action

Defer to spec-reviewer judgment on whether to retain. If retained, the tests are technically clean. If trimmed, the recommended minimal cut is to keep test (3) (replace check) and drop tests (1) and (2) — or move (1) and (2) into a separate "primitive content lint" file with its own justification, distinct from the include-guard lint named in the DoD.
