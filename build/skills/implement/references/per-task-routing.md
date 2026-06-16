# Per-Task Routing (`task_type`)

Before dispatching the implementer for a task, main chat reads `task_type` from the task's `tasks/task-NN.md` frontmatter and resolves three per-task flags:

```
task_type ∈ {code, lightweight}              # from tasks/task-NN.md frontmatter (default: code)

if task_type == "lightweight":
    implementer_subagent = "qrspi-implementer-lightweight"
    review_depth_effective = "quick"         # forced — overrides config.review_depth
    codex_enabled_per_task = false           # forced — overrides config.second_reviewer
else:
    implementer_subagent = "qrspi-implementer"
    review_depth_effective = config.review_depth
    codex_enabled_per_task = config.second_reviewer

dispatch: Agent({ subagent_type: implementer_subagent })   # (vendor, model) resolved by the Tier Resolution Chain below
```

The concrete `(vendor, model)` pair is NOT read from the task frontmatter — it is resolved at the dispatch boundary by the Tier Resolution Chain (see implement/SKILL.md), which owns vendor/model selection via the agent's `tier:`, any `--tier-override`, and `config.md`'s `model_routing:` block.

Tasks that omit `task_type:` default to `code` and proceed through the standard routing chain (no per-task `model` default — model selection always defers to the Tier Resolution Chain off the agent's `tier:` field).

**Inherited unchanged across both `task_type` values:** fix-loop round count (3 cycles), accepted-with-issues batch-gate behavior, BLOCKED escape hatch, SendMessage continuity, reviewer parallelism. Lightweight only flips the three flags above.

**Gate-level reviewer (cross-task).** The Batch Gate's `qrspi-implement-gate-reviewer` is gated by `config.second_reviewer` (config-level), not per-task `task_type`. A wave mixing `code` and `lightweight` tasks still gets the gate-level Codex parallel if config enables it.
