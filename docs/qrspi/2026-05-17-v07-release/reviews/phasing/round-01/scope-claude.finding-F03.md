---
finding_id: R1-F03
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/phasing.md:L44-L85]
artifact: phasing
round: 1
reviewer: scope-claude
---

The replan-gate criteria throughout `## Phases` contain Plan-level task expectations, Parallelize-level wave decisions, and Implement-level dispatch verbs and shell invocations that belong to downstream artifacts per the DEFERS rule.

Specific boundary-crossing instances:

- **Plan-owned task expectations** (DEFERS: "Task specs, LOC estimates, ordered task lists, per-task test expectations"): Slice 2 gate specifies the ordered dispatch sequence "triggers `qrspi-test-writer`... then `qrspi-implementer` after the RED-verification gate" and behavioral classifications (`assertion-failure`, `infrastructure-failure`, `pass`) — these are per-task test expectations. Slice 6 gate specifies "a plan with N=3 tasks dispatches sub-subagents in parallel and produces 3 separate `tasks/task-NN.md` files" — a Plan-level acceptance criterion.

- **Parallelize-owned wave decisions** (DEFERS: "Dependency graph, Wave decisions, branch maps"): Slice 5 gate states "A wave-1 reference-gated task pauses Implement before any wave-2 dependent dispatches" — wave sequencing and wave-boundary behavior are owned by Parallelize, not Phasing.

- **Implement-level dispatch verbs and shell commands** (DEFERS: "Implementation prose, code, hook syntax, subagent dispatch verbs"): Slice 1 gate includes a full shell invocation with flags (`scripts/run-third-party-llm.sh --provider deepseek --model deepseek-v3 --output-file /tmp/r.txt`), which is implementation jargon. Slice 5 gate names "`SendUserFile`" — a specific subagent dispatch verb.

Replan-gate criteria should be demonstrability thresholds stated at the slice level (what the user can observe end-to-end), not task-dispatch order, wave structure, or shell command correctness. The fix is to restate each gate criterion in terms of observable slice-level outcomes — e.g. "cost-reduction route is exercised against a real provider" rather than specifying the exact CLI flags — and remove ordering, wave, and dispatch-verb detail that Plan and Parallelize will define.
