---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files:
  - skills/structure/SKILL.md
  - skills/plan/SKILL.md
  - skills/parallelize/SKILL.md
  - skills/implement/SKILL.md
---

# F01 — Multi-Actor Flow Check gate adopted but never invoked from any consumer's Process flow

Each consumer adopts `## Multi-Actor Flow Check` as a standalone section with `!cat` include but no surrounding wiring ties it into the numbered Process / Process Steps / Wave Dispatch / Per-Task Execution flow. The snippet is self-triggering ("Before authoring any deliverable that operationalizes a design decision involving two or more actors..."), but a reader executing the numbered steps linearly will not encounter that trigger from inside the workflow.

Most acute in `skills/implement/SKILL.md`: per-task implementers are dispatched against `tasks/task-NN.md` in worktrees; the implementer subagent reads the task spec, not `skills/implement/SKILL.md`; nothing in the dispatch prompt or Per-Task Execution invokes Multi-Actor Flow Check. The STOP path therefore cannot fire at the point where actor-flow guesses actually get baked into code.

**Silent-failure pattern.** Iron law says "silently inventing a missing hand-off is a contract violation… must be reported even if the deliverable otherwise looks complete." But with no Process step saying "invoke this check before authoring step X," the contract degrades to log-and-continue: rule on disk, deliverable authored, no STOP fires, downstream consumers proceed against a guessed hand-off — exactly the failure mode CD-3 was supposed to close.

**Suggested remediation:** add a one-liner from each consumer's Process flow into the gate. E.g.:
- Plan Overview Subagent: "0. Run Multi-Actor Flow Check above against every in-scope design decision in design.md; STOP per its diagnostic before authoring any task spec."
- Structure Subagent: same pattern at start of its task list, before file-map authoring.
- Parallelize: add at Step 1, before dependency-graph synthesis.
- Implement: add to the implementer dispatch prompt (Per-Task Execution → dispatch contract) so the per-task subagent receives the directive at authoring time, not just on the orchestrator's SKILL.md page it never reads.

In-scope per task DoD #3 ("at the multi-actor-flow checking gate") and within the modify-list.
