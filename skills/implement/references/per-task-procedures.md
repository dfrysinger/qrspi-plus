# Per-task auxiliary procedures

## Per-Task Reviewer Dispatch: DONE-Report Companion Wiring

Per the T15 implementer-protocol hygiene contract, every per-task reviewer dispatch (correctness AND thoroughness, every round) MUST include `companion_done_report` (wrapped body of this round's implementer DONE report between `<<<UNTRUSTED-ARTIFACT-START id=done-report>>>` and END markers) and `done_report_path` (absolute path). Omitting either is a hygiene-contract violation; the reviewer's pre-flight fails loud per `skills/implementer-protocol/SKILL.md` § Unacknowledged Hygiene Hits.

## Conditional-Dispatch Precondition Evaluation (T43 runtime contract)

Before any per-task dispatch fires — before pre-implementer test-writer, RED-verification gate, and implementer — main chat reads `conditional:` and `conditional_precondition:` from the task's frontmatter.

- **`conditional:` absent OR `conditional: false`** — unconditionally dispatched; `conditional_precondition:` (if present) is ignored.
- **`conditional: true`** — main chat evaluates `conditional_precondition:` verbatim (a self-describing predicate verifiable against on-disk artifacts and git state without dispatching a subagent). Met → proceed. Not met → short-circuit (no test-writer, no RED gate, no implementer); orchestrator synthesizes a terminal DONE report with `status: skipped` and the precondition-evaluation result as `rationale:`. Batch-gate accounting treats `status: skipped` as terminal, distinct from `clean` and `accepted-with-issues`.

The conditional read is logged to the round's audit trail with the resolved decision (`dispatched`/`skipped`) and, on the skipped path, the precondition-evaluation text.

## TDD Process (inside the implementer subagent)

All steps run inside the implementer subagent. Main chat does not run tests, write code, or commit directly.

1. **Read test expectations** from the task spec.
2. **Write failing tests** based on those expectations.
3. **Run tests — verify fail.** If they pass, the test is vacuous — fix it.
4. **Write minimal implementation** to make the tests pass.
5. **Run tests — verify pass.** If they fail, fix the implementation (not the test).
6. **Sanity check and commit.** Implementer-side typecheck/lint green, then commit inside the worktree's git. NOT the formal review.

**Multi-line commit messages (F-17):** `Write .qrspi-commit-msg.txt` inside the worktree, then `git -C .worktrees/{slug}/task-NN/ commit -F .qrspi-commit-msg.txt`. Delete the file after commit.

## Implementer Status Reporting

The implementer subagent returns one of the statuses below. The Action column names what main chat does next — every Action involves dispatching another subagent, never main-chat execution.

| Status | Main chat action |
|--------|--------|
| **DONE** | Dispatch reviewer subagents against this task's worktree (correctness group; then thoroughness if `review_depth_effective == "deep"` — deep AND `task_type: code`) |
| **DONE_WITH_CONCERNS** | Read concerns; if correctness/scope, note in review log; dispatch reviewers (same as DONE — concerns do not skip review) |
| **NEEDS_CONTEXT** | Gather missing info, re-dispatch implementer subagent with augmented prompt |
| **BLOCKED** | Assess: re-dispatch with more context, switch to more capable model, decompose into smaller tasks, or escalate to user |

## Review Groups

| Group | Reviewer | Quick | Deep | Execution |
|-------|----------|-------|------|-----------|
| Correctness | spec-reviewer | Yes | Yes | First (gate for the rest) |
| Correctness | code-quality-reviewer | Yes | Yes | Parallel after spec passes |
| Correctness | silent-failure-hunter | Yes | Yes | Parallel after spec passes |
| Correctness | security-reviewer | Yes | Yes | Parallel after spec passes |
| Thoroughness | goal-traceability-reviewer | No | Yes | Parallel after correctness passes |
| Thoroughness | test-coverage-reviewer | No | Yes | Parallel after correctness passes |
| Thoroughness | type-design-analyzer (only when new types) | No | Yes | Parallel after correctness passes |
| Thoroughness | code-simplifier | No | Yes | Parallel after correctness passes |
