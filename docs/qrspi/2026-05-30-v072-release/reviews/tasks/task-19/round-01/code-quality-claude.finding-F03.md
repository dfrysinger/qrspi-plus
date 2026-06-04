---
finding_id: F03
reviewer_tag: code-quality-claude
severity: low
change_type: style
referenced_files:
  - tests/unit/test-routing-matrix-application.bats:477
  - tests/unit/test-routing-matrix-application.bats:497
  - tests/unit/test-routing-matrix-application.bats:505
  - tests/unit/test-routing-matrix-application.bats:513
  - tests/unit/test-dispatch-companion-availability.bats:63
  - tests/unit/test-dispatch-companion-availability.bats:80
  - tests/unit/test-second-reviewer-available.bats:208
  - tests/unit/test-second-reviewer-available.bats:221
---

## QRSPI-internal ID `D5` copied from task spec into test names and comments

Multiple new additions in the diff embed `D5` — a QRSPI-internal design-decision token
(D-prefixed numeric, matches `\b[GRDFTQ]-?[0-9]+\b`) — directly in test names and code
comments. Per the ID hygiene rules, QRSPI-internal IDs are forbidden in test names,
`@test` block labels, and code comments.

**Test names (forbidden surface)** — `test-routing-matrix-application.bats`:
```
@test "_resolve-lib.sh D5 matrix: claude-code default second-reviewer vendor is openai-codex"
@test "_resolve-lib.sh D5 matrix: copilot-cli default second-reviewer vendor is openai-codex"
@test "_resolve-lib.sh D5 matrix: unknown host default second-reviewer vendor is none"
```
Section comment at the same location: `# second-reviewer D5 matrix and routing coverage (Task 19)`

**Comments in test bodies** — `test-dispatch-companion-availability.bats`:
```
# D5 names openai-codex as the default second-reviewer vendor for copilot-cli.
# D5 maps copilot-cli → openai-codex as the default second-reviewer vendor → probe exits 0.
```
And in `test-second-reviewer-available.bats`:
```
# D5 names openai-codex as the default second-reviewer vendor for copilot-cli
# (Codex is third-party on Claude Code but still potentially reachable via dispatch-companion.sh).
```

The described behavior is already fully articulated by the test names and body text
without the `D5` token; removing it does not reduce information for a reader who doesn't
have the task spec in hand.

**Suggested fix:** Replace `D5` with the concept it names. For example:
- `@test "_resolve-lib.sh host×vendor matrix: claude-code default second-reviewer is openai-codex"`
- In comments: "the default second-reviewer vendor for copilot-cli is openai-codex per the
  host×vendor matrix" (no spec token needed).
