The per-task flow dispatches subagents defined under `agents/`. Each agent file carries its full prompt body, tool list, and dispatch-parameter contract; main chat invokes them via `dispatch(subagent_type: <agent-name>)`.

```
agents/
├── qrspi-implementer.md                       (TDD — task_type: code)
├── qrspi-implementer-lightweight.md           (single-pass — task_type: lightweight)
├── qrspi-spec-reviewer.md                     (correctness — gate)
├── qrspi-code-quality-reviewer.md             (correctness)
├── qrspi-silent-failure-hunter.md             (correctness)
├── qrspi-security-reviewer.md                 (correctness)
├── qrspi-goal-traceability-reviewer.md        (thoroughness — deep only)
├── qrspi-test-coverage-reviewer.md            (thoroughness — deep only)
├── qrspi-type-design-analyzer.md              (thoroughness — deep only)
├── qrspi-code-simplifier.md                   (thoroughness — deep only)
└── qrspi-implement-gate-reviewer.md           (cross-task gate-level reviewer)
```

Correctness checks if code is right and safe — always runs. Thoroughness checks if it's complete, well-typed, and clean — deep mode only, AND only on `task_type: code`. Execution: spec-reviewer first (gate), remaining correctness in parallel, then thoroughness in parallel (deep + code only).

**Why spec-reviewer is a gate.** When spec-reviewer fails, the fix-loop typically rewrites whole functions or adds missing behaviors, which moves every line number and invalidates every line-level finding the other reviewers would have produced. Running cq + sf + sec in parallel with spec-reviewer wastes reviewer tokens on findings that go stale.

> ⚠ **Spec-reviewer is a gate, not the whole review.** A CLEAN spec-reviewer in any round MUST immediately trigger the same-round fan-out:
>
> - **Quick mode:** spec-reviewer (CLEAN) → cq + sf + sec in parallel → if all CLEAN, task terminal CLEAN.
> - **Deep mode:** spec-reviewer (CLEAN) → cq + sf + sec in parallel → if all CLEAN, gt + tc + tda + cs in parallel → if all CLEAN, task terminal CLEAN.
>
> Declaring terminal CLEAN on spec-gate evidence alone is a **P0 process violation** — it ships task code without the depth-mode safety net.
