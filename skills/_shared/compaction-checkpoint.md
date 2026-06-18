# Compaction Checkpoints (shared)

Single source of truth for the compaction checkpoint contract. QRSPI skills mark transition points where main-chat context bloat degrades downstream quality. At every checkpoint and every user-input pause, the orchestrator follows the Iron Rule below — regardless of perceived utilization. The wait-for-user behavior is interactive-mode-only (see Iron Rule). Self-contained: every rule the orchestrator must apply at a checkpoint is here.

## Iron Rule

Always recommend `/compact` to the user before continuing — at every checkpoint and every user-input pause, regardless of perceived utilization.

**Interactive mode:** pause after surfacing the recommendation so the user can `/compact` (or decline) before responding. Do not skip the recommendation.

**Auto mode:** emit the recommendation as a one-line surface and continue immediately. Do not wait — there is no interactive user to decide. The recommendation remains visible in the session log for later audit.

Detect mode via `bash scripts/detect-interaction-mode.sh` (`VERDICT=auto` or `DETECTION_TYPE=llm-context` with an active autopilot signal → auto mode; otherwise interactive).

## Auto-mode rationale

The recommendation itself is exempt from the auto-mode "minimize interruptions, prefer action" guidance — it exists precisely because mid-flight context bloat is the failure mode auto-mode runs into. Emitting the line costs nothing and preserves audit signal. Waiting in auto mode, however, would deadlock the pipeline (no one to respond), so the wait is interactive-only.

## Two named checkpoints + a piggyback rule

| Mechanism | Trigger | Surface as todo? |
|---|---|---|
| `pre-fanout` checkpoint | Before any parallel subagent dispatch. | **Yes.** |
| `pre-handoff` checkpoint | At end-of-skill, after artifact committed, before invoking the next skill. | **Yes.** |
| Piggyback rule | At every existing user-input pause (review pause-gate menus, verifier-uncertain prompts, max-rounds-reached prompts, artifact-approval gates, replan-gate decisions, any other "wait for user response" moment). Surface the compact recommendation **alongside** whatever the SKILL is already asking. Do **not** introduce new pauses. | No. |

## Todo-surfaced recommendation at named checkpoints

When the orchestrator reaches either named checkpoint (`pre-fanout` or `pre-handoff`), in addition to surfacing the imperative pause, add a todo entry:

```
title:       "Recommend /compact ({checkpoint-type}) — {current-skill-name}"
description: "{checkpoint-type}: {one-line stage-specific reason}. User decides whether to /compact."
```

Mark the todo `completed` once the user responds either way. The todo entry makes the recommendation visible in the user's task list. Piggyback pauses do **not** surface a todo — the existing user-input prompt at that site is itself the visibility surface, and a todo entry would double-surface the same recommendation.

## Per-checkpoint label format

Every named checkpoint (`pre-fanout` / `pre-handoff`) uses this one-line shape:

```
**Compaction checkpoint: {type}.** {Stage-specific reason — one sentence.}
```

## Piggyback-pause format

Existing user-input prompts gain a one-line addition (typically the last bullet or last sentence of the prompt):

```
Before responding, consider running `/compact` — context may be saturated.
```

The user-facing line stands on its own. The Iron Rule itself is NOT restated at per-site labels or piggyback-pause additions — the canonical contract above is the single source of truth. Per-site rationale stays specific to the moment (e.g., `Reviewer fan-out reads synthesis state; saturated context produces truncated findings`); the Iron Rule stays shared.
