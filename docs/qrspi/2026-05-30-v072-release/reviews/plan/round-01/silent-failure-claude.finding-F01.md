---
finding_id: R1-F01
severity: low
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
  - docs/qrspi/2026-05-30-v072-release/design.md
artifact: plan.md
---

# T16 (G22) `_resolve-lib.sh` hardcoded-`medium` fallback is a log-and-continue silent failure

## Where

`plan.md` § **Task 16: G22 `model_routing` config schema and agent-sweep migration**:

- **Scope → In:** "Create/update `scripts/_resolve-lib.sh` as the shared routing resolver for agent-frontmatter `tier:` parsing, precedence (`--tier-override` / per-dispatch override → agent `tier:` → `default_tier:` → **hardcoded `medium` with loud warning**), …"
- **Test expectations:** "Exercise/grep `_resolve-lib.sh` coverage for per-dispatch tier override, agent `tier:`, `default_tier:`, and **hardcoded-medium-with-warning** precedence."

Carried forward verbatim from `design.md` § **CD-1 → component 1 → Override precedence**, step 4: *"Hard-coded fallback `medium` with loud warning"*.

## What goes wrong silently

This is a designed-in `log-and-continue` fallback (silent-failure-hunter criterion #4) layered on top of an "or default if missing" pattern (criterion #2). When the resolver reaches precedence step 4, the conditions are:

- An agent dispatch was requested with no `--tier-override`, AND
- The agent's frontmatter has no `tier:` field, AND
- `config.md` has no `default_tier:` (or `default_tier:` is malformed and the validator did not catch it).

The resolver's documented response is to **emit a stderr warning and continue dispatch at tier `medium`** rather than halt. In an LLM-orchestrator runtime (Claude Code, Copilot CLI, Codex CLI), bash stderr warnings emitted by a script that returns exit 0 do not reliably surface in the orchestrator's conversation context — only the exit code drives orchestrator branching. The orchestrator will therefore proceed as if the agent ran at its intended tier, when in fact:

- An agent intended for `high` (e.g., a sensitive code-quality reviewer) silently runs at `medium`, downgrading review depth without an observable signal.
- An agent intended for `low` silently runs at `medium`, over-spending without an observable signal.
- An audit of the round's dispatch manifest will record `model: <medium-tier-model>` with no record that this differed from the agent's declared intent (the agent had no declared intent — that's the failure mode being papered over).

The T16 DoD explicitly carves out *some* silent-fallback prohibitions — `"never silently falls back to a neighboring tier or agent-bundled model"` — but this prohibition does not name the hardcoded-`medium` fallback case (because `medium` is neither a "neighboring tier" relative to the agent's missing-tier nor an "agent-bundled model"). The carve-out is precisely the silent-failure surface.

## Why the warning is not loud enough

The brief's criterion #4 says: *"Does the task treat logging as a substitute for error propagation?"* The answer here is yes. The "loud warning" is stderr text; the propagation is missing because:

1. **Exit code is 0.** Callers (skill prose, dispatch-agent.sh stdout-consumer code, orchestrator branching) cannot distinguish "resolved cleanly" from "fell through to hardcoded default".
2. **Dispatch manifest does not flag the fallback.** Per CD-1, manifest entries record resolved `model` only; there is no `tier_resolution_source:` field that would let a reviewer audit notice the fallback fired.
3. **No round-end summary surfaces stderr warnings.** `await-round.sh` (T12) is explicitly bounded to a "short status line" of stdout/stderr; the loud warning bypasses that summary path.

## Why the validation procedure does not cover this

T16 also creates `skills/_shared/config-validation-procedure.md`, and T17 adds a `model_routing:` validation-table row that fails loudly when the block is missing. But:

- T16 DoD says "missing or malformed `model_routing:` configuration fails loudly" — it does not say "missing `default_tier:` specifically fails loudly". `default_tier:` is a sub-field; a config with `model_routing:` present but `default_tier:` absent is not obviously covered by the existing validation path.
- T16 sweeps every existing `agents/qrspi-*.md` to declare `tier:` — but the resolver fallback fires for *any future agent* (third-party, downstream consumer plugin) added without `tier:`. The sweep is a one-time hygiene, not a permanent invariant.

So in practice, the fallback's reachability is "defense-in-depth that should rarely fire" — but when it does fire, it fires silently from the orchestrator's perspective.

## Suggested remediation (plan-level edit, not implementation work)

Tighten the T16 precedence chain in **Scope → In** and **Definition of done** so step 4 halts loudly instead of continuing:

> *Precedence (`--tier-override` → agent `tier:` → `default_tier:` → halt with non-zero exit and a diagnostic naming the unresolved agent and missing `default_tier:` lookup).*

And tighten the **Test expectations** correspondingly:

> *Exercise/grep `_resolve-lib.sh` coverage for per-dispatch tier override, agent `tier:`, `default_tier:`, and **unresolved-tier halt** behavior; verify the resolver never returns a hardcoded-default tier without a non-zero exit.*

This makes the fallback fail-loud (consistent with the `none`-tier halt the same task already requires) and aligns the resolver with the dispatch-routing fail-loud invariant T18 establishes for the broader section.

If the operator wants to preserve the design-approved "warning + continue" behavior because it functions as a migration-window safety net, the plan should at minimum require:

- The resolver writes a `tier_resolution_source: hardcoded-medium-fallback` field to the dispatch manifest entry so post-round audits can grep for fallback fires.
- The `await-round.sh` short status line surfaces a non-zero count of fallback fires for the round.

Either remediation closes the log-and-continue loop. The current plan + design as written does neither.

## Severity rationale

`low` (not `medium` or `high`) because:

- The fallback's reachability requires two failures (missing agent `tier:` AND missing/malformed `default_tier:`) — the T16 agent sweep + T17 validation row together make it rare.
- It does not affect security or data integrity; the worst case is degraded review quality from a silent tier downgrade.
- The behavior is explicitly approved at design.md ## CD-1 component 1, so this finding is asking the operator to re-confirm a known trade-off rather than fix an oversight.

But `low` (not `informational`) because:

- Silent tier downgrades on reviewer agents directly affect the correctness-gating posture v0.7.2 is supposed to harden.
- The "loud warning" framing in plan + design papers over the fact that stderr warnings are not reliably visible to LLM orchestrators, which is the exact runtime context this release operates in.
- The fix is small (change one precedence step from "warn + continue" to "halt") and reverses the silent-failure surface without losing any documented behavior the agent sweep already establishes.
