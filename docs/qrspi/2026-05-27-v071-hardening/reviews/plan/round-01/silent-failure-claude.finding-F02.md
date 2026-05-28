---
id: F02
reviewer: silent-failure-claude
round: 1
artifact: plan.md
category: SILENT_FALLBACK
severity: medium
tasks_affected: [Task 9, Task 10]
goal_ids: [G7b]
---

# F02 — `inherit` tier name preserved in agent prose but has no required `model_routing` entry; resolution silently undefined

## What the plan says

**Task 9 description** (emphasis added):

> "Tier-name references in dispatcher prose blocks **(haiku, sonnet, opus, inherit)** within each
> file are not modified; only the standalone `model:` key in the YAML front matter block is removed."

Task 9 explicitly names `inherit` as a fourth tier-name vocabulary word that survives in agent body
prose after the frontmatter `model:` field is deleted.

**Task 10 test expectations** (the place where `model_routing` coverage is pinned):

> "`docs/qrspi/2026-05-27-v071-hardening/config.md` contains a `model_routing:` table with at
> least one concrete model identifier entry for each of the three tier names (**haiku, sonnet,
> opus**) under the `claude-code` host."
> "`docs/qrspi/2026-05-27-v071-hardening/config.md` contains at least one concrete model
> identifier entry for each of the three tier names under the `copilot-cli` host."

`inherit` does not appear in Task 10's test expectations. Design DKR9 similarly lists only three
tier names: "haiku, sonnet, opus." No design decision or plan task assigns a `model_routing` row
to `inherit`.

## Why this is a silent failure

After Task 9 completes, agents whose body prose contains `inherit` as a tier-name (e.g., in an
inline dispatch annotation) have no resolved model ID path:

- The `model:` frontmatter field is gone (Task 9).
- The `model_routing` table has no row for `inherit` (Task 10 test expectations don't require one).
- No plan task specifies what the dispatcher does when the tier-name lookup in `model_routing`
  produces no match.

At runtime the dispatcher will either:
1. Produce an empty string / null model identifier, which gets sent to the API, causing an
   opaque provider-side error (e.g., "model not found"), **not** the clean "model not available"
   warning the plan is explicitly trying to eliminate; or
2. Silently fall back to some platform default, producing output that doesn't reflect the agent's
   intended tier — callers cannot distinguish "dispatched at intended tier" from "fell back to
   default."

Either outcome is a silent failure. The second is the classic silent-fallback shape:
`missing key → some default → operator cannot tell`.

## Disambiguation: is `inherit` a live tier or dead vocabulary?

The plan does not say `inherit` is a dead keyword being cleaned up. Task 9 says it is **preserved**.
If `inherit` is genuinely dead (no agent body prose uses it), Task 9's description should say "no
agent files currently use `inherit` in prose" — and the structural lint in Task 9 should confirm
that assertion. If it is live, Task 10 must add a `model_routing` entry for it.

## What needs to be added

**Option A — `inherit` is dead vocabulary:** Add a Task 9 test expectation:

> "No agent file body prose contains the string `inherit` as a tier-name token in a dispatch
> annotation after the frontmatter deletion."

This confirms the preserve-but-unused claim and prevents future silent fallbacks.

**Option B — `inherit` is live vocabulary:** Add a Task 10 test expectation:

> "`docs/qrspi/2026-05-27-v071-hardening/config.md` `model_routing:` table contains a concrete
> model identifier entry for `inherit` under both `claude-code` and `copilot-cli` hosts, or the
> `model_routing` resolution logic specifies explicit behavior (e.g., inheriting the caller's
> model context) for that tier name."

**Option C — specify the miss behavior:** Regardless of A or B, Task 10's description and test
expectations must specify what the dispatcher does when a tier name is not found in the
`model_routing` table — it must fail loudly (die with a named-tier error message), not silently
produce empty output or fall back to a default.
