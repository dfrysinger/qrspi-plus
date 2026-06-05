# F01 — QRSPI-internal goal IDs (`G35`, `G3-class`) embedded in shipped Design SKILL prose

**Severity:** must-fix
**Category:** ID hygiene (rule 11) / cleanliness

## Where

`skills/design/SKILL.md` (post-edit), introduced by this task's diff:

1. `## What Design produces` paragraph:
   > "Unified system architecture, file maps, module boundaries, and the unified test architecture that stitches per-solution acceptance criteria into a coherent test plan are Structure's job (**see G35**); per-test specification (per-assertion test code) is Plan's job."

2. `## Altitude Sub-Rule C — End-to-End Flow`, *Required flow elements* → Context-cost call-out bullet:
   > "...explicitly state what enters the orchestrator's context vs. what stays in subagent context or on disk. **This is the substrate for G3-class concerns**; flows that bloat the orchestrator window without saying so leak prompt content silently."

## What's wrong

Per the reviewer-protocol ID-hygiene rule (strict surface): "QRSPI-internal IDs — G/R/D/T/Q-prefixed numeric tokens: forbidden in code comments, test names, … fixture names — flag every occurrence outside `docs/qrspi/`, regardless of how scoped the comment is." `skills/design/SKILL.md` is a deployed runtime prompt template, not content under `docs/qrspi/`. It is the strictest surface (a prompt string authored in the task's diff).

`G35` and `G3` are this run's local goal identifiers. They are meaningless to:
- the LLM consuming `skills/design/SKILL.md` at runtime in any future project,
- a maintainer reading the skill outside this run's `goals.md`,
- any user installing the plugin in a different repo.

The task spec itself flags this exact failure mode under "Test expectations": *"Cross-cutting prompt-prose review confirms … the prose is evergreen, with no dialogue exhaust, TODOs, placeholders, or stale line-number references."* Run-local goal IDs are dialogue exhaust — they were live in design.md ## G1 during authoring and got copied through into shipped prose verbatim.

## Suggested fix

Replace each with the load-bearing concept the ID was a shorthand for:

1. `(see G35)` → drop the parenthetical entirely, or replace with a behavioral pointer such as `(see Structure's owns/defers contract)`. The surrounding sentence already names what Structure owns; the citation adds no signal.

2. `This is the substrate for G3-class concerns` → name the concern directly, e.g. *"This is the substrate for orchestrator-context-budget concerns"* or *"This is what prevents silent context-window bloat across the orchestrator/subagent boundary."* The surrounding sentence already explains the failure mode; `G3-class` is a run-local label that obscures rather than communicates.

## Why must-fix, not nit

These are the only two items that clearly fail an evergreen check on the new prose. The skill is a long-lived plugin asset; pruning run-IDs at install time is much cheaper than after the prompt ships and starts being copied into derivative work. Both fixes are one-line edits.
