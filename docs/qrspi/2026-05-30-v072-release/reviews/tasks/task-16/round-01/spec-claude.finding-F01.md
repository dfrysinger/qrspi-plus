---
id: F01
reviewer: spec-claude
change_type: missing-behavior
severity: blocking
---

# F01 — Two reviewer agents missing `DISPATCH_FILE` first-action instruction

## Location

- `agents/qrspi-code-simplifier.md` (lines 1–7, current HEAD)
- `agents/qrspi-type-design-analyzer.md` (lines 1–7, current HEAD)

## What the spec requires

Task 16 DoD (§ "Definition of done", bullet 6):

> "Every reviewer agent reads `DISPATCH_FILE=<path>` as its full dispatch before any other procedural step."

Both `qrspi-code-simplifier` and `qrspi-type-design-analyzer`:

- Carry `skills: [reviewer-protocol]` in their frontmatter (line 6 of each file).
- Are dispatched as **thoroughness reviewers** in `skills/implement/SKILL.md` under the "Thoroughness reviewers (deep mode only)" section — alongside `qrspi-goal-traceability-reviewer`, `qrspi-test-coverage-reviewer`, and `qrspi-code-simplifier` — using the same `Agent({ subagent_type: "..." })` dispatch pattern as every other reviewer agent.
- Emit findings via the reviewer-protocol disk-write contract.

They are unambiguously "reviewer agents" in the sense the DoD uses.

## What was implemented

The diff adds `tier: medium` to both agent files but does NOT add the `DISPATCH_FILE` first-action paragraph to either. The current bodies begin immediately with "You are the Code Simplifier…" / "You are the Type Design Analyzer…" — no DISPATCH_FILE instruction.

Compare with agents that were correctly migrated (e.g., `qrspi-code-quality-reviewer.md`), which received:

```
**Read your `DISPATCH_FILE=<path>` as your full dispatch before doing anything else.** The orchestrator passes a single-line `DISPATCH_FILE=<absolute-path>` prompt as your only input; Read that file first — it holds your complete dispatch (reviewer protocol, agent body, and dispatch parameters) — and follow its contents before any other procedural step.
```

Neither `qrspi-code-simplifier.md` nor `qrspi-type-design-analyzer.md` has this paragraph.

## Test coverage gap

The test sweep (`test-routing-matrix-application.bats`, "reviewer agents" section) checks only five specific reviewer agents for the DISPATCH_FILE instruction: `qrspi-code-quality-reviewer`, `qrspi-spec-reviewer`, `qrspi-security-reviewer`, `qrspi-plan-reviewer`, and `qrspi-silent-failure-hunter`. Neither `qrspi-code-simplifier` nor `qrspi-type-design-analyzer` is included in that test set, so the omission is not caught by the test suite.

## Impact

When these two reviewer agents are dispatched, they will attempt to execute their reviewer logic against the DISPATCH_FILE=<path> single-line prompt as though it were a full subject_code/task_definition prompt, rather than reading the file it points to first. This produces incorrect behaviour for every thoroughness-mode deep review that includes either agent.

## Required fix

Add the identical DISPATCH_FILE first-action paragraph to **both** files immediately after the YAML frontmatter block (before "You are the…" opening line), matching the paragraph in all other reviewer agents.

Optionally extend the test sweep to cover both agents to close the gap in test coverage.
