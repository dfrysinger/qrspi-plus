---
finding_id: quality-claude-F01
severity: minor
change_type: style
referenced_files:
  - skills/using-qrspi/SKILL.md:413
artifact: task-07
round: 1
reviewer: quality-claude
---

# F01 — QRSPI goal-ID `G6` leaked into SKILL.md runtime prompt-template prose

The added bullet at `skills/using-qrspi/SKILL.md:413` reads:

> "The dispatcher invokes the task tool with `agent_type: code-review` and `model: gpt-5.3-codex` (the Codex model identifier named in `design.md` and goal G6)."

`SKILL.md` is a runtime prompt template loaded by agents at dispatch time (not a `docs/qrspi/`-scoped artifact). Per the ID-hygiene rule for prompt templates / prompt strings authored within the task's diff, QRSPI-internal `G`-prefixed numeric tokens are forbidden on this surface.

The token adds no operational signal to a downstream agent reading the SKILL — the model identifier `gpt-5.3-codex` is self-describing, and "named in `design.md`" already provides provenance. The `G6` token will go stale immediately after the v0.7.1 hardening run completes.

**Recommendation:** Remove `and goal G6` from the parenthetical. The remaining `(the Codex model identifier named in design.md)` carries all provenance an operator needs without coupling the runtime prompt surface to a run-internal goal ID.
