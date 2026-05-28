---
round: 12
artifact: design
status: fixing
---

# Round 12 dispositions

## Findings inventory

- quality-claude: 0 findings (clean sentinel — 3rd consecutive)
- scope-claude: 0 findings (clean sentinel — 12th consecutive)
- quality-codex: 3 findings (medium=3)
- scope-codex: 0 findings (clean sentinel — 10th consecutive)

Total: 3 findings. No HIGH. All correctness. All accept.

Convergence trend: 10 → 3 → 5 → 4 → 2 → 4 → 3 → 4 → 6 → 1 → 2 → 3. Count uptick, but all medium-severity correctness on integration-with-research points; no scope drift, no HIGH. Codex re-launch after compaction recovery (round 12 was re-dispatched because launch jobIds went stale; results are not a drift signal).

## R12-F01 quality-codex (medium) — accept

G1 introduces `model_role:` as agent-file metadata "so agent files name a role, not a concrete model," but research summary documents that current Claude Code resolves agent defaults from concrete `model:` frontmatter at activation time. As written, downstream implementers could replace concrete `model:` with `model_role:` and break Claude-side activation resolution.

**Fix:** In G1, specify the mechanism explicitly. `model_role:` is ADDITIVE metadata; the agent file MUST still carry a concrete `model:` value as the activation-time fallback. The G1 model-resolution chain is:
1. Per-invocation override (passed by orchestrator) — wins.
2. Otherwise: if a `model_role:` is declared AND `config.md.role_map` resolves it, use the resolved concrete model.
3. Otherwise: fall back to the agent file's concrete `model:` frontmatter (the current activation behavior).

Add a design-level test bullet: agent file with `model_role: cheap_reviewer` + `model: sonnet` AND `config.md.role_map.cheap_reviewer: deepseek-v3` resolves to deepseek-v3 at dispatch; remove `role_map` entry and same agent resolves to sonnet (fallback verified).

## R12-F02 quality-codex (medium) — accept

G6 splits test-writer between Plan-time pre-implementation tests and post-implementation tests but treats `qrspi-test-writer` as if it already accepts `task_definition` as the mode signal. Research summary says the current agent body is Test-phase-only. Downstream Plan/Implement could under-scope the work as orchestration-only.

**Fix:** In G6, add an explicit subsection "Agent-contract change required" noting that `qrspi-test-writer` must be extended to support a new Implement-phase mode keyed by `task_definition` presence (matching the existing per-task reviewer dual-mode pattern). The current Test-phase contract is preserved when `task_definition` is absent. Plan/Implement own the agent-body edit; Design owns the dual-mode contract.

Add a design-level test bullet: test-writer dispatch with `task_definition` present produces pre-implementation tests for a single task; same agent dispatched without `task_definition` (Test phase) still produces acceptance tests against `plan.md`.

## R12-F03 quality-codex (medium) — accept

G4 treats Claude Code Agent-tool dispatch automatic prompt caching as settled fact; research summary only establishes general provider patterns, not QRSPI-specific dispatch-path behavior. As written, downstream could under-scope G4 as verification-only.

**Fix:** In G4, soften the Mechanism A framing. Replace assertion-style wording with explicit-hypothesis wording: "If Claude Code's Agent-tool dispatch path already caches stable system-prompt prefixes, Mechanism A reduces to instrumenting hit-rate measurement and validating cache efficacy. If it does not (to be verified during Plan-time spike), Mechanism A also includes adding the caching mechanism at the Anthropic SDK boundary (Anthropic-style `cache_control` markers on stable prefixes) before measurement."

Add a Plan-time spike bullet: verify whether `Agent({})` dispatches produce Anthropic cache-hit metadata in the response; if not, G4 scope expands to include cache enablement.

## Fix dispatch plan

Single fix subagent. 3 accepts. All in design.md.

## Status

draft → fixing → re-review round 13.
