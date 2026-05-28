---
artifact: design
reviewer: quality-claude
round: 1
finding_id: F03
severity: medium
check: no-internal-contradictions
---

# F03 — DKR6 introduces a "Host = Codex CLI" detection branch that DKR7 and the test strategy leave without a specified dispatch transport

## Location

- `design.md` § **DKR6** — detection logic introduces three possible host states
- `design.md` § **DKR7** — dispatch transport specified for only two of those three states
- `design.md` § **Test Strategy — G6**
- `design.md` § **System Diagram** — `H_CODEX` node is a terminal with no outbound edges

## Observation

DKR6 defines a three-way detection result:

1. `COPILOT_CLI=1` set → **Host = Copilot CLI**
2. `command -v codex` succeeds → **Host = Codex CLI** (standalone)
3. Neither matches → **Host = Claude Code**

DKR7 then documents Codex dispatch transport branches **for only two of the three hosts**:

> Under Claude Code: shell pipeline via `scripts/run-codex-review.sh`.  
> Under Copilot CLI: native subagent dispatch via the `task` tool with `agent_type: code-review` and `model: gpt-5.3-codex`.

The "Host = Codex CLI" case is never addressed. The system diagram makes this visible as `H_CODEX` — a terminal node with no outbound edge to either DISPATCH or any other component. The G6 test strategy exercises only "COPILOT_CLI=1 set" and "COPILOT_CLI unset + command -v codex mock" scenarios, but does not specify what the expected behavior is when the host is detected as standalone Codex CLI (what transport does the test assert?).

`goals.md` acknowledges the scope limit ("Codex CLI's own Codex-reviewer dispatch transport is out of scope for v0.7.1 unless trivial"), but the design does not propagate that decision into DKR7. As written, DKR7 implies the detection result selects the transport, without saying what the Codex CLI detection result *selects*.

## Why it matters

An implementer writing the host-detection function sees three `if`/`elif`/`else` branches in DKR6. When they reach the DKR7 transport-selection logic, they have no specified behavior for the `H_CODEX` branch. Likely implementation choices — silently fall back to Claude Code transport, emit an error and exit, or skip Codex reviewer dispatch entirely — have meaningfully different user-experience consequences and are not equivalent. Without a stated decision, an implementer will guess.

The test strategy gap compounds this: if the G6 integration test for standalone Codex CLI host is left unspecified, the implemented behavior will never be pinned, and the three-state detection function will ship with one branch effectively dead-code from a test-coverage perspective.

## Recommended fix

Add a sentence to DKR7 (or a new DKR7a) that explicitly disposes of the Codex CLI host branch for v0.7.1. For example:

> Under standalone Codex CLI (detected via `command -v codex`), Codex reviewer dispatch is **not attempted** in v0.7.1; the function returns `codex_unavailable` with a one-line diagnostic naming the host and deferring to v0.8. The shell pipeline is not invoked.

(Or alternatively: "falls back to Claude Code transport as a safe default.")

Update the G6 test strategy to assert the expected behavior for the third detection state. Update the system diagram to add an explicit edge or annotation from `H_CODEX` to show it is intentionally a no-op in v0.7.1.
