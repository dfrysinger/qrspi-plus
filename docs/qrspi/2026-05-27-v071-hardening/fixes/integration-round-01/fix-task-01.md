---
task_type: lightweight
fix_round: integration-round-01
source_findings: [R1-F02, R1-F04]
target_files: [agents/qrspi-test-writer.md]
estimated_loc: 25
---

# Fix Task 01 — Reconcile qrspi-test-writer.md prose contradictions and add implementer-protocol preload

## Source findings (integration round 1, both KEPT post-verifier)

- **R1-F02 (HIGH, correctness, score 85)** — agents/qrspi-test-writer.md "All modes" Output Contract contradicts T2-added implement-phase RED-run+commit behavior.
- **R1-F04 (MED, correctness, score 78)** — agents/qrspi-test-writer.md performs commit cycle but does not load the `implementer-protocol` skill (frontmatter has no `skills:` field).

Both findings have the same root cause: T2 (commit-hygiene scope) added implement-phase behavior to the test-writer but Hotfix A's parallel mutations + the pre-existing all-modes prose were not reconciled. Fixing them together is the smallest coherent change.

## Required changes

### Change 1 — Add `skills:` field to frontmatter (closes R1-F04)

File: `agents/qrspi-test-writer.md` lines 1-6

Current state:
```yaml
---
name: qrspi-test-writer
description: "Dual-mode test-writing agent. In Implement-phase mode (task_definition present): writes per-task failing tests against the un-implemented spec. In Test-phase mode (task_definition absent): writes plan-level acceptance tests that verify the implementation meets the original goals. Does NOT modify production code."
model_role: test-writer
tools: Read, Write, Edit, Bash, Grep, Glob
---
```

Required state — add `skills: [implementer-protocol]` field on a new line between `tools:` and `---`:
```yaml
---
name: qrspi-test-writer
description: "Dual-mode test-writing agent. In Implement-phase mode (task_definition present): writes per-task failing tests against the un-implemented spec. In Test-phase mode (task_definition absent): writes plan-level acceptance tests that verify the implementation meets the original goals. Does NOT modify production code."
model_role: test-writer
tools: Read, Write, Edit, Bash, Grep, Glob
skills: [implementer-protocol]
---
```

Rationale: agent body line 28 explicitly invokes "the implementer-protocol scratch-file pattern" but the protocol body (commit-hygiene invariants 1-3, pre-DONE hygiene self-check at SKILL.md:148-160) is not preloaded without this declaration. agents/qrspi-implementer.md already carries `skills: [implementer-protocol]` at line 5 — apply the same preload to the test-writer.

### Change 2 — Scope the "All modes" Output Contract to test-phase only (closes R1-F02)

File: `agents/qrspi-test-writer.md` lines 267-272

Current state (lines 267-272 — "## Output Contract" section "All modes:" block):
```
All modes:

- Test files are written to `output_dir` only. The agent must not write outside that directory.
- The agent emits a final status token on the last line: `DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, or `BLOCKED`.
- The agent does NOT run any test file it writes. Running tests is out of scope for this agent.
- The agent does NOT fix production code.
```

Required state — split into a genuinely-all-modes block and a test-phase-only block:
```
All modes:

- Test files are written to `output_dir` only. The agent must not write outside that directory.
- The agent emits a final status token on the last line: `DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, or `BLOCKED`.
- The agent does NOT fix production code. If a test fails for an infrastructure/setup reason, the agent fixes the test, never the production code under test.

Test-phase mode only:

- The agent does NOT run any test file it writes. The orchestrator runs tests at the Test gate.

Implement-phase mode:

- The agent DOES run tests via `bats --filter` to verify RED (per Behavior step 4 above). The agent DOES commit the RED tests via the scratch-file pattern (per Behavior step 6 above). See the implement-phase Behavior block for the full contract.
```

### Change 3 — Scope the "Red Flags — STOP" "Attempting to run tests" entry to test-phase only (closes R1-F02 secondary surface)

File: `agents/qrspi-test-writer.md` line 261 (inside "## Red Flags — STOP" section)

Current state at line 261:
```
- Attempting to run tests or report results (the orchestrator runs tests).
```

Required state — qualify with test-phase scope:
```
- Test-phase mode: attempting to run tests or report results (the orchestrator runs tests at the Test gate). Implement-phase mode: NOT a red flag — running `bats --filter` to verify RED is required behavior (see Behavior step 4).
```

## Out-of-scope

- DO NOT modify the implement-phase Behavior block (lines 71-76) — it is already correct.
- DO NOT modify the Tool-grant scope block (lines 17-29) — it is already correct.
- DO NOT modify the description sentence — it is already correct.
- DO NOT touch any other file. The two related findings (F03/F05 = clarity-threshold drops about implementer-protocol/SKILL.md stale prose + single-mechanism .git/info/exclude reference) are out of scope for this fix and have been filed as v0.7.2 followups.

## Test expectations

- `bats tests/unit/test-test-writer-dual-mode.bats` continues to pass post-fix (does not regress the cleanup change committed at 898c171).
- Full `bats tests/unit/` continues to pass 1305/1305.
- `awk '/^---$/{n++; next} n==1{print}' agents/qrspi-test-writer.md | grep -q '^skills:'` exits 0.
- `grep -n 'Attempting to run tests' agents/qrspi-test-writer.md` shows the line is qualified with "Test-phase mode" prefix.

## Done report

Report `DONE` with a one-line summary of each change and the bats pass count.
