---
id: quality-claude-006
artifact: questions
severity: MEDIUM
check: comprehensiveness
---

## Finding

No question addresses whether `scripts/run-third-party-llm.sh` is reachable from Copilot CLI dispatches — a prerequisite check the goals' Cross-Cutting Notes explicitly place at the opening of Questions/Design for G1.

### What the goals say

The Cross-Cutting Notes state:

> A potential G8 placeholder remains open for the broader subagent-dispatch port question (whether `scripts/run-third-party-llm.sh`, `scripts/codex-companion-bg.sh`, `scripts/run-codex-review.sh`, and the fan-out reviewer dispatch contracts that assume `Agent({})` semantics are partially dead under Copilot CLI). **G1 (#185 grep-P in `run-third-party-llm.sh`) may collapse into G8 if that script is unreachable under Copilot. The walkthrough at the top of Questions / Design should re-shape G1 and decide whether G8 fits v0.7.1 or earns its own release.**

This is an explicit instruction to Questions to include a question that determines whether the G1 fix is materially reachable before committing Design effort to it.

### What is missing

Q1 asks about the current implementation of control-character detection inside `run-third-party-llm.sh`. Q2 asks for POSIX-portable alternatives. Neither question asks:

1. What dispatch path calls `run-third-party-llm.sh` under Copilot CLI (or whether any dispatch path does)?
2. Which skills or agent files currently invoke the script, and do those call sites operate under the Copilot CLI transport?
3. Could the G1 portability fix become moot if the script is not on the active dispatch path for the target host?

### Impact

If Research returns answers to Q1 and Q2 without resolving the G8 reachability question, Design will open with research on a fix whose applicability is uncertain. The goals explicitly flag this as the question that determines whether G1 should be re-scoped or collapsed — omitting it risks wasted Design effort.

### Suggested additional question

> [codebase] What agent files, skill files, or dispatcher scripts invoke `scripts/run-third-party-llm.sh` today, and is this script on the active dispatch path for non-Anthropic LLM calls under the Copilot CLI transport — or is it only reachable under the Claude Code / direct-subprocess transport?
